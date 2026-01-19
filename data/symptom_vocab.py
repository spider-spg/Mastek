import json
import os

BASE_DIR = os.path.dirname(os.path.dirname(__file__))

PHASE1_PATH = os.path.join(BASE_DIR, "question_flows", "phase1_flows.json")
PHASE2_PATH = os.path.join(BASE_DIR, "question_flows", "phase2_candidates.json")
DISEASE_MAP_PATH = os.path.join(BASE_DIR, "data", "disease_symptom_map.py")


def build_symptom_vocab():
    symptoms = set()

    # -------- Phase 1 --------
    with open(PHASE1_PATH, "r") as f:
        phase1 = json.load(f)

    for flows in phase1.values():
        if isinstance(flows, dict):
            flows = flows.get("questions", [])

        for q in flows:
            if isinstance(q, dict):
                s = q.get("maps_to")
                if isinstance(s, str) and s.strip():
                    symptoms.add(s)

    # -------- Phase 2 --------
    with open(PHASE2_PATH, "r") as f:
        phase2 = json.load(f)

    items = phase2.values() if isinstance(phase2, dict) else phase2
    for q in items:
        if isinstance(q, dict):
            s = q.get("maps_to", q.get("id"))
            if isinstance(s, str) and s.strip():
                symptoms.add(s)

    return sorted(symptoms)
