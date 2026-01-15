# testss/manual_flow_test.py

from controller.scorer import update_scores
from controller.stop_policy import should_stop
from controller.confidence import normalize_confidence

state = {
    "scores": {
        "gastritis": 0,
        "peptic_ulcer": 0,
        "pancreatitis": 0,
        "appendicitis": 0
    },
    "diagnostics": {
        "vomiting": {
            "gastritis": 0.5,
            "pancreatitis": 0.7,
            "appendicitis": 0.4
        },
        "fever": {
            "appendicitis": 0.6,
            "pancreatitis": 0.3
        },
        "abdominal_pain": {
            "appendicitis": 1.0,
            "pancreatitis": 0.8
        },
        "dizziness": {
            "pancreatitis": 0.2
        }
    },
    "questions_asked": 0,
    "phase2_questions_asked": 0,
    "rank_stable_for": 0,
    "prev_top_disease": None,
    "top_confidence": 0,
    "max_questions": 4,
    "red_flag": False
}

mock_answers = [
    ("vomiting", "yes"),
    ("fever", "no"),
    ("abdominal_pain", "yes"),
    ("dizziness", "no"),
]

for qid, answer in mock_answers:
    update_scores(state, qid, answer)
    state["questions_asked"] += 1
    state["phase2_questions_asked"] += 1

    confidence = normalize_confidence(state["scores"])
    state["top_confidence"] = max(confidence.values())

    decision = should_stop(state)

    print(f"After {qid} → {decision}")
    print("  Scores:", state["scores"])
    print("  Top confidence:", state["top_confidence"])
    print("  Rank stable for:", state["rank_stable_for"])

    if decision != "CONTINUE":
        break
