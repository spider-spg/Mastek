import os
import joblib
import numpy as np
from controller.diagnostics import DISEASES

BASE_DIR = os.path.dirname(__file__)
MODEL_PATH = os.path.join(BASE_DIR, "artifacts", "disease_model.pkl")

artifacts = joblib.load(MODEL_PATH)
model = artifacts["model"]
scaler = artifacts["scaler"]
N_FEATURES = artifacts["n_features"]

disease_labels = list(DISEASES)


def predict_proba(X):
    X = np.array(X, dtype=float).reshape(1, -1)
    X = scaler.transform(X)

    probs = model.predict_proba(X)[0]

    return {
        disease_labels[i]: float(probs[i])
        for i in range(len(disease_labels))
    }
