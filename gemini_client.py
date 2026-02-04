"""
Google Gemini API Client
For intelligent question generation and symptom interpretation
"""

import google.generativeai as genai
import logging
import json
from typing import Dict, List, Any, Optional

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class GeminiClient:
    """
    Client for Google Gemini API
    Handles intelligent question generation and medical reasoning
    """
    
    def __init__(self, api_key: Optional[str] = None):
        """
        Initialize Gemini client
        
        Args:
            api_key: Google Gemini API key (if None, reads from environment)
        """
        # Configure API key
        if api_key:
            genai.configure(api_key=api_key)
        
        # Use Gemini 2.0 Flash model
        self.model = genai.GenerativeModel('gemini-2.0-flash')
    
    def generate_questions_for_disease(
        self, 
        disease_name: str, 
        symptoms: List[str], 
        body_area: str
    ) -> List[Dict[str, Any]]:
        """
        Generate discriminating questions for a disease based on its symptoms
        
        Args:
            disease_name: Name of the disease
            symptoms: List of associated symptoms from SNOMED
            body_area: Affected body area
            
        Returns:
            List of question dictionaries with options
        """
        prompt = f"""You are a medical diagnostic assistant. Generate 3-5 discriminating questions to help diagnose {disease_name}.

Disease: {disease_name}
Body Area: {body_area}
Known Symptoms: {', '.join(symptoms) if symptoms else 'None provided'}

Generate questions in this EXACT JSON format:
{{
    "questions": [
        {{
            "id": "unique_question_id",
            "text": "Question text?",
            "options": ["Option 1", "Option 2", "Option 3"],
            "type": "single_choice",
            "priority": 5
        }}
    ]
}}

Requirements:
- Questions should be clear, non-technical, patient-friendly
- Options should be mutually exclusive
- Priority: 1-10 (10 = most important for diagnosis)
- Focus on symptoms, duration, severity, triggers, timing
- Use simple language, avoid medical jargon

Generate the JSON now:"""

        try:
            response = self.model.generate_content(prompt)
            
            # Extract JSON from response
            text = response.text.strip()
            
            # Remove markdown code blocks if present
            if text.startswith('```json'):
                text = text[7:]
            if text.startswith('```'):
                text = text[3:]
            if text.endswith('```'):
                text = text[:-3]
            
            text = text.strip()
            
            data = json.loads(text)
            questions = data.get('questions', [])
            
            logger.info(f"Generated {len(questions)} questions for {disease_name}")
            return questions
            
        except Exception as e:
            logger.error(f"Error generating questions: {e}")
            return []
    
    def map_snomed_findings_to_symptoms(
        self, 
        findings: List[Dict[str, Any]]
    ) -> List[str]:
        """
        Convert SNOMED clinical findings to simple symptom descriptions
        
        Args:
            findings: List of SNOMED clinical findings
            
        Returns:
            List of simple symptom descriptions
        """
        if not findings:
            return []
        
        findings_text = "\n".join([f"- {f.get('finding', f.get('type', 'Unknown'))}" for f in findings])
        
        prompt = f"""Convert these SNOMED CT clinical findings into simple, patient-friendly symptom descriptions.

SNOMED Findings:
{findings_text}

Convert each to a simple symptom phrase (e.g., "headache", "fever", "cough", "chest pain").
Return ONLY a JSON array of strings, nothing else:

["symptom1", "symptom2", ...]"""

        try:
            response = self.model.generate_content(prompt)
            
            text = response.text.strip()
            
            # Remove markdown
            if text.startswith('```json'):
                text = text[7:]
            if text.startswith('```'):
                text = text[3:]
            if text.endswith('```'):
                text = text[:-3]
            
            text = text.strip()
            
            symptoms = json.loads(text)
            logger.info(f"Mapped {len(findings)} findings to {len(symptoms)} symptoms")
            return symptoms
            
        except Exception as e:
            logger.error(f"Error mapping findings: {e}")
            return []
    
    def analyze_answers_for_diagnosis(
        self,
        disease_candidates: List[Dict[str, Any]],
        user_answers: Dict[str, Any]
    ) -> List[Dict[str, Any]]:
        """
        Use Gemini to analyze user answers and rank disease probabilities
        
        Args:
            disease_candidates: List of possible diseases with symptoms
            user_answers: User's answers to questions
            
        Returns:
            Ranked list of diseases with confidence scores
        """
        diseases_text = "\n".join([
            f"- {d['name']}: {', '.join(d.get('symptoms', []))}"
            for d in disease_candidates
        ])
        
        answers_text = "\n".join([
            f"- {k}: {v}"
            for k, v in user_answers.items()
        ])
        
        prompt = f"""You are a medical diagnostic AI. Based on the patient's answers, rank these diseases by likelihood.

Possible Diseases:
{diseases_text}

Patient Answers:
{answers_text}

Return a JSON array of diseases ranked by probability (highest first):
[
    {{
        "disease": "Disease Name",
        "confidence": 0.85,
        "reasoning": "Brief explanation"
    }}
]

Confidence should be 0.0-1.0. Be conservative with high confidence scores."""

        try:
            response = self.model.generate_content(prompt)
            
            text = response.text.strip()
            
            # Remove markdown
            if text.startswith('```json'):
                text = text[7:]
            if text.startswith('```'):
                text = text[3:]
            if text.endswith('```'):
                text = text[:-3]
            
            text = text.strip()
            
            rankings = json.loads(text)
            logger.info(f"Analyzed {len(rankings)} disease probabilities")
            return rankings
            
        except Exception as e:
            logger.error(f"Error analyzing answers: {e}")
            return []
    
    def map_body_area_to_snomed_site(self, body_area: str) -> str:
        """
        Map user-friendly body area to SNOMED anatomical site
        
        Args:
            body_area: User-selected body area (e.g., "head", "chest")
            
        Returns:
            SNOMED anatomical search term
        """
        mapping = {
            "head": "head structure",
            "eyes": "eye structure",
            "ears": "ear structure",
            "nose": "nasal structure",
            "throat": "throat structure",
            "chest": "thorax structure",
            "abdomen": "abdominal structure",
            "back": "back structure",
            "arms": "upper limb structure",
            "legs": "lower limb structure",
            "skin": "skin structure",
            "general": "body structure",
            "joints": "joint structure"
        }
        
        return mapping.get(body_area.lower(), body_area)


