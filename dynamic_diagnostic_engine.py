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
    def get_merged_prioritized_questions(self, merged_diseases: List[Dict[str, Any]], max_questions: int = 15) -> List[Dict[str, Any]]:
        """
        Generate, merge, deduplicate, and prioritize questions for a list of diseases.
        Args:
            merged_diseases: List of disease dicts (each with symptoms/questions)
            max_questions: Maximum number of questions to return
        Returns:
            List of prioritized questions
        """
        all_questions = []
        seen_texts = set()
        for disease in merged_diseases:
            questions = self.generate_questions_for_disease(disease)
            for q in questions:
                # Deduplicate by question text
                text = q.get('text', '').strip()
                if text and text not in seen_texts:
                    # Attach disease name(s) for context
                    q['disease_names'] = [disease.get('name', 'Unknown')]
                    all_questions.append(q)
                    seen_texts.add(text)
                else:
                    # If duplicate, append disease name to existing question
                    for existing in all_questions:
                        if existing.get('text', '').strip() == text:
                            if 'disease_names' in existing:
                                existing['disease_names'].append(disease.get('name', 'Unknown'))
                            else:
                                existing['disease_names'] = [existing.get('disease_name', 'Unknown'), disease.get('name', 'Unknown')]
                            break
        # Prioritize and limit
        prioritized = self.prioritize_questions(all_questions, merged_diseases)
        return prioritized[:max_questions]

    # User-provided hardcoded diseases, symptoms, and questions
    HARDCODED_DISEASES = {
            'head': [
                {
                    'snomed_id': 'USER_tension_headache',
                    'name': 'Tension headache',
                    'symptoms': [{'source': 'user', 'symptom': 'dull pressure'}, {'source': 'user', 'symptom': 'scalp tightness'}],
                    'finding_sites': ['head'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_tension_band', 'text': 'Is the pain like a tight band around your head?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'dull pressure'}
                    ]
                },
                {
                    'snomed_id': 'USER_cluster_headache',
                    'name': 'Cluster headache',
                    'symptoms': [{'source': 'user', 'symptom': 'severe one-sided pain'}, {'source': 'user', 'symptom': 'tearing eye'}],
                    'finding_sites': ['head'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_cluster_severe', 'text': 'Is the headache extremely severe on one side with eye watering?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'severe one-sided pain'}
                    ]
                },
                {
                    'snomed_id': 'USER_temporal_arteritis',
                    'name': 'Temporal arteritis',
                    'symptoms': [{'source': 'user', 'symptom': 'scalp tenderness'}, {'source': 'user', 'symptom': 'jaw pain'}, {'source': 'user', 'symptom': 'vision issues'}],
                    'finding_sites': ['head'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_temporal_jaw', 'text': 'Do you feel jaw pain while chewing or sudden vision problems?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'jaw pain'}
                    ]
                },
                {
                    'snomed_id': 'USER_concussion',
                    'name': 'Concussion',
                    'symptoms': [{'source': 'user', 'symptom': 'dizziness'}, {'source': 'user', 'symptom': 'confusion after injury'}],
                    'finding_sites': ['head'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_concussion_injury', 'text': 'Did symptoms start after a recent head injury or fall?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'confusion after injury'}
                    ]
                }
            ],
            'nose': [
                {
                    'snomed_id': 'USER_common_cold',
                    'name': 'Common cold',
                    'symptoms': [{'source': 'user', 'symptom': 'runny nose'}, {'source': 'user', 'symptom': 'sore throat'}],
                    'finding_sites': ['nose'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_cold_fever', 'text': 'Did symptoms begin with mild fever or sore throat?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'sore throat'}
                    ]
                },
                {
                    'snomed_id': 'USER_allergic_rhinitis',
                    'name': 'Allergic rhinitis',
                    'symptoms': [{'source': 'user', 'symptom': 'sneezing'}, {'source': 'user', 'symptom': 'itching'}, {'source': 'user', 'symptom': 'watery eyes'}],
                    'finding_sites': ['nose'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_rhinitis_itch', 'text': 'Do you have itching with frequent sneezing and watery eyes?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'itching'}
                    ]
                },
                {
                    'snomed_id': 'USER_nasal_polyp',
                    'name': 'Nasal polyp',
                    'symptoms': [{'source': 'user', 'symptom': 'blockage'}, {'source': 'user', 'symptom': 'reduced smell'}],
                    'finding_sites': ['nose'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_polyp_smell', 'text': 'Have you noticed a reduced sense of smell?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'reduced smell'}
                    ]
                },
                {
                    'snomed_id': 'USER_deviated_septum',
                    'name': 'Deviated septum',
                    'symptoms': [{'source': 'user', 'symptom': 'constant one-side blockage'}],
                    'finding_sites': ['nose'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_septum_block', 'text': 'Is one side of your nose always blocked even without infection?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'constant one-side blockage'}
                    ]
                }
            ],
            'back': [
                {
                    'snomed_id': 'USER_muscle_strain',
                    'name': 'Muscle strain',
                    'symptoms': [{'source': 'user', 'symptom': 'pain after lifting'}, {'source': 'user', 'symptom': 'localized stiffness'}],
                    'finding_sites': ['back'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_strain_lift', 'text': 'Did the pain start after lifting something heavy or sudden movement?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'pain after lifting'}
                    ]
                },
                {
                    'snomed_id': 'USER_spinal_stenosis',
                    'name': 'Spinal stenosis',
                    'symptoms': [{'source': 'user', 'symptom': 'leg numbness while walking'}],
                    'finding_sites': ['back'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_stenosis_leg', 'text': 'Do you feel leg pain or numbness that worsens when walking?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'leg numbness while walking'}
                    ]
                },
                {
                    'snomed_id': 'USER_ankylosing_spondylitis',
                    'name': 'Ankylosing spondylitis',
                    'symptoms': [{'source': 'user', 'symptom': 'morning stiffness improving with activity'}],
                    'finding_sites': ['back'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_ank_spond_morning', 'text': 'Is back stiffness worse in the morning but better with movement?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'morning stiffness improving with activity'}
                    ]
                },
                {
                    'snomed_id': 'USER_vertebral_compression_fracture',
                    'name': 'Vertebral compression fracture',
                    'symptoms': [{'source': 'user', 'symptom': 'sudden severe pain'}, {'source': 'user', 'symptom': 'older age'}],
                    'finding_sites': ['back'],
                    'nhs_url': '',
                    'overview': '',
                    'questions': [
                        {'id': 'q_vcf_sudden', 'text': 'Did severe back pain start suddenly after a minor fall or in older age?', 'options': ['Yes', 'No'], 'type': 'single_choice', 'priority': 5, 'symptom_match': 'sudden severe pain'}
                    ]
                }
            ],
        # ... (other body areas omitted for brevity, add as needed) ...
    }

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
        discovered_names = set()  # Prevent duplicates by name (case-insensitive)

        # Helper to add only unique diseases
        def add_unique_disease(disease, source_label=None):
            name = disease.get('name', '').strip().lower()
            if name and name not in discovered_names:
                discovered.append(disease)
                discovered_names.add(name)
                if source_label:
                    logger.info(f"  ✓ {disease.get('name')} ({source_label})")

        # Source 1.5: User-provided hardcoded diseases
        for user_disease in self.HARDCODED_DISEASES.get(body_area, []):
            add_unique_disease(user_disease, 'User')

        # Source 1: NHS UK (fast, reliable)
        logger.info(f"Querying NHS UK for {body_area} conditions...")
        nhs_conditions = self.nhs_scraper.get_conditions_for_body_area(body_area)
        for nhs_slug in nhs_conditions[:limit]:
            nhs_data = self.nhs_scraper.get_disease_info(nhs_slug)
            if nhs_data:
                disease_name = nhs_data['name']
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
                if disease_data['symptoms']:
                    add_unique_disease(disease_data, 'NHS UK')

        # Source 2: SNOMED (comprehensive but slower)
        # The following block is commented out to avoid SNOMED access
        # if len(discovered) < limit:
        #     logger.info(f"Querying SNOMED for {body_area} disorders...")
        #     snomed_term = self.body_area_map.get(body_area, body_area)
        #     snomed_diseases = self.snomed.search_by_body_area(snomed_term, limit=limit-len(discovered))
        #     for disease in snomed_diseases:
        #         disease_name = disease['term']
        #         if disease_name.lower() in discovered_names:
        #             continue
        #         disease_data = self._enrich_disease_data(disease)
        #         if disease_data and disease_data['symptoms']:
        #             add_unique_disease(disease_data, 'SNOMED')

        logger.info(f"Discovered {len(discovered)} total diseases for {body_area}")
        return discovered[:limit]
    
    def _find_snomed_code_for_disease(self, disease_name: str) -> Optional[str]:
        # SNOMED code lookup disabled by user request
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
        # Use hardcoded questions if present
        if 'questions' in disease_data and disease_data['questions']:
            return disease_data['questions']
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

        # List of body part keywords for arms/legs/joints
        body_parts = [
            'elbow', 'elbows', 'shoulder', 'shoulders', 'wrist', 'wrists', 'hand', 'hands', 'finger', 'fingers',
            'forearm', 'forearms', 'arm', 'arms',
            'knee', 'knees', 'leg', 'legs', 'thigh', 'thighs', 'ankle', 'ankles', 'foot', 'feet', 'toe', 'toes',
            'joint', 'joints'
        ]

        for i, symptom_data in enumerate(symptoms):
            symptom = symptom_data['symptom']
            symptom_lower = symptom.lower()
            # If the symptom is just a body part or contains only a body part, clarify as pain in that part
            matched_part = None
            for part in body_parts:
                if symptom_lower.strip() == part or (symptom_lower.strip() in [f"{part}s", f"{part} and {part}s"]):
                    matched_part = part
                    break
                # If symptom is like 'forearms and wrists', 'hands and fingers', etc.
                if all(p in body_parts for p in [s.strip() for s in symptom_lower.replace('and',',').split(',')]):
                    matched_part = symptom
                    break
            if matched_part:
                question_text = f"Do you have pain in your {matched_part}?"
            else:
                question_text = f"Do you have: {symptom}?"

            # Create question ID that includes symptom keywords for matching
            symptom_key = symptom_lower.replace(' ', '_').replace(',', '')[:30]

            questions.append({
                'id': f"symptom_{symptom_key}",
                'text': question_text,
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
                matched_this_symptom = False
                for answer_key, answer_value in user_answers.items():
                    if isinstance(answer_value, str):
                        answer_lower = answer_value.lower()
                        if answer_lower == 'yes':
                            symptom_keywords = symptom.split()[:3]
                            for keyword in symptom_keywords:
                                if len(keyword) > 3 and keyword in answer_key.lower():
                                    matched_this_symptom = True
                                    break
                            if symptom[:20] in answer_key.lower():
                                matched_this_symptom = True
                                break
                    elif isinstance(answer_value, list):
                        for val in answer_value:
                            if val and symptom[:15] in str(val).lower():
                                matched_this_symptom = True
                                break
                if matched_this_symptom:
                    matched += 1
                    matched_symptoms.append(symptom)
            
            # Even with 1 match, include it (for better results)
            if matched > 0:
                # Confidence based strictly on proportion of symptoms matched
                confidence = matched / total_symptoms if total_symptoms else 0.0
                triage = (
                    self.gemini.classify_disease_triage(
                        disease_data['name'],
                        matched_symptoms if matched_symptoms else [s['symptom'] for s in disease_data['symptoms']],
                        disease_data.get('overview', '')
                    ) if self.gemini else self._rule_based_triage(
                        disease_data['name'],
                        matched_symptoms if matched_symptoms else [s['symptom'] for s in disease_data['symptoms']]
                    )
                )
                home_remedies = None
                if triage == 'home care' and self.gemini:
                    try:
                        remedies_prompt = f"""
You are a medical assistant. Suggest 2-3 simple home remedies or exercises for the following condition:
Condition: {disease_data['name']}
Symptoms: {', '.join(matched_symptoms if matched_symptoms else [s['symptom'] for s in disease_data['symptoms']])}
Overview: {disease_data.get('overview', '')[:200]}

Return ONLY a numbered list of remedies/exercises, each 1-2 sentences. Do not mention consulting a doctor unless asked. Do not add extra text.
"""
                        remedies_response = self.gemini.model.generate_content(remedies_prompt)
                        remedies_text = remedies_response.text.strip()
                        home_remedies = remedies_text + "\n\nPerform these remedies/exercises for 2-3 days. If not recovered or you do not feel better, consult medical help."
                    except Exception as e:
                        home_remedies = "Unable to generate home remedies at this time."
                results.append({
                    'disease': disease_data['name'],
                    'snomed_code': disease_data['snomed_id'],
                    'confidence': confidence,
                    'confidence_percentage': f"{confidence * 100:.1f}%",
                    'matched_symptoms': list(set(matched_symptoms)),  # Remove duplicates
                    'total_symptoms': total_symptoms,
                    'nhs_url': disease_data.get('nhs_url'),
                    'overview': disease_data.get('overview', ''),
                    'triage': triage,
                    'home_remedies': home_remedies if triage == 'home care' else None
                })

        # Sort by confidence
        results.sort(key=lambda x: x['confidence'], reverse=True)
        return results

    def _rule_based_triage(self, disease_name: str, symptoms: List[str]) -> str:
        emergency_keywords = [
            'chest pain', 'shortness of breath', 'severe pain', 'bleeding', 'unconscious',
            'difficulty breathing', 'severe headache', 'sudden weakness', 'vision loss',
            'confusion', 'high fever', 'stroke', 'heart attack', 'crushing pain', 'sepsis', 'loss of consciousness'
        ]
        medical_attention_keywords = [
            'infection', 'pneumonia', 'bronchitis', 'asthma', 'appendicitis', 'cellulitis', 'diabetes', 'angina', 'fracture', 'meningitis', 'concussion', 'dvt', 'varicose veins', 'gout', 'arthritis', 'psoriasis', 'shingles', 'tonsillitis', 'labyrinthitis', 'glaucoma', 'cataracts', 'stroke', 'heart disease', 'high blood pressure', 'rheumatoid arthritis', 'osteoarthritis', 'pleurisy', 'constipation', 'diarrhoea', 'food poisoning', 'sinusitis', 'nosebleed', 'nasal polyps', 'ear infections', 'tinnitus', 'earwax build-up', 'dry eyes', 'migraine', 'eczema', 'chickenpox', 'hives', 'rashes', 'sciatica', 'slipped disc', 'carpal tunnel syndrome', 'tennis elbow', 'repetitive strain injury', 'fever', 'coronavirus', 'covid-19'
        ]
        disease_name_lower = disease_name.lower()
        for kw in emergency_keywords:
            if kw in disease_name_lower or any(kw in s.lower() for s in symptoms):
                return 'emergency'
        for kw in medical_attention_keywords:
            if kw in disease_name_lower or any(kw in s.lower() for s in symptoms):
                return 'requires medical attention'
        return 'home care'


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
        print(f"   - {d['disease']}: {d['confidence_percentage']} | Triage: {d['triage']}")

    print("\n" + "=" * 70)
