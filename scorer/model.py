import joblib

MODEL_PATH = "disease_model.pkl"

def load_model():
    return joblib.load(MODEL_PATH)
