# controller/gating.py

BODY_PART_TO_DISEASES = {
    "chest": {
        "Bronchial Asthma",
        "Pneumonia",
        "Tuberculosis",
        "Heart attack",
        "Hypertension",
        "Common Cold"
    },
    "abdomen": {
        "Gastroenteritis",
        "Peptic ulcer diseae",
        "GERD",
        "Jaundice",
        "Hepatitis A",
        "Hepatitis B",
        "Hepatitis C",
        "Hepatitis D",
        "Hepatitis E",
        "Alcoholic hepatitis"
    },
    "skin": {
        "Acne",
        "Psoriasis",
        "Impetigo",
        "Fungal infection",
        "Allergy"
    },
    "urinary": {
        "Urinary tract infection"
    },
    "head_neuro": {
        "Migraine",
        "(vertigo) Paroymsal Positional Vertigo",
        "Paralysis (brain hemorrhage)"
    },
    "ent": {
        "Common Cold",
        "Tuberculosis"
    },
    "systemic_flags": set(),  # no restriction
}


def gate_diseases(body_part: str, all_diseases: list[str]) -> list[str]:
    allowed = BODY_PART_TO_DISEASES.get(body_part)

    if not allowed or len(allowed) == 0:
        return all_diseases  # fallback: no gating

    return [d for d in all_diseases if d in allowed]
