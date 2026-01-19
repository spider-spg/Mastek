# import os
# import numpy as np
# import joblib

# from sklearn.model_selection import train_test_split
# from sklearn.ensemble import RandomForestClassifier
# from sklearn.metrics import accuracy_score


# DATASET_PATH = "data/output/per_disease_dataset.npz"
# MODEL_PATH = "scorer/artifacts/disease_model.pkl"


# def load_dataset(path):
#     data = np.load(path, allow_pickle=True)
#     X = data["X"]
#     y = data["y"]
#     feature_order = data["feature_order"].tolist()
#     diseases = data["diseases"].tolist()
#     return X, y, feature_order, diseases


# def main():
#     X, y, feature_order, diseases = load_dataset(DATASET_PATH)

#     X_train, X_val, y_train, y_val = train_test_split(
#         X, y,
#         test_size=0.2,
#         random_state=42,
#         stratify=y
#     )

#     clf = RandomForestClassifier(
#         n_estimators=300,
#         max_depth=None,
#         min_samples_leaf=2,
#         class_weight="balanced",
#         random_state=42,
#         n_jobs=-1
#     )

#     clf.fit(X_train, y_train)

#     preds = clf.predict(X_val)
#     acc = accuracy_score(y_val, preds)
#     print(f"Validation Accuracy: {acc:.3f}")

#     os.makedirs(os.path.dirname(MODEL_PATH), exist_ok=True)

#     joblib.dump(
#         {
#             "model": clf,
#             "feature_order": feature_order,
#             "diseases": diseases,
#             "model_type": "random_forest"
#         },
#         MODEL_PATH
#     )

#     print("Artifacts saved successfully.")


# if __name__ == "__main__":
#     main()



import os
import joblib
import pandas as pd

from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score


# ---------------- PATHS ----------------
DATA_PATH = "data/training.csv"
ARTIFACT_DIR = "scorer/artifacts"
os.makedirs(ARTIFACT_DIR, exist_ok=True)

MODEL_PATH = os.path.join(ARTIFACT_DIR, "disease_model.pkl")
FEATURE_PATH = os.path.join(ARTIFACT_DIR, "feature_order.pkl")
LABEL_PATH = os.path.join(ARTIFACT_DIR, "label_encoder.pkl")
# --------------------------------------


def main():
    # ---------- Load dataset ----------
    df = pd.read_csv(DATA_PATH)

    X = df.drop(columns=["prognosis", "medicine"], errors="ignore")
    y = df["prognosis"]

    feature_order = list(X.columns)

    # ---------- Clean up duplicate labels ----------
    print("Original label counts:")
    print(y.value_counts().head())
    
    # Fix the duplicate "Diabetes" entries
    y = y.replace({"Diabetes ": "Diabetes"})  # Remove trailing space if any
    
    # Remove classes with too few samples (< 2) for stratified split
    class_counts = y.value_counts()
    valid_classes = class_counts[class_counts >= 2].index
    mask = y.isin(valid_classes)
    X = X[mask]
    y = y[mask]
    
    print(f"\nAfter cleanup: {len(y.unique())} unique diseases")
    print(f"Removed {(~mask).sum()} samples with insufficient class size")
    
    # ---------- Encode labels ----------
    le = LabelEncoder()
    y_enc = le.fit_transform(y)

    # ---------- Split ----------
    X_train, X_val, y_train, y_val = train_test_split(
        X, y_enc, test_size=0.2, random_state=42, stratify=y_enc
    )


    # ---------- Train RandomForest ----------
    model = RandomForestClassifier(
        n_estimators=500,
        max_depth=20,
        min_samples_split=5,
        min_samples_leaf=2,
        class_weight="balanced",  # Handle class imbalance
        random_state=42,
        n_jobs=-1
    )

    model.fit(X_train, y_train)

    # ---------- Validate ----------
    preds = model.predict(X_val)
    probs = model.predict_proba(X_val)
    
    acc = accuracy_score(y_val, preds)
    print(f"Validation Accuracy: {acc:.3f}")
    
    # Check top diseases being predicted
    pred_diseases = [le.classes_[p] for p in preds]
    print(f"\nMost frequently predicted diseases:")
    pred_counts = pd.Series(pred_diseases).value_counts().head(10)
    for disease, count in pred_counts.items():
        print(f"  {disease}: {count}")
    
    # Check prediction confidence
    max_probs = probs.max(axis=1)
    print(f"\nPrediction confidence stats:")
    print(f"  Mean confidence: {max_probs.mean():.3f}")
    print(f"  Low confidence (<0.5): {(max_probs < 0.5).sum()}/{len(max_probs)}")
    print(f"  High confidence (>0.8): {(max_probs > 0.8).sum()}/{len(max_probs)}")

    # ---------- Save artifacts ----------
    joblib.dump(model, "scorer/artifacts/disease_model.pkl")
    joblib.dump(le, "scorer/artifacts/label_encoder.pkl")
    joblib.dump(feature_order, "scorer/artifacts/feature_order.pkl")


    print("Artifacts saved successfully.")


if __name__ == "__main__":
    main()
