# controller/candidate_gating.py

from controller.diagnostics import PHASE2_DIAGNOSTICS


def gate_diseases(
    symptoms: dict,
    body_part: str,
    min_rule_score: float = 0.2
):
    """
    Returns a SET of candidate diseases allowed for ML ranking.
    """

    disease_scores = {}

    for symptom, value in symptoms.items():
        if value != 1.0:
            continue

        if symptom not in PHASE2_DIAGNOSTICS:
            continue

        for disease, weight in PHASE2_DIAGNOSTICS[symptom].items():
            disease_scores[disease] = disease_scores.get(disease, 0.0) + weight

    # --- hard gate ---
    candidates = {
        d for d, score in disease_scores.items()
        if score >= min_rule_score
    }

    # fallback: if nothing passes, allow weak ones
    if not candidates:
        candidates = set(disease_scores.keys())

    return candidates
