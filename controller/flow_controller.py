import os
import json
import joblib

from controller.stop_policy import should_stop
from controller.question_selector import select_phase2_question
from controller.confidence import normalize_confidence
from scorer.predict_specialized import predict_specialized
from scorer.predict import predict_proba, predict_ranked
from controller.gating import gate_diseases   # hard body-part gating
from controller.diagnostics import DISEASES
from controller.diagnostics import PHASE2_DIAGNOSTICS
from scorer.predict import predict_proba, predict_ranked
from controller.gating import gate_diseases
from data.symptom_mapping import map_symptoms_to_features


BASE_DIR = os.path.dirname(os.path.dirname(__file__))

PHASE1_PATH = os.path.join(BASE_DIR, "question_flows", "phase1_flows.json")
PHASE2_PATH = os.path.join(BASE_DIR, "question_flows", "phase2_candidates.json")

MODEL_PATH = os.path.join(BASE_DIR, "scorer", "artifacts", "disease_model.pkl")
FEATURE_ORDER_PATH = os.path.join(BASE_DIR, "scorer", "artifacts", "feature_order.pkl")


# --------------------------------------------------
# Helpers
# --------------------------------------------------
def normalize_phase1(raw):
    """
    Always return: list[ {maps_to, text} ]
    """
    normalized = []

    if isinstance(raw, dict):
        raw = raw.get("questions", [])

    for q in raw:
        if isinstance(q, str):
            normalized.append({
                "maps_to": q,
                "text": f"Do you have {q.replace('_', ' ')}?"
            })
        elif isinstance(q, dict):
            normalized.append({
                "maps_to": q["maps_to"],
                "text": q.get("text", f"Do you have {q['maps_to'].replace('_',' ')}?")
            })

    return normalized


def normalize_phase2(raw):
    out = []
    items = raw.values() if isinstance(raw, dict) else raw

    for q in items:
        if not isinstance(q, dict):
            continue
        q = q.copy()
        q.setdefault("maps_to", q["id"])
        out.append(q)

    return out


