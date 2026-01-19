# controller/question_selector.py
# ❗MOVE import INSIDE function to avoid circular dependency

def select_phase2_question(
    state: dict,
    current_confidence: float,
    phase2_candidates: list,
    asked_symptoms: set,
    predict_fn,
    feature_order: list,
):
    # Import specialized predictor to avoid circular dependency
    from scorer.predict_specialized import predict_specialized
    from controller.confidence import normalize_confidence

    best_gain = 0.0
    best_candidate = None

    for q in phase2_candidates:
        symptom = q["maps_to"]

        if symptom in asked_symptoms:
            continue

        # Simulate "yes" answer
        sim_symptoms_yes = dict(state["symptoms"])
        sim_symptoms_yes[symptom] = 1.0
        
        probs_yes = predict_specialized(sim_symptoms_yes, state["body_part"])
        conf_yes = normalize_confidence(probs_yes)
        top_conf_yes = max(conf_yes.values()) if conf_yes else 0.0

        # Simulate "no" answer  
        sim_symptoms_no = dict(state["symptoms"])
        sim_symptoms_no[symptom] = -1.0
        
        probs_no = predict_specialized(sim_symptoms_no, state["body_part"])
        conf_no = normalize_confidence(probs_no)
        top_conf_no = max(conf_no.values()) if conf_no else 0.0

        # Calculate information gain (best case scenario)
        gain = max(top_conf_yes, top_conf_no) - current_confidence
        
        print(f"DEBUG: Question '{q['text'][:50]}...' - gain: {gain:.3f}")
        
        if gain > best_gain:
            best_gain = gain
            best_candidate = q

    if best_candidate is None or best_gain <= 0:
        return None

    return best_candidate
