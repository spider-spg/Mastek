#!/usr/bin/env python3
"""Simulate a full session with all unsure responses"""

import sys
sys.path.append('.')

from controller.flow_controller import run_flow

def simulate_all_unsure_session():
    """Simulate answering all questions with 'unsure'"""
    
    print("=== Testing All-Unsure Session ===\n")
    
    # Mock the input function to always return 'unsure'
    original_input = __builtins__.input
    
    responses = ['chest'] + ['unsure'] * 20  # Body part + lots of 'unsure' responses
    response_iter = iter(responses)
    
    def mock_input(prompt):
        try:
            response = next(response_iter)
            print(f"{prompt}{response}")
            return response
        except StopIteration:
            return 'unsure'
    
    # Replace input temporarily
    __builtins__.input = mock_input
    
    try:
        # Run the flow
        run_flow()
    finally:
        # Restore original input
        __builtins__.input = original_input

if __name__ == "__main__":
    simulate_all_unsure_session()