# --------------------------------------------------
# Main flow
# --------------------------------------------------
def run_flow():
    # ---------- Load artifacts ----------
    model = joblib.load(MODEL_PATH)
    feature_order = joblib.load(FEATURE_ORDER_PATH)

    with open(PHASE1_PATH) as f:
        PHASE1 = json.load(f)

    with open(PHASE2_PATH) as f:
        PHASE2_RAW = json.load(f)

    # ---------- Body part ----------
    print("\nWhich body part is bothering you?")
    print("Options:", ", ".join(PHASE1.keys()))
    body_part = input("Enter body part: ").strip().lower()

    phase1_questions = normalize_phase1(PHASE1.get(body_part, []))
    phase2_candidates = normalize_phase2(PHASE2_RAW.get(body_part, {}))
    
    print(f"DEBUG: Found {len(phase2_candidates)} Phase 2 candidates for {body_part}")

    # ---------- State ----------
    state = {
    "body_part": body_part,
    "symptoms": {},
    "scores": {d: 0.0 for d in DISEASES},
    "diagnostics": PHASE2_DIAGNOSTICS,

    "questions_asked": 0,
    "phase2_questions_asked": 0,
    "rank_stable_for": 0,
    "prev_top_disease": None,
    "top_confidence": 0.0,
    "red_flag": False,

    # 🔑 REQUIRED by stop_policy
    "max_questions": 10
}

    asked = set()

    # ==================================================
    # PHASE 1 — ALWAYS ASK ALL
    # ==================================================
    print(f"\n--- Phase 1: {body_part.upper()} ---\n")

    for q in phase1_questions:
        print(q["text"])
        ans = input("Answer (yes / no / unsure): ").strip().lower()
        if ans not in {"yes", "no", "unsure"}:
            ans = "unsure"

        state["symptoms"][q["maps_to"]] = (
            1.0 if ans == "yes" else -1.0 if ans == "no" else 0.0
        )

        asked.add(q["maps_to"])
        state["questions_asked"] += 1

    # ==================================================
    # BASELINE ML (ranking only)
    # ==================================================
    # Map questionnaire symptoms to model features  
    mapped_features = map_symptoms_to_features(state["symptoms"])
    state["feature_vector"] = [
        mapped_features.get(s, 0.0) for s in feature_order
    ]
    
    # Calculate baseline confidence for Phase 2 decision making
    baseline_probs = predict_specialized(state["symptoms"], body_part)
    baseline_confidence = normalize_confidence(baseline_probs)
    top_diseases = sorted(baseline_confidence.items(), key=lambda x: x[1], reverse=True)
    state["top_confidence"] = top_diseases[0][1] if top_diseases else 0.0
    state["current_confidence"] = baseline_confidence  # Store for ambiguity checking

    # ==================================================
    # PHASE 2 — ML-DRIVEN QUESTIONING
    # ==================================================
    print("\n--- Phase 2: Follow-up questions ---\n")

    while True:
        stop_reason = should_stop(state)
        print(f"DEBUG: Stop policy says: {stop_reason}")
        print(f"DEBUG: Current state - questions_asked: {state.get('questions_asked', 0)}, max_questions: {state.get('max_questions', 0)}, top_confidence: {state.get('top_confidence', 0.0)}")
        
        if stop_reason != "CONTINUE":
            print(f"DEBUG: Breaking Phase 2 loop because: {stop_reason}")
            break

        q = select_phase2_question(
            state=state,
            current_confidence=state.get("top_confidence", 0.0),
            phase2_candidates=phase2_candidates,
            asked_symptoms=asked,
            predict_fn=predict_proba,
            feature_order=feature_order,
        )

        if q is None:
            print("DEBUG: No Phase 2 questions available - breaking")
            break
        
        print(f"DEBUG: Selected question: {q.get('text', 'No text')}")

        print(q["text"])
        ans = input("Answer (yes / no / unsure): ").strip().lower()
        if ans not in {"yes", "no", "unsure"}:
            ans = "unsure"

        state["symptoms"][q["maps_to"]] = (
            1.0 if ans == "yes" else -1.0 if ans == "no" else 0.0
        )

        asked.add(q["maps_to"])
        state["phase2_questions_asked"] += 1

        # Map questionnaire symptoms to model features
        mapped_features = map_symptoms_to_features(state["symptoms"])
        
        # Update feature vector and recalculate confidence
        updated_probs = predict_specialized(state["symptoms"], body_part)
        updated_confidence = normalize_confidence(updated_probs) 
        top_diseases = sorted(updated_confidence.items(), key=lambda x: x[1], reverse=True)
        state["top_confidence"] = top_diseases[0][1] if top_diseases else 0.0
        state["current_confidence"] = updated_confidence  # Store for ambiguity checking

    # ==================================================
    # FINAL HYBRID INFERENCE (RULES → ML)
    # ==================================================
    allowed = gate_diseases(
    body_part=state["body_part"],
    all_diseases=list(state["scores"].keys())
)

    ranked = predict_ranked(
        feature_vector=state["feature_vector"],
        allowed_diseases=allowed
    )

    state["topk"] = sorted(
        ranked.items(),
        key=lambda x: x[1],
        reverse=True
    )[:3]

    state["confidence"] = state["topk"][0][1] if state["topk"] else 0.0


    return state


def normalize_phase2(body_part_data):
    """
    Normalize phase-2 questions for a specific body part into list[dict] with guaranteed:
    - id
    - maps_to
    - text
    """
    normalized = []
    
    # Handle body part specific structure
    candidates = body_part_data.get("candidates", []) if isinstance(body_part_data, dict) else []

    for q in candidates:
        if not isinstance(q, dict):
            continue

        q = q.copy()

        # Ensure maps_to exists
        if "maps_to" not in q:
            continue  # cannot use this question safely

        # Ensure id exists (fallback to maps_to)
        q["id"] = q.get("id", q["maps_to"])

        # Ensure text exists
        q["text"] = q.get(
            "text",
            f"Do you have {q['maps_to'].replace('_', ' ')}?"
        )

        normalized.append(q)

    return normalized
