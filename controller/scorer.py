# controller/scorer.py

ANSWER_MAP = {
    "yes": 1.0,
    "no": 0.0,
    "not_sure": 0.0
}

MAX_SCORE = 10.0
MIN_DELTA_FOR_STABILITY = 0.05


def update_scores(state, question_id, answer):
    """
    Updates disease scores using diagnostic weights.
    Maintains rank stability signal.
    """

    diagnostics = state["diagnostics"]   # phase-2 diagnostic weights
    scores = state["scores"]

    if question_id not in diagnostics:
        return

    delta_applied = False
    total_delta = 0.0

    answer_value = ANSWER_MAP.get(answer, 0.0)

    for disease, weight in diagnostics[question_id].items():
        delta = weight * answer_value
        if delta != 0:
            scores[disease] += delta
            total_delta += abs(delta)

            # Clamp scores to avoid runaway dominance
            scores[disease] = max(
                min(scores[disease], MAX_SCORE),
                -MAX_SCORE
            )

            delta_applied = True

    # Rank stability logic (only if meaningful update)
    prev_top = state.get("prev_top_disease")
    curr_top = max(scores, key=scores.get)

    if (
        prev_top == curr_top
        and delta_applied
        and total_delta >= MIN_DELTA_FOR_STABILITY
    ):
        state["rank_stable_for"] += 1
    else:
        state["rank_stable_for"] = 0

    state["prev_top_disease"] = curr_top
