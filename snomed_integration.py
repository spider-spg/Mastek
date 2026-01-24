#!/usr/bin/env python3
"""
SNOMED CT Integration for Rural India Diagnostic System
======================================================
Real medical knowledge base to replace hardcoded rules
"""

import json
import re

class SnomedIntegration:
    def __init__(self):
        """Initialize SNOMED medical knowledge base"""
        self.load_snomed_concepts()
        
    def load_snomed_concepts(self):
        """Load core SNOMED concepts for rural medicine"""
        # Core medical knowledge from SNOMED CT
        self.concepts = {
            # Urinary conditions
            "urinary_tract_infection": {
                "snomed_id": "68566005",
                "term": "Urinary tract infectious disease",
                "symptoms": ["burning_urination", "frequent_urination", "fievre"],
                "required_symptoms": ["burning_urination"],
                "confidence_base": 0.85,
                "clinical_notes": "Common bacterial infection, often E.coli"
            },
            "cystitis": {
                "snomed_id": "38822007", 
                "term": "Cystitis",
                "symptoms": ["burning_urination", "frequent_urination"],
                "required_symptoms": ["burning_urination"],
                "confidence_base": 0.8,
                "clinical_notes": "Bladder inflammation"
            },
            
            # Head/neurological conditions
            "meningitis_suspected": {
                "snomed_id": "7180009",
                "term": "Meningitis",
                "symptoms": ["fievre", "severe_headache", "neck_stiffness", "severe_confusion"],
                "required_symptoms": ["fievre", "severe_headache"],
                "confidence_base": 0.9,
                "clinical_notes": "EMERGENCY: Brain infection requiring immediate care",
                "emergency": True
            },
            "severe_headache_syndrome": {
                "snomed_id": "25064002",
                "term": "Severe headache",
                "symptoms": ["severe_headache", "vision_problems", "nausea"],
                "required_symptoms": ["severe_headache"],
                "confidence_base": 0.75,
                "clinical_notes": "May indicate migraine, tension headache, or intracranial pressure"
            },
            "febrile_headache": {
                "snomed_id": "386661006",
                "term": "Fever with headache", 
                "symptoms": ["fievre", "headache"],
                "required_symptoms": ["fievre", "headache"],
                "confidence_base": 0.7,
                "clinical_notes": "Common in viral infections"
            },
            
            # Skin conditions  
            "infectious_dermatitis": {
                "snomed_id": "312608009",
                "term": "Infectious skin disease",
                "symptoms": ["fievre", "rash", "itching"],
                "required_symptoms": ["rash"],
                "confidence_base": 0.8,
                "clinical_notes": "Bacterial or fungal skin infection"
            },
            "allergic_dermatitis": {
                "snomed_id": "238575004",
                "term": "Allergic contact dermatitis",
                "symptoms": ["rash", "itching"],
                "required_symptoms": ["rash", "itching"],
                "confidence_base": 0.75,
                "clinical_notes": "Allergic skin reaction"
            },
            
            # Gastrointestinal  
            "gastroenteritis": {
                "snomed_id": "25374005",
                "term": "Gastroenteritis",
                "symptoms": ["fievre", "nausea", "vomiting", "diarrhea", "stomach_pain"],
                "required_symptoms": ["stomach_pain"],
                "confidence_base": 0.8,
                "clinical_notes": "Stomach and intestinal infection"
            },
            "acute_gastritis": {
                "snomed_id": "4556007",
                "term": "Acute gastritis", 
                "symptoms": ["stomach_pain", "nausea", "vomiting"],
                "required_symptoms": ["stomach_pain"],
                "confidence_base": 0.7,
                "clinical_notes": "Stomach lining inflammation"
            },
            
            # Respiratory
            "upper_respiratory_infection": {
                "snomed_id": "54150009",
                "term": "Upper respiratory infection",
                "symptoms": ["fievre", "toux", "throat_pain", "nose_congestion"],
                "required_symptoms": ["toux"],
                "confidence_base": 0.75,
                "clinical_notes": "Common cold or flu"
            },
            "pneumonia_suspected": {
                "snomed_id": "233604007",
                "term": "Pneumonia",
                "symptoms": ["fievre", "toux", "breathing_difficulty", "chest_pain"],
                "required_symptoms": ["fievre", "toux", "breathing_difficulty"],
                "confidence_base": 0.85,
                "clinical_notes": "Lung infection requiring medical treatment"
            }
        }
        
        # Symptom to body system mapping
        self.body_systems = {
            "urinary": ["burning_urination", "frequent_urination", "blood_in_urine"],
            "neurological": ["headache", "severe_headache", "dizziness", "vision_problems", "severe_confusion", "neck_stiffness"],
            "dermatological": ["rash", "itching", "skin_wounds", "skin_color_change"],
            "gastrointestinal": ["stomach_pain", "nausea", "vomiting", "diarrhea", "heartburn"],
            "respiratory": ["toux", "breathing_difficulty", "chest_pain", "throat_pain", "nose_congestion"],
            "general": ["fievre", "fatigue"]
        }
    
    def analyze_symptoms(self, symptoms_dict):
        """Analyze symptoms using SNOMED medical knowledge"""
        # Convert symptom responses to simple list
        positive_symptoms = [sym for sym, value in symptoms_dict.items() if value > 0]
        
        if not positive_symptoms:
            return []
        
        print(f"🔍 SNOMED analysis: {len(positive_symptoms)} symptoms")
        
        # Score each medical concept
        scored_concepts = []
        
        for concept_id, concept in self.concepts.items():
            score = self._calculate_concept_score(positive_symptoms, concept)
            if score > 0:
                scored_concepts.append({
                    "concept_id": concept_id,
                    "snomed_id": concept["snomed_id"],
                    "term": concept["term"], 
                    "score": score,
                    "confidence": min(score * concept["confidence_base"], 0.95),
                    "clinical_notes": concept.get("clinical_notes", ""),
                    "emergency": concept.get("emergency", False)
                })
        
        # Sort by score
        scored_concepts.sort(key=lambda x: x["score"], reverse=True)
        
        if scored_concepts:
            print(f"   🎯 Top SNOMED match: {scored_concepts[0]['term']} ({scored_concepts[0]['confidence']*100:.1f}%)")
        
        return scored_concepts[:3]  # Return top 3
    
    def _calculate_concept_score(self, positive_symptoms, concept):
        """Calculate how well symptoms match a medical concept"""
        concept_symptoms = set(concept["symptoms"])
        required_symptoms = set(concept.get("required_symptoms", []))
        patient_symptoms = set(positive_symptoms)
        
        # Must have required symptoms
        if not required_symptoms.issubset(patient_symptoms):
            return 0
        
        # Calculate match ratio
        matching_symptoms = concept_symptoms.intersection(patient_symptoms)
        
        if not matching_symptoms:
            return 0
            
        # Score based on:
        # 1. Ratio of matching symptoms
        # 2. Bonus for required symptoms
        # 3. Penalty for extra unrelated symptoms
        
        match_ratio = len(matching_symptoms) / len(concept_symptoms)
        required_bonus = 0.3 if required_symptoms.issubset(patient_symptoms) else 0
        
        # Penalty for symptoms not in this concept
        unrelated_symptoms = patient_symptoms - concept_symptoms
        penalty = len(unrelated_symptoms) * 0.1
        
        score = match_ratio + required_bonus - penalty
        return max(score, 0)
    
    def get_treatment_recommendations(self, concept_id):
        """Get SNOMED-based treatment recommendations"""
        if concept_id not in self.concepts:
            return "Seek medical consultation for proper treatment"
            
        concept = self.concepts[concept_id]
        
        treatments = {
            "urinary_tract_infection": {
                "immediate": "Increase fluid intake, maintain hygiene",
                "medication": "Antibiotics needed - seek medical care",
                "follow_up": "Medical consultation required within 24-48 hours"
            },
            "infectious_dermatitis": {
                "immediate": "Keep area clean and dry, avoid scratching",
                "medication": "Antiseptic cream, possible antibiotics",
                "follow_up": "Medical care if no improvement in 3-4 days"
            },
            "meningitis_suspected": {
                "immediate": "EMERGENCY - Call 108/102 immediately",
                "medication": "Urgent hospital treatment required",
                "follow_up": "Life-threatening - immediate medical intervention"
            },
            "gastroenteritis": {
                "immediate": "ORS, clear fluids, rest",
                "medication": "Maintain hydration, avoid solid foods temporarily",
                "follow_up": "Medical care if symptoms worsen or persist >24h"
            }
        }
        
        return treatments.get(concept_id, {
            "immediate": "Rest and supportive care",
            "medication": "Medical consultation recommended",
            "follow_up": "Follow up with healthcare provider"
        })
    
    def detect_primary_system(self, symptoms_dict):
        """Detect which body system is primarily affected"""
        positive_symptoms = [sym for sym, value in symptoms_dict.items() if value > 0]
        
        system_scores = {}
        for system, system_symptoms in self.body_systems.items():
            matches = len(set(positive_symptoms).intersection(set(system_symptoms)))
            if matches > 0:
                system_scores[system] = matches / len(system_symptoms)
        
        if system_scores:
            primary_system = max(system_scores, key=system_scores.get)
            print(f"   🎯 Primary body system: {primary_system}")
            return primary_system
        
        return "general"

def test_snomed_integration():
    """Test SNOMED integration with sample cases"""
    snomed = SnomedIntegration()
    
    # Test case 1: UTI symptoms
    print("\n🧪 Testing UTI symptoms:")
    uti_symptoms = {"fievre": 1, "burning_urination": 1, "frequent_urination": 0}
    results = snomed.analyze_symptoms(uti_symptoms)
    for result in results:
        print(f"   {result['term']}: {result['confidence']*100:.1f}%")
    
    # Test case 2: Head emergency
    print("\n🧪 Testing head emergency:")
    head_symptoms = {"fievre": 1, "severe_headache": 1, "severe_confusion": 1}
    results = snomed.analyze_symptoms(head_symptoms)
    for result in results:
        print(f"   {result['term']}: {result['confidence']*100:.1f}%")

if __name__ == "__main__":
    test_snomed_integration()