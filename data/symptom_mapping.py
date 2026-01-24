# data/symptom_mapping.py

"""
Mapping between questionnaire symptom names and model feature names.
The questionnaire uses descriptive names like "chest_pain_present" 
while the model expects original dataset feature names like "chest_pain".
"""

SYMPTOM_TO_FEATURE_MAP = {
    # Chest symptoms
    "chest_pain_present": "chest_pain",
    "breathing_difficulty_present": "breathlessness", 
    "wheezing_present": "wheezing",  # Need to check if this exists in dataset
    "cough_present": "cough",
    "chest_pain_exertional": "chest_pain",  # Maps to same feature
    
    # Skin symptoms  
    "skin_rash_present": "skin_rash",
    "itching_present": "itching",
    "skin_eruptions_present": "nodal_skin_eruptions",
    
    # Abdomen symptoms
    "abdominal_pain_present": "abdominal_pain",
    "stomach_pain_present": "stomach_pain", 
    "nausea_present": "nausea",
    "vomiting_present": "vomiting",
    "diarrhea_present": "diarrhoea",
    
    # ENT symptoms
    "sore_throat_present": "throat_irritation",
    "runny_nose_present": "runny_nose",
    "sneezing_present": "continuous_sneezing",
    "sinus_pressure_present": "sinus_pressure",
    "ear_pain_present": "ear_pain",  # Need to check if this exists
    
    # Neurological/Head symptoms  
    "headache_present": "headache",
    "dizziness_present": "dizziness", 
    "vision_problems": "altered_sensorium",  # Closest available
    "light_sound_sensitivity": "irritability",  # Closest available
    
    # Missing chest symptom mappings
    "cough_duration": "cough",  # Duration maps to general cough feature
    "smoking_frequency": "smoking",  # Maps to smoking feature if it exists
    "chest_pain_exertional": "chest_pain",  # Exercise-induced chest pain
    "chest_pain_persistent": "chest_pain",  # Persistent chest pain
    "breathing_difficulty_persistent": "breathlessness",  # Persistent breathing issues
    
    # Head/Neuro symptoms
    "headache_present": "headache",
    "dizziness_present": "dizziness",
    "neck_pain_present": "neck_pain",
    "vision_problems_present": "blurred_and_distorted_vision",
    
    # Systemic symptoms
    "systemic_fever": "high_fever",
    "systemic_fatigue": "fatigue", 
    "systemic_weight_loss": "weight_loss",
    
    # Urinary symptoms - FIXED MAPPINGS
    "burning_urination_present": "burning_micturition",
    "urinary_pain_present": "burning_micturition", 
    "frequent_urination_present": "continuous_feel_of_urine",
    "urinating_large_amounts": "polyuria",
    "lower_abdominal_pain_present": "abdominal_pain",
    "bladder_pain_present": "bladder_discomfort",
    "burning_urination_persistent": "burning_micturition",
    "frequent_urination_persistent": "continuous_feel_of_urine",
    # Additional urinary mappings for new questions
    "painful_urination": "burning_micturition",
    "frequent_urination": "continuous_feel_of_urine", 
    "blood_in_urine": "blood_in_sputum",  # Closest available
    "lower_abdominal_pain": "abdominal_pain",
    "incomplete_emptying": "continuous_feel_of_urine",
}

def map_symptoms_to_features(symptoms_dict):
    """
    Convert questionnaire symptoms to model features.
    
    Args:
        symptoms_dict: Dict with questionnaire symptom names as keys
    
    Returns:
        Dict with model feature names as keys
    """
    features = {}
    
    for symptom_name, value in symptoms_dict.items():
        feature_name = SYMPTOM_TO_FEATURE_MAP.get(symptom_name)
        if feature_name:
            features[feature_name] = value
        else:
            print(f"WARNING: No mapping found for symptom '{symptom_name}'")
    
    return features