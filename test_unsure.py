#!/usr/bin/env python3
"""Test what happens when all symptoms are unsure"""

import sys
sys.path.append('.')

def test_all_unsure():
    """Test the system when all symptoms are marked as 'unsure'"""
    
    print("Testing all 'unsure' responses...")
    
    from scorer.predict_specialized import predict_specialized
    
    # Simulate all chest symptoms as "unsure" (0.0)
    symptoms_dict = {
        'chest_pain_present': 0.0,           # unsure
        'breathing_difficulty_present': 0.0,  # unsure
        'wheezing_present': 0.0,             # unsure
        'cough_present': 0.0,                # unsure
        'cough_duration': 0.0,               # unsure
        'chest_pain_exertional': 0.0,        # unsure
        'smoking_frequency': 0.0,            # unsure (answered no, but this tests the point)
    }
    
    print(f"Input symptoms (all unsure/0.0): {symptoms_dict}")
    
    # Test the chest prediction
    result = predict_specialized(symptoms_dict, 'chest')
    
    print(f"\nPrediction results: {result}")
    
    if result:
        sorted_diseases = sorted(result.items(), key=lambda x: x[1], reverse=True)
        print("\nTop predictions:")
        for disease, prob in sorted_diseases[:3]:
            print(f"  {disease}: {prob:.3f}")
            
        top_disease = sorted_diseases[0][0]
        if "Cannot determine" in top_disease:
            print("\n✅ SUCCESS: System correctly identifies it cannot make a prediction")
        else:
            print(f"\n❌ ISSUE: System still predicting '{top_disease}' when all symptoms are unsure")

if __name__ == "__main__":
    test_all_unsure()