import os
import joblib
import numpy as np
from data.symptom_mapping import map_symptoms_to_features

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
SPECIALIZED_DIR = os.path.join(BASE_DIR, "scorer", "specialized_artifacts")

# Mapping from body parts to model categories
BODY_PART_TO_CATEGORY = {
    "chest": "chest",
    "skin": "skin", 
    "ent": "ent",
    "abdomen": "abdomen",
    "systemic_flags": "systemic",
    "urinary": "urinary",  # Use dedicated urinary model
    "head_neuro": "neuro"
}

# Cache for loaded models
_model_cache = {}

def load_specialized_model(category):
    """Load a specialized model and its artifacts."""
    if category in _model_cache:
        return _model_cache[category]
    
    try:
        model_path = os.path.join(SPECIALIZED_DIR, f"{category}_model.pkl")
        encoder_path = os.path.join(SPECIALIZED_DIR, f"{category}_label_encoder.pkl")
        features_path = os.path.join(SPECIALIZED_DIR, f"{category}_feature_order.pkl")
        
        model = joblib.load(model_path)
        label_encoder = joblib.load(encoder_path)
        feature_order = joblib.load(features_path)
        
        artifacts = {
            'model': model,
            'label_encoder': label_encoder,
            'feature_order': feature_order,
            'diseases': list(label_encoder.classes_)
        }
        
        _model_cache[category] = artifacts
        return artifacts
        
    except FileNotFoundError:
        print(f"Warning: Specialized model for {category} not found, falling back to abdomen model for urinary symptoms")
        # Fallback to abdomen model for urinary symptoms
        if category == "urinary":
            return load_specialized_model("abdomen")
        return None

def predict_specialized(symptoms_dict, body_part):
    """
    Predict using specialized model for the given body part.
    
    Args:
        symptoms_dict: Dict of symptom_name -> value
        body_part: Body part category (chest, skin, ent, etc.)
    
    Returns:
        dict: {disease: probability} for relevant diseases only
    """
    # Special case for urinary symptoms - simple rule-based UTI detection
    if body_part == "urinary":
        return predict_urinary_simple(symptoms_dict)
    
    # Special case for chest - use abdomen model as fallback since chest model failed to train
    if body_part == "chest":
        return predict_chest_fallback(symptoms_dict)
    
    # Check if all symptoms are uncertain (0.0) - should return low confidence
    mapped_features = map_symptoms_to_features(symptoms_dict)
    non_zero_features = [f for f, v in mapped_features.items() if v != 0.0]
    
    if len(non_zero_features) == 0:
        print("DEBUG: All symptoms uncertain - returning low confidence prediction")
        return generate_uncertain_prediction(body_part)
    
    category = BODY_PART_TO_CATEGORY.get(body_part)
    if not category:
        print(f"Warning: No specialized model category for body_part '{body_part}'")
        return {}
    
    artifacts = load_specialized_model(category)
    if not artifacts:
        return {}
    
    # Build feature vector for this specialized model
    feature_vector = [
        mapped_features.get(feature, 0.0) 
        for feature in artifacts['feature_order']
    ]
    
    # Debug: Show non-zero features
    non_zero = [(f, v) for f, v in zip(artifacts['feature_order'], feature_vector) if v != 0]
    print(f"DEBUG: Using {category} model with {len(non_zero)} non-zero features: {[f for f,v in non_zero]}")
    
    # Predict
    X = np.array(feature_vector, dtype=float).reshape(1, -1)
    probs = artifacts['model'].predict_proba(X)[0]
    
    # Return disease probabilities
    results = {}
    for i, disease in enumerate(artifacts['diseases']):
        if i < len(probs):  # Safety check
            results[disease] = float(probs[i])
    
    return results
    
    category = BODY_PART_TO_CATEGORY.get(body_part)
    if not category:
        print(f"Warning: No specialized model category for body_part '{body_part}'")
        return {}
    
    artifacts = load_specialized_model(category)
    if not artifacts:
        return {}
    
    # Map questionnaire symptoms to model features
    mapped_features = map_symptoms_to_features(symptoms_dict)
    
    # Build feature vector for this specialized model
    feature_vector = [
        mapped_features.get(feature, 0.0) 
        for feature in artifacts['feature_order']
    ]
    
    # Debug: Show non-zero features
    non_zero = [(f, v) for f, v in zip(artifacts['feature_order'], feature_vector) if v != 0]
    print(f"DEBUG: Using {category} model with {len(non_zero)} non-zero features: {[f for f,v in non_zero]}")
    
    # Predict
    X = np.array(feature_vector, dtype=float).reshape(1, -1)
    probs = artifacts['model'].predict_proba(X)[0]
    
    # Return disease probabilities
    results = {}
    for i, disease in enumerate(artifacts['diseases']):
        if i < len(probs):  # Safety check
            results[disease] = float(probs[i])
    
    return results


