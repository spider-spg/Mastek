# controller/flow_controller.py
# ✅ FINAL FIX: feature_order is ONLY a mapping hint, not dimensional truth

from controller.scorer import update_scores
from controller.stop_policy import should_stop
from controller.confidence import normalize_confidence
from controller.question_selector import select_phase2_question
from controller.diagnostics import PHASE2_DIAGNOSTICS, DISEASES
from scorer.predict import predict_proba
import joblib
import os


def run_flow():
    ARTIFACT_PATH = os.path.join(
        os.path.dirname(__file__), "..", "scorer", "artifacts", "disease_model.pkl"
    )
    artifacts = joblib.load(ARTIFACT_PATH)
    n_features = artifacts["n_features"]

    # feature_order is ONLY for mapping symptoms → indices
    feature_order = list(PHASE2_DIAGNOSTICS.keys())

    state = {
        "symptoms": {},
        "scores": {d: 0.0 for d in DISEASES},
        "diagnostics": PHASE2_DIAGNOSTICS,
        "questions_asked": 0,
        "phase2_questions_asked": 0,
        "rank_stable_for": 0,
        "prev_top_disease": None,
        "top_confidence": 0.0,
        "red_flag": False,
        "max_questions": 10,
    }

    asked_symptoms = set()

    while True:
        confidence = normalize_confidence(state["scores"])
        _, top_conf = max(confidence.items(), key=lambda x: x[1])
        state["top_confidence"] = top_conf

        if should_stop(state) != "CONTINUE":
            break

        question = select_phase2_question(
            state=state,
            current_confidence=top_conf,
            phase2_candidates=[
                {"id": k, "maps_to": k} for k in PHASE2_DIAGNOSTICS.keys()
            ],
            asked_symptoms=asked_symptoms,
            predict_fn=predict_proba,
            feature_order=feature_order,
        )

        if question is None:
            break

        update_scores(state, question["id"], "yes")
        state["symptoms"][question["maps_to"]] = 1.0
        asked_symptoms.add(question["maps_to"])
        state["questions_asked"] += 1
        state["phase2_questions_asked"] += 1

    return state
