import pandas as pd

# Load the dataset
df = pd.read_csv('Disease_symptom_and_patient_profile_dataset.csv')

# Get diseases with chest/respiratory symptoms and good sample counts
chest_symptoms = ['chest_pain', 'breathlessness', 'cough', 'fast_heart_rate', 'palpitations']
chest_diseases = set()

print("Analyzing chest/respiratory symptoms...")

for symptom in chest_symptoms:
    if symptom in df.columns:
        diseases_with_symptom = df[df[symptom] == 1]['Disease'].unique()
        chest_diseases.update(diseases_with_symptom)
        print(f"\nDiseases with {symptom}: {len(diseases_with_symptom)} diseases")

# Check sample counts for chest diseases
disease_counts = df['Disease'].value_counts()
valid_chest_diseases = []

for disease in chest_diseases:
    count = disease_counts[disease] if disease in disease_counts else 0
    if count >= 10:  # Only diseases with 10+ samples
        valid_chest_diseases.append((disease, count))

valid_chest_diseases.sort(key=lambda x: x[1], reverse=True)

print(f"\n=== VALID CHEST DISEASES (10+ samples) ===")
for disease, count in valid_chest_diseases:
    print(f"  {disease}: {count} samples")

print(f"\nRecommended chest diseases for model:")
recommended = valid_chest_diseases[:6]  # Top 6
for disease, count in recommended:
    print(f"  \"{disease}\",")