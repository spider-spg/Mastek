import random
import json
import numpy as np
from collections import defaultdict

from data.disease_symptom_map import DISEASE_SYMPTOMS
from data.symptom_vocab import build_symptom_vocab


# ================= CONFIG =================
SAMPLES_PER_DISEASE = 200
CORE_PROB = 0.9
SECONDARY_PROB = 0.6
DISTRACTOR_PROB = 0.05
MAX_DISTRACTORS = 2

OUTPUT_PATH = "data/output/training.npz"
PHASE1_PATH = "question_flows/phase1_flows.json"
# =========================================


# ---------- Load Phase-1 body-part mapping ----------
with open(PHASE1_PATH, "r") as f:
    PHASE1_FLOWS = json.load(f)

SYMPTOM_TO_BODY_PART = {}
for body_part, questions in PHASE1_FLOWS.items():
    for q in questions:
        if isinstance(q, dict) and "maps_to" in q:
            SYMPTOM_TO_BODY_PART[q["maps_to"]] = body_part


# ---------- Build vocab ----------
FEATURE_ORDER = build_symptom_vocab()
SYMPTOM_INDEX = {s: i for i, s in enumerate(FEATURE_ORDER)}

DISEASES = list(DISEASE_SYMPTOMS.keys())


# ---------- Infer disease → body part ----------
DISEASE_TO_BODY_PART = {}

for disease, spec in DISEASE_SYMPTOMS.items():
    votes = []

    # 1️⃣ Phase-1 mapping (preferred)
    for s in spec["core"]:
        if s in SYMPTOM_TO_BODY_PART:
            votes.append(SYMPTOM_TO_BODY_PART[s])

    # 2️⃣ Majority vote if possible
    if votes:
        DISEASE_TO_BODY_PART[disease] = max(set(votes), key=votes.count)
        continue

    # 3️⃣ Heuristic fallback (safe + realistic)
    if disease.lower() in {
        "fungal infection", "acne", "psoriasis", "impetigo"
    }:
        DISEASE_TO_BODY_PART[disease] = "skin"
        continue

    # 4️⃣ Absolute fallback (should be rare)
    DISEASE_TO_BODY_PART[disease] = "general"



# ---------- Body-part → symptoms ----------
BODY_PART_SYMPTOMS = defaultdict(set)
for disease, spec in DISEASE_SYMPTOMS.items():
    bp = DISEASE_TO_BODY_PART[disease]
    for group in ("core", "secondary"):
        for s in spec.get(group, []):
            BODY_PART_SYMPTOMS[bp].add(s)


# ---------- Sampling ----------
def sample_case(disease):
    spec = DISEASE_SYMPTOMS[disease]
    body_part = DISEASE_TO_BODY_PART[disease]

    x = np.zeros(len(FEATURE_ORDER), dtype=np.float32)

    # 1️⃣ core symptoms
    for s in spec["core"]:
        if s in SYMPTOM_INDEX and random.random() < CORE_PROB:
            x[SYMPTOM_INDEX[s]] = 1.0

    # 2️⃣ secondary symptoms
    for s in spec.get("secondary", []):
        if s in SYMPTOM_INDEX and random.random() < SECONDARY_PROB:
            x[SYMPTOM_INDEX[s]] = 1.0

    # 3️⃣ distractors (same body part only)
    pool = [
        s for s in BODY_PART_SYMPTOMS[body_part]
        if s in SYMPTOM_INDEX and s not in spec["core"]
    ]
    random.shuffle(pool)

    for s in pool[:MAX_DISTRACTORS]:
        if random.random() < DISTRACTOR_PROB:
            x[SYMPTOM_INDEX[s]] = 1.0

    # 4️⃣ HARD MASK other body parts (GUARDED)
    for other_bp, symptoms in BODY_PART_SYMPTOMS.items():
        if other_bp != body_part:
            for s in symptoms:
                if s in SYMPTOM_INDEX:
                    x[SYMPTOM_INDEX[s]] = 0.0

    return x



# ---------- Main ----------
def main():
    X, y = [], []

    for disease_idx, disease in enumerate(DISEASES):
        for _ in range(SAMPLES_PER_DISEASE):
            X.append(sample_case(disease))
            y.append(disease_idx)

    X = np.array(X, dtype=np.float32)
    y = np.array(y, dtype=np.int64)

    np.savez(
        OUTPUT_PATH,
        X=X,
        y=y,
        feature_order=np.array(FEATURE_ORDER),
        diseases=np.array(DISEASES),
    )

    print("Saved dataset:")
    print("X:", X.shape)
    print("y:", y.shape)
    print("Diseases:", len(DISEASES))
    print("Features:", len(FEATURE_ORDER))


if __name__ == "__main__":
    main()
