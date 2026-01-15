import numpy as np
from data.disease_index import DISEASE_INDEX, NUM_DISEASES
from data.disease_aliases import DISEASE_ALIASES


def build_soft_labels(rule_scores: dict, temperature: float = 2.0):
    y = np.zeros(NUM_DISEASES, dtype=np.float32)

    diseases = []
    scores = []

    for raw_disease, score in rule_scores.items():
        if raw_disease not in DISEASE_ALIASES:
            continue

        disease = DISEASE_ALIASES[raw_disease]

        if disease not in DISEASE_INDEX:
            continue

        diseases.append(disease)
        scores.append(float(score))

    if not diseases:
        raise ValueError(
            f"No dataset-mappable diseases in rule_scores: {rule_scores}"
        )

    scores = np.asarray(scores, dtype=np.float32)
    scores -= scores.max()

    probs = np.exp(scores / temperature)
    probs /= probs.sum()

    for disease, prob in zip(diseases, probs):
        y[DISEASE_INDEX[disease]] = prob

    return y
