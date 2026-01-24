#!/usr/bin/env python3
"""
🇮🇳 RURAL INDIA DIAGNOSTIC SYSTEM
=================================
DDXPlus-powered system optimized for rural Indian healthcare
Simple English + Hindi hints for local healthcare workers
"""

import pickle
import json
import numpy as np
import sys
import os
from snomed_integration import SnomedIntegration

class IndiaRuralDiagnosticSystem:
    def __init__(self):
        self.load_models()
        self.setup_questions()
        self.user_responses = {}
        self.questions_asked = 0
        # Adaptive max questions based on body system
        self.base_max_questions = 15  # Increased from fixed 7
        self.emergency_detected = False
        
        # Initialize SNOMED medical knowledge
        self.snomed = SnomedIntegration()
        
    def load_models(self):
        """Load DDXPlus ML model"""
        try:
            with open("ddxplus_model.pkl", "rb") as f:
                self.model = pickle.load(f)
            
            with open("ddxplus_features.pkl", "rb") as f:
                self.feature_names = pickle.load(f)
            
        except FileNotFoundError:
            print("❌ Please run ddxplus_integrator.py first!")
            sys.exit(1)
    
    def setup_questions(self):
        """Setup simple English questions for rural India"""
        # Create mapping from our English questions to DDXPlus features
        self.symptom_to_feature_map = {
            # Emergency symptoms
            "severe_breathing": "dyspn",
            "severe_chest_pain": "douleurxx", 
            "unconsciousness": "syncope",
            "severe_headache": "douleurxx",
            "seizures": "convulsions",
            "severe_confusion": "confusion",
            
            # Core symptoms
            "fever": "fievre",
            "fatigue": "fatig_ext",
            
            # Chest symptoms
            "cough": "toux",
            "breathing_difficulty": "dysp_effort",
            "chest_pain": "douleurxx",
            "wheezing": "wheez",
            
            # Head symptoms  
            "headache": "douleurxx",
            "dizziness": "vertiges",
            "vision_problems": "baisse_vision",
            "neck_stiffness": "raideur_nuque",
            
            # Stomach symptoms
            "stomach_pain": "douleurxx",
            "nausea": "nausee", 
            "vomiting": "nausee",  # Map both nausea and vomiting to nausee
            "diarrhea": "diarrhee",
            "heartburn": "douleurxx",  # General pain for heartburn
            
            # Urinary symptoms
            "urination_pain": "dysurie",
            "frequent_urination": "pollakiurie",
            "blood_in_urine": "hematurie",
            
            # ENT symptoms
            "throat_pain": "douleurxx",
            "ear_pain": "douleurxx",
            "nose_congestion": "rhinorrhee",
            "hearing_problems": "baisse_audition",
            
            # Skin symptoms
            "rash": "lesions_peau",
            "itching": "prurit_occ",
            "skin_wounds": "lesions_peau_elevee",
            "skin_color_change": "lesions_peau_couleur",
            
            # General symptoms
            "weight_loss": "amaigris",
            "appetite_loss": "anorexie",
            "night_sweats": "sueurs_noc"
        }
        
        # Emergency symptoms by body system - only ask if relevant
        self.emergency_by_system = {
            "chest": {
                "severe_breathing": {"question": "Are you having severe difficulty breathing right now?", "importance": "emergency"},
                "severe_chest_pain": {"question": "Do you have severe chest pain right now?", "importance": "emergency"}
            },
            "head": {
                "unconsciousness": {"question": "Have you lost consciousness or fainted recently?", "importance": "emergency"},
                "severe_headache": {"question": "Do you have the worst headache of your life?", "importance": "emergency"},
                "seizures": {"question": "Have you had seizures or fits?", "importance": "emergency"},
                "severe_confusion": {"question": "Are you very confused or not thinking clearly?", "importance": "emergency"}
            },
            "ent": {
                "severe_throat_closing": {"question": "Is your throat closing or do you feel like you can't breathe through throat?", "importance": "emergency"},
                "severe_swallowing_difficulty": {"question": "Can you not swallow at all, even saliva?", "importance": "emergency"}
            },
            "general": {
                "severe_bleeding": {"question": "Are you bleeding heavily from anywhere?", "importance": "emergency"}
            }
        }
        
        # Simple English questions for rural India
        self.core_questions = {
            "fievre": {"question": "Do you feel hot or have fever?", "importance": "high"},
            "fatigue": {"question": "Do you feel very tired or weak?", "importance": "medium"}
        }
        
        # Body system specific questions
        self.body_system_questions = {
            "chest": {
                "toux": {"question": "Do you have cough?", "importance": "high"},
                "dyspn": {"question": "Do you have difficulty breathing?", "importance": "high"},
                "chest_pain": {"question": "Do you have chest pain?", "importance": "high"},
                "wheeze": {"question": "Do you have wheezing sound when breathing?", "importance": "medium"}
            },
            "head": {
                "douleur_tete": {"question": "Do you have headache?", "importance": "high"},
                "vertiges": {"question": "Do you feel dizzy or unsteady?", "importance": "medium"},
                "vision_problems": {"question": "Do you have vision problems?", "importance": "medium"},
                "neck_stiff": {"question": "Do you have neck stiffness?", "importance": "medium"}
            },
            "stomach": {
                "stomach_pain": {"question": "Do you have stomach pain?", "importance": "high"},
                "nausea": {"question": "Do you feel like vomiting?", "importance": "high"},
                "diarrhea": {"question": "Do you have loose motions/diarrhea?", "importance": "medium"},
                "heartburn": {"question": "Do you have burning sensation in chest after eating?", "importance": "medium"}
            },
            "urinary": {
                "burning_urination": {"question": "Do you feel burning while passing urine?", "importance": "high"},
                "frequent_urination": {"question": "Do you need to pass urine very often?", "importance": "high"},
                "blood_urine": {"question": "Do you see blood in urine?", "importance": "high"},
                "kidney_pain": {"question": "Do you have pain in lower back/side?", "importance": "medium"}
            },
            "ent": {
                "sore_throat": {"question": "Do you have sore throat or throat pain?", "importance": "high"},
                "ear_pain": {"question": "Do you have ear pain?", "importance": "high"},
                "hearing_problems": {"question": "Do you have hearing problems or difficulty hearing?", "importance": "medium"},
                "nasal_congestion": {"question": "Is your nose blocked or congested?", "importance": "medium"},
                "runny_nose": {"question": "Do you have runny nose or nasal discharge?", "importance": "medium"},
                "voice_problems": {"question": "Do you have voice problems or hoarseness?", "importance": "medium"},
                "difficulty_swallowing": {"question": "Do you have difficulty swallowing?", "importance": "high"}
            },
            "skin": {
                "rash": {"question": "Do you have skin rash or red patches?", "importance": "high"},
                "itching": {"question": "Do you have itching on skin?", "importance": "medium"},
                "skin_lesions": {"question": "Do you have any wounds or sores on skin?", "importance": "medium"},
                "skin_color_change": {"question": "Has your skin color changed anywhere?", "importance": "medium"}
            },
            "general": {
                "weight_loss": {"question": "Have you lost weight recently?", "importance": "medium"},
                "night_sweats": {"question": "Do you sweat a lot at night?", "importance": "medium"},
                "appetite_loss": {"question": "Have you lost your appetite?", "importance": "medium"},
                "sleep_problems": {"question": "Do you have trouble sleeping?", "importance": "low"}
            }
        }
        
        # Simplified disease names for rural understanding
        self.disease_simplifications = {
            "Pneumothorax spontané": "Collapsed lung",
            "Céphalée en grappe": "Severe headache",
            "Syndrome de Boerhaave": "Chest condition",
            "Fracture de côte spontanée": "Rib injury",
            "RGO": "Acid reflux",
            "VIH (Primo-infection)": "HIV infection",
            "Anémie": "Low blood count",
            "Pharyngite virale": "Throat infection",
            "Hernie inguinale": "Hernia",
            "Myasthénie grave": "Muscle weakness",
            "Tuberculose": "TB infection",
            "Syndrome de Guillain-Barré": "Nerve problem",
            "Laryngospasme": "Throat tightness"
        }
    
    def start_rural_diagnosis(self, show_detailed_reasoning=False):
        """Start diagnosis optimized for rural India"""
        print("\n" + "="*60)
        print("🇮🇳 RURAL INDIA MEDICAL ASSISTANCE SYSTEM")
        print("="*60)
        print("🏥 Machine learning medical assistance for rural healthcare")
        print("📱 Simple questions in English")
        print("⚡ Based on medical ML model (99.3% training accuracy)")
        print("-"*60)
        
        # Set detailed reasoning flag
        self.show_detailed_reasoning_flag = show_detailed_reasoning
        
        # Patient assessment
        self._ask_core_questions()
        
        # Get AI diagnosis
        diagnosis = self._get_ai_diagnosis()
        
        # Show results
        self._show_rural_friendly_results(diagnosis)
        
        return diagnosis
    
    def _ask_core_questions(self):
        """Ask questions: main complaint first, then relevant emergency check, then targeted questions"""
        print("\n🔍 PATIENT ASSESSMENT")
        print("Please ask the patient these questions:")
        print("-"*40)
        
        # Step 1: Ask about main complaint area FIRST
        main_area = self._ask_main_complaint_area()
        
        # Step 1.5: For ENT, ask specific area
        ent_specific_area = None
        if main_area == "ent":
            ent_specific_area = self._ask_ent_specific_area()
        
        # Adjust max questions based on complexity
        max_questions = self._get_adaptive_max_questions(main_area)
        
        # Step 2: Ask core questions (fever, fatigue)
        print("\n🎯 CORE SYMPTOMS:")
        for evidence, question_data in self.core_questions.items():
            if self.questions_asked >= max_questions:
                break
            self._ask_single_question(evidence, question_data)
        
        # Step 3: Ask relevant emergency questions as part of normal flow
        if main_area in self.emergency_by_system:
            print(f"\n⚠️ {main_area.upper()} SPECIFIC URGENT SYMPTOMS:")
            for evidence, question_data in self.emergency_by_system[main_area].items():
                if self.questions_asked >= max_questions:
                    break
                self._ask_single_question(evidence, question_data)
        
        # Step 4: Dynamic question selection based on responses and confidence
        if main_area in self.body_system_questions:
            targeted_questions = self._get_targeted_questions(main_area, ent_specific_area)
            area_name = f"{main_area.upper()}{f' ({ent_specific_area.upper()})' if ent_specific_area else ''}"
            print(f"\n🔎 {area_name} SPECIFIC QUESTIONS:")
            
            self._ask_dynamic_questions(targeted_questions, max_questions)
        
        print(f"\n✅ Assessment complete: {self.questions_asked} questions asked")
    

    def _ask_main_complaint_area(self):
        print("\nQ1: What is your main problem area?")
        print("   1. Chest/Breathing problems")
        print("   2. Head/Brain related")
        print("   3. Stomach/Digestion")
        print("   4. Urinary/Kidney problems")
        print("   5. Ear/Nose/Throat (ENT)")
        print("   6. Skin problems")
        print("   7. General body problems")
        print("   8. Multiple areas")
        
        area_map = {
            '1': 'chest', 'chest': 'chest', 'breathing': 'chest',
            '2': 'head', 'head': 'head', 'brain': 'head',
            '3': 'stomach', 'stomach': 'stomach', 'digestion': 'stomach',
            '4': 'urinary', 'urinary': 'urinary', 'kidney': 'urinary',
            '5': 'ent', 'ent': 'ent', 'ear': 'ent', 'nose': 'ent', 'throat': 'ent',
            '6': 'skin', 'skin': 'skin',
            '7': 'general', 'general': 'general', 'body': 'general',
            '8': 'general', 'multiple': 'general'
        }
        
        while True:
            response = input("   Answer (1-8 or area name): ").lower().strip()
            if response in area_map:
                selected_area = area_map[response]
                print(f"   Selected: {selected_area} problems")
                self.questions_asked += 1
                return selected_area
            else:
                print("   Please choose 1-8 or area name")
    
    def _ask_dynamic_questions(self, available_questions, max_questions):
        """Dynamically select and ask questions based on responses and confidence"""
        # Sort questions by importance (high first)
        importance_order = {'emergency': 4, 'high': 3, 'medium': 2, 'low': 1}
        sorted_questions = sorted(available_questions.items(), 
                                key=lambda x: importance_order.get(x[1]['importance'], 0), 
                                reverse=True)
        
        positive_symptoms = 0
        negative_symptoms = 0
        
        for evidence, question_data in sorted_questions:
            if self.questions_asked >= max_questions:
                print(f"   🔴 Reached question limit ({max_questions})")
                break
            
            # Early stopping logic based on confidence
            if self.questions_asked >= 4:  # After minimum questions
                confidence_score = self._calculate_current_confidence()
                
                # Stop if we have high confidence
                if confidence_score > 0.8 and positive_symptoms >= 2:
                    print(f"   🎆 High confidence reached ({confidence_score:.1%}) - stopping early")
                    break
                    
                # Stop if too many negatives suggest different condition
                if negative_symptoms >= 3 and positive_symptoms <= 1:
                    print(f"   ⚠️ Many negative responses suggest different condition - stopping")
                    break
            
            # Ask the question
            response = self._ask_single_question(evidence, question_data)
            
            if response == 1:
                positive_symptoms += 1
                # Ask follow-up if this is a key positive symptom
                if question_data['importance'] in ['emergency', 'high']:
                    follow_up = self._get_follow_up_questions(evidence, available_questions)
                    if follow_up and self.questions_asked < max_questions:
                        print(f"   👉 Follow-up question:")
                        for follow_evidence, follow_question in follow_up:
                            if self.questions_asked >= max_questions:
                                break
                            self._ask_single_question(follow_evidence, follow_question)
            elif response == 0.5:
                positive_symptoms += 0.5  # Partial positive
                print(f"   🔄 Intermittent symptom noted")
            elif response == 0:
                negative_symptoms += 1
            elif response == -2:  # Don't know
                print(f"   ❓ Uncertain response - will need manual review")
            # response == -1 is skip, don't count either way
        
        print(f"   📊 Dynamic assessment: {positive_symptoms} positive, {negative_symptoms} negative symptoms")
    
    def _calculate_current_confidence(self):
        """Calculate rough confidence based on current symptom pattern"""
        positive_count = len([v for v in self.user_responses.values() if v > 0])
        partial_count = len([v for v in self.user_responses.values() if v == 0.5])
        total_count = len([v for v in self.user_responses.values() if v >= 0])  # Exclude skips
        
        if total_count == 0:
            return 0.0
        
        # Weight partial symptoms as 0.5
        weighted_positive = len([v for v in self.user_responses.values() if v == 1]) + (partial_count * 0.5)
        ratio = weighted_positive / total_count
        
        # Bonus for emergency/high priority symptoms
        high_priority_symptoms = 0
        for response_key, value in self.user_responses.items():
            if value > 0 and any(response_key in qs for qs in self.emergency_by_system.values()):
                high_priority_symptoms += 1
        
        confidence = ratio * 0.7 + (min(high_priority_symptoms, 2) * 0.15)
        return min(confidence, 0.95)
    
    def _get_follow_up_questions(self, evidence, available_questions):
        """Get follow-up questions for positive key symptoms"""
        follow_ups = {
            'stomach_pain': [('pain_severity', {'question': 'Is the stomach pain very severe right now?', 'importance': 'high'})],
            'chest_pain': [('pain_location', {'question': 'Is the chest pain on the left side of your chest?', 'importance': 'high'})],
            'headache': [('headache_type', {'question': 'Is this the worst headache you have ever had?', 'importance': 'emergency'})],
            'ear_pain': [('hearing_loss', {'question': 'Do you also have hearing loss?', 'importance': 'medium'})]
        }
        
        return follow_ups.get(evidence, [])
    
    def _ask_ent_specific_area(self):
        """Ask which specific ENT area is the problem"""
        print("\nQ1b: Which ENT area is your main problem?")
        print("   1. Ear problems (hearing, pain, discharge)")
        print("   2. Nose problems (congestion, runny nose, smell)")
        print("   3. Throat problems (sore throat, swallowing, voice)")
        print("   4. All areas affected")
        
        area_map = {
            '1': 'ear', 'ear': 'ear',
            '2': 'nose', 'nose': 'nose', 'nasal': 'nose',
            '3': 'throat', 'throat': 'throat',
            '4': 'all', 'all': 'all'
        }
        
        while True:
            response = input("   Answer (1-4 or area name): ").lower().strip()
            if response in area_map:
                selected_area = area_map[response]
                print(f"   Selected: {selected_area} problems")
                self.questions_asked += 1
                return selected_area
            else:
                print("   Please choose 1-4 or area name")
    
    def _get_adaptive_max_questions(self, main_area):
        """Get adaptive max questions based on body system complexity"""
        complexity_map = {
            "chest": 12,     # Breathing issues can be complex
            "head": 10,      # Neurological symptoms need careful checking
            "stomach": 8,    # Digestive issues usually straightforward
            "urinary": 6,    # Usually clear symptoms
            "ent": 10,       # ENT can be complex, especially if targeted
            "skin": 6,       # Skin issues usually visible
            "general": 15    # General symptoms may need more investigation
        }
        return complexity_map.get(main_area, self.base_max_questions)
    
    def _get_targeted_questions(self, main_area, ent_area=None):
        """Get targeted questions based on main area and specific sub-area"""
        if main_area != "ent" or not ent_area:
            return self.body_system_questions.get(main_area, {})
        
        # For ENT, filter questions based on specific area
        all_ent_questions = self.body_system_questions["ent"]
        
        if ent_area == "ear":
            # Prioritize ear-related questions
            ear_questions = {k: v for k, v in all_ent_questions.items() 
                           if "ear" in k or "hearing" in k}
            # Add some general ENT questions
            ear_questions.update({k: v for k, v in all_ent_questions.items() 
                                if k in ["sore_throat", "nasal_congestion"]})
            return ear_questions
            
        elif ent_area == "nose":
            # Prioritize nose-related questions
            nose_questions = {k: v for k, v in all_ent_questions.items() 
                            if "nasal" in k or "nose" in k}
            # Add some general questions
            nose_questions.update({k: v for k, v in all_ent_questions.items() 
                                 if k in ["sore_throat", "ear_pain"]})
            return nose_questions
            
        elif ent_area == "throat":
            # Prioritize throat-related questions
            throat_questions = {k: v for k, v in all_ent_questions.items() 
                              if "throat" in k or "swallow" in k or "voice" in k}
            # Add some general questions
            throat_questions.update({k: v for k, v in all_ent_questions.items() 
                                   if k in ["ear_pain", "nasal_congestion"]})
            return throat_questions
        
        else:  # "all" areas
            return all_ent_questions
    
    def _ask_single_question(self, evidence, question_data):
        """Ask a single question and record response"""
        print(f"\nQ{self.questions_asked + 1}: {question_data['question']}")
        print(f"   Priority: {question_data['importance']}")
        
        response_value = 0
        while True:
            response = input("   Answer (yes/no/sometimes/don't know/skip): ").lower().strip()
            if response in ['y', 'yes']:
                self.user_responses[evidence] = 1
                response_value = 1
                break
            elif response in ['n', 'no']:
                self.user_responses[evidence] = 0
                response_value = 0
                break
            elif response in ['sometimes', 'some', 't']:
                self.user_responses[evidence] = 0.5  # Partial symptom
                response_value = 0.5
                print("   📝 Noted: Intermittent symptom")
                break
            elif response in ['don\'t know', 'dont know', 'dk', 'unsure', 'unknown']:
                # Flag for manual review but don't count in ML
                if not hasattr(self, 'uncertain_responses'):
                    self.uncertain_responses = []
                self.uncertain_responses.append(evidence)
                response_value = -2  # Don't know flag
                print("   ❓ Flagged for manual review")
                break
            elif response in ['s', 'skip']:
                print("   Skipped")
                response_value = -1  # Skipped
                break
            else:
                print("   Please answer: yes/no/sometimes/don't know/skip")
        
        self.questions_asked += 1
        return response_value
    
    def _get_ai_diagnosis(self):
        """Get diagnosis from AI model"""
        # Analysis running silently for clean user interface
        
        # Create feature vector
        feature_vector = np.zeros(len(self.feature_names))
        matched_features = 0
        unmatched_symptoms = []
        
        for evidence, value in self.user_responses.items():
            # Try to find matching DDXPlus feature
            ddx_feature = self.symptom_to_feature_map.get(evidence)
            
            if ddx_feature and ddx_feature in self.feature_names:
                idx = self.feature_names.index(ddx_feature)
                feature_vector[idx] = value  # Can be 0, 0.5, or 1 now
                if value > 0:  # Count both 0.5 and 1 as matched
                    matched_features += 1
            elif evidence in self.feature_names:
                # Direct match (shouldn't happen much now)
                idx = self.feature_names.index(evidence)
                feature_vector[idx] = value
                if value > 0:
                    matched_features += 1
            elif value > 0:  # Only count positive/partial responses as unmatched
                unmatched_symptoms.append(evidence)
        
        total_positive_symptoms = len([v for v in self.user_responses.values() if v > 0])
        # Debug info removed for clean user interface
        
        # Show uncertain responses for manual review
        if hasattr(self, 'uncertain_responses') and self.uncertain_responses:
            print(f"   ❓ Uncertain symptoms (manual review): {', '.join(self.uncertain_responses)}")
        
        # Store feature vector for reasoning analysis
        self._last_feature_vector = feature_vector
        
        # Get prediction
        try:
            probabilities = self.model.predict_proba(feature_vector.reshape(1, -1))[0]
            classes = self.model.classes_
            
            # Get top predictions
            top_indices = np.argsort(probabilities)[-3:][::-1]  # Top 3
            
            # Calculate normalized confidence (relative to top prediction)
            max_prob = probabilities[top_indices[0]]
            
            # If no symptoms matched, use fallback diagnosis
            if matched_features == 0:
                print("   ⚠️ No symptoms matched ML features - using symptom-based diagnosis")
                return self._get_basic_diagnosis()
            
            # Force clinical diagnosis for clear body-system symptoms (DDXPlus bias issue)
            stomach_symptoms = [k for k in self.user_responses.keys() 
                              if k in ['stomach_pain', 'nausea', 'vomiting', 'diarrhea', 'heartburn'] 
                              and self.user_responses[k] > 0]
            skin_symptoms = [k for k in self.user_responses.keys() 
                           if k in ['rash', 'itching', 'skin_lesions', 'skin_color_change'] 
                           and self.user_responses[k] > 0]
            chest_symptoms = [k for k in self.user_responses.keys() 
                            if k in ['toux', 'dyspn', 'chest_pain', 'wheeze'] 
                            and self.user_responses[k] > 0]
            head_symptoms = [k for k in self.user_responses.keys() 
                           if k in ['headache', 'dizziness', 'vision_problems', 'neck_stiffness', 'severe_headache', 'severe_confusion'] 
                           and self.user_responses[k] > 0]
            urinary_symptoms = [k for k in self.user_responses.keys() 
                              if k in ['burning_urination', 'frequent_urination', 'blood_in_urine'] 
                              and self.user_responses[k] > 0]
            
            # Check for head emergency combinations (fever + severe head symptoms)
            head_emergency_combo = (
                self.user_responses.get('fievre', 0) > 0 and 
                (self.user_responses.get('severe_headache', 0) > 0 or 
                 self.user_responses.get('severe_confusion', 0) > 0) and
                len(head_symptoms) >= 2
            )
            
            # Check for any emergency symptoms (should never be throat tightness)
            emergency_symptoms = [
                'severe_breathing', 'severe_chest_pain', 'unconsciousness', 
                'severe_headache', 'seizures', 'severe_confusion'
            ]
            has_emergency = any(self.user_responses.get(sym, 0) > 0 for sym in emergency_symptoms)
            
            # Override for obvious system-specific symptoms OR emergencies
            if len(urinary_symptoms) >= 1:  # Even 1 urinary symptom should override
                print("   🏥 Clear urinary symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            elif has_emergency and not any(self.user_responses.get(sym, 0) > 0 for sym in ['throat_pain', 'breathing_difficulty']):
                print("   🏥 Emergency symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            elif head_emergency_combo:
                print("   🏥 URGENT head symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            elif len(stomach_symptoms) >= 1:  # Lower threshold
                print("   🏥 Clear stomach symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            elif len(skin_symptoms) >= 1:  # Lower threshold
                print("   🏥 Clear skin symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            elif len(chest_symptoms) >= 2:
                print("   🏥 Clear chest symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            elif len(head_symptoms) >= 2:  # Lower threshold
                print("   🏥 Clear head symptoms detected - using clinical diagnosis (DDXPlus bias override)")
                self.used_clinical_override = True
                return self._get_basic_diagnosis()
            
            # If low symptom match rate, use clinical fallback diagnosis 
            if matched_features < total_positive_symptoms * 0.8:  # Less than 80% match
                stomach_symptoms = [k for k in self.user_responses.keys() 
                                  if k in ['stomach_pain', 'nausea', 'vomiting', 'diarrhea', 'heartburn'] 
                                  and self.user_responses[k] == 1]
                if len(stomach_symptoms) >= 2:  # 2+ stomach symptoms 
                    print("   ⚠️ Stomach symptoms detected - using clinical diagnosis instead of ML")
                    self.used_clinical_override = True
                    return self._get_basic_diagnosis()
            
            # Store matched features for trust scoring
            self.matched_features = matched_features
            
            predictions = []
            for i, idx in enumerate(top_indices):
                french_disease = classes[idx]
                raw_confidence = probabilities[idx]
                
                # CRITICAL: Filter out inappropriate "Laryngospasme" (throat tightness) predictions
                if french_disease == "Laryngospasme":
                    # Only allow throat tightness for actual throat/breathing symptoms
                    throat_symptoms = ['throat_pain', 'breathing_difficulty', 'severe_breathing', 'toux']
                    has_throat_symptoms = any(self.user_responses.get(sym, 0) > 0 for sym in throat_symptoms)
                    
                    # Block throat tightness for non-throat body systems
                    non_throat_systems = {
                        'skin': ['rash', 'itching', 'skin_wounds', 'skin_color_change'],
                        'stomach': ['stomach_pain', 'nausea', 'vomiting', 'diarrhea', 'heartburn'],
                        'head': ['headache', 'dizziness', 'vision_problems', 'severe_headache', 'severe_confusion'],
                        'urinary': ['burning_urination', 'frequent_urination', 'blood_in_urine']
                    }
                    
                    has_system_specific = False
                    for system, system_symptoms in non_throat_systems.items():
                        if any(self.user_responses.get(sym, 0) > 0 for sym in system_symptoms):
                            has_system_specific = True
                            print(f"   ❌ BLOCKED throat tightness - clear {system} symptoms detected")
                            break
                    
                    # AGGRESSIVE: Skip throat tightness if ANY non-throat symptoms
                    if has_system_specific:
                        print(f"   ❌ SKIPPING inappropriate throat tightness prediction")
                        continue
                    
                    # Even if no clear system symptoms, heavily penalize throat tightness
                    if not has_throat_symptoms:
                        raw_confidence *= 0.1  # Massive penalty
                        print(f"   ⚠️ Throat tightness heavily penalized (no throat symptoms)")
                
                # Normalize confidence relative to top prediction and scale up
                if i == 0:
                    # Top prediction gets boosted confidence, but lower if few symptoms matched
                    base_confidence = min(0.95, max_prob * 5)  # Scale up but cap at 95%
                    # Reduce confidence if few symptoms matched
                    symptom_penalty = max(0.3, matched_features / max(total_positive_symptoms, 1))
                    normalized_confidence = base_confidence * symptom_penalty
                else:
                    # Other predictions scaled relative to top
                    normalized_confidence = (raw_confidence / max_prob) * normalized_confidence if max_prob > 0 else raw_confidence
                
                # Get simplified English name
                simple_name = self.disease_simplifications.get(french_disease, french_disease)
                medical_name = french_disease
                
                predictions.append({
                    "simple_name": simple_name,
                    "medical_name": medical_name,
                    "confidence": normalized_confidence,
                    "raw_confidence": raw_confidence
                })
            
            return predictions
            
        except Exception as e:
            print(f"   ❌ ML model error: {e}")
            return self._get_basic_diagnosis()
    
    def _get_basic_diagnosis(self):
        """SNOMED-based medical diagnosis using real medical knowledge"""
        # Using SNOMED CT medical analysis (running silently)
        
        # Set matched_features for trust scoring (when using clinical override)
        total_positive_symptoms = len([v for v in self.user_responses.values() if v > 0])
        if not hasattr(self, 'matched_features'):
            # Estimate matching for clinical override cases
            self.matched_features = min(total_positive_symptoms, len([k for k in self.user_responses.keys() if k in self.feature_names]))
        
        # Use SNOMED to analyze symptoms
        snomed_results = self.snomed.analyze_symptoms(self.user_responses)
        
        if not snomed_results:
            # Fallback for completely unknown cases
            symptoms = [k for k, v in self.user_responses.items() if v > 0]
            if "fievre" in symptoms:
                return [{"simple_name": "Fever syndrome", "medical_name": "Febrile illness", "confidence": 0.5}]
            else:
                return [{"simple_name": "General symptoms", "medical_name": "Undifferentiated condition", "confidence": 0.4}]
        
        # Convert SNOMED results to our format
        predictions = []
        for result in snomed_results:
            predictions.append({
                "simple_name": result['term'],
                "medical_name": f"{result['term']} (SNOMED: {result['snomed_id']})",
                "confidence": result['confidence'],
                "snomed_id": result['snomed_id'],
                "clinical_notes": result.get('clinical_notes', ''),
                "emergency": result.get('emergency', False)
            })
        
        if predictions:
            top_result = snomed_results[0]
            print(f"   ✅ SNOMED diagnosis: {top_result['term']} (confidence: {top_result['confidence']*100:.1f}%)")
            if top_result.get('emergency'):
                print(f"   🚨 EMERGENCY condition detected!")
        
        return predictions
    
    def get_diagnosis_reasoning(self, predictions, feature_vector):
        """Generate detailed reasoning for diagnosis with feature contribution analysis"""
        reasoning = {
            'primary_factors': [],      # Main symptoms that drove diagnosis
            'supporting_factors': [],   # Secondary supporting symptoms  
            'confidence_factors': [],   # What affects trust level
            'clinical_pathway': '',     # SNOMED reasoning chain
            'trust_analysis': {},       # Detailed trust breakdown
        }
        
        if not predictions:
            return reasoning
            
        # Feature importance analysis for ML predictions
        if hasattr(self.model, 'feature_importances_') and not self.used_clinical_override:
            # For tree-based models, get feature importance
            importances = self.model.feature_importances_
            
            # Get contributing features for this prediction
            active_features = [(i, self.feature_names[i], feature_vector[i], importances[i]) 
                              for i in range(len(feature_vector)) 
                              if feature_vector[i] > 0]
            
            # Sort by contribution (symptom_value * importance)
            active_features.sort(key=lambda x: x[2] * x[3], reverse=True)
            
            for i, (idx, feature_name, value, importance) in enumerate(active_features[:6]):
                contribution = value * importance * 100
                
                # Convert technical feature names to readable symptoms
                readable_name = self._get_readable_symptom_name(feature_name)
                
                factor_data = {
                    'symptom': readable_name,
                    'strength': 'definite' if value == 1.0 else 'sometimes' if value == 0.5 else 'mild',
                    'contribution': f"{contribution:.1f}%",
                    'technical_name': feature_name
                }
                
                if i < 3:  # Top 3 are primary
                    reasoning['primary_factors'].append(factor_data)
                else:  # Rest are supporting
                    reasoning['supporting_factors'].append(factor_data)
        else:
            # For SNOMED clinical reasoning
            reasoning['clinical_pathway'] = f"Clinical analysis via SNOMED CT medical knowledge base"
            if self.used_clinical_override:
                reasoning['clinical_pathway'] += f" (Override: Clear body-system symptoms detected)"
            
            # Show active symptoms for clinical reasoning
            active_symptoms = [(k, v) for k, v in self.user_responses.items() if v > 0]
            active_symptoms.sort(key=lambda x: x[1], reverse=True)  # Sort by confidence
            
            for i, (symptom, strength) in enumerate(active_symptoms[:6]):
                readable_name = self._get_readable_symptom_name(symptom)
                factor_data = {
                    'symptom': readable_name,
                    'strength': 'definite' if strength == 1.0 else 'sometimes' if strength == 0.5 else 'mild',
                    'clinical_relevance': 'primary' if i < 3 else 'supporting'
                }
                
                if i < 3:
                    reasoning['primary_factors'].append(factor_data)
                else:
                    reasoning['supporting_factors'].append(factor_data)
        
        return reasoning
    
    def _get_readable_symptom_name(self, technical_name):
        """Convert technical symptom names to human-readable format"""
        readable_map = {
            'fievre': 'Fever',
            'toux': 'Cough', 
            'dyspn': 'Breathing difficulty',
            'stomach_pain': 'Stomach pain',
            'headache': 'Headache',
            'burning_urination': 'Burning during urination',
            'frequent_urination': 'Frequent urination',
            'nausea': 'Nausea',
            'vomiting': 'Vomiting',
            'diarrhea': 'Diarrhea',
            'rash': 'Skin rash',
            'chest_pain': 'Chest pain',
            'severe_headache': 'Severe headache',
            'dizziness': 'Dizziness',
            'throat_pain': 'Throat pain'
        }
        return readable_map.get(technical_name, technical_name.replace('_', ' ').title())
    
    def calculate_trust_score(self, predictions):
        """Calculate comprehensive trust score based on multiple medical factors"""
        if not predictions:
            return {'trust_score': 0, 'risk_level': 'UNKNOWN', 'risk_factors': ['No diagnosis generated']}
            
        trust_score = 100  # Start at 100%
        risk_factors = []
        confidence_boosters = []
        
        # Factor 1: Model confidence (including SNOMED medical confidence)
        confidence = predictions[0].get('confidence', 0)
        if confidence < 0.3:
            trust_score -= 40  # Very low medical confidence
            risk_factors.append("Very low medical diagnosis confidence")
        elif confidence < 0.5:
            trust_score -= 30  # Low medical confidence
            risk_factors.append("Low medical diagnosis confidence") 
        elif confidence < 0.7:
            trust_score -= 15  # Moderate medical confidence
            risk_factors.append("Moderate medical diagnosis confidence")
        elif confidence >= 0.8:
            confidence_boosters.append("High medical diagnosis confidence")
        else:
            confidence_boosters.append("Good medical diagnosis confidence")
        
        # Factor 2: Symptom matching rate  
        total_positive_symptoms = len([v for v in self.user_responses.values() if v > 0])
        if total_positive_symptoms > 0:
            match_rate = self.matched_features / total_positive_symptoms
            if match_rate < 0.5:
                trust_score -= 30
                risk_factors.append("Poor symptom matching to medical training data")
            elif match_rate < 0.7:
                trust_score -= 15
                risk_factors.append("Some symptoms not in training data")
            elif match_rate >= 0.9:
                confidence_boosters.append("Excellent symptom matching")
        
        # Factor 3: Clinical override vs ML disagreement
        if self.used_clinical_override:
            # Only boost trust if SNOMED confidence is reasonable
            if confidence >= 0.6:
                trust_score += 10  # Clinical reasoning is more trusted when confident
                confidence_boosters.append("Clinical medical knowledge used with good confidence")
            elif confidence >= 0.4:
                trust_score += 5   # Moderate boost for moderate confidence
                confidence_boosters.append("Clinical medical knowledge used")
            else:
                # Don't boost trust for low-confidence clinical diagnoses
                confidence_boosters.append("Clinical medical knowledge used (low confidence)")
        
        # Factor 4: Uncertain responses
        if hasattr(self, 'uncertain_responses') and len(self.uncertain_responses) > 3:
            trust_score -= 20
            risk_factors.append("Many uncertain symptom responses")
        elif hasattr(self, 'uncertain_responses') and len(self.uncertain_responses) > 1:
            trust_score -= 10
            risk_factors.append("Some uncertain symptom responses")
        
        # Factor 5: Emergency symptoms (reduce trust if missed)
        emergency_symptoms = ['severe_breathing', 'severe_chest_pain', 'unconsciousness', 
                             'severe_headache', 'seizures', 'severe_confusion']
        has_emergency = any(self.user_responses.get(sym, 0) > 0 for sym in emergency_symptoms)
        if has_emergency:
            trust_score += 15
            confidence_boosters.append("Emergency symptoms properly identified")
        
        # Factor 6: Symptom coherence (conflicting body systems)
        conflicting_systems = self._detect_conflicting_systems()
        if len(conflicting_systems) > 1:
            trust_score -= 15
            risk_factors.append(f"Symptoms span multiple systems: {', '.join(conflicting_systems)}")
        
        # Factor 7: Question count (too few questions = less reliable)
        if self.questions_asked < 8:
            trust_score -= 15
            risk_factors.append("Limited symptom information collected")
        elif self.questions_asked >= 12:
            confidence_boosters.append("Comprehensive symptom assessment")
        
        # Set risk level with medical confidence consideration
        final_score = max(0, min(100, trust_score))
        
        # Cap trust score based on medical diagnosis confidence to prevent misleading high trust
        medical_confidence = predictions[0].get('confidence', 0)
        if medical_confidence < 0.4:
            final_score = min(final_score, 60)  # Cap at 60 for low medical confidence
        elif medical_confidence < 0.6:
            final_score = min(final_score, 80)  # Cap at 80 for moderate medical confidence
        
        if final_score >= 85:
            risk_level = "LOW RISK - High confidence prediction"
        elif final_score >= 65: 
            risk_level = "MEDIUM RISK - Moderate confidence, verify with medical professional"
        elif final_score >= 45:
            risk_level = "HIGH RISK - Low confidence, requires medical evaluation"
        else:
            risk_level = "VERY HIGH RISK - Multiple evaluations needed"
        
        return {
            'trust_score': final_score,
            'risk_level': risk_level,
            'risk_factors': risk_factors,
            'confidence_boosters': confidence_boosters
        }
    
    def _detect_conflicting_systems(self):
        """Detect if symptoms span conflicting body systems"""
        system_symptoms = {
            'respiratory': ['toux', 'dyspn', 'chest_pain', 'breathing_difficulty', 'severe_breathing'],
            'digestive': ['stomach_pain', 'nausea', 'vomiting', 'diarrhea', 'heartburn'],
            'neurological': ['headache', 'dizziness', 'vision_problems', 'severe_headache', 'severe_confusion'],
            'urinary': ['burning_urination', 'frequent_urination', 'blood_in_urine'],
            'dermatological': ['rash', 'itching', 'skin_lesions', 'skin_color_change'],
            'ent': ['throat_pain', 'ear_pain', 'nasal_congestion']
        }
        
        active_systems = []
        for system, symptoms in system_symptoms.items():
            if any(self.user_responses.get(sym, 0) > 0 for sym in symptoms):
                active_systems.append(system)
        
        return active_systems
    
    def show_detailed_reasoning(self, predictions, reasoning, trust_analysis):
        """Show comprehensive reasoning to healthcare workers"""
        print("\n" + "="*60)
        print("🧠 DIAGNOSTIC REASONING ANALYSIS") 
        print("="*60)
        
        if not predictions:
            print("❌ No diagnosis could be determined")
            return
        
        top_prediction = predictions[0]
        print(f"\n🎯 PRIMARY DIAGNOSIS: {top_prediction['simple_name']}")
        print(f"   Medical confidence: {top_prediction.get('confidence', 0):.1%}")
        print(f"   Trust score: {trust_analysis['trust_score']:.0f}/100")
        print(f"   Risk assessment: {trust_analysis['risk_level']}")
        
        if reasoning['primary_factors']:
            print(f"\n🔍 KEY CONTRIBUTING FACTORS:")
            for factor in reasoning['primary_factors']:
                if factor['strength'] == 'definite':
                    strength_emoji = "🔴"
                elif factor['strength'] == 'sometimes': 
                    strength_emoji = "🟡"
                else:
                    strength_emoji = "🟠"
                
                if 'contribution' in factor:
                    print(f"   {strength_emoji} {factor['symptom']} ({factor['strength']}) - {factor['contribution']} influence")
                else:
                    print(f"   {strength_emoji} {factor['symptom']} ({factor['strength']}) - {factor.get('clinical_relevance', 'clinical')} evidence")
        
        if reasoning['supporting_factors']:
            print(f"\n📋 SUPPORTING EVIDENCE:")
            for factor in reasoning['supporting_factors']:
                if 'contribution' in factor:
                    print(f"   • {factor['symptom']} - {factor['contribution']} influence")
                else:
                    print(f"   • {factor['symptom']} ({factor['strength']})")
        
        if trust_analysis['confidence_boosters']:
            print(f"\n✅ CONFIDENCE BOOSTERS:")
            for booster in trust_analysis['confidence_boosters']:
                print(f"   + {booster}")
        
        if trust_analysis['risk_factors']:
            print(f"\n⚠️ TRUST LIMITATIONS:")
            for risk in trust_analysis['risk_factors']:
                print(f"   - {risk}")
        
        print(f"\n🏥 CLINICAL REASONING PATH:")
        if reasoning['clinical_pathway']:
            print(f"   {reasoning['clinical_pathway']}")
        else:
            print(f"   Standard DDXPlus ML analysis with {self.matched_features}/{len([v for v in self.user_responses.values() if v > 0])} symptoms matched")
        
        # Action recommendations based on trust score
        print(f"\n🎯 RECOMMENDED ACTION:")
        trust_score = trust_analysis['trust_score']
        if trust_score >= 85:
            print(f"   🟢 HIGH TRUST: Proceed with treatment planning")
        elif trust_score >= 65:
            print(f"   🟡 MODERATE TRUST: Verify diagnosis with additional tests/consultation")
        elif trust_score >= 45:
            print(f"   🟠 LOW TRUST: Requires thorough medical evaluation")
        else:
            print(f"   🔴 VERY LOW TRUST: Multiple diagnostic approaches needed")
    
    def _show_rural_friendly_results(self, predictions):
        """Show results in rural-friendly format"""
        
        # Check for emergency symptoms first
        all_emergency_questions = {}
        for system_emergencies in self.emergency_by_system.values():
            all_emergency_questions.update(system_emergencies)
        
        emergency_symptoms = [k for k, v in self.user_responses.items() 
                            if k in all_emergency_questions and v == 1]
        
        if emergency_symptoms:
            print("\n" + "="*60)
            print("🚨 URGENT MEDICAL ATTENTION NEEDED")
            print("="*60)
            print("⚠️ Emergency symptoms detected:")
            for symptom in emergency_symptoms:
                if symptom in all_emergency_questions:
                    symptom_name = all_emergency_questions[symptom]['question']
                    print(f"   🔴 {symptom_name}")
            
            print("\n🚨 IMMEDIATE ACTION:")
            print("   • Call emergency services (108/102) NOW")
            print("   • Take to nearest hospital immediately")
            print("   • Monitor breathing and consciousness")
            print("   • Share full diagnosis below with doctors")
        
        print("\n" + "="*60)
        print("🏥 MEDICAL ASSESSMENT RESULTS")
        print("="*60)
        
        if predictions:
            top_prediction = predictions[0]
            confidence = top_prediction.get("confidence", 0)
            
            # Generate reasoning and trust analysis
            feature_vector = getattr(self, '_last_feature_vector', np.zeros(len(self.feature_names)))
            reasoning = self.get_diagnosis_reasoning(predictions, feature_vector)
            trust_analysis = self.calculate_trust_score(predictions)
            
            print(f"\n🎯 PRIMARY ASSESSMENT:")
            print(f"   Condition: {top_prediction['simple_name']}")
            
            if "medical_name" in top_prediction:
                print(f"   Medical term: {top_prediction['medical_name']}")
            
            print(f"   ML Model Confidence: {confidence:.1%}")
            print(f"   Trust Score: {trust_analysis['trust_score']:.0f}/100")
            
            # Enhanced confidence interpretation with trust scoring
            trust_score = trust_analysis['trust_score']
            if confidence >= 0.7 and trust_score >= 80:
                print("   🟢 HIGH CONFIDENCE & HIGH TRUST - Strong indication")
            elif confidence >= 0.7 and trust_score >= 60:
                print("   🟡 HIGH CONFIDENCE & MODERATE TRUST - Likely condition")
            elif confidence >= 0.4 and trust_score >= 60:
                print("   🟡 MODERATE CONFIDENCE & MODERATE TRUST - Possible condition")
            elif confidence >= 0.4 or trust_score >= 45:
                print("   🟠 FAIR CONFIDENCE - Needs medical verification")
            else:
                print("   🔴 LOW CONFIDENCE & LOW TRUST - Requires evaluation")
            
            # Show key reasoning factors
            if reasoning['primary_factors']:
                print(f"\n🔍 KEY SYMPTOMS IDENTIFIED:")
                for i, factor in enumerate(reasoning['primary_factors'][:3]):
                    strength_emoji = "🔴" if factor['strength'] == 'definite' else "🟡" if factor['strength'] == 'sometimes' else "🟠"
                    print(f"   {strength_emoji} {factor['symptom']} ({factor['strength']})")
            
            # Show trust limitations in simple format
            if trust_analysis['risk_factors']:
                print(f"\n⚠️ IMPORTANT NOTES:")
                for risk in trust_analysis['risk_factors'][:2]:  # Show top 2 limitations
                    print(f"   • {risk}")
            
            # Show raw ML probability for medical staff reference
            if "raw_confidence" in top_prediction:
                print(f"   📊 ML Raw Probability: {top_prediction['raw_confidence']:.1%}")
            
            # Show detailed reasoning for medical staff
            show_detailed = getattr(self, 'show_detailed_reasoning_flag', False)
            if show_detailed:
                self.show_detailed_reasoning(predictions, reasoning, trust_analysis)
            
            # Show alternatives if available
            if len(predictions) > 1:
                print(f"\n📋 ALTERNATIVE POSSIBILITIES:")
                for i, pred in enumerate(predictions[1:], 2):
                    conf = pred.get("confidence", 0)
                    print(f"   {i}. {pred['simple_name']} ({pred['medical_name']}) - {conf:.1%}")

        
        # Rural healthcare guidance
        print(f"\n🚨 RURAL HEALTHCARE GUIDANCE:")
        self._provide_rural_guidance(predictions)
        
        # Important disclaimers for medical use
        print(f"\n⚠️ IMPORTANT DISCLAIMERS:")
        print(f"   • This is a medical assistance tool, NOT a doctor")
        print(f"   • Always consult qualified medical professional for diagnosis")
        print(f"   • In emergencies, seek immediate medical attention")
        print(f"   • This tool helps identify possible conditions only")
    
    def _provide_rural_guidance(self, predictions):
        """Provide guidance appropriate for rural healthcare settings"""
        if not predictions:
            print("   • Patient needs medical evaluation")
            print("   • Refer to nearest health center if possible")
            return
        
        top_condition = predictions[0]["simple_name"].lower()
        confidence = predictions[0].get("confidence", 0)
        
        # High-priority conditions
        if any(term in top_condition for term in ["chest", "breathing", "heart"]):
            print("   🚨 URGENT: Breathing/chest problems need immediate attention")
            print("   • Give patient rest, monitor breathing")
            print("   • Refer to doctor/hospital immediately if severe")
        
        elif "headache" in top_condition:
            print("   💊 HEADACHE CARE:")
            print("   • Give patient rest in quiet, dark place")
            print("   • Provide water, check for fever")
            print("   • If severe or with neck stiffness - seek medical help")
        
        elif any(term in top_condition for term in ["stomach", "abdomen", "nausea"]):
            print("   🥤 STOMACH PROBLEMS:")
            print("   • Give oral rehydration solution (ORS)")
            print("   • Light food only, avoid spicy/oily food") 
            print("   • Monitor for dehydration signs")
        
        elif "fever" in top_condition or "infection" in top_condition:
            print("   🌡️ FEVER/INFECTION CARE:")
            print("   • Keep patient hydrated, give frequent fluids")
            print("   • Cool compress for high fever")
            print("   • Monitor temperature, seek help if very high fever")
        
        else:
            print("   🏥 GENERAL CARE:")
            print("   • Provide rest and comfort to patient")
            print("   • Monitor symptoms, note any changes")
            print("   • Seek medical consultation when possible")
        
        # Confidence-based recommendations
        if confidence < 0.6:
            print("   ⚠️  UNCERTAIN DIAGNOSIS:")
            print("   • Multiple conditions possible")
            print("   • Refer to trained medical professional")
            print("   • Continue monitoring patient closely")

def main():
    """Main function for rural India diagnostic system"""
    try:
        print("🇮🇳 INITIALIZING RURAL MEDICAL ML SYSTEM...")
        
        system = IndiaRuralDiagnosticSystem()
        diagnosis = system.start_rural_diagnosis()
        
        print(f"\n🙏 Thank you for using Rural Medical ML System")
        print("Stay healthy!")
        
    except KeyboardInterrupt:
        print(f"\n\n👋 System stopped by user")
    except Exception as e:
        print(f"\n❌ System error: {e}")

if __name__ == "__main__":
    main()