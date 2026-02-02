"""
HuggingFace-based Symptom Normalizer
-------------------------------------
This module provides a utility function to normalize noisy, multilingual, user-entered symptom text
into standardized symptom phrases using a HuggingFace transformer model (e.g., for paraphrasing or translation).

- Only used for symptom normalization (not diagnosis or prediction)
- Should be called before SNOMED/UMLS mapping and ML inference
- Keeps all downstream logic explainable and robust
"""

from typing import List

# Example: Use a multilingual paraphrase model from HuggingFace
from transformers import pipeline

# You can choose a model like 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2' or similar
# For demonstration, we'll use a generic pipeline (replace with your preferred model)

class SymptomNormalizer:
    def __init__(self, model_name: str = 'sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2'):
        self.paraphraser = pipeline('text2text-generation', model=model_name)

    def normalize(self, symptoms: List[str]) -> List[str]:
        """
        Normalize a list of user-entered symptom strings to standardized phrases.
        Args:
            symptoms: List of raw symptom strings (possibly noisy, multilingual, etc.)
        Returns:
            List of normalized symptom phrases (in English, standardized)
        """
        normalized = []
        for symptom in symptoms:
            # Paraphrase/translate to standard English phrase
            result = self.paraphraser(symptom, max_length=32, num_return_sequences=1)
            norm = result[0]['generated_text'].strip()
            normalized.append(norm)
        return normalized

# Example usage:
# normalizer = SymptomNormalizer()
# clean_symptoms = normalizer.normalize(["mal de tête", "dolor de cabeza", "severe headache"])
# print(clean_symptoms)
