# scripts/generate_ml_dataset.py

import sys
from pathlib import Path
import numpy as np
# from data.feature_assembler import assemble_features

# -------------------------------------------------
# Ensure project root is on Python path
# -------------------------------------------------
ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

# -------------------------------------------------
# Project imports (CORRECT)
# -------------------------------------------------
from controller.simulation import run_simulation
from controller.confidence import normalize_confidence
from data.build_ml_dataset import build_dataset
from data.disease_index import NUM_DISEASES
from data.feature_assembler import assemble_features


# -------------------------------------------------
# Feature extraction (MUST stay stable)
# -------------------------------------------------
def extract_features_from_state(state: dict):
    """
    Extracts features in explicit channels to avoid leakage.
    """

    # Channel A: raw symptoms
    symptoms = []
    for key in sorted(state["symptoms"]):
        symptoms.append(float(state["symptoms"][key]))

    # Channel B: interaction meta
    meta = [
        state.get("questions_asked", 0),
        state.get("phase2_questions_asked", 0),
        state.get("rank_stable_for", 0),
    ]

    # Channel C: rule priors (DANGEROUS, optional)
    rule_priors = []
    for key in sorted(state["scores"]):
        rule_priors.append(float(state["scores"][key]))

    return {
        "symptoms": symptoms,
        "meta": meta,
        "rule_priors": rule_priors,
    }


# -------------------------------------------------
# Dataset generator
# -------------------------------------------------

def generate_conversations(n: int, use_rule_priors: bool):
    for _ in range(n):
        state = run_simulation()
        rule_scores = normalize_confidence(state["scores"])

        feature_dict = extract_features_from_state(state)
        X = assemble_features(feature_dict, use_rule_priors)

        yield {
            "features": X,
            "rule_scores": rule_scores
        }



# -------------------------------------------------
# Main runner
# -------------------------------------------------
def main():
    from pathlib import Path

    output_dir = Path("data/output")
    output_dir.mkdir(parents=True, exist_ok=True)

    # -------- WITH RULE PRIORS --------
    conversations = generate_conversations(
        n=1_000,
        use_rule_priors=True
    )

    X, y = build_dataset(conversations, temperature=2.0)

    assert np.allclose(y.sum(axis=1), 1.0)
    np.savez(output_dir / "ml_dataset_with_rules.npz", X=X, y=y)

    print("Saved: ml_dataset_with_rules.npz", X.shape, y.shape)

    # -------- WITHOUT RULE PRIORS --------
    conversations = generate_conversations(
        n=1_000,
        use_rule_priors=False
    )

    X, y = build_dataset(conversations, temperature=2.0)

    assert np.allclose(y.sum(axis=1), 1.0)
    np.savez(output_dir / "ml_dataset_without_rules.npz", X=X, y=y)

    print("Saved: ml_dataset_without_rules.npz", X.shape, y.shape)


if __name__ == "__main__":
    main()


