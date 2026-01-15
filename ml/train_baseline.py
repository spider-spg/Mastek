import sys
from pathlib import Path
import numpy as np
import os
import joblib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from sklearn.model_selection import train_test_split
from sklearn.linear_model import LogisticRegression
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score


def load_dataset(path):
    d = np.load(path)
    X = d["X"]
    Y_soft = d["y"]

    def harden_labels(Y_soft, margin=0.05):
        labels = []
        for row in Y_soft:
            top = np.argmax(row)
            sorted_vals = np.sort(row)
            if sorted_vals[-1] - sorted_vals[-2] < margin:
                labels.append(-1)
            else:
                labels.append(top)
        return np.array(labels)

    y_raw = harden_labels(Y_soft)
    mask = y_raw != -1

    return X[mask], y_raw[mask]



def main():
    X, y = load_dataset("data/output/ml_dataset_with_rules.npz")

    X_train, X_val, y_train, y_val = train_test_split(
        X, y, test_size=0.2, stratify=y, random_state=42
    )

    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_val = scaler.transform(X_val)

    clf = LogisticRegression(
        max_iter=2000,
        multi_class="ovr",
        class_weight="balanced",
        n_jobs=-1,
    )

    clf.fit(X_train, y_train)

    preds = clf.predict(X_val)
    acc = accuracy_score(y_val, preds)

    print(f"Validation accuracy: {acc:.3f}")

    ARTIFACT_DIR = Path("scorer/artifacts")
    ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)

    joblib.dump(
        {
            "model": clf,
            "scaler": scaler,
            "n_features": X.shape[1],
        },
        ARTIFACT_DIR / "disease_model.pkl",
    )

    print("Artifacts saved successfully.")


if __name__ == "__main__":
    main()
