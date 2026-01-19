#!/usr/bin/env python3
"""Test the improved chest prediction"""

import sys
sys.path.append('.')

def test_chest_symptoms():
    """Test chest symptoms that were incorrectly predicting heart attack"""
    
    print("Testing chest symptoms...")
    
    from scorer.predict_specialized import predict_specialized
    
    # The symptoms from the user's test: chest pain=yes, breathing=yes, wheezing=yes
    symptoms_dict = {
        'chest_pain_present': 1.0,           # yes - chest pain
        'breathing_difficulty_present': 1.0,  # yes - breathing difficulty  
        'wheezing_present': 1.0,             # yes - wheezing
        'cough_present': -1.0,               # no - cough
        'chest_pain_exertional': 1.0,        # yes - exertional chest pain
        'smoking_frequency': -1.0,           # no - smoking
    }
    
    print(f"Input symptoms: {symptoms_dict}")
    
    # Test the chest prediction
    result = predict_specialized(symptoms_dict, 'chest')
    
    print(f"\nPrediction results: {result}")
    
    if result:
        sorted_diseases = sorted(result.items(), key=lambda x: x[1], reverse=True)
        print("\nTop predictions:")
        for disease, prob in sorted_diseases[:5]:
            print(f"  {disease}: {prob:.3f}")
            
        top_disease = sorted_diseases[0][0]
        if "Asthma" in top_disease or "asthma" in top_disease.lower():
            print(f"\n✅ IMPROVED: Top prediction is '{top_disease}' (more appropriate for wheezing + breathing difficulty)")
        elif "Heart attack" in top_disease:
            print(f"\n⚠️  STILL ISSUE: Predicting '{top_disease}' for respiratory symptoms")
        else:
            print(f"\n✅ REASONABLE: Predicting '{top_disease}'")

if __name__ == "__main__":
    test_chest_symptoms()