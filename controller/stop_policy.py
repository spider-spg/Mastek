# controller/stop_policy.py

CONF_THRESHOLD = 0.8
RANK_STABLE_LIMIT = 2
MIN_CONF_FOR_RANK_STOP = 0.6
MIN_AMBIGUITY_GAP = 0.15  # If top 2 diseases are within 15%, continue asking


def should_stop(state):
    """
    Determines whether Phase-2 questioning should stop.
    Returns: CONTINUE | STOP | ESCALATE
    """

    # Hard safety stop
    if state.get("red_flag"):
        return "ESCALATE"

    # Max questions reached
    if state["questions_asked"] >= state["max_questions"]:
        return "STOP"

    # Check for diagnostic ambiguity - continue if top diseases are close
    if has_diagnostic_ambiguity(state):
        return "CONTINUE"

    # High confidence achieved (minimum evidence)
    if (
        state.get("top_confidence", 0.0) >= CONF_THRESHOLD
        and state.get("phase2_questions_asked", 0) >= 1
    ):
        return "STOP"

    # Rank stability only matters if confidence is non-trivial
    if (
        state.get("rank_stable_for", 0) >= RANK_STABLE_LIMIT
        and state.get("top_confidence", 0.0) >= MIN_CONF_FOR_RANK_STOP
    ):
        return "STOP"

    return "CONTINUE"


def has_diagnostic_ambiguity(state):
    """
    Check if there's ambiguity between top diseases that warrants more questions.
    Returns True if top 2 diseases have similar probabilities.
    """
    confidence_dict = state.get("current_confidence", {})
    if len(confidence_dict) < 2:
        return False
    
    # Get top 2 diseases
    sorted_diseases = sorted(confidence_dict.items(), key=lambda x: x[1], reverse=True)
    top1_prob = sorted_diseases[0][1]
    top2_prob = sorted_diseases[1][1]
    
    # If both are reasonably confident and close, there's ambiguity
    if top1_prob > 0.2 and top2_prob > 0.2:  # Both have reasonable confidence
        gap = top1_prob - top2_prob
        if gap < MIN_AMBIGUITY_GAP:  # Close probabilities = ambiguity
            print(f"DEBUG: Diagnostic ambiguity detected - {sorted_diseases[0][0]}: {top1_prob:.3f} vs {sorted_diseases[1][0]}: {top2_prob:.3f} (gap: {gap:.3f})")
            return True
    
    return False


def demo_decision(confidence_dict, k=3):
    topk = sorted(confidence_dict.items(), key=lambda x: x[1], reverse=True)[:k]
    top1_disease, top1_conf = topk[0]

    if top1_conf < 0.25:
        return {
            "mode": "suggestion",
            "topk": topk,        # show Top-3
            "note": "Low confidence — showing best matches"
        }

    return {
        "mode": "prediction",
        "top1": top1_disease,
        "confidence": top1_conf,
        "topk": topk
    }
