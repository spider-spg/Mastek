# data/disease_symptom_map.py
# ✅ CLEAN, NORMALIZED, READY-TO-USE (43 diseases)

DISEASE_SYMPTOMS = {

    # -------------------- Infections --------------------
    "Fungal infection": {
        "core": ["itching", "rash"],
        "secondary": ["redness"]
    },
    "Allergy": {
        "core": ["itching", "rash"],
        "secondary": ["sneezing"]
    },
    "Drug Reaction": {
        "core": ["rash", "itching"],
        "secondary": ["fever", "swelling"]
    },
    "AIDS": {
        "core": ["weight_loss", "fatigue"],
        "secondary": ["fever"]
    },
    "Tuberculosis": {
        "core": ["cough", "weight_loss", "night_sweats"],
        "secondary": ["fever"]
    },
    "Common Cold": {
        "core": ["cough", "sneezing"],
        "secondary": ["fatigue"]
    },
    "Pneumonia": {
        "core": ["cough", "fever", "breathlessness"],
        "secondary": ["chest_pain"]
    },

    # -------------------- Vector-borne --------------------
    "Malaria": {
        "core": ["fever", "chills", "sweating"],
        "secondary": ["headache"]
    },
    "Dengue": {
        "core": ["fever", "joint_pain", "muscle_pain"],
        "secondary": ["rash"]
    },
    "Chikungunya": {
        "core": ["fever", "joint_pain"],
        "secondary": ["muscle_pain", "fatigue"]
    },
    "Typhoid": {
        "core": ["fever", "abdominal_pain"],
        "secondary": ["diarrhea"]
    },

    # -------------------- Gastro / Liver --------------------
    "GERD": {
        "core": ["heartburn", "chest_pain"],
        "secondary": ["nausea"]
    },
    "Peptic ulcer diseae": {
        "core": ["abdominal_pain"],
        "secondary": ["nausea", "vomiting"]
    },
    "Gastroenteritis": {
        "core": ["diarrhea", "vomiting"],
        "secondary": ["abdominal_pain"]
    },
    "Jaundice": {
        "core": ["yellow_eyes", "dark_urine"],
        "secondary": ["fatigue"]
    },
    "Chronic cholestasis": {
        "core": ["itching", "yellow_eyes"],
        "secondary": ["dark_urine"]
    },
    "hepatitis A": {
        "core": ["fever", "yellow_eyes"],
        "secondary": ["nausea"]
    },
    "Hepatitis B": {
        "core": ["fatigue", "yellow_eyes"],
        "secondary": ["abdominal_pain"]
    },
    "Hepatitis C": {
        "core": ["fatigue", "yellow_eyes"],
        "secondary": ["weight_loss"]
    },
    "Hepatitis D": {
        "core": ["fatigue", "yellow_eyes"],
        "secondary": ["abdominal_pain"]
    },
    "Hepatitis E": {
        "core": ["fever", "yellow_eyes"],
        "secondary": ["nausea"]
    },
    "Alcoholic hepatitis": {
        "core": ["yellow_eyes", "abdominal_pain"],
        "secondary": ["nausea"]
    },

    # -------------------- Metabolic / Endocrine --------------------
    "Diabetes": {
        "core": ["frequent_urination", "increased_thirst"],
        "secondary": ["fatigue", "weight_loss"]
    },
    "Hypoglycemia": {
        "core": ["sweating", "dizziness"],
        "secondary": ["palpitations"]
    },
    "Hypothyroidism": {
        "core": ["fatigue", "weight_gain"],
        "secondary": ["dry_skin"]
    },
    "Hyperthyroidism": {
        "core": ["weight_loss", "palpitations"],
        "secondary": ["sweating"]
    },

    # -------------------- Cardio / Neuro --------------------
    "Hypertension": {
        "core": ["headache"],
        "secondary": ["dizziness"]
    },
    "Heart attack": {
        "core": ["chest_pain", "sweating"],
        "secondary": ["breathlessness", "nausea"]
    },
    "Paralysis (brain hemorrhage)": {
        "core": ["weakness", "loss_of_speech"],
        "secondary": ["confusion"]
    },
    "Migraine": {
        "core": ["headache", "nausea"],
        "secondary": ["light_sensitivity"]
    },
    "(vertigo) Paroymsal Positional Vertigo": {
        "core": ["dizziness", "loss_of_balance"],
        "secondary": ["nausea"]
    },

    # -------------------- Musculoskeletal --------------------
    "Cervical spondylosis": {
        "core": ["neck_pain", "stiffness"],
        "secondary": ["headache"]
    },
    "Osteoarthristis": {
        "core": ["joint_pain", "movement_pain"],
        "secondary": ["stiffness"]
    },
    "Arthritis": {
        "core": ["joint_pain", "stiffness"],
        "secondary": ["swelling"]
    },

    # -------------------- Skin --------------------
    "Psoriasis": {
        "core": ["skin_lesions", "scaling"],
        "secondary": ["itching"]
    },
    "Impetigo": {
        "core": ["pus", "skin_lesions"],
        "secondary": ["redness"]
    },
    "Acne": {
        "core": ["pimples"],
        "secondary": ["pus"]
    },

    # -------------------- Others --------------------
    "Urinary tract infection": {
        "core": ["burning_urination", "frequent_urination"],
        "secondary": ["pelvic_pain"]
    },
    "Dimorphic hemmorhoids(piles)": {
        "core": ["rectal_bleeding", "constipation"],
        "secondary": ["pain"]
    },
    "Varicose veins": {
        "core": ["varicose_veins", "leg_swelling"],
        "secondary": ["pain"]
    }
}
print(len(DISEASE_SYMPTOMS))
print(sorted(DISEASE_SYMPTOMS.keys()))