def generate_uncertain_prediction(body_part):
    """
    Generate a response when all symptoms are uncertain (0.0).
    Returns very low confidence to indicate we can't make a reliable prediction.
    """
    return {
        "Cannot determine - insufficient information": 0.01,  # Very low confidence
        "Recommend consulting healthcare provider": 0.01
    }


def predict_chest_fallback(symptoms_dict):
    """
    Simple rule-based prediction for chest symptoms since chest model had insufficient data.
    """
    print("DEBUG: Using rule-based chest predictor (insufficient training data)")
    
    # Map questionnaire symptoms to model features
    mapped_features = map_symptoms_to_features(symptoms_dict)
    
    # Check for specific symptom patterns
    chest_pain = mapped_features.get("chest_pain", 0)
    breathlessness = mapped_features.get("breathlessness", 0) 
    cough = mapped_features.get("cough", 0)
    wheezing = mapped_features.get("wheezing", 0)
    
    print(f"DEBUG: Chest symptoms - pain: {chest_pain}, breathing: {breathlessness}, cough: {cough}, wheezing: {wheezing}")
    
    # Simple rule-based scoring
    scores = {}
    
    # Asthma indicators: wheezing + breathing difficulty + chest tightness
    if wheezing > 0 and breathlessness > 0:
        scores["Bronchial Asthma"] = 0.7
    elif breathlessness > 0 and chest_pain > 0:
        scores["Bronchial Asthma"] = 0.4
    
    # GERD indicators: chest pain without breathing issues
    if chest_pain > 0 and breathlessness <= 0 and wheezing <= 0:
        scores["GERD"] = 0.6
    elif chest_pain > 0:
        scores["GERD"] = 0.3
        
    # Pneumonia: cough + breathing difficulty + chest pain
    if cough > 0 and breathlessness > 0 and chest_pain > 0:
        scores["Pneumonia"] = 0.5
    elif cough > 0 and breathlessness > 0:
        scores["Pneumonia"] = 0.3
    
    # Heart attack: chest pain + breathing difficulty (but less likely without other symptoms)
    if chest_pain > 0 and breathlessness > 0 and wheezing <= 0:
        scores["Heart attack"] = 0.2  # Lower probability without classic symptoms
    
    # Normalize scores
    if not scores:
        return generate_uncertain_prediction("chest")
        
    total = sum(scores.values())
    if total > 1.0:
        scores = {k: v/total for k, v in scores.items()}
    
    # Fill remaining probability
    remaining = 1.0 - sum(scores.values())
    if remaining > 0:
        scores["Other chest condition"] = remaining
        
    return scores


def predict_urinary_simple(symptoms_dict):
    """
    Simple rule-based UTI detection for urinary symptoms.
    """
    print("DEBUG: Using rule-based urinary predictor")
    
    # Map questionnaire symptoms to model features
    mapped_features = map_symptoms_to_features(symptoms_dict)
    
    # Check for classic UTI symptoms
    burning = mapped_features.get("burning_micturition", 0)
    frequent = mapped_features.get("continuous_feel_of_urine", 0) 
    abdominal_pain = mapped_features.get("abdominal_pain", 0)
    
    print(f"DEBUG: UTI symptoms - burning: {burning}, frequent: {frequent}, abdominal_pain: {abdominal_pain}")
    
    # Simple scoring
    uti_score = 0.0
    if burning > 0:  # Burning urination is classic UTI
        uti_score += 0.7
    if frequent > 0:  # Frequent urination
        uti_score += 0.2
    if abdominal_pain > 0:  # Lower abdominal pain
        uti_score += 0.3
        
    # Normalize to probabilities
    if uti_score > 1.0:
        uti_score = 1.0
        
    other_score = 1.0 - uti_score
    
    return {
        "Urinary tract infection": uti_score,
        "Other urinary condition": other_score
    }

# Backward compatibility - keep the old function name for app.py
def predict_proba(feature_vector_list):
    """
    Backward compatibility function for app.py
    Note: This won't work well since it doesn't know the body part
    """
    # This is a fallback - won't work well without body part context
    print("Warning: Using old predict_proba without body part specialization")
    return {"Unknown": 0.5}  # Placeholder