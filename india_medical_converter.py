#!/usr/bin/env python3
"""
🇮🇳 DDXPLUS ENGLISH TRANSLATION SYSTEM
======================================
Extracts English versions for rural India deployment
"""

import json
import pickle
import numpy as np

class DDXPlusEnglishSystem:
    def __init__(self, ddxplus_path="D:/Symptomate😂2/20043374 (1)"):
        self.ddxplus_path = ddxplus_path
        self.english_diseases = {}
        self.english_questions = {}
        self.india_optimized_questions = {}
        
    def extract_english_data(self):
        """Extract all English versions from DDXPlus"""
        print("🇮🇳 EXTRACTING ENGLISH DATA FOR INDIA DEPLOYMENT")
        print("=" * 55)
        
        # Load and extract English diseases
        with open(f"{self.ddxplus_path}/release_conditions.json", 'r', encoding='utf-8') as f:
            conditions = json.load(f)
        
        print("📋 Extracting English disease names...")
        for french_name, data in conditions.items():
            english_name = data.get("cond-name-eng", french_name)
            self.english_diseases[french_name] = {
                "english_name": english_name,
                "icd10": data.get("icd10-id", ""),
                "french_name": french_name
            }
        
        # Load and extract English questions
        with open(f"{self.ddxplus_path}/release_evidences.json", 'r', encoding='utf-8') as f:
            evidences = json.load(f)
        
        print("❓ Extracting English questions...")
        for evidence_name, data in evidences.items():
            english_question = data.get("question_en", "")
            if english_question:
                self.english_questions[evidence_name] = {
                    "english_question": english_question,
                    "french_question": data.get("question_fr", ""),
                    "data_type": data.get("data_type", "B")
                }
        
        print(f"✅ Extracted {len(self.english_diseases)} diseases in English")
        print(f"✅ Extracted {len(self.english_questions)} questions in English")
        
        return True
    
    def create_india_friendly_questions(self):
        """Create India-friendly simplified questions"""
        print("\n🇮🇳 CREATING INDIA-FRIENDLY QUESTIONS")
        print("=" * 45)
        
        # Core questions for rural India - simplified and culturally appropriate
        india_core_questions = [
            {
                "evidence": "fievre",
                "original": "Do you have a fever (either felt or measured with a thermometer)?",
                "india_friendly": "Do you feel hot or have fever?",
                "hindi_hint": "(बुखार है?)",
                "importance": "high"
            },
            {
                "evidence": "toux", 
                "original": "Do you have a cough?",
                "india_friendly": "Do you have cough?",
                "hindi_hint": "(खांसी है?)",
                "importance": "high"
            },
            {
                "evidence": "dyspn",
                "original": "Are you experiencing shortness of breath?", 
                "india_friendly": "Do you have difficulty breathing?",
                "hindi_hint": "(सांस लेने में तकलीफ?)",
                "importance": "high"
            },
            {
                "evidence": "douleur_tete",
                "original": "Do you have a headache?",
                "india_friendly": "Do you have headache?", 
                "hindi_hint": "(सिर दर्द है?)",
                "importance": "high"
            },
            {
                "evidence": "nausee",
                "original": "Do you feel nauseous?",
                "india_friendly": "Do you feel like vomiting?",
                "hindi_hint": "(उल्टी जैसा लगता है?)",
                "importance": "medium"
            },
            {
                "evidence": "fatigue",
                "original": "Do you feel fatigue?",
                "india_friendly": "Do you feel very tired or weak?",
                "hindi_hint": "(बहुत थकान या कमजोरी?)",
                "importance": "medium"
            },
            {
                "evidence": "douleurxx_ventre",
                "original": "Do you have abdominal pain?",
                "india_friendly": "Do you have stomach pain?",
                "hindi_hint": "(पेट में दर्द?)",
                "importance": "high"
            },
            {
                "evidence": "vertiges",
                "original": "Do you have dizziness?", 
                "india_friendly": "Do you feel dizzy or unsteady?",
                "hindi_hint": "(चक्कर आना?)",
                "importance": "medium"
            }
        ]
        
        # Save India-friendly questions
        for q in india_core_questions:
            evidence = q["evidence"]
            self.india_optimized_questions[evidence] = {
                "question": q["india_friendly"],
                "hindi_hint": q["hindi_hint"], 
                "importance": q["importance"],
                "original_question": q["original"]
            }
        
        print(f"✅ Created {len(self.india_optimized_questions)} India-friendly questions")
        
        return self.india_optimized_questions
    
    def create_english_disease_mapping(self):
        """Create clean English disease mapping"""
        print("\n🏥 CREATING ENGLISH DISEASE MAPPING")
        print("=" * 40)
        
        # Common diseases translated to simple English for rural India
        india_disease_mapping = {}
        
        for french_name, data in self.english_diseases.items():
            english_name = data["english_name"]
            
            # Simplify medical terms for rural understanding
            simplified_name = self._simplify_medical_term(english_name)
            
            india_disease_mapping[french_name] = {
                "medical_name": english_name,
                "simple_name": simplified_name,
                "icd10": data["icd10"]
            }
        
        print(f"✅ Mapped {len(india_disease_mapping)} diseases to simple English")
        
        # Show some examples
        print("\n📋 Sample Disease Translations:")
        sample_count = 0
        for french, data in india_disease_mapping.items():
            if sample_count < 5:
                print(f"   {data['medical_name']} → {data['simple_name']}")
                sample_count += 1
        
        return india_disease_mapping
    
    def _simplify_medical_term(self, medical_term):
        """Simplify medical terms for rural understanding"""
        simplifications = {
            "Spontaneous pneumothorax": "Collapsed lung",
            "Cluster headache": "Severe headache",
            "Boerhaave syndrome": "Chest pain condition", 
            "Gastroesophageal reflux": "Acid reflux",
            "HIV": "HIV infection",
            "Anemia": "Low blood count",
            "Viral pharyngitis": "Throat infection",
            "Inguinal hernia": "Hernia",
            "Myasthenia gravis": "Muscle weakness",
            "Tuberculosis": "TB infection",
            "Guillain-Barré syndrome": "Nerve problem",
            "Laryngospasm": "Throat tightness"
        }
        
        return simplifications.get(medical_term, medical_term)
    
    def save_india_system(self):
        """Save complete India-optimized system"""
        print("\n💾 SAVING INDIA-OPTIMIZED SYSTEM")
        print("=" * 35)
        
        # Prepare India system data
        india_system = {
            "diseases": self.create_english_disease_mapping(),
            "questions": self.india_optimized_questions,
            "metadata": {
                "target_region": "Rural India",
                "languages": ["English", "Hindi hints"],
                "total_diseases": len(self.english_diseases),
                "core_questions": len(self.india_optimized_questions),
                "cultural_adaptation": True
            }
        }
        
        # Save India system
        with open("india_medical_system.json", "w", encoding='utf-8') as f:
            json.dump(india_system, f, indent=2, ensure_ascii=False)
        
        print("✅ Saved complete India medical system!")
        print("📁 File: india_medical_system.json")
        
        return india_system
    
    def show_india_system_demo(self):
        """Demo the India-optimized system"""
        print("\n🇮🇳 INDIA MEDICAL SYSTEM DEMO")
        print("=" * 35)
        
        print("📋 Sample Questions for Rural India:")
        print("-" * 40)
        
        for i, (evidence, data) in enumerate(self.india_optimized_questions.items(), 1):
            print(f"{i}. {data['question']}")
            print(f"   Hindi: {data['hindi_hint']}")
            print(f"   Priority: {data['importance']}")
            print()
        
        print("🏥 Sample Diagnoses (Simplified):")
        print("-" * 35)
        
        disease_mapping = self.create_english_disease_mapping()
        sample_count = 0
        for french_name, data in disease_mapping.items():
            if sample_count < 8:
                print(f"• {data['simple_name']} ({data['medical_name']})")
                sample_count += 1
        
        print(f"\n🎯 SYSTEM OPTIMIZED FOR INDIA:")
        print("✅ Simple English questions")
        print("✅ Hindi pronunciation hints") 
        print("✅ Culturally appropriate language")
        print("✅ Medical terms simplified")
        print("✅ Rural-friendly interface")

def main():
    """Create India-optimized system from DDXPlus"""
    print("🇮🇳 DDXPLUS TO INDIA SYSTEM CONVERTER")
    print("=" * 45)
    
    india_system = DDXPlusEnglishSystem()
    
    # Extract English data
    india_system.extract_english_data()
    
    # Create India-friendly questions
    india_system.create_india_friendly_questions()
    
    # Save complete system
    system_data = india_system.save_india_system()
    
    # Show demo
    india_system.show_india_system_demo()
    
    print(f"\n🎉 SUCCESS!")
    print("DDXPlus data converted for rural India deployment!")
    print("System ready with English + Hindi support! 🚀")

if __name__ == "__main__":
    main()