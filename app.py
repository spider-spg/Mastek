# Main entry point for Symptomate application (API / UI hook)
# app.py
# Minimal interactive test for end-to-end flow

from controller.flow_controller import run_flow
from scorer.predict_specialized import predict_specialized
from controller.confidence import normalize_confidence
from controller.demo_output import demo_decision

def main():
    print("\n=== Symptomate Interactive Test ===\n")

    print("Answer questions with: yes / no / unsure\n")

    # Run the rule + phase logic
    state = run_flow()

    # Final ML inference (called ONCE)
    body_part = state.get("body_part")
    if not body_part:
        print("❌ No body part specified.")
        return
        
    raw = predict_specialized(state.get("symptoms", {}), body_part)
    
    # Debug: Check raw probabilities before confidence normalization
    top_raw = sorted(raw.items(), key=lambda x: x[1], reverse=True)[:5]
    print("DEBUG: Top 5 raw probabilities from specialized model:")
    for disease, prob in top_raw:
        print(f"  {disease}: {prob:.3f}")
    
    confidence = normalize_confidence(raw)

    result = demo_decision(confidence)

    print("\n=== Final Output ===")
    
    # Check if this is an uncertain prediction (all symptoms were "unsure")
    if result["mode"] == "prediction" and "Cannot determine" in result["top1"]:
        print("❓ Cannot make a reliable prediction")
        print("Reason: All symptoms marked as 'unsure' - insufficient information")
        print("Recommendation: Please consult a healthcare provider for proper diagnosis")
    elif result["mode"] == "prediction":
        print(f"Prediction: {result['top1']}")
        print(f"Confidence: {result['confidence']:.2f}")
    else:
        print("Low confidence — showing best matches")

    print("\nTop-3:")
    for d, c in result["topk"]:
        print(f"  {d}: {c:.2f}")

    print("\n=== Session End ===\n")


if __name__ == "__main__":
    main()
