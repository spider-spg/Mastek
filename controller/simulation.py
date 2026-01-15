# controller/simulation.py
# ✅ FINAL FIX: always build FULL-LENGTH feature vector (no mismatch possible)

from controller.flow_controller import run_flow
import joblib
import os


def run_simulation():
    return run_flow()


def simulate_confidence(state, symptom, value, predict_fn, feature_order):
    """
    Always builds a feature vector with EXACT dimensionality
    expected by the trained model.
    """

    # load expected feature length from artifacts
    ARTIFACT_PATH = os.path.join(
        os.path.dirname(__file__), "..", "scorer", "artifacts", "disease_model.pkl"
    )
    artifacts = joblib.load(ARTIFACT_PATH)
    n_features = artifacts["n_features"]

    sim_symptoms = dict(state.get("symptoms", {}))
    sim_symptoms[symptom] = value

    # 🔒 FULL-LENGTH VECTOR (pad with zeros)
    X = [0.0] * n_features
    for i, f in enumerate(feature_order):
        if i >= n_features:
            break
        X[i] = sim_symptoms.get(f, 0.0)

    scores = predict_fn(X)

    vals = sorted(scores.values(), reverse=True)
    if len(vals) < 2:
        return 1.0

    return (vals[0] - vals[1]) / max(vals[0], 1e-6)
