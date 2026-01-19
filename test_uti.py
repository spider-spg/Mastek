#!/usr/bin/env python3
"""Test UTI symptom prediction directly"""

import sys
import os

# Add current directory to path for imports
sys.path.append('.')

def test_uti_symptoms():
    """Test the UTI symptoms that were predicting AIDS"""
    
    print("Testing UTI symptoms...")
    
    # Test the urinary prediction directly
    from scorer.predict_specialized import predict_specialized
    
    # Use the actual questionnaire symptom names
    symptoms_dict = {
        'burning_urination_present': 1.0,      # Maps to burning_micturition
        'frequent_urination_present': 1.0,     # Maps to continuous_feel_of_urine
        'lower_abdominal_pain_present': 1.0,   # Maps to abdominal_pain
    }
    
    print(f"Input symptoms: {symptoms_dict}")
    
    # Test the urinary prediction
    result = predict_specialized(symptoms_dict, 'urinary')
    
    print(f"\nPrediction results: {result}")
    
    # Show the top predictions
    if result:
        sorted_diseases = sorted(result.items(), key=lambda x: x[1], reverse=True)
        print("\nTop predictions:")
        for disease, prob in sorted_diseases[:5]:
            print(f"  {disease}: {prob:.1%}")
            
        # Check if UTI is the top prediction
        top_disease = sorted_diseases[0][0]
        if "urinary tract infection" in top_disease.lower():
            print("\n✅ SUCCESS: UTI correctly predicted for burning urination + frequent urination + lower abdominal pain")
        else:
            print(f"\n❌ ISSUE: Top prediction is '{top_disease}', not UTI")

if __name__ == "__main__":
    test_uti_symptoms()