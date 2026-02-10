"""
Extract all diseases from SNOMED CT dataset
Assumes SNOMED CT files are in the standard folder structure.
"""
import os
import csv


SNOMED_PATH = "D:\Symptomate😂2\SnomedCT_ManagedServiceUS_PRODUCTION_US1000124_20250901T120000Z"

# Recursively find SNOMED CT files
def find_file(root, filename):
    for dirpath, _, files in os.walk(root):
        for f in files:
            if f.lower() == filename.lower():
                return os.path.join(dirpath, f)
    return None

CONCEPT_FILENAME = "sct2_Concept_Full_US1000124_20250901.txt"
DESCRIPTION_FILENAME = "sct2_Description_Full-en_US1000124_20250901.txt"

CONCEPT_FILE = find_file(SNOMED_PATH, CONCEPT_FILENAME)
DESCRIPTION_FILE = find_file(SNOMED_PATH, DESCRIPTION_FILENAME)

DISEASE_SEMANTIC_TAGS = {"disorder", "disease", "syndrome", "infection", "injury", "neoplasm", "malformation"}


def load_concepts(concept_file):
    concepts = set()
    with open(concept_file, encoding="utf-8") as f:
        reader = csv.reader(f, delimiter="\t")
        next(reader)  # skip header
        for row in reader:
            concept_id = row[0]
            active = row[2]
            if active == "1":
                concepts.add(concept_id)
    return concepts


def extract_diseases(description_file, concepts):
    diseases = []
    with open(description_file, encoding="utf-8") as f:
        reader = csv.reader(f, delimiter="\t")
        next(reader)  # skip header
        for row in reader:
            concept_id = row[0]
            term = row[7]
            if concept_id in concepts:
                # Check if term contains a disease semantic tag
                for tag in DISEASE_SEMANTIC_TAGS:
                    if f"({tag})" in term.lower():
                        diseases.append({"concept_id": concept_id, "name": term})
                        break
    return diseases


def main():
    if not CONCEPT_FILE or not DESCRIPTION_FILE:
        print("❌ Could not find required SNOMED CT files.")
        print(f"Concept file found: {CONCEPT_FILE}")
        print(f"Description file found: {DESCRIPTION_FILE}")
        return
    print(f"Loading concepts from: {CONCEPT_FILE}")
    concepts = load_concepts(CONCEPT_FILE)
    print(f"Loaded {len(concepts)} active concepts.")
    print(f"Extracting diseases from: {DESCRIPTION_FILE}")
    diseases = extract_diseases(DESCRIPTION_FILE, concepts)
    print(f"Found {len(diseases)} diseases.")
    # Save to CSV
    with open("extracted_diseases.csv", "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=["concept_id", "name"])
        writer.writeheader()
        for d in diseases:
            writer.writerow(d)
    print("Diseases saved to extracted_diseases.csv")

if __name__ == "__main__":
    main()
