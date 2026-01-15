DISEASES = [
    "gastritis",
    "peptic_ulcer",
    "pancreatitis",
    "appendicitis"
]

PHASE2_DIAGNOSTICS = {
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
}
