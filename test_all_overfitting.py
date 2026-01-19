#!/usr/bin/env python3
"""Test if overfitting is fixed across all body parts"""

import sys
sys.path.append('.')

def test_all_body_parts():
    """Test prediction behavior across different body parts"""
    
    from scorer.predict_specialized import predict_specialized
    
    test_cases = [
        {
            "body_part": "skin", 
            "symptoms": {
                'skin_rash_present': 1.0,
                'itching_present': 1.0,
            },
            "description": "skin rash + itching"
        },
        {
            "body_part": "ent",
            "symptoms": {
                'sore_throat_present': 1.0,
                'runny_nose_present': 1.0,
            },
            "description": "sore throat + runny nose"
        },
        {
            "body_part": "abdomen",
            "symptoms": {
                'abdominal_pain_present': 1.0,
                'nausea_present': 1.0,
            },
            "description": "abdominal pain + nausea"
        },
        {
            "body_part": "systemic",
            "symptoms": {
                'systemic_fever': 1.0,
                'systemic_fatigue': 1.0,
            },
            "description": "fever + fatigue"
        }
    ]
    
    print("Testing overfitting across body parts...\n")
    
    for case in test_cases:
        print(f"=== {case['body_part'].upper()} ===")
        print(f"Symptoms: {case['description']}")
        
        result = predict_specialized(case['symptoms'], case['body_part'])
        
        if result:
            sorted_diseases = sorted(result.items(), key=lambda x: x[1], reverse=True)
            
            # Check if we have the old overfitting pattern (1.0, 0.0, 0.0...)
            top_prob = sorted_diseases[0][1]
            has_overfitting = (top_prob >= 0.99 and len(sorted_diseases) > 1 and sorted_diseases[1][1] <= 0.01)
            
            print(f"Top prediction: {sorted_diseases[0][0]} ({top_prob:.3f})")
            if len(sorted_diseases) > 1:
                print(f"2nd prediction: {sorted_diseases[1][0]} ({sorted_diseases[1][1]:.3f})")
            
            if has_overfitting:
                print("❌ OVERFITTING: Still showing 1.0/0.0 pattern")
            else:
                print("✅ IMPROVED: More reasonable probability distribution")
        else:
            print("❌ No prediction returned")
            
        print()

if __name__ == "__main__":
    test_all_body_parts()