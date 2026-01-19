import os
import joblib
import numpy as np

BASE_DIR = os.path.dirname(os.path.dirname(__file__))
ARTIFACT_DIR = os.path.join(BASE_DIR, "scorer", "artifacts")

MODEL_PATH = os.path.join(ARTIFACT_DIR, "disease_model.pkl")
ENCODER_PATH = os.path.join(ARTIFACT_DIR, "label_encoder.pkl")
FEATURE_ORDER_PATH = os.path.join(ARTIFACT_DIR, "feature_order.pkl")

# --------------------------------------------------
# Load artifacts ONCE
# --------------------------------------------------
model = joblib.load(MODEL_PATH)
label_encoder = joblib.load(ENCODER_PATH)
feature_order = joblib.load(FEATURE_ORDER_PATH)

CLASSES = list(label_encoder.classes_)  # 🔑 single source of truth


# --------------------------------------------------
# Probability inference (raw)
# --------------------------------------------------
def predict_proba(X):
    """
    X: list[list[float]] or np.ndarray shape (n_samples, n_features)
    returns: dict[disease -> probability]
    """
    X = np.asarray(X, dtype=np.float32)
    if X.ndim == 1:
        X = X.reshape(1, -1)

    probs = model.predict_proba(X)[0]

    return {
        CLASSES[i]: float(probs[i])
        for i in range(min(len(CLASSES), len(probs)))
    }


# --------------------------------------------------
# Ranked inference with hard gating
# --------------------------------------------------
def predict_ranked(feature_vector, allowed_diseases=None):
    """
    feature_vector: list[float]
    allowed_diseases: set[str] | None
    """
    X = np.asarray(feature_vector, dtype=np.float32).reshape(1, -1)
    probs = model.predict_proba(X)[0]

    scores = {}
    for i in range(min(len(CLASSES), len(probs))):
        disease = CLASSES[i]
        if allowed_diseases and disease not in allowed_diseases:
            continue
        scores[disease] = float(probs[i])

    return scores

