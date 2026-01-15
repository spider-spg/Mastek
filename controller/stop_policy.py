# controller/stop_policy.py

CONF_THRESHOLD = 0.75
RANK_STABLE_LIMIT = 2
MIN_CONF_FOR_RANK_STOP = 0.6


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
