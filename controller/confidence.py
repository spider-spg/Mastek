# controller/confidence.py
import math


def normalize_confidence(scores: dict) -> dict:
    """
    Converts raw disease scores into a normalized confidence distribution
    using a numerically stable softmax.
    """

    if not scores:
        return {}

    # Numerical stability: subtract max
    max_score = max(scores.values())
    exp_scores = {
        d: math.exp(v - max_score)
        for d, v in scores.items()
    }

    total = sum(exp_scores.values())
    if total == 0:
        # fallback to uniform distribution
        n = len(scores)
        return {d: 1.0 / n for d in scores}

    return {d: v / total for d, v in exp_scores.items()}


def get_top_k(confidence: dict, k: int = 3):
    """
    Returns top-k diseases sorted by confidence.
    """
    if not confidence:
        return []

    return sorted(
        confidence.items(),
        key=lambda x: x[1],
        reverse=True
    )[:k]
