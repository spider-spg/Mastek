#!/usr/bin/env python3
"""Direct test of uncertain handling in the full pipeline"""

import sys
import os
sys.path.append('.')

from controller.flow_controller import run_flow
from controller.confidence import normalize_confidence
from controller.demo_output import demo_decision

def test_uncertain_pipeline():
    """Test the full pipeline when returning uncertain predictions"""
    
    # Direct test of our uncertain prediction
    from scorer.predict_specialized import predict_specialized
    
    print("=== Testing Uncertain Prediction Pipeline ===\n")
    
    # All symptoms uncertain (0.0)
    symptoms_dict = {
        'chest_pain_present': 0.0,
        'breathing_difficulty_present': 0.0,
        'wheezing_present': 0.0,
        'cough_present': 0.0
    }
    
    print("1. Testing predict_specialized with all uncertain symptoms:")
    raw_prediction = predict_specialized(symptoms_dict, 'chest')
    print(f"   Raw prediction: {raw_prediction}")
    
    print("\n2. Testing confidence normalization:")
    normalized_confidence = normalize_confidence(raw_prediction) 
    print(f"   Normalized confidence: {normalized_confidence}")
    
    print("\n3. Testing demo_decision:")
    result = demo_decision(normalized_confidence)
    print(f"   Demo decision result: {result}")
    
    print("\n4. Testing final output message:")
    if result["mode"] == "prediction" and "Cannot determine" in result["top1"]:
        print("   ✅ SUCCESS: Will show 'Cannot make a reliable prediction' message")
    else:
        print("   ❌ ISSUE: Will not show uncertain message")
        print(f"      Mode: {result['mode']}, Top1: {result['top1']}")

if __name__ == "__main__":
    test_uncertain_pipeline()