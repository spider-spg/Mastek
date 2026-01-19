import random
import numpy as np
from data.disease_symptom_map import DISEASE_SYMPTOMS

# -------- CONFIG (demo-tuned) --------
SAMPLES_PER_DISEASE = 200
CORE_PROB = 0.6
SECONDARY_PROB = 0.3
DISTRACTOR_PROB = 0.2
MAX_DISTRACTORS = 5
DROP_CORE_PROB = 0.3
OUTPUT_PATH = "data/output/per_disease_dataset_noisy.npz"
# ------------------------------------

ALL_SYMPTOMS = sorted(
    {s for d in DISEASE_SYMPTOMS.values() for g in d.values() for s in g}
)

FEATURE_ORDER = ALL_SYMPTOMS
DISEASES = list(DISEASE_SYMPTOMS.keys())


def sample_symptoms(disease):
    present = {}

    core = DISEASE_SYMPTOMS[disease]["core"]
    secondary = DISEASE_SYMPTOMS[disease].get("secondary", [])

    # randomly drop one core symptom (realistic noise)
    core_used = core[:]
    if random.random() < DROP_CORE_PROB and len(core_used) > 1:
        core_used.remove(random.choice(core_used))

    for s in core_used:
        present[s] = 1 if random.random() < CORE_PROB else 0

    for s in secondary:
        present[s] = 1 if random.random() < SECONDARY_PROB else 0

    distractors = list(set(ALL_SYMPTOMS) - set(core) - set(secondary))
    random.shuffle(distractors)

    for s in distractors[:MAX_DISTRACTORS]:
        present[s] = 1 if random.random() < DISTRACTOR_PROB else 0

    return present


def build_feature_vector(symptoms):
    return [symptoms.get(s, 0) for s in FEATURE_ORDER]


def main():
    X, y = [], []

    for disease_idx, disease in enumerate(DISEASES):
        for _ in range(SAMPLES_PER_DISEASE):
            symptoms = sample_symptoms(disease)
            X.append(build_feature_vector(symptoms))
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

    print("Saved NOISY dataset:")
    print("X:", X.shape)
    print("Diseases:", len(DISEASES))
    print("Features:", len(FEATURE_ORDER))


if __name__ == "__main__":
    main()
