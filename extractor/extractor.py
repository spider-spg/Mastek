from mapping import (
    SYMPTOM_MAP,
    RISK_FACTOR_MAP,
    NEGATIONS,
    NEGATION_WINDOW
)

# -------------------------
# Negation detection
# -------------------------
def is_negated(text: str, phrase: str) -> bool:
    words = text.split()
    phrase_words = phrase.split()

    for i in range(len(words)):
        if words[i:i + len(phrase_words)] == phrase_words:
            start = max(0, i - NEGATION_WINDOW)
            context = " ".join(words[start:i])
            for neg in NEGATIONS:
                if neg in context:
                    return True
    return False


# -------------------------
# LOCAL frequency detection
# -------------------------
def get_frequency_weight(text: str, phrase: str) -> float:
    words = text.split()
    phrase_words = phrase.split()
    WINDOW = 4  # <-- LOCAL, NOT imported

    for i in range(len(words)):
        if words[i:i + len(phrase_words)] == phrase_words:
            start = i + len(phrase_words)
            end = min(len(words), start + WINDOW)
            context = " ".join(words[start:end])

            if any(w in context for w in ["occasionally", "sometimes", "rarely"]):
                return 0.3
            if any(w in context for w in ["daily", "regularly", "often"]):
                return 0.7
            return 1.0

    return 1.0


# -------------------------
# Extractor
# -------------------------
def extract_from_text(text: str, schema: dict) -> dict:
    text = text.lower()

    # ===== Symptoms =====
    for symptom, phrases in SYMPTOM_MAP.items():
        for phrase in phrases:
            if phrase in text:
                if is_negated(text, phrase):
                    schema["symptoms"][symptom] = 0.0
                else:
                    if any(w in text for w in ["severe", "very", "extreme"]):
                        schema["symptoms"][symptom] = 0.7
                    else:
                        schema["symptoms"][symptom] = 0.4
                break

    # ===== Risk Factors =====
    for risk, phrases in RISK_FACTOR_MAP.items():
        for phrase in phrases:
            if phrase in text:
                if is_negated(text, phrase):
                    schema["risk_factors"][risk] = 0.0
                else:
                    schema["risk_factors"][risk] = get_frequency_weight(text, phrase)
                break

    # ===== Context =====
    schema["context"]["symptom_count"] = sum(
        1 for v in schema["symptoms"].values() if v > 0
    )

    return schema
