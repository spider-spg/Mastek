# import pandas as pd

# from controller.scorer import update_scores
# from controller.confidence import normalize_confidence
# from controller.diagnostics import DISEASES, PHASE2_DIAGNOSTICS


# INPUT_PATH = "data/training.csv"
# OUTPUT_PATH = "data/training_with_rules.csv"


# def enrich_row(row):
#     state = {
#         "scores": {d: 0 for d in DISEASES},
#         "diagnostics": PHASE2_DIAGNOSTICS,
#         "rank_stable_for": 0,
#         "prev_top_disease": None
#     }

#     questions_asked = 0

#     for symptom, value in row.items():
#         if symptom in PHASE2_DIAGNOSTICS:
#             if value == 1:
#                 update_scores(state, symptom, "yes")
#                 questions_asked += 1
#             elif value == 0:
#                 update_scores(state, symptom, "no")
#                 questions_asked += 1

#     confidence = normalize_confidence(state["scores"])

#     engineered = {}
#     for d in DISEASES:
#         engineered[f"{d}_score"] = state["scores"][d]

#     engineered["phase2_confidence"] = max(confidence.values())
#     engineered["questions_asked"] = questions_asked

#     return engineered


# def main():
#     df = pd.read_csv(INPUT_PATH)

#     enriched_rows = df.apply(enrich_row, axis=1, result_type="expand")

#     final_df = pd.concat([df, enriched_rows], axis=1)

#     final_df.to_csv(OUTPUT_PATH, index=False)
#     print("Saved:", OUTPUT_PATH)


# if __name__ == "__main__":
#     main()



# data/build_ml_dataset.py

import numpy as np
from data.soft_labels import build_soft_labels


def build_dataset(
    conversations,
    temperature: float = 2.0
):
    """
    Builds ML-ready dataset from conversations.

    Each conversation must contain:
      - "features": list[float]
      - "rule_scores": dict[str, float]

    Returns:
      X: np.ndarray (N, num_features)
      y: np.ndarray (N, NUM_DISEASES)
    """

    X_list = []
    y_list = []

    for convo in conversations:
        if "features" not in convo or "rule_scores" not in convo:
            raise KeyError("Conversation missing required keys")

        X = np.asarray(convo["features"], dtype=np.float32)
        y = build_soft_labels(convo["rule_scores"], temperature)

        X_list.append(X)
        y_list.append(y)

    if not X_list:
        raise ValueError("No conversations provided")

    X = np.vstack(X_list)
    y = np.vstack(y_list)

    return X, y
