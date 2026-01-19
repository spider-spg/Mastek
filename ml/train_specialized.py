import os
import joblib
import pandas as pd
import numpy as np

from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score


# Disease categories by body part
DISEASE_CATEGORIES = {
    "chest": [
        "Asthma", "Pneumonia", "Myocardial Infarction", "Hypertensive Heart Disease"
    ],
    "skin": [
        "Fungal infection", "Acne", "Psoriasis", "Impetigo", "Drug Reaction", "Allergy"
    ],
    "ent": [
        "Common Cold", "Allergy", "Migraine"  # ENT + some overlap
    ],
    "abdomen": [
        "Gastroenteritis", "Peptic ulcer diseae", "GERD", "Chronic cholestasis", 
        "Hepatitis A", "Hepatitis B", "Hepatitis C", "Hepatitis D", "Hepatitis E"
    ],
    "systemic": [
        "Diabetes", "Hypertension", "Hyperthyroidism", "Hypothyroidism",
        "Malaria", "Dengue", "Typhoid", "Tuberculosis", "AIDS"
    ],
    "urinary": [
        "Urinary tract infection", "Diabetes"  # Add Diabetes since polyuria is a symptom
    ],
    "neuro": [
        "Migraine", "(vertigo) Paroymsal  Positional Vertigo", "Paralysis (brain hemorrhage)",
        "Cervical spondylosis"
    ]
}

# Relevant symptoms by body part
SYMPTOM_CATEGORIES = {
    "chest": [
        "chest_pain", "breathlessness", "cough", "wheezing", "fast_heart_rate",
        "palpitations", "sweating", "fatigue", "weakness_in_limbs"
    ],
    "skin": [
        "itching", "skin_rash", "nodal_skin_eruptions", "pus_filled_pimples", 
        "blackheads", "scurring", "skin_peeling", "silver_like_dusting", 
        "small_dents_in_nails", "inflammatory_nails", "blister", "red_sore_around_nose"
    ],
    "ent": [
        "throat_irritation", "runny_nose", "continuous_sneezing", "sinus_pressure",
        "congestion", "headache", "watering_from_eyes", "redness_of_eyes"
    ],
    "abdomen": [
        "stomach_pain", "abdominal_pain", "nausea", "vomiting", "diarrhoea",
        "constipation", "acidity", "indigestion", "loss_of_appetite", 
        "yellowish_skin", "dark_urine", "yellowing_of_eyes"
    ],
    "systemic": [
        "high_fever", "fatigue", "weight_loss", "weight_gain", "excessive_hunger",
        "polyuria", "sweating", "chills", "dehydration", "malaise"
    ],
    "urinary": [
        "burning_micturition", "continuous_feel_of_urine", "bladder_discomfort",
        "foul_smell_of urine", "spotting_ urination", "passage_of_gases",
        "polyuria", "abdominal_pain"  # Add abdominal pain for lower abdomen symptoms
    ],
    "neuro": [
        "headache", "dizziness", "neck_pain", "blurred_and_distorted_vision",
        "weakness_of_one_body_side", "loss_of_balance", "unsteadiness",
        "spinning_movements", "stiff_neck"
    ]
}


def train_specialized_model(category, diseases, symptoms, df):
    """Train a specialized model for a specific body part category."""
    
    print(f"\n=== Training {category.upper()} Model ===")
    
    # Filter data for this category's diseases
    category_df = df[df['prognosis'].isin(diseases)]
    
    if len(category_df) == 0:
        print(f"No data found for {category} diseases: {diseases}")
        return None
        
    print(f"Found {len(category_df)} samples for {len(diseases)} diseases")
    
    # Select relevant symptoms (features)
    available_symptoms = [s for s in symptoms if s in df.columns]
    if len(available_symptoms) == 0:
        print(f"No matching symptoms found for {category}")
        return None
        
    print(f"Using {len(available_symptoms)} relevant symptoms: {available_symptoms[:5]}...")
    
    # Prepare data
    X = category_df[available_symptoms]
    y = category_df['prognosis']
    
    # Handle classes with too few samples
    class_counts = y.value_counts()
    valid_classes = class_counts[class_counts >= 2].index
    mask = y.isin(valid_classes)
    X = X[mask]
    y = y[mask]
    
    if len(y.unique()) < 2:
        print(f"Not enough disease classes for {category}")
        return None
    
    # Encode labels
    le = LabelEncoder()
    y_enc = le.fit_transform(y)
    
    # Split data
    X_train, X_val, y_train, y_val = train_test_split(
        X, y_enc, test_size=0.2, random_state=42, stratify=y_enc
    )
    
    # Train model with anti-overfitting settings
    model = RandomForestClassifier(
        n_estimators=100,  # Reduced from 300
        max_depth=8,       # Reduced from 15  
        min_samples_split=5,  # Increased from 3
        min_samples_leaf=3,   # Increased from 1 - CRITICAL FIX
        max_features='sqrt',  # Add feature randomness
        class_weight="balanced",
        random_state=42,
        n_jobs=-1
    )
    
    model.fit(X_train, y_train)
    
    # Validate
    preds = model.predict(X_val)
    acc = accuracy_score(y_val, preds)
    print(f"Validation Accuracy: {acc:.3f}")
    
    # Check confidence
    probs = model.predict_proba(X_val)
    max_probs = probs.max(axis=1)
    print(f"Mean confidence: {max_probs.mean():.3f}")
    print(f"High confidence (>0.5): {(max_probs > 0.5).sum()}/{len(max_probs)}")
    
    return {
        'model': model,
        'label_encoder': le,
        'feature_order': available_symptoms,
        'diseases': list(le.classes_),
        'category': category
    }


def main():
    # Load dataset
    df = pd.read_csv("data/training.csv")
    print(f"Loaded {len(df)} samples with {len(df['prognosis'].unique())} diseases")
    
    # Create artifacts directory
    artifact_dir = "scorer/specialized_artifacts"
    os.makedirs(artifact_dir, exist_ok=True)
    
    # Train specialized models
    results = {}
    
    for category in DISEASE_CATEGORIES:
        diseases = DISEASE_CATEGORIES[category]
        symptoms = SYMPTOM_CATEGORIES[category]
        
        result = train_specialized_model(category, diseases, symptoms, df)
        
        if result:
            results[category] = result
            
            # Save artifacts
            model_path = os.path.join(artifact_dir, f"{category}_model.pkl")
            encoder_path = os.path.join(artifact_dir, f"{category}_label_encoder.pkl") 
            features_path = os.path.join(artifact_dir, f"{category}_feature_order.pkl")
            
            joblib.dump(result['model'], model_path)
            joblib.dump(result['label_encoder'], encoder_path)
            joblib.dump(result['feature_order'], features_path)
            
            print(f"Saved {category} model artifacts")
    
    print(f"\n=== Summary ===")
    print(f"Successfully trained {len(results)} specialized models:")
    for category, result in results.items():
        print(f"  {category}: {len(result['diseases'])} diseases, {len(result['feature_order'])} symptoms")


if __name__ == "__main__":
    main()