# def get_empty_schema():
#     return {
#         "symptoms": {
#             "fever": 0.0,
#             "cough": 0.0,
#             "breathing_difficulty": 0.0,
#             "chest_pain": 0.0,
#             "wheezing": 0.0,
#             "fatigue": 0.0,
#             "sore_throat": 0.0,
#             "headache": 0.0,
#             "abdominal_pain": 0.0,
#             "nausea": 0.0,
#             "vomiting": 0.0,
#             "diarrhea": 0.0
#         },
#         "risk_factors": {
#             "smoker": 0,
#             "alcohol_use": 0,
#             "diabetes": 0,
#             "hypertension": 0,
#             "pregnant": 0,
#             "age_group": None
#         },
#         "context": {
#             "duration_days": None,
#             "symptom_count": 0
#         }
#     }



def get_empty_schema():
    return {
        "symptoms": {
            "fever": 0.0,
            "cough": 0.0,
            "breathing_difficulty": 0.0,
            "chest_pain": 0.0,
            "wheezing": 0.0,
            "fatigue": 0.0,
            "sore_throat": 0.0,
            "headache": 0.0,
            "abdominal_pain": 0.0,
            "nausea": 0.0,
            "vomiting": 0.0,
            "diarrhea": 0.0
        },

        # 🔴 Risk factors are now EXPLICITLY GRADED (0.0–1.0)
        "risk_factors": {
            "smoker": 0.0,          # never → heavy
            "alcohol_use": 0.0,     # never → heavy
            "diabetes": 0.0,
            "hypertension": 0.0,
            "pregnant": 0.0,
            "age_group": None
        },

        "context": {
            "duration_days": None,
            "symptom_count": 0
        }
    }
