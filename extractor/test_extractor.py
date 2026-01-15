from schema import get_empty_schema
from extractor import extract_from_text
from state import merge_states

state = get_empty_schema()

texts = [
    "I have chest tightness and a headache and stomach pain",
    "I occasionally drink alcohol and smoke daily",
    "I have a dry cough and fever of 101 degrees",
    "No shortness of breath but I feel fatigued",
]

for t in texts:
    s = extract_from_text(t, get_empty_schema())
    state = merge_states(state, s)

print(state)
