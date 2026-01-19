import sys
from pathlib import Path
import numpy as np
import joblib

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score


CLEAN_PATH = "data/output/per_disease_dataset.npz"
NOISY_PATH = "data/output/per_disease_dataset_noisy.npz"
ARTIFACT_DIR = Path("scorer/artifacts")
ARTIFACT_DIR.mkdir(parents=True, exist_ok=True)


def load(path):
    d = np.load(path, allow_pickle=True)
    return d["X"], d["y"], d["feature_order"].tolist(), d["diseases"].tolist()


def main():
    X_clean, y_clean, feature_order, diseases = load(CLEAN_PATH)
    X_noisy, y_noisy, _, _ = load(NOISY_PATH)

    # ---- curriculum mix ----
    X = np.vstack([X_clean, X_noisy])
    y = np.concatenate([y_clean, y_noisy])

    X_train, X_val, y_train, y_val = train_test_split(
        X,
        y,
        test_size=0.2,
        stratify=y,
        random_state=42,
    )

    scaler = StandardScaler()
    X_train = scaler.fit_transform(X_train)
    X_val = scaler.transform(X_val)

    clf = LogisticRegression(
        max_iter=4000,
        class_weight="balanced",
        n_jobs=-1,
    )

    clf.fit(X_train, y_train)

    preds = clf.predict(X_val)
    acc = accuracy_score(y_val, preds)

    print(f"Curriculum Validation Accuracy: {acc:.3f}")

    joblib.dump(
        {
            "model": clf,
            "scaler": scaler,
            "feature_order": feature_order,
            "diseases": diseases,
            "n_features": X.shape[1],
        },
        ARTIFACT_DIR / "disease_model.pkl",
    )

    print("Curriculum model saved.")


if __name__ == "__main__":
    main()
