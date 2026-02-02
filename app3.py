"""
Rule-Based Diagnostic System Backend
Uses NHS UK disease information and SNOMED CT terminology
Phase 1: Body area selection
Phase 2: Discriminating questions based on characteristics (timing, frequency, severity, character)
"""

# from fastapi import FastAPI, HTTPException
# from fastapi.middleware.cors import CORSMiddleware
# from pydantic import BaseModel
from typing import List, Dict, Optional, Any
import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# FASTAPI COMMENTED OUT FOR TERMINAL TESTING
# app = FastAPI(title="Symptomate - Rule-Based Diagnostic System")
# 
# # CORS middleware
# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=["*"],
#     allow_credentials=True,
#     allow_methods=["*"],
#     allow_headers=["*"],
# )

# ============================================================================
# BODY AREAS CONFIGURATION
# ============================================================================

BODY_AREAS = {
    "head": {
        "name": "Head",
        "sub_areas": ["forehead", "temples", "scalp", "face", "jaw"],
        "icon": "🧠"
    },
    "eyes": {
        "name": "Eyes",
        "sub_areas": ["left_eye", "right_eye", "both_eyes"],
        "icon": "👁️"
    },
    "ears": {
        "name": "Ears",
        "sub_areas": ["left_ear", "right_ear", "both_ears"],
        "icon": "👂"
    },
    "nose": {
        "name": "Nose/Sinuses",
        "sub_areas": ["nasal_passage", "sinuses"],
        "icon": "👃"
    },
    "throat": {
        "name": "Throat/Neck",
        "sub_areas": ["throat", "tonsils", "neck", "lymph_nodes"],
        "icon": "🗣️"
    },
    "chest": {
        "name": "Chest/Lungs",
        "sub_areas": ["upper_chest", "lungs", "heart_area", "ribs"],
        "icon": "🫁"
    },
    "abdomen": {
        "name": "Abdomen",
        "sub_areas": ["upper_abdomen", "lower_abdomen", "stomach", "intestines"],
        "icon": "🫃"
    },
    "back": {
        "name": "Back",
        "sub_areas": ["upper_back", "lower_back", "spine"],
        "icon": "🦴"
    },
    "arms": {
        "name": "Arms/Hands",
        "sub_areas": ["left_arm", "right_arm", "both_arms", "hands", "fingers"],
        "icon": "💪"
    },
    "legs": {
        "name": "Legs/Feet",
        "sub_areas": ["left_leg", "right_leg", "both_legs", "feet", "toes"],
        "icon": "🦵"
    },
    "skin": {
        "name": "Skin (General)",
        "sub_areas": ["rash", "lesions", "discoloration"],
        "icon": "🧴"
    },
    "general": {
        "name": "General/Systemic",
        "sub_areas": ["fever", "fatigue", "weakness", "weight_loss"],
        "icon": "🌡️"
    },
    "joints": {
        "name": "Joints",
        "sub_areas": ["knees", "elbows", "wrists", "ankles", "shoulders"],
        "icon": "🦴"
    }
}

# ============================================================================
# NHS UK INTEGRATION
# ============================================================================

