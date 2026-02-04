"""
Dynamic Diagnostic Engine
Discovers diseases from SNOMED + NHS UK at runtime
Generates questions dynamically using Gemini
"""

import logging
import os
from typing import Dict, List, Any, Optional
from snomed_local import SNOMEDLocal
from gemini_client import GeminiClient
import requests
from bs4 import BeautifulSoup
import time

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class NHSUKScraper:
    """Scraper for NHS UK disease information"""
    
    def __init__(self):
        self.base_url = "https://www.nhs.uk/conditions/"
        self.cache = {}
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
        
        # Common NHS UK conditions (pre-populated for faster discovery)
        self.common_conditions = {
            'head': ['headaches', 'migraine', 'meningitis', 'stroke', 'concussion'],
            'eyes': ['conjunctivitis', 'dry-eyes', 'cataracts', 'glaucoma'],
            'ears': ['ear-infections', 'tinnitus', 'earwax-build-up', 'labyrinthitis'],
            'nose': ['sinusitis', 'nosebleed', 'nasal-polyps'],
            'throat': ['sore-throat', 'tonsillitis', 'strep-a', 'laryngitis'],
            'chest': ['pneumonia', 'bronchitis', 'asthma', 'pleurisy', 'chest-pain', 'heart-attack', 'angina'],
            'abdomen': ['appendicitis', 'gastritis', 'irritable-bowel-syndrome-ibs', 'constipation', 'diarrhoea', 'food-poisoning'],
            'back': ['back-pain', 'sciatica', 'slipped-disc'],
            'arms': ['carpal-tunnel-syndrome', 'tennis-elbow', 'repetitive-strain-injury-rsi'],
            'legs': ['dvt', 'varicose-veins', 'gout'],
            'skin': ['eczema', 'psoriasis', 'acne', 'cellulitis', 'chickenpox', 'shingles', 'hives', 'rashes-babies-and-children'],
            'joints': ['arthritis', 'rheumatoid-arthritis', 'osteoarthritis', 'gout'],
            'general': ['fever-in-adults', 'diabetes', 'high-blood-pressure', 'coronavirus-covid-19']
        }
    
    def get_conditions_for_body_area(self, body_area: str) -> List[str]:
        """Get list of NHS UK condition slugs for a body area"""
        return self.common_conditions.get(body_area, [])
    
    def get_disease_info(self, disease_slug: str) -> Optional[Dict[str, Any]]:
        """Fetch disease information from NHS UK"""
        if disease_slug in self.cache:
            return self.cache[disease_slug]
        
        url = f"{self.base_url}{disease_slug}/"
        
        try:
            logger.debug(f"Fetching NHS UK: {url}")
            response = self.session.get(url, timeout=10)
            
            if response.status_code == 404:
                logger.debug(f"NHS UK page not found: {disease_slug}")
                return None
            
            response.raise_for_status()
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract symptoms
            symptoms = []
            symptom_section = soup.find('h2', string=lambda x: x and 'symptom' in x.lower())
            if symptom_section:
                symptom_list = symptom_section.find_next(['ul', 'ol'])
                if symptom_list:
                    symptoms = [li.get_text(strip=True) for li in symptom_list.find_all('li')]
            
            # Extract overview
            overview = ""
            overview_section = soup.find('section', class_='module module--highlighted')
            if overview_section:
                overview = overview_section.get_text(strip=True)[:500]
            
            # Extract title
            title = soup.find('h1')
            disease_name = title.get_text(strip=True) if title else disease_slug.replace('-', ' ').title()
            
            info = {
                'name': disease_name,
                'url': url,
                'symptoms': symptoms,
                'overview': overview,
                'found': True
            }
            
            self.cache[disease_slug] = info
            return info
            
        except Exception as e:
            logger.error(f"Error scraping NHS UK for {disease_slug}: {e}")
            return None


class DynamicDiseaseDiscovery:
    """
    Discovers diseases dynamically from SNOMED + NHS UK
    No hardcoded disease rules
    """
    
    def __init__(self, snomed_path: str, gemini_api_key: Optional[str] = None):
        """
        Initialize dynamic discovery system
        
        Args:
            snomed_path: Path to local SNOMED RF2 directory
            gemini_api_key: Google Gemini API key (optional)
        """
        self.snomed = SNOMEDLocal(snomed_path)
        self.nhs_scraper = NHSUKScraper()
        
        # Initialize Gemini if API key available
        self.gemini = None
        if gemini_api_key:
            try:
                self.gemini = GeminiClient(gemini_api_key)
                logger.info("Gemini AI client initialized")
            except Exception as e:
                logger.warning(f"Could not initialize Gemini: {e}")
        
        # Body area to SNOMED anatomical structure mapping
        self.body_area_map = {
            "head": "head structure",
            "eyes": "eye structure",
            "ears": "ear structure",
            "nose": "nasal structure",
            "throat": "throat structure",
            "chest": "thoracic structure",
            "abdomen": "abdominal structure",
            "back": "back structure",
            "arms": "upper limb structure",
            "legs": "lower limb structure",
            "skin": "skin structure",
            "general": "entire body",
            "joints": "joint structure"
        }
    
    def discover_diseases_for_body_area(self, body_area: str, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Discover all diseases affecting a body area from SNOMED + NHS UK
        
        Args:
            body_area: Body area selected by user
            limit: Maximum diseases to discover
            
        Returns:
            List of discovered diseases with merged SNOMED + NHS UK data
        """
        logger.info(f"Discovering diseases for body area: {body_area}")
        
        discovered = []
        discovered_names = set()  # Prevent duplicates
        
        # Source 1: NHS UK (fast, reliable)
        logger.info(f"Querying NHS UK for {body_area} conditions...")
        nhs_conditions = self.nhs_scraper.get_conditions_for_body_area(body_area)
        
        for nhs_slug in nhs_conditions[:limit]:
            nhs_data = self.nhs_scraper.get_disease_info(nhs_slug)
            if nhs_data:
                disease_name = nhs_data['name']
                
                # Try to find SNOMED code for this NHS condition
                snomed_id = self._find_snomed_code_for_disease(disease_name)
                
                disease_data = {
                    'snomed_id': snomed_id if snomed_id else f"NHS_{nhs_slug}",
                    'name': disease_name,
                    'nhs_slug': nhs_slug,
                    'symptoms': [{'source': 'nhs_uk', 'symptom': s} for s in nhs_data.get('symptoms', [])],
                    'finding_sites': [body_area],
                    'nhs_url': nhs_data['url'],
                    'overview': nhs_data.get('overview', '')
                }
                
                if disease_data['symptoms']:  # Only add if has symptoms
                    discovered.append(disease_data)
                    discovered_names.add(disease_name.lower())
                    logger.info(f"  ✓ {disease_name} (NHS UK)")
        
        # Source 2: SNOMED (comprehensive but slower)
        if len(discovered) < limit:
            logger.info(f"Querying SNOMED for {body_area} disorders...")
            snomed_term = self.body_area_map.get(body_area, body_area)
            snomed_diseases = self.snomed.search_by_body_area(snomed_term, limit=limit-len(discovered))
            
            for disease in snomed_diseases:
                disease_name = disease['term']
                
                # Skip if already found from NHS UK
                if disease_name.lower() in discovered_names:
                    continue
                
                disease_data = self._enrich_disease_data(disease)
                if disease_data and disease_data['symptoms']:
                    discovered.append(disease_data)
                    discovered_names.add(disease_name.lower())
                    logger.info(f"  ✓ {disease_name} (SNOMED)")
        
        logger.info(f"Discovered {len(discovered)} total diseases for {body_area}")
        return discovered[:limit]
    
    def _find_snomed_code_for_disease(self, disease_name: str) -> Optional[str]:
        """Try to find SNOMED code for an NHS UK disease name"""
        # Load descriptions if not already loaded
        if not self.snomed.descriptions_cache:
            self.snomed.load_descriptions()
        
        # Search for matching term
        disease_lower = disease_name.lower()
        for concept_id, descriptions in self.snomed.descriptions_cache.items():
            for desc in descriptions:
                if disease_lower in desc['term'].lower():
                    return concept_id
        
        return None
    
    def _enrich_disease_data(self, snomed_disease: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Enrich SNOMED disease with NHS UK data and clinical findings
        
        Args:
            snomed_disease: Basic SNOMED disease info
            
        Returns:
            Enriched disease data or None if insufficient data
        """
        concept_id = snomed_disease['conceptId']
        disease_name = snomed_disease['term']
        
        # Get SNOMED clinical findings
        snomed_findings = self.snomed.get_associated_findings(concept_id)
        snomed_sites = self.snomed.get_finding_sites(concept_id)
        
        # Convert disease name to NHS URL slug
        nhs_slug = disease_name.lower().replace(' ', '-').replace('(', '').replace(')', '')
        
        # Try to fetch from NHS UK
        nhs_data = self.nhs_scraper.get_disease_info(nhs_slug)
        
        # Merge symptoms from both sources
        all_symptoms = []
        
        # Add SNOMED findings
        for finding in snomed_findings:
            all_symptoms.append({
                'source': 'snomed',
                'symptom': finding['finding']
            })
        
        # Add NHS UK symptoms
        if nhs_data and nhs_data.get('symptoms'):
            for symptom in nhs_data['symptoms']:
                all_symptoms.append({
                    'source': 'nhs_uk',
                    'symptom': symptom
                })
        
        # Skip if no symptoms found
        if not all_symptoms:
            logger.debug(f"Skipping {disease_name} - no symptoms found")
            return None
        
        return {
            'snomed_id': concept_id,
            'name': disease_name,
            'nhs_slug': nhs_slug,
            'symptoms': all_symptoms,
            'finding_sites': [s['site'] for s in snomed_sites],
            'nhs_url': nhs_data['url'] if nhs_data else None,
            'overview': nhs_data.get('overview', '') if nhs_data else ''
        }
    
    def generate_questions_for_disease(self, disease_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Generate discriminating questions for a disease
        Uses Gemini if available, falls back to template-based
        
        Args:
            disease_data: Enriched disease data
            
        Returns:
            List of questions
        """
        symptoms = [s['symptom'] for s in disease_data['symptoms']]
        
        # Try Gemini first
        if self.gemini:
            try:
                questions = self.gemini.generate_questions_for_disease(
                    disease_name=disease_data['name'],
                    symptoms=symptoms[:5],  # Top 5 symptoms
                    body_area=disease_data.get('finding_sites', [''])[0] if disease_data.get('finding_sites') else ''
                )
                if questions:
                    return questions
            except Exception as e:
                logger.warning(f"Gemini question generation failed: {e}")
        
        # Fallback to template-based questions
        return self._generate_template_questions(disease_data)
    
    def _generate_template_questions(self, disease_data: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Generate basic template questions when Gemini unavailable"""
        questions = []
        symptoms = disease_data['symptoms'][:5]  # Top 5 symptoms
        
        for i, symptom_data in enumerate(symptoms):
            symptom = symptom_data['symptom']
            
            # Create question ID that includes symptom keywords for matching
            symptom_key = symptom.lower().replace(' ', '_').replace(',', '')[:30]
            
            questions.append({
                'id': f"symptom_{symptom_key}",
                'text': f"Do you have: {symptom}?",
                'options': ['Yes', 'No'],
                'type': 'single_choice',
                'priority': 5,
                'symptom_match': symptom,
                'disease_id': disease_data['snomed_id']
            })
        
        return questions
    
    def prioritize_questions(self, all_questions: List[Dict[str, Any]], discovered_diseases: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Prioritize questions based on:
        1. Discriminating power (symptom uniqueness)
        2. Severity (emergency symptoms)
        3. Commonality (common vs rare diseases)
        
        Args:
            all_questions: List of all questions from all diseases
            discovered_diseases: List of enriched disease data
            
        Returns:
            Prioritized and scored questions
        """
        logger.info("Prioritizing questions for maximum diagnostic value...")
        
        # Emergency/severity keywords (high priority)
        emergency_keywords = [
            'chest pain', 'shortness of breath', 'severe pain', 'bleeding', 'unconscious',
            'difficulty breathing', 'severe headache', 'sudden weakness', 'vision loss',
            'confusion', 'high fever', 'chest pressure', 'crushing pain', 'stroke'
        ]
        
        # Common symptom keywords (lower discriminating power)
        common_keywords = [
            'tired', 'fatigue', 'headache', 'cough', 'fever', 'pain', 'ache'
        ]
        
        # Count how many diseases each symptom appears in
        symptom_disease_count = {}
        disease_prevalence = {
            'pneumonia': 8, 'bronchitis': 7, 'asthma': 9,  # Common
            'heart attack': 5, 'stroke': 4,  # Severe
            'pleurisy': 3, 'angina': 4  # Less common
        }
        
        for q in all_questions:
            symptom = q.get('symptom_match', q.get('text', '')).lower()
            if symptom not in symptom_disease_count:
                symptom_disease_count[symptom] = 0
            symptom_disease_count[symptom] += 1
        
        # Score each question
        for q in all_questions:
            score = 5.0  # Base score
            symptom = q.get('symptom_match', q.get('text', '')).lower()
            text = q.get('text', '').lower()
            
            # 1. Severity/Emergency bonus (+5 points)
            for emergency_kw in emergency_keywords:
                if emergency_kw in text or emergency_kw in symptom:
                    score += 5.0
                    q['is_emergency'] = True
                    break
            
            # 2. Discriminating power (unique symptoms get bonus)
            disease_count = symptom_disease_count.get(symptom, 1)
            if disease_count == 1:
                score += 3.0  # Unique symptom = high discriminating power
            elif disease_count == 2:
                score += 1.5
            elif disease_count >= 5:
                score -= 1.0  # Very common symptom = low discriminating power
            
            # 3. Common symptom penalty
            for common_kw in common_keywords:
                if common_kw in symptom or common_kw in text:
                    score -= 1.0
                    break
            
            # 4. Disease prevalence (ask about common diseases first)
            disease_name = None
            for disease in discovered_diseases:
                if disease['snomed_id'] == q.get('disease_id'):
                    disease_name = disease['name'].lower()
                    break
            
            if disease_name:
                for disease_key, prevalence in disease_prevalence.items():
                    if disease_key in disease_name:
                        score += prevalence * 0.3  # Common diseases get slight boost
                        break
            
            q['priority_score'] = max(score, 0.1)  # Minimum score
        
        # Sort by priority score (highest first)
        sorted_questions = sorted(all_questions, key=lambda x: x.get('priority_score', 5), reverse=True)
        
        logger.info(f"Prioritized {len(sorted_questions)} questions. Top priority: {sorted_questions[0]['text'][:50]}... (score: {sorted_questions[0].get('priority_score', 0):.1f})")
        
        return sorted_questions
    
    def build_dynamic_rule(self, disease_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Build a diagnostic rule dynamically from disease data
        
        Args:
            disease_data: Enriched disease data
            
        Returns:
            Diagnostic rule compatible with existing engine
        """
        # Generate questions
        questions = self.generate_questions_for_disease(disease_data)
        
        # Build rule
        rule = {
            'snomed_code': disease_data['snomed_id'],
            'display_name': disease_data['name'],
            'nhs_page': disease_data['nhs_slug'],
            'questions': questions,
            'symptoms': [s['symptom'] for s in disease_data['symptoms']],
            'required_conditions': [],
            'optional_conditions': [],
            'base_confidence': 0.4
        }
        
        return rule
    
    def diagnose_from_answers(self, discovered_diseases: List[Dict[str, Any]], user_answers: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Perform diagnosis based on discovered diseases and user answers
        
        Args:
            discovered_diseases: List of enriched disease data
            user_answers: User's answers to questions
            
        Returns:
            Ranked list of matching diseases
        """
        results = []
        
        for disease_data in discovered_diseases:
            # Calculate match score
            total_symptoms = len(disease_data['symptoms'])
            if total_symptoms == 0:
                continue
            
            matched = 0
            matched_symptoms = []
            
            # Check each symptom against answers
            for symptom_data in disease_data['symptoms']:
                symptom = symptom_data['symptom'].lower()
                
                # Check if user answered "yes" to any question containing this symptom
                for answer_key, answer_value in user_answers.items():
                    if isinstance(answer_value, str):
                        answer_lower = answer_value.lower()
                        
                        # If user said "yes" and the question was about this symptom
                        if answer_lower == 'yes':
                            # Extract question text from the question ID or check if symptom keywords match
                            symptom_keywords = symptom.split()[:3]  # First 3 words
                            for keyword in symptom_keywords:
                                if len(keyword) > 3 and keyword in answer_key.lower():
                                    matched += 1
                                    matched_symptoms.append(symptom)
                                    break
                            
                            # Also check direct symptom mention in question
                            if symptom[:20] in answer_key.lower():  # First 20 chars of symptom
                                matched += 1
                                matched_symptoms.append(symptom)
                                break
                    
                    elif isinstance(answer_value, list):
                        # Multiple choice answer
                        for val in answer_value:
                            if val and symptom[:15] in str(val).lower():
                                matched += 1
                                matched_symptoms.append(symptom)
                                break
            
            # Even with 1 match, include it (for better results)
            if matched > 0:
                # Confidence based on proportion of symptoms matched
                confidence = min((matched / total_symptoms) * 1.5, 1.0)  # Boost confidence
                
                results.append({
                    'disease': disease_data['name'],
                    'snomed_code': disease_data['snomed_id'],
                    'confidence': confidence,
                    'confidence_percentage': f"{round(confidence * 100)}%",
                    'matched_symptoms': list(set(matched_symptoms)),  # Remove duplicates
                    'total_symptoms': total_symptoms,
                    'nhs_url': disease_data.get('nhs_url'),
                    'overview': disease_data.get('overview', '')
                })
        
        # Sort by confidence
        results.sort(key=lambda x: x['confidence'], reverse=True)
        
        return results


if __name__ == "__main__":
    # Test the dynamic system
    print("=" * 70)
    print("Testing Dynamic Disease Discovery System")
    print("=" * 70)
    
    snomed_path = "D:\\Symptomate😂2\\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z\\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z"
    gemini_key = os.getenv('GEMINI_API_KEY')
    
    engine = DynamicDiseaseDiscovery(snomed_path, gemini_key)
    
    # Test: Discover diseases for chest
    print("\n1. Discovering diseases for 'chest'...")
    diseases = engine.discover_diseases_for_body_area("chest", limit=5)
    
    for disease in diseases:
        print(f"\n   Disease: {disease['name']}")
        print(f"   SNOMED ID: {disease['snomed_id']}")
        print(f"   Symptoms: {len(disease['symptoms'])}")
        if disease['symptoms']:
            print(f"   - {disease['symptoms'][0]['symptom']}")
        print(f"   NHS URL: {disease.get('nhs_url', 'N/A')}")
    
    # Test: Generate questions for first disease
    if diseases:
        print(f"\n2. Generating questions for {diseases[0]['name']}...")
        questions = engine.generate_questions_for_disease(diseases[0])
        for q in questions[:3]:
            print(f"   Q: {q['text']}")
    
    # Test: Diagnose from sample answers
    print("\n3. Testing diagnosis with sample answers...")
    sample_answers = {
        'has_cough': 'yes',
        'has_chest_pain': 'yes',
        'has_fever': 'yes'
    }
    
    diagnoses = engine.diagnose_from_answers(diseases, sample_answers)
    print(f"\n   Found {len(diagnoses)} matches:")
    for d in diagnoses[:3]:
        print(f"   - {d['disease']}: {d['confidence_percentage']}")
    
    print("\n" + "=" * 70)
