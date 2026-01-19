import sys
from pathlib import Path
import numpy as np
import joblib
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, top_k_accuracy_score

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

DATASET_PATH = "data/output/per_disease_dataset.npz"
ARTIFACT_PATH = "scorer/artifacts/disease_model.pkl"


def main():
    data = np.load(DATASET_PATH, allow_pickle=True)
    X = data["X"]
    y = data["y"]

    artifacts = joblib.load(ARTIFACT_PATH)
    model = artifacts["model"]
    scaler = artifacts["scaler"]

    # SAME split logic as training
    _, X_test, _, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        stratify=y,
        random_state=42,
    )

    X_test = scaler.transform(X_test)
    probs = model.predict_proba(X_test)
    preds = probs.argmax(axis=1)

    top1 = accuracy_score(y_test, preds)
    top3 = top_k_accuracy_score(y_test, probs, k=3)

    print("\n=== Per-Disease Dataset Evaluation ===")
    print(f"Samples: {len(y_test)}")
    print(f"Top-1 Accuracy: {top1:.3f}")
    print(f"Top-3 Accuracy: {top3:.3f}")


if __name__ == "__main__":
    main()