class NHSUKScraper:
    """Scrapes and caches disease information from NHS UK"""
    
    BASE_URL = "https://www.nhs.uk/conditions"
    
    def __init__(self):
        self.cache = {}
        self.session = requests.Session()
        self.session.headers.update({
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        })
    
    def get_disease_info(self, condition_name: str) -> Dict[str, Any]:
        """Fetch disease information from NHS UK"""
        
        # Check cache first
        if condition_name in self.cache:
            logger.info(f"Returning cached NHS UK data for {condition_name}")
            return self.cache[condition_name]
        
        try:
            # Format condition name for URL
            url_condition = condition_name.lower().replace(" ", "-")
            url = f"{self.BASE_URL}/{url_condition}/"
            
            logger.info(f"Fetching NHS UK page: {url}")
            response = self.session.get(url, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract information
            info = {
                "name": condition_name,
                "url": url,
                "symptoms": self._extract_symptoms(soup),
                "causes": self._extract_causes(soup),
                "when_to_see_doctor": self._extract_when_to_see_doctor(soup),
                "treatment": self._extract_treatment(soup),
                "overview": self._extract_overview(soup),
                "scraped_at": datetime.now().isoformat()
            }
            
            # Cache it
            self.cache[condition_name] = info
            logger.info(f"Cached NHS UK data for {condition_name}")
            return info
            
        except requests.RequestException as e:
            logger.error(f"Error fetching NHS UK page for {condition_name}: {e}")
            return {"error": str(e), "name": condition_name}
    
    def _extract_overview(self, soup: BeautifulSoup) -> str:
        """Extract overview/introduction"""
        # Look for the first paragraph or intro section
        intro = soup.find('p', class_='nhsuk-lede-text')
        if intro:
            return intro.get_text().strip()
        
        # Fallback to first paragraph
        first_p = soup.find('p')
        if first_p:
            return first_p.get_text().strip()
        
        return ""
    
    def _extract_symptoms(self, soup: BeautifulSoup) -> List[str]:
        """Extract symptoms from NHS page"""
        symptoms = []
        
        # Look for symptoms section
        for header in soup.find_all(['h2', 'h3']):
            if 'symptom' in header.get_text().lower():
                # Get the next sibling content
                content = header.find_next(['ul', 'p', 'div'])
                if content:
                    if content.name == 'ul':
                        symptoms.extend([li.get_text().strip() for li in content.find_all('li')])
                    else:
                        symptoms.append(content.get_text().strip())
        
        return symptoms
    
    def _extract_causes(self, soup: BeautifulSoup) -> List[str]:
        """Extract causes from NHS page"""
        causes = []
        
        for header in soup.find_all(['h2', 'h3']):
            if 'cause' in header.get_text().lower():
                content = header.find_next(['ul', 'p', 'div'])
                if content:
                    if content.name == 'ul':
                        causes.extend([li.get_text().strip() for li in content.find_all('li')])
                    else:
                        causes.append(content.get_text().strip())
        
        return causes
    
    def _extract_when_to_see_doctor(self, soup: BeautifulSoup) -> str:
        """Extract when to see a doctor information"""
        for header in soup.find_all(['h2', 'h3']):
            text = header.get_text().lower()
            if 'see' in text and ('gp' in text or 'doctor' in text):
                content = header.find_next(['p', 'div'])
                if content:
                    return content.get_text().strip()
        return ""
    
    def _extract_treatment(self, soup: BeautifulSoup) -> List[str]:
        """Extract treatment information"""
        treatments = []
        
        for header in soup.find_all(['h2', 'h3']):
            if 'treatment' in header.get_text().lower():
                content = header.find_next(['ul', 'p', 'div'])
                if content:
                    if content.name == 'ul':
                        treatments.extend([li.get_text().strip() for li in content.find_all('li')])
                    else:
                        treatments.append(content.get_text().strip())
        
        return treatments

# ============================================================================
# RULE-BASED QUESTION ENGINE
# ============================================================================

class QuestionEngine:
    """Generates discriminating questions based on selected body areas with intelligent branching"""
    
    def __init__(self):
        # Question templates for different symptom types
        # These are DISCRIMINATING questions that help differentiate between similar conditions
        # Each question can have:
        # - depends_on: list of conditions that must be met to show this question
        # - priority: 1-10, higher = asked first
        # - follow_up_questions: questions to ask based on specific answers
        self.question_templates = {
            "fever": [
                {
                    "id": "has_fever",
                    "question": "Do you have a fever?",
                    "type": "single_choice",
                    "priority": 10,  # Ask first
                    "options": [
                        {"value": "yes", "label": "Yes, I have a fever"},
                        {"value": "no", "label": "No fever"},
                        {"value": "unsure", "label": "Not sure / Haven't checked temperature"}
                    ]
                },
                {
                    "id": "fever_timing",
                    "question": "When does the fever occur?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_fever", "values": ["yes", "unsure"]}],
                    "options": [
                        {"value": "alternate_days", "label": "Every alternate day (on/off pattern)", "suggests": ["dengue", "malaria"]},
                        {"value": "specific_time", "label": "At a specific time each day (e.g., always in evening)", "suggests": ["malaria"]},
                        {"value": "continuous", "label": "Continuous/persistent throughout day", "suggests": ["bacterial_infection", "viral_infection"]},
                        {"value": "evening_night", "label": "Mainly in evening/night", "suggests": ["tuberculosis"]},
                        {"value": "morning", "label": "Mainly in the morning", "suggests": []}
                    ]
                },
                {
                    "id": "fever_severity",
                    "question": "How high is the fever?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_fever", "values": ["yes"]}],
                    "options": [
                        {"value": "low", "label": "Low grade (37.5-38°C / 99.5-100.4°F)", "suggests": ["mild_viral_infection"]},
                        {"value": "moderate", "label": "Moderate (38-39°C / 100.4-102.2°F)", "suggests": []},
                        {"value": "high", "label": "High (>39°C / >102.2°F)", "suggests": ["dengue", "malaria", "severe_infection"]},
                        {"value": "very_high", "label": "Very high (>40°C / >104°F)", "suggests": ["severe_bacterial_infection", "sepsis"]}
                    ]
                },
                {
                    "id": "fever_duration",
                    "question": "How long have you had the fever?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_fever", "values": ["yes", "unsure"]}],
                    "options": [
                        {"value": "less_24h", "label": "Less than 24 hours", "suggests": ["acute_infection"]},
                        {"value": "1_3_days", "label": "1-3 days", "suggests": ["flu", "common_cold"]},
                        {"value": "4_7_days", "label": "4-7 days", "suggests": ["dengue", "typhoid"]},
                        {"value": "over_week", "label": "More than a week", "suggests": ["malaria", "tuberculosis", "typhoid"]},
                        {"value": "over_two_weeks", "label": "More than 2 weeks", "suggests": ["tuberculosis", "chronic_infection"]}
                    ]
                },
                {
                    "id": "fever_chills",
                    "question": "Do you experience chills/shivering with the fever?",
                    "type": "single_choice",
                    "priority": 7,
                    "depends_on": [{"question_id": "has_fever", "values": ["yes"]}],
                    "options": [
                        {"value": "severe_chills", "label": "Yes, severe shaking chills", "suggests": ["malaria", "sepsis"]},
                        {"value": "mild_chills", "label": "Yes, mild chills", "suggests": []},
                        {"value": "no_chills", "label": "No chills", "suggests": ["dengue"]}
                    ]
                }
            ],
            "head_pain": [
                {
                    "id": "has_headache",
                    "question": "Do you have a headache or head pain?",
                    "type": "single_choice",
                    "priority": 10,
                    "options": [
                        {"value": "yes", "label": "Yes"},
                        {"value": "no", "label": "No"}
                    ]
                },
                {
                    "id": "headache_type",
                    "question": "What type of headache pain is it?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_headache", "values": ["yes"]}],
                    "options": [
                        {"value": "throbbing", "label": "Throbbing/pulsating (like a heartbeat)", "suggests": ["migraine"]},
                        {"value": "pressure", "label": "Pressure/tightness (like a band around head)", "suggests": ["tension_headache"]},
                        {"value": "sharp_stabbing", "label": "Sharp/stabbing pain", "suggests": ["cluster_headache"]},
                        {"value": "dull_ache", "label": "Dull, constant ache", "suggests": ["tension_headache"]},
                        {"value": "explosive", "label": "Sudden, explosive (worst headache ever)", "suggests": ["subarachnoid_hemorrhage"]}
                    ]
                },
                {
                    "id": "headache_location",
                    "question": "Where is the headache located?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_headache", "values": ["yes"]}],
                    "options": [
                        {"value": "one_side", "label": "One side of head", "suggests": ["migraine", "cluster_headache"]},
                        {"value": "both_sides", "label": "Both sides of head", "suggests": ["tension_headache"]},
                        {"value": "forehead_eyes", "label": "Forehead/around eyes", "suggests": ["sinusitis"]},
                        {"value": "back_head_neck", "label": "Back of head/neck", "suggests": ["tension_headache"]},
                        {"value": "temple", "label": "Temple area", "suggests": ["temporal_arteritis", "migraine"]}
                    ]
                },
                {
                    "id": "headache_triggers",
                    "question": "What triggers or worsens the headache?",
                    "type": "multiple_choice",
                    "priority": 7,
                    "depends_on": [{"question_id": "has_headache", "values": ["yes"]}],
                    "options": [
                        {"value": "light", "label": "Bright light", "suggests": ["migraine"]},
                        {"value": "sound", "label": "Loud sounds", "suggests": ["migraine"]},
                        {"value": "movement", "label": "Physical movement", "suggests": ["migraine"]},
                        {"value": "bending", "label": "Bending forward", "suggests": ["sinusitis"]},
                        {"value": "stress", "label": "Stress", "suggests": ["tension_headache"]},
                        {"value": "none", "label": "No specific triggers", "suggests": []}
                    ]
                },
                {
                    "id": "headache_onset",
                    "question": "How did the headache start?",
                    "type": "single_choice",
                    "priority": 6,
                    "depends_on": [{"question_id": "has_headache", "values": ["yes"]}],
                    "options": [
                        {"value": "sudden_seconds", "label": "Suddenly (within seconds) - thunderclap", "suggests": ["subarachnoid_hemorrhage"]},
                        {"value": "rapid_minutes", "label": "Rapidly (within minutes)", "suggests": ["cluster_headache"]},
                        {"value": "gradual_hours", "label": "Gradually (over hours)", "suggests": ["migraine", "tension_headache"]},
                        {"value": "slow_days", "label": "Slowly (over days)", "suggests": ["chronic_daily_headache"]}
                    ]
                }
            ],
            "chest_pain": [
                {
                    "id": "has_chest_pain",
                    "question": "Do you have chest pain?",
                    "type": "single_choice",
                    "priority": 10,
                    "options": [
                        {"value": "yes", "label": "Yes"},
                        {"value": "no", "label": "No"}
                    ]
                },
                {
                    "id": "chest_pain_type",
                    "question": "What type of chest pain is it?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_chest_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "crushing_pressure", "label": "Crushing/squeezing pressure", "suggests": ["angina", "heart_attack"]},
                        {"value": "sharp_stabbing", "label": "Sharp/stabbing", "suggests": ["pleurisy", "pneumothorax"]},
                        {"value": "burning", "label": "Burning sensation", "suggests": ["gerd", "heartburn"]},
                        {"value": "aching", "label": "Dull aching", "suggests": ["muscle_strain"]},
                        {"value": "tearing", "label": "Tearing/ripping sensation", "suggests": ["aortic_dissection"]}
                    ]
                },
                {
                    "id": "chest_pain_radiation",
                    "question": "Does the pain spread to other areas?",
                    "type": "multiple_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_chest_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "left_arm", "label": "Left arm", "suggests": ["heart_attack", "angina"]},
                        {"value": "jaw", "label": "Jaw/neck", "suggests": ["heart_attack", "angina"]},
                        {"value": "back", "label": "Back/between shoulder blades", "suggests": ["aortic_dissection"]},
                        {"value": "shoulder", "label": "Shoulder", "suggests": ["pleurisy"]},
                        {"value": "no_radiation", "label": "No, stays in one spot", "suggests": ["costochondritis", "muscle_strain"]}
                    ]
                },
                {
                    "id": "chest_pain_breathing",
                    "question": "How does breathing affect the pain?",
                    "type": "single_choice",
                    "priority": 7,
                    "depends_on": [{"question_id": "has_chest_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "worse_deep_breath", "label": "Worse with deep breathing", "suggests": ["pleurisy", "pneumothorax"]},
                        {"value": "worse_shallow", "label": "Difficult to take deep breath", "suggests": ["pneumonia", "pulmonary_embolism"]},
                        {"value": "no_effect", "label": "No effect from breathing", "suggests": ["angina", "gerd"]},
                        {"value": "better_holding", "label": "Better when holding breath", "suggests": []}
                    ]
                }
            ],
            "respiratory": [
                {
                    "id": "has_cough",
                    "question": "Do you have a cough?",
                    "type": "single_choice",
                    "priority": 10,
                    "options": [
                        {"value": "yes", "label": "Yes"},
                        {"value": "no", "label": "No"}
                    ]
                },
                {
                    "id": "cough_type",
                    "question": "What type of cough do you have?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_cough", "values": ["yes"]}],
                    "options": [
                        {"value": "dry", "label": "Dry cough (no mucus)", "suggests": ["covid", "asthma", "viral_infection"]},
                        {"value": "productive_clear", "label": "Productive with clear/white mucus", "suggests": ["bronchitis", "viral_infection"]},
                        {"value": "productive_yellow", "label": "Productive with yellow/green mucus", "suggests": ["bacterial_bronchitis", "pneumonia"]},
                        {"value": "bloody", "label": "With blood or blood-tinged mucus", "suggests": ["tuberculosis", "pneumonia", "lung_cancer"]},
                        {"value": "barking", "label": "Barking/seal-like sound", "suggests": ["croup"]},
                        {"value": "whooping", "label": "Whooping sound after cough", "suggests": ["whooping_cough"]}
                    ]
                },
                {
                    "id": "cough_timing",
                    "question": "When is the cough worst?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_cough", "values": ["yes"]}],
                    "options": [
                        {"value": "night", "label": "At night/when lying down", "suggests": ["asthma", "gerd", "heart_failure"]},
                        {"value": "morning", "label": "In the morning", "suggests": ["chronic_bronchitis", "smoker_cough"]},
                        {"value": "exercise", "label": "During/after exercise", "suggests": ["asthma"]},
                        {"value": "constant", "label": "Throughout the day", "suggests": ["pneumonia", "bronchitis"]}
                    ]
                },
                {
                    "id": "breathing_difficulty",
                    "question": "Do you have difficulty breathing?",
                    "type": "single_choice",
                    "priority": 9,
                    "options": [
                        {"value": "no", "label": "No difficulty breathing", "suggests": []},
                        {"value": "exertion", "label": "Only during physical activity", "suggests": ["asthma", "copd"]},
                        {"value": "rest", "label": "Even at rest", "suggests": ["pneumonia", "heart_failure", "severe_asthma"]},
                        {"value": "wheezing", "label": "With wheezing/whistling sound", "suggests": ["asthma", "bronchitis"]},
                        {"value": "sudden", "label": "Sudden onset, severe", "suggests": ["pneumothorax", "pulmonary_embolism"]}
                    ]
                }
            ],
            "abdominal_pain": [
                {
                    "id": "has_abdominal_pain",
                    "question": "Do you have abdominal pain?",
                    "type": "single_choice",
                    "priority": 10,
                    "options": [
                        {"value": "yes", "label": "Yes"},
                        {"value": "no", "label": "No"}
                    ]
                },
                {
                    "id": "abdominal_pain_location",
                    "question": "Where is the abdominal pain located?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_abdominal_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "upper_right", "label": "Upper right (below ribs)", "suggests": ["gallstones", "liver_disease"]},
                        {"value": "upper_center", "label": "Upper center (epigastric)", "suggests": ["gastritis", "peptic_ulcer", "pancreatitis"]},
                        {"value": "upper_left", "label": "Upper left", "suggests": ["spleen_issue"]},
                        {"value": "lower_right", "label": "Lower right", "suggests": ["appendicitis"]},
                        {"value": "lower_center", "label": "Lower center/pelvis", "suggests": ["bladder_infection", "reproductive_issue"]},
                        {"value": "lower_left", "label": "Lower left", "suggests": ["diverticulitis"]},
                        {"value": "around_navel", "label": "Around belly button", "suggests": ["early_appendicitis", "intestinal_issue"]},
                        {"value": "diffuse", "label": "All over/diffuse", "suggests": ["gastroenteritis", "ibs"]}
                    ]
                },
                {
                    "id": "abdominal_pain_type",
                    "question": "What type of pain is it?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_abdominal_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "cramping", "label": "Cramping/colicky (comes and goes in waves)", "suggests": ["gastroenteritis", "ibs", "kidney_stones"]},
                        {"value": "constant_sharp", "label": "Constant, sharp pain", "suggests": ["appendicitis", "pancreatitis"]},
                        {"value": "burning", "label": "Burning", "suggests": ["gastritis", "peptic_ulcer"]},
                        {"value": "dull_ache", "label": "Dull, constant ache", "suggests": []},
                        {"value": "stabbing", "label": "Sudden, stabbing", "suggests": ["perforation"]}
                    ]
                },
                {
                    "id": "abdominal_pain_eating",
                    "question": "How does eating affect the pain?",
                    "type": "single_choice",
                    "priority": 7,
                    "depends_on": [{"question_id": "has_abdominal_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "worse_after", "label": "Worse immediately after eating", "suggests": ["gastritis", "gallstones"]},
                        {"value": "worse_hours", "label": "Worse 2-3 hours after eating", "suggests": ["peptic_ulcer"]},
                        {"value": "better", "label": "Better after eating", "suggests": ["duodenal_ulcer"]},
                        {"value": "no_relation", "label": "No relation to eating", "suggests": ["appendicitis", "kidney_stones"]}
                    ]
                }
            ],
            "digestive": [
                {
                    "id": "has_nausea",
                    "question": "Do you feel nauseous or have you been vomiting?",
                    "type": "single_choice",
                    "priority": 10,
                    "options": [
                        {"value": "yes", "label": "Yes"},
                        {"value": "no", "label": "No"}
                    ]
                },
                {
                    "id": "nausea_timing",
                    "question": "When do you feel nauseous?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_nausea", "values": ["yes"]}],
                    "options": [
                        {"value": "morning", "label": "Mainly in the morning", "suggests": ["pregnancy", "gastritis"]},
                        {"value": "after_eating", "label": "After eating", "suggests": ["food_poisoning", "gastritis"]},
                        {"value": "continuous", "label": "Throughout the day", "suggests": ["gastroenteritis"]},
                        {"value": "motion", "label": "During motion/travel", "suggests": ["motion_sickness"]},
                        {"value": "evening", "label": "Mainly in evening/night", "suggests": []}
                    ]
                },
                {
                    "id": "vomiting_characteristics",
                    "question": "If you're vomiting, what does it look like?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_nausea", "values": ["yes"]}],
                    "options": [
                        {"value": "food", "label": "Undigested food", "suggests": ["food_poisoning", "gastroenteritis"]},
                        {"value": "bile", "label": "Yellow/green bile", "suggests": ["bile_reflux"]},
                        {"value": "blood", "label": "Blood or coffee-ground appearance", "suggests": ["gastric_bleeding", "ulcer"]},
                        {"value": "projectile", "label": "Forceful/projectile vomiting", "suggests": ["obstruction"]},
                        {"value": "not_vomiting", "label": "Just nausea, no vomiting", "suggests": []}
                    ]
                }
            ],
            "joint_pain": [
                {
                    "id": "has_joint_pain",
                    "question": "Do you have joint pain or swelling?",
                    "type": "single_choice",
                    "priority": 10,
                    "options": [
                        {"value": "yes", "label": "Yes"},
                        {"value": "no", "label": "No"}
                    ]
                },
                {
                    "id": "joint_pattern",
                    "question": "Which joints are affected?",
                    "type": "single_choice",
                    "priority": 9,
                    "depends_on": [{"question_id": "has_joint_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "one_joint", "label": "Single joint", "suggests": ["injury", "gout", "septic_arthritis"]},
                        {"value": "symmetric", "label": "Same joints on both sides (e.g., both knees)", "suggests": ["rheumatoid_arthritis", "osteoarthritis"]},
                        {"value": "migrating", "label": "Pain moves from joint to joint", "suggests": ["rheumatic_fever", "viral_arthritis"]},
                        {"value": "multiple", "label": "Multiple different joints", "suggests": ["polyarthritis"]}
                    ]
                },
                {
                    "id": "joint_stiffness",
                    "question": "When is joint stiffness worst?",
                    "type": "single_choice",
                    "priority": 8,
                    "depends_on": [{"question_id": "has_joint_pain", "values": ["yes"]}],
                    "options": [
                        {"value": "morning_long", "label": "Morning, lasts >1 hour", "suggests": ["rheumatoid_arthritis"]},
                        {"value": "morning_short", "label": "Morning, lasts <30 minutes", "suggests": ["osteoarthritis"]},
                        {"value": "after_rest", "label": "After sitting/resting", "suggests": ["osteoarthritis"]},
                        {"value": "end_of_day", "label": "Gets worse through the day", "suggests": ["osteoarthritis"]},
                        {"value": "no_stiffness", "label": "No stiffness, just pain", "suggests": ["injury"]}
                    ]
                }
            ],
            "eye_symptoms": [
            {
                "id": "has_eye_symptoms",
                "question": "Are you experiencing any eye problems?",
                "type": "single_choice",
                "priority": 10,
                "options": [
                    {"value": "yes", "label": "Yes"},
                    {"value": "no", "label": "No"}
                ]
            },
            {
                "id": "eye_symptom_type",
                "question": "What eye symptoms do you have?",
                "type": "multiple_choice",
                "priority": 9,
                "depends_on": [{"question_id": "has_eye_symptoms", "values": ["yes"]}],
                "options": [
                    {"value": "redness", "label": "Redness/bloodshot eyes", "suggests": ["conjunctivitis", "dry_eye"]},
                    {"value": "pain", "label": "Eye pain", "suggests": ["glaucoma", "uveitis"]},
                    {"value": "discharge", "label": "Discharge/watery eyes", "suggests": ["conjunctivitis"]},
                    {"value": "itching", "label": "Itching", "suggests": ["allergic_conjunctivitis"]},
                    {"value": "blurred_vision", "label": "Blurred vision", "suggests": ["refractive_error"]},
                    {"value": "sensitivity", "label": "Light sensitivity", "suggests": ["migraine", "uveitis"]}
                ]
            }
        ],
        "ear_symptoms": [
            {
                "id": "has_ear_symptoms",
                "question": "Are you experiencing ear problems?",
                "type": "single_choice",
                "priority": 10,
                "options": [
                    {"value": "yes", "label": "Yes"},
                    {"value": "no", "label": "No"}
                ]
            },
            {
                "id": "ear_symptom_type",
                "question": "What ear symptoms do you have?",
                "type": "multiple_choice",
                "priority": 9,
                "depends_on": [{"question_id": "has_ear_symptoms", "values": ["yes"]}],
                "options": [
                    {"value": "pain", "label": "Ear pain/ache", "suggests": ["ear_infection"]},
                    {"value": "discharge", "label": "Discharge from ear", "suggests": ["ear_infection"]},
                    {"value": "hearing_loss", "label": "Hearing loss/muffled", "suggests": ["ear_wax", "ear_infection"]},
                    {"value": "ringing", "label": "Ringing/tinnitus", "suggests": ["tinnitus"]},
                    {"value": "fullness", "label": "Feeling of fullness", "suggests": ["ear_wax", "eustachian_tube"]}
                ]
            }
        ],
        "skin_symptoms": [
            {
                "id": "has_skin_symptoms",
                "question": "Do you have any skin problems?",
                "type": "single_choice",
                "priority": 10,
                "options": [
                    {"value": "yes", "label": "Yes"},
                    {"value": "no", "label": "No"}
                ]
            },
            {
                "id": "skin_symptom_type",
                "question": "What skin symptoms do you have?",
                "type": "multiple_choice",
                "priority": 9,
                "depends_on": [{"question_id": "has_skin_symptoms", "values": ["yes"]}],
                "options": [
                    {"value": "rash", "label": "Rash", "suggests": ["allergic_reaction", "eczema"]},
                    {"value": "itching", "label": "Itching", "suggests": ["eczema", "allergic_reaction"]},
                    {"value": "redness", "label": "Redness/inflammation", "suggests": ["cellulitis", "dermatitis"]},
                    {"value": "spots", "label": "Spots/bumps/blisters", "suggests": ["chickenpox", "shingles"]},
                    {"value": "dryness", "label": "Dryness/flaking", "suggests": ["eczema", "psoriasis"]}
                ]
            }
        ]
        }
        
        # Map body areas to relevant question categories
        self.body_area_question_map = {
            "head": ["head_pain", "fever"],
            "eyes": ["eye_symptoms", "fever"],
            "ears": ["ear_symptoms", "fever"],
            "nose": ["respiratory", "fever"],
            "throat": ["respiratory", "fever"],
            "chest": ["chest_pain", "respiratory"],
            "abdomen": ["abdominal_pain", "digestive"],
            "back": ["head_pain"],  # Back pain similar questions to head pain
            "arms": ["joint_pain"],
            "legs": ["joint_pain"],
            "skin": ["skin_symptoms"],
            "general": ["fever"],
            "joints": ["joint_pain"]
        }
    
    def get_questions_for_areas(self, selected_areas: List[str], previous_answers: Dict[str, Any] = None) -> List[Dict[str, Any]]:
        """
        Generate relevant discriminating questions based on selected body areas
        With intelligent filtering based on previous answers
        
        Args:
            selected_areas: List of body areas selected by user
            previous_answers: Optional dict of previous answers for conditional logic
        """
        if previous_answers is None:
            previous_answers = {}
        
        all_questions = []
        asked_categories = set()
        
        # Gather all relevant questions based on body areas
        for area in selected_areas:
            if area in self.body_area_question_map:
                categories = self.body_area_question_map[area]
                for category in categories:
                    if category not in asked_categories:
                        if category in self.question_templates:
                            all_questions.extend(self.question_templates[category])
                            asked_categories.add(category)
        
        # Filter questions based on dependencies
        filtered_questions = []
        for question in all_questions:
            if self._should_ask_question(question, previous_answers):
                filtered_questions.append(question.copy())
        
        # Sort by priority (highest first)
        filtered_questions.sort(key=lambda q: q.get("priority", 5), reverse=True)
        
        # Add question numbers for display
        for idx, question in enumerate(filtered_questions, 1):
            question["number"] = idx
        
        return filtered_questions
    
    def _should_ask_question(self, question: Dict[str, Any], answers: Dict[str, Any]) -> bool:
        """
        Determine if a question should be asked based on dependencies
        
        Args:
            question: Question dict with optional 'depends_on' field
            answers: User's previous answers
            
        Returns:
            True if question should be asked, False otherwise
        """
        # If no dependencies, always ask
        if "depends_on" not in question:
            return True
        
        dependencies = question["depends_on"]
        
        # Check all dependencies
        for dependency in dependencies:
            question_id = dependency.get("question_id")
            required_values = dependency.get("values", [dependency.get("value")])
            
            # Convert single value to list
            if not isinstance(required_values, list):
                required_values = [required_values]
            
            # Get user's answer for the dependency question
            user_answer = answers.get(question_id)
            
            # If dependency question not answered yet, don't ask this question
            if user_answer is None:
                return False
            
            # Check if user's answer matches any required value
            if user_answer not in required_values:
                return False
        
        # All dependencies met
        return True
    
    def get_next_batch_questions(self, selected_areas: List[str], current_answers: Dict[str, Any], batch_size: int = 5) -> List[Dict[str, Any]]:
        """
        Get next batch of questions progressively
        
        Args:
            selected_areas: Body areas selected
            current_answers: Answers provided so far
            batch_size: Number of questions to return at once
            
        Returns:
            Next batch of questions to ask
        """
        # Get all eligible questions
        all_eligible = self.get_questions_for_areas(selected_areas, current_answers)
        
        # Filter out already answered questions
        unanswered = [q for q in all_eligible if q["id"] not in current_answers]
        
        # Return next batch
        return unanswered[:batch_size]

