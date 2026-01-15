SYMPTOM_MAP = {
    "fever": ["fever", "temperature"],
    "cough": ["cough", "coughing"],
    "breathing_difficulty": [
        "shortness of breath",
        "difficulty breathing",
        "breathing issue",
        "breathless"
    ],
    "chest_pain": ["chest pain", "chest tightness", "tight chest"],
    "wheezing": ["wheezing"],
    "fatigue": ["fatigue", "tired", "exhausted"],
    "sore_throat": ["sore throat"],
    "headache": ["headache"],
    "abdominal_pain": ["stomach pain", "abdominal pain"],
    "nausea": ["nausea"],
    "vomiting": ["vomiting"],
    "diarrhea": ["diarrhea"]
}

RISK_FACTOR_MAP = {
    "smoker": ["smoke", "smoker", "cigarette", "tobacco","smoke daily"],
    "alcohol_use": ["alcohol", "drink"],
    "diabetes": ["diabetes"],
    "hypertension": ["hypertension", "high bp"],
    "pregnant": ["pregnant"]
}

NEGATIONS = [
    "no",
    "not",
    "dont",
    "don't",
    "do not",
    "never",
    "without",
    "quit",
    "stopped"
]

NEGATION_WINDOW = 4