if __name__ == "__main__":
    import os
    
    # Test the Gemini client
    api_key = os.getenv('GEMINI_API_KEY')
    
    if not api_key:
        print("ERROR: Please set GEMINI_API_KEY environment variable")
        print("Get your API key from: https://makersuite.google.com/app/apikey")
        exit(1)
    
    client = GeminiClient(api_key)
    
    print("=" * 70)
    print("Testing Gemini AI Client")
    print("=" * 70)
    
    # Test 1: Generate questions
    print("\n1. Generating questions for 'Migraine'...")
    questions = client.generate_questions_for_disease(
        disease_name="Migraine",
        symptoms=["throbbing headache", "nausea", "light sensitivity"],
        body_area="head"
    )
    
    for q in questions:
        print(f"\n   Q: {q.get('text')}")
        print(f"   Options: {q.get('options')}")
        print(f"   Priority: {q.get('priority')}")
    
    # Test 2: Map SNOMED findings
    print("\n2. Mapping SNOMED findings to symptoms...")
    findings = [
        {"finding": "Cephalgia (finding)"},
        {"finding": "Nausea and vomiting (finding)"},
        {"finding": "Photophobia (finding)"}
    ]
    
    symptoms = client.map_snomed_findings_to_symptoms(findings)
    print(f"   Mapped symptoms: {symptoms}")
    
    print("\n" + "=" * 70)