# ============================================================================
# DIAGNOSTIC RULE ENGINE
# ============================================================================

class DiagnosticEngine:
    """Rule-based diagnostic engine using NHS UK data and SNOMED CT"""
    
    def __init__(self, nhs_scraper: NHSUKScraper):
        self.nhs_scraper = nhs_scraper
        self.rules = self._load_diagnostic_rules()
    
    def _load_diagnostic_rules(self) -> Dict[str, Any]:
        """
        Load comprehensive diagnostic rules - FLEXIBLE MATCHING
        Each rule defines:
        - SNOMED CT code
        - Required conditions (must match at least one)
        - Optional conditions (bonus points)
        """
        return {
            # Simpler, more flexible rules
            "headache_general": {
                "snomed_code": "25064002",
                "display_name": "Headache (General)",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_headache", "value": "yes"}
                ],
                "optional_conditions": [],
                "base_confidence": 0.4
            },
            "fever_general": {
                "snomed_code": "386661006",
                "display_name": "Fever (General)",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_fever", "value": "yes"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "fever_severity", "value": "high", "points": 0.2}
                ],
                "base_confidence": 0.3
            },
            "dengue": {
                "snomed_code": "38362002",
                "display_name": "Dengue Fever",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_fever", "value": "yes"},
                    {"type": "answer", "question_id": "fever_timing", "value": "alternate_days"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "fever_duration", "values": ["4_7_days", "over_week"], "points": 0.3},
                    {"type": "answer", "question_id": "fever_severity", "value": "high", "points": 0.2},
                    {"type": "answer", "question_id": "fever_chills", "value": "no_chills", "points": 0.15}
                ],
                "base_confidence": 0.5
            },
            "malaria": {
                "snomed_code": "61462000",
                "display_name": "Malaria",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_fever", "value": "yes"},
                    {"type": "answer", "question_id": "fever_timing", "value": "specific_time"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "fever_severity", "value": "high", "points": 0.2},
                    {"type": "answer", "question_id": "fever_chills", "value": "severe_chills", "points": 0.25},
                    {"type": "answer", "question_id": "fever_duration", "value": "over_week", "points": 0.15}
                ],
                "base_confidence": 0.6
            },
            "migraine": {
                "snomed_code": "37796009",
                "display_name": "Migraine",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_headache", "value": "yes"},
                    {"type": "answer", "question_id": "headache_type", "value": "throbbing"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "headache_location", "value": "one_side", "points": 0.2},
                    {"type": "answer", "question_id": "headache_triggers", "values": ["light", "sound"], "points": 0.2},
                    {"type": "body_area", "area": "head", "points": 0.1}
                ],
                "base_confidence": 0.5
            },
            "tension_headache": {
                "snomed_code": "398057008",
                "display_name": "Tension Headache",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_headache", "value": "yes"},
                    {"type": "answer", "question_id": "headache_type", "values": ["pressure", "dull_ache"]}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "headache_location", "value": "both_sides", "points": 0.2},
                    {"type": "answer", "question_id": "headache_triggers", "value": "stress", "points": 0.15},
                    {"type": "body_area", "area": "head", "points": 0.1}
                ],
                "base_confidence": 0.5
            },
            "cluster_headache": {
                "snomed_code": "193031009",
                "display_name": "Cluster Headache",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_headache", "value": "yes"},
                    {"type": "answer", "question_id": "headache_type", "value": "sharp_stabbing"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "headache_location", "value": "one_side", "points": 0.25}
                ],
                "base_confidence": 0.5
            },
            "conjunctivitis": {
                "snomed_code": "9826008",
                "display_name": "Conjunctivitis (Pink Eye)",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_eye_symptoms", "value": "yes"},
                    {"type": "answer", "question_id": "eye_symptom_type", "values": ["redness", "discharge"]}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "eye_symptom_type", "value": "itching", "points": 0.15}
                ],
                "base_confidence": 0.6
            },
            "appendicitis": {
                "snomed_code": "74400008",
                "display_name": "Appendicitis",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_abdominal_pain", "value": "yes"},
                    {"type": "answer", "question_id": "abdominal_pain_location", "value": "lower_right"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "abdominal_pain_type", "value": "constant_sharp", "points": 0.2},
                    {"type": "answer", "question_id": "has_fever", "value": "yes", "points": 0.15}
                ],
                "base_confidence": 0.6
            },
            "gastritis": {
                "snomed_code": "4556007",
                "display_name": "Gastritis",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_abdominal_pain", "value": "yes"},
                    {"type": "answer", "question_id": "abdominal_pain_location", "value": "upper_center"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "abdominal_pain_type", "value": "burning", "points": 0.2},
                    {"type": "answer", "question_id": "abdominal_pain_eating", "value": "worse_after", "points": 0.15},
                    {"type": "answer", "question_id": "has_nausea", "value": "yes", "points": 0.1}
                ],
                "base_confidence": 0.5
            },
            "pneumonia": {
                "snomed_code": "233604007",
                "display_name": "Pneumonia",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_cough", "value": "yes"},
                    {"type": "answer", "question_id": "cough_type", "values": ["productive_yellow", "productive_clear"]}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "breathing_difficulty", "value": "rest", "points": 0.25},
                    {"type": "answer", "question_id": "has_fever", "value": "yes", "points": 0.2},
                    {"type": "answer", "question_id": "has_chest_pain", "value": "yes", "points": 0.15},
                    {"type": "body_area", "area": "chest", "points": 0.1}
                ],
                "base_confidence": 0.5
            },
            "asthma": {
                "snomed_code": "195967001",
                "display_name": "Asthma",
                "required_conditions": [
                    {"type": "answer", "question_id": "breathing_difficulty", "value": "wheezing"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "has_cough", "value": "yes", "points": 0.15},
                    {"type": "answer", "question_id": "cough_type", "value": "dry", "points": 0.15},
                    {"type": "answer", "question_id": "cough_timing", "values": ["night", "exercise"], "points": 0.2},
                    {"type": "body_area", "area": "chest", "points": 0.1}
                ],
                "base_confidence": 0.5
            },
            "bronchitis": {
                "snomed_code": "32398004",
                "display_name": "Bronchitis",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_cough", "value": "yes"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "cough_type", "values": ["productive_clear", "productive_yellow"], "points": 0.3},
                    {"type": "answer", "question_id": "breathing_difficulty", "value": "wheezing", "points": 0.2}
                ],
                "base_confidence": 0.4
            },
            "rheumatoid_arthritis": {
                "snomed_code": "69896004",
                "display_name": "Rheumatoid Arthritis",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_joint_pain", "value": "yes"},
                    {"type": "answer", "question_id": "joint_pattern", "value": "symmetric"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "joint_stiffness", "value": "morning_long", "points": 0.3}
                ],
                "base_confidence": 0.5
            },
            "osteoarthritis": {
                "snomed_code": "396275006",
                "display_name": "Osteoarthritis",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_joint_pain", "value": "yes"}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "joint_stiffness", "values": ["morning_short", "after_rest", "end_of_day"], "points": 0.3}
                ],
                "base_confidence": 0.4
            },
            "tuberculosis": {
                "snomed_code": "56717001",
                "display_name": "Tuberculosis",
                "required_conditions": [
                    {"type": "answer", "question_id": "has_fever", "value": "yes"},
                    {"type": "answer", "question_id": "fever_timing", "value": "evening_night"},
                    {"type": "answer", "question_id": "fever_duration", "values": ["over_week", "over_two_weeks"]}
                ],
                "optional_conditions": [
                    {"type": "answer", "question_id": "has_cough", "value": "yes", "points": 0.2},
                    {"type": "answer", "question_id": "cough_type", "value": "bloody", "points": 0.3}
                ],
                "base_confidence": 0.5
            }
        }
    
    def diagnose(self, body_areas: List[str], answers: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Run diagnostic rules and return possible conditions
        
        Args:
            body_areas: Selected body areas
            answers: User's answers to questions {question_id: selected_value or [values]}
            
        Returns:
            List of possible diagnoses sorted by confidence
        """
        results = []
        
        for disease_name, rule in self.rules.items():
            confidence = 0.0
            matching_criteria = []
            all_required_met = True
            
            # Check ALL required conditions - if any fail, skip this disease
            for condition in rule.get("required_conditions", []):
                if condition["type"] == "body_area":
                    if condition["area"] in body_areas:
                        matching_criteria.append(f"✓ Affects {condition['area']}")
                    else:
                        all_required_met = False
                        break
                
                elif condition["type"] == "answer":
                    question_id = condition["question_id"]
                    user_answer = answers.get(question_id)
                    
                    # Handle single value or multiple values
                    if "value" in condition:
                        if user_answer == condition["value"]:
                            matching_criteria.append(f"✓ {question_id}: {condition['value']}")
                        else:
                            all_required_met = False
                            break
                    
                    elif "values" in condition:
                        if user_answer in condition["values"]:
                            matching_criteria.append(f"✓ {question_id}: {user_answer}")
                        else:
                            all_required_met = False
                            break
            
            # If any required condition not met, skip this disease
            if not all_required_met:
                continue
            
            # Start with base confidence
            confidence = rule["base_confidence"]
            
            # Check optional conditions for bonus points
            for condition in rule.get("optional_conditions", []):
                points = condition.get("points", 0.1)
                
                if condition["type"] == "body_area":
                    if condition["area"] in body_areas:
                        confidence += points
                        matching_criteria.append(f"+ {condition['area']} affected (+{points:.2f})")
                
                elif condition["type"] == "answer":
                    question_id = condition["question_id"]
                    user_answer = answers.get(question_id)
                    
                    if "value" in condition:
                        if user_answer == condition["value"]:
                            confidence += points
                            matching_criteria.append(f"+ {question_id}: {condition['value']} (+{points:.2f})")
                    
                    elif "values" in condition:
                        # For multiple choice questions
                        if isinstance(user_answer, list):
                            if any(val in user_answer for val in condition["values"]):
                                confidence += points
                                matching_criteria.append(f"+ {question_id} match (+{points:.2f})")
                        else:
                            if user_answer in condition["values"]:
                                confidence += points
                                matching_criteria.append(f"+ {question_id}: {user_answer} (+{points:.2f})")
            
            # Cap confidence at 1.0
            confidence = min(confidence, 1.0)
            
            # Fetch NHS UK information
            nhs_info = self.nhs_scraper.get_disease_info(disease_name)
            
            results.append({
                "disease": disease_name,
                "display_name": rule.get("display_name", disease_name.replace("_", " ").title()),
                "snomed_code": rule.get("snomed_code"),
                "confidence": round(confidence, 2),
                "confidence_percentage": f"{round(confidence * 100)}%",
                "matching_criteria": matching_criteria,
                "nhs_info": nhs_info
            })
        
        # Sort by confidence (highest first)
        results.sort(key=lambda x: x["confidence"], reverse=True)
        
        return results

# ============================================================================
# INITIALIZE SERVICES
# ============================================================================

nhs_scraper = NHSUKScraper()
question_engine = QuestionEngine()
diagnostic_engine = DiagnosticEngine(nhs_scraper)

# ============================================================================
# PYDANTIC MODELS - COMMENTED OUT FOR TERMINAL TESTING
# ============================================================================

# class BodyAreaSelection(BaseModel):
#     areas: List[str]
# 
# class ProgressiveQuestionRequest(BaseModel):
#     body_areas: List[str]
#     current_answers: Dict[str, Any] = {}
#     batch_size: int = 5
# 
# class DiagnosticAnswers(BaseModel):
#     body_areas: List[str]
#     answers: Dict[str, Any]  # {question_id: selected_value or [values] for multi-choice}

# ============================================================================
# FASTAPI ENDPOINTS - COMMENTED OUT FOR TERMINAL TESTING
# ============================================================================

# @app.get("/")
# async def root():
#     """Root endpoint"""
#     return {
#         "service": "Symptomate Rule-Based Diagnostic System",
#         "version": "3.0",
#         "approach": "Rule-based with NHS UK and SNOMED CT integration",
#         "phases": [
#             "Phase 1: Body area selection",
#             "Phase 2: Discriminating questions (timing, frequency, severity, character)"
#         ],
#         "knowledge_sources": ["NHS UK", "SNOMED CT"]
#     }
# 
# @app.get("/api/body-areas")
# async def get_body_areas():
#     """
#     PHASE 1: Get available body areas for selection
#     User selects where they have pain/symptoms
#     """
#     return {
#         "body_areas": BODY_AREAS,
#         "instructions": "Select ALL areas where you are experiencing symptoms, pain, or discomfort",
#         "phase": "1 - Body Area Selection"
#     }
# 
# @app.post("/api/get-questions")
# async def get_questions(selection: BodyAreaSelection):
#     """
#     PHASE 2: Get ALL discriminating questions based on selected body areas
#     
#     These questions help differentiate between similar conditions using:
#     - Timing (when does it occur?)
#     - Frequency (how often?)
#     - Character (what type of pain/symptom?)
#     - Severity (how bad is it?)
#     
#     Note: This returns ALL potential questions. Use /api/get-next-questions for progressive questioning.
#     """
#     if not selection.areas:
#         raise HTTPException(status_code=400, detail="No body areas selected")
#     
#     # Validate areas
#     invalid_areas = [area for area in selection.areas if area not in BODY_AREAS]
#     if invalid_areas:
#         raise HTTPException(status_code=400, detail=f"Invalid body areas: {invalid_areas}")
#     
#     questions = question_engine.get_questions_for_areas(selection.areas)
#     
#     return {
#         "body_areas": selection.areas,
#         "questions": questions,
#         "total_questions": len(questions),
#         "phase": "2 - Discriminating Questions",
#         "mode": "all_questions",
#         "instructions": "Answer these questions to help narrow down your condition"
#     }
# 
# @app.post("/api/get-next-questions")
# async def get_next_questions(request: ProgressiveQuestionRequest):
#     """
#     PHASE 2 - PROGRESSIVE: Get next batch of questions based on previous answers
#     
#     This endpoint provides intelligent, adaptive questioning:
#     - Only asks relevant questions based on previous answers
#     - Skips questions if user answered "no" to parent question
#     - Returns questions in priority order (most discriminating first)
#     - Supports batch-by-batch questioning for better UX
#     
#     Example:
#     - User says "no fever" → skip all fever-related questions
#     - User says "yes headache" → ask headache type, location, etc.
#     """
#     if not request.body_areas:
#         raise HTTPException(status_code=400, detail="No body areas selected")
#     
#     # Validate areas
#     invalid_areas = [area for area in request.body_areas if area not in BODY_AREAS]
#     if invalid_areas:
#         raise HTTPException(status_code=400, detail=f"Invalid body areas: {invalid_areas}")
#     
#     # Get next batch of questions
#     next_questions = question_engine.get_next_batch_questions(
#         request.body_areas,
#         request.current_answers,
#         request.batch_size
#     )
#     
#     # Check if we're done
#     all_eligible = question_engine.get_questions_for_areas(request.body_areas, request.current_answers)
#     answered_count = len([q for q in all_eligible if q["id"] in request.current_answers])
#     total_eligible = len(all_eligible)
#     
#     return {
#         "body_areas": request.body_areas,
#         "questions": next_questions,
#         "batch_size": len(next_questions),
#         "progress": {
#             "answered": answered_count,
#             "total_eligible": total_eligible,
#             "remaining": total_eligible - answered_count,
#             "percentage": round((answered_count / total_eligible * 100) if total_eligible > 0 else 0)
#         },
#         "is_complete": len(next_questions) == 0,
#         "phase": "2 - Progressive Discriminating Questions",
#         "mode": "adaptive_progressive",
#         "instructions": "Answer these questions. More questions may appear based on your answers."
#     }
# 
# @app.post("/api/diagnose")
# async def diagnose(data: DiagnosticAnswers):
#     """
#     Perform rule-based diagnosis
#     
#     Returns possible conditions sorted by confidence with:
#     - SNOMED CT codes
#     - Matching criteria explanation
#     - NHS UK information (symptoms, causes, treatment)
#     """
#     if not data.body_areas:
#         raise HTTPException(status_code=400, detail="No body areas provided")
#     
#     if not data.answers:
#         raise HTTPException(status_code=400, detail="No answers provided")
#     
#     # Run diagnostic engine
#     diagnoses = diagnostic_engine.diagnose(data.body_areas, data.answers)
#     
#     if not diagnoses:
#         return {
#             "body_areas": data.body_areas,
#             "answers": data.answers,
#             "diagnoses": [],
#             "message": "No matching conditions found. Please consult a healthcare provider.",
#             "timestamp": datetime.now().isoformat()
#         }
#     
#     return {
#         "body_areas": data.body_areas,
#         "answers": data.answers,
#         "diagnoses": diagnoses,
#         "total_matches": len(diagnoses),
#         "top_match": diagnoses[0] if diagnoses else None,
#         "timestamp": datetime.now().isoformat()
#     }
# 
# @app.get("/api/disease-info/{disease_name}")
# async def get_disease_info(disease_name: str):
#     """Get detailed NHS UK information for a specific disease"""
#     info = nhs_scraper.get_disease_info(disease_name)
#     
#     if "error" in info:
#         raise HTTPException(status_code=404, detail=f"Could not fetch information for {disease_name}")
#     
#     return info
# 
# @app.get("/api/health")
# async def health_check():
#     """Health check endpoint"""
#     return {
#         "status": "healthy",
#         "timestamp": datetime.now().isoformat(),
#         "nhs_cache_size": len(nhs_scraper.cache),
#         "total_rules": len(diagnostic_engine.rules),
#         "question_categories": len(question_engine.question_templates)
#     }
# 
# @app.get("/api/stats")
# async def get_stats():
#     """Get system statistics"""
#     return {
#         "total_body_areas": len(BODY_AREAS),
#         "total_diagnostic_rules": len(diagnostic_engine.rules),
#         "total_question_categories": len(question_engine.question_templates),
#         "diseases_with_rules": list(diagnostic_engine.rules.keys()),
#         "nhs_cached_diseases": list(nhs_scraper.cache.keys())
#     }

# ============================================================================
# TERMINAL-BASED TESTING INTERFACE
# ============================================================================

def terminal_interface():
    """Interactive terminal interface for testing"""
    print("=" * 70)
    print("🏥 SYMPTOMATE - Rule-Based Diagnostic System (Terminal Mode)")
    print("=" * 70)
    print("📚 Knowledge: NHS UK + SNOMED CT")
    print("🎯 Method: Adaptive rule-based questioning")
    print("=" * 70)
    print()
    
    # PHASE 1: Body Area Selection
    print("📍 PHASE 1: Body Area Selection")
    print("-" * 70)
    print("Available body areas:")
    print()
    
    area_list = []
    for idx, (area_id, area_data) in enumerate(BODY_AREAS.items(), 1):
        print(f"  {idx}. {area_data['icon']} {area_data['name']} ({area_id})")
        area_list.append(area_id)
    
    print()
    print("Enter the numbers of affected areas (comma-separated, e.g., 1,12):")
    selection_input = input("➤ ").strip()
    
    selected_areas = []
    try:
        selected_indices = [int(x.strip()) - 1 for x in selection_input.split(",")]
        selected_areas = [area_list[i] for i in selected_indices if 0 <= i < len(area_list)]
    except:
        print("❌ Invalid input. Using 'head' and 'general' as default.")
        selected_areas = ["head", "general"]
    
    print(f"\n✅ Selected areas: {', '.join([BODY_AREAS[a]['name'] for a in selected_areas])}")
    print()
    
    # PHASE 2: Progressive Questioning
    print("=" * 70)
    print("❓ PHASE 2: Adaptive Discriminating Questions")
    print("=" * 70)
    print("Answer questions one by one. The system will adapt based on your answers.")
    print()
    
    current_answers = {}
    batch_size = 3  # Ask 3 questions at a time
    
    while True:
        # Get next batch of questions
        next_questions = question_engine.get_next_batch_questions(
            selected_areas,
            current_answers,
            batch_size
        )
        
        if not next_questions:
            print("\n✅ All relevant questions answered!")
            break
        
        # Ask each question in the batch
        for question in next_questions:
            print("-" * 70)
            print(f"\n[Q{question['number']}] {question['question']}")
            print()
            
            if question['type'] == 'single_choice':
                for idx, option in enumerate(question['options'], 1):
                    print(f"  {idx}. {option['label']}")
                
                print()
                choice_input = input("➤ Enter number: ").strip()
                
                try:
                    choice_idx = int(choice_input) - 1
                    if 0 <= choice_idx < len(question['options']):
                        selected_value = question['options'][choice_idx]['value']
                        current_answers[question['id']] = selected_value
                        print(f"   ✓ Answered: {question['options'][choice_idx]['label']}")
                    else:
                        print("   ⚠ Invalid choice. Skipping question.")
                except:
                    print("   ⚠ Invalid input. Skipping question.")
            
            elif question['type'] == 'multiple_choice':
                for idx, option in enumerate(question['options'], 1):
                    print(f"  {idx}. {option['label']}")
                
                print()
                print("Enter numbers (comma-separated, e.g., 1,3):")
                choice_input = input("➤ ").strip()
                
                try:
                    choice_indices = [int(x.strip()) - 1 for x in choice_input.split(",")]
                    selected_values = [
                        question['options'][i]['value']
                        for i in choice_indices
                        if 0 <= i < len(question['options'])
                    ]
                    current_answers[question['id']] = selected_values
                    print(f"   ✓ Answered: {len(selected_values)} options selected")
                except:
                    print("   ⚠ Invalid input. Skipping question.")
            
            print()
    
    # PHASE 3: Diagnosis
    print("=" * 70)
    print("🔬 PHASE 3: Running Diagnostic Engine...")
    print("=" * 70)
    print()
    
    diagnoses = diagnostic_engine.diagnose(selected_areas, current_answers)
    
    if not diagnoses:
        print("❌ No matching conditions found based on your answers.")
        print("   Please consult a healthcare provider for proper evaluation.")
    else:
        print(f"✅ Found {len(diagnoses)} possible condition(s):\n")
        
        for idx, diagnosis in enumerate(diagnoses, 1):
            print("=" * 70)
            print(f"#{idx} - {diagnosis['display_name']}")
            print("=" * 70)
            print(f"Confidence: {diagnosis['confidence_percentage']} ({diagnosis['confidence']:.2f})")
            print(f"SNOMED Code: {diagnosis['snomed_code']}")
            print()
            print("Matching Criteria:")
            for criteria in diagnosis['matching_criteria']:
                print(f"  • {criteria}")
            print()
            
            # Show NHS UK info if available
            nhs_info = diagnosis.get('nhs_info', {})
            if nhs_info and 'error' not in nhs_info:
                print("NHS UK Information:")
                print(f"  URL: {nhs_info.get('url', 'N/A')}")
                
                if nhs_info.get('overview'):
                    print(f"\n  Overview:")
                    print(f"    {nhs_info['overview'][:200]}...")
                
                if nhs_info.get('symptoms'):
                    print(f"\n  Symptoms:")
                    for symptom in nhs_info['symptoms'][:3]:
                        print(f"    • {symptom[:100]}")
                
                if nhs_info.get('when_to_see_doctor'):
                    print(f"\n  When to see a doctor:")
                    print(f"    {nhs_info['when_to_see_doctor'][:150]}...")
            print()
    
    print("=" * 70)
    print("⚠️  DISCLAIMER: This is not a substitute for professional medical advice.")
    print("   Please consult a healthcare provider for proper diagnosis and treatment.")
    print("=" * 70)

if __name__ == "__main__":
    # Terminal testing mode
    terminal_interface()
    
    # FastAPI mode (commented out)
    # import uvicorn
    # print("=" * 60)
    # print("🏥 SYMPTOMATE - Rule-Based Diagnostic System")
    # print("=" * 60)
    # print("📚 Knowledge Sources:")
    # print("   - NHS UK website for disease information")
    # print("   - SNOMED CT for medical terminology")
    # print("\n🎯 Two-Phase Approach:")
    # print("   Phase 1: User selects affected body areas")
    # print("   Phase 2: Discriminating questions (timing, frequency, character)")
    # print("\n✅ NO ML MODEL - Pure rule-based logic")
    # print("=" * 60)
    # uvicorn.run(app, host="0.0.0.0", port=8000)
