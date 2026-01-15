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
    from controller.simulation import simulate_confidence  # ✅ lazy import

    best_gain = 0.0
    best_candidate = None

    for q in phase2_candidates:
        symptom = q["maps_to"]

        if symptom in asked_symptoms:
            continue

        conf_yes = simulate_confidence(
            state, symptom, 1.0, predict_fn, feature_order
        )
        conf_no = simulate_confidence(
            state, symptom, 0.0, predict_fn, feature_order
        )

        expected_conf = 0.5 * conf_yes + 0.5 * conf_no
        gain = expected_conf - current_confidence

        if gain > best_gain:
            best_gain = gain
            best_candidate = q

    if best_candidate is None or best_gain <= 0:
        return None

    return best_candidate
