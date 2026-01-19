import sys
from pathlib import Path
import numpy as np
import joblib
from collections import defaultdict
from sklearn.model_selection import train_test_split

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

    _, X_test, _, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        stratify=y,
        random_state=42,
    )

    X_test = scaler.transform(X_test)
    probs = model.predict_proba(X_test)

    buckets = defaultdict(lambda: {"correct": 0, "total": 0})

    for i in range(len(y_test)):
        pred = probs[i].argmax()
        conf = probs[i].max()

        bucket = round(conf, 1)  # 0.0, 0.1, ..., 1.0
        buckets[bucket]["total"] += 1
        if pred == y_test[i]:
            buckets[bucket]["correct"] += 1

    print("\n=== Confidence Calibration (In-Distribution) ===")
    for b in sorted(buckets):
        total = buckets[b]["total"]
        acc = buckets[b]["correct"] / max(total, 1)
        print(f"Conf {b:.1f} → Acc {acc:.3f} ({total} samples)")


if __name__ == "__main__":
    main()
