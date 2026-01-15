# # # import pandas as pd
# # # from pgmpy.models import BayesianNetwork
# # # from pgmpy.estimators import BayesianEstimator
# # # from pgmpy.inference import VariableElimination

# # # # ------------------------------------------------------------
# # # # 1. LOAD DATA
# # # # ------------------------------------------------------------
# # # df = pd.read_csv(r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (6)\train_disease.csv").dropna().copy()

# # # # ------------------------------------------------------------
# # # # 2. DISCRETIZE AGE
# # # # ------------------------------------------------------------
# # # age_bins = [0, 22, 30, 60, 120]
# # # age_labels = ["child", "young_adult", "adult", "senior"]
# # # df["Age_binned"] = pd.cut(df["Age"], bins=age_bins, labels=age_labels)

# # # # Columns used in ontology
# # # cols = [
# # #     "Disease",
# # #     "Fever",
# # #     "Cough",
# # #     "Fatigue",
# # #     "Difficulty Breathing",
# # #     "Age_binned",
# # #     "Gender",
# # #     "Blood Pressure",
# # #     "Cholesterol Level",
# # #     "Outcome Variable"
# # # ]

# # # df = df[cols]

# # # # ------------------------------------------------------------
# # # # 3. ENCODE CATEGORICAL VARIABLES
# # # # ------------------------------------------------------------
# # # mappings = {}
# # # df_encoded = pd.DataFrame()

# # # for col in df.columns:
# # #     codes, uniques = pd.factorize(df[col].astype(str).str.strip())
# # #     df_encoded[col] = codes
# # #     mappings[col] = {k: v for v, k in enumerate(uniques)}

# # # print("\n=== Category Mappings ===")
# # # for k, v in mappings.items():
# # #     print(k, v)

# # # # ------------------------------------------------------------
# # # # 4. ONTOLOGY-DEFINED BN STRUCTURE (FIXED)
# # # # ------------------------------------------------------------
# # # model = BayesianNetwork([
# # #     # Symptoms → Disease
# # #     ("Fever", "Disease"),
# # #     ("Cough", "Disease"),
# # #     ("Fatigue", "Disease"),
# # #     ("Difficulty Breathing", "Disease"),

# # #     # Demographics → Disease
# # #     ("Age_binned", "Disease"),
# # #     ("Gender", "Disease"),

# # #     # Disease → Outcome
# # #     ("Disease", "Outcome Variable"),

# # #     # Health indicators → Outcome
# # #     ("Blood Pressure", "Outcome Variable"),
# # #     ("Cholesterol Level", "Outcome Variable"),
# # # ])

# # # # ------------------------------------------------------------
# # # # 5. TRAIN WITH BAYESIAN ESTIMATOR (SMOOTHING)
# # # # ------------------------------------------------------------
# # # model.fit(
# # #     df_encoded,
# # #     estimator=BayesianEstimator,
# # #     prior_type="BDeu",
# # #     equivalent_sample_size=5
# # # )

# # # print("\n=== CPDs Learned ===")
# # # for cpd in model.get_cpds():
# # #     print(cpd)

# # # # ------------------------------------------------------------
# # # # 6. INFERENCE ENGINE
# # # # ------------------------------------------------------------
# # # infer = VariableElimination(model)

# # # def encode_evidence(evidence_dict):
# # #     encoded = {}
# # #     for k, v in evidence_dict.items():
# # #         if v not in mappings[k]:
# # #             raise ValueError(f"{v} not valid for {k}. Options: {list(mappings[k].keys())}")
# # #         encoded[k] = mappings[k][v]
# # #     return encoded

# # # # ------------------------------------------------------------
# # # # 7. EXAMPLE QUERY
# # # # ------------------------------------------------------------
# # # raw_evidence = {
# # #     "Fever": "No",
# # #     "Cough": "No",
# # #     "Fatigue": "Yes",
# # #     "Difficulty Breathing": "No",
# # #     "Age_binned": "senior",
# # #     "Gender": "Male"
# # # }


# # # evidence = encode_evidence(raw_evidence)

# # # result = infer.query(
# # #     variables=["Disease"],
# # #     evidence=evidence
# # # )
# # # # result is a pgmpy DiscreteFactor
# # # probs = result.values
# # # diseases = list(mappings["Disease"].keys())

# # # print("\n=== Diseases with probability > 0 ===")
# # # for i, p in enumerate(probs):
# # #     if p > 0:
# # #         print(f"{diseases[i]} : {p:.4f}")


# # # print("\n=== P(Disease | symptoms) ===")
# # # print(result)













# # import pandas as pd
# # from pgmpy.models import BayesianNetwork
# # from pgmpy.estimators import BayesianEstimator
# # from pgmpy.inference import VariableElimination

# # # ------------------------------------------------------------
# # # 1. LOAD DATA
# # # ------------------------------------------------------------
# # df = pd.read_csv(
# #     r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (6)\train_disease.csv"
# # ).dropna().copy()

# # # ------------------------------------------------------------
# # # 2. HANDLE AGE (OPTIONAL)
# # # ------------------------------------------------------------
# # if "Age" in df.columns:
# #     age_bins = [0, 22, 30, 60, 120]
# #     age_labels = ["child", "young_adult", "adult", "senior"]
# #     df["Age_binned"] = pd.cut(df["Age"], bins=age_bins, labels=age_labels)
# # else:
# #     df["Age_binned"] = "unknown"

# # # ------------------------------------------------------------
# # # 3. REQUIRED & OPTIONAL COLUMNS
# # # ------------------------------------------------------------
# # required_cols = ["Disease", "Fever", "Cough", "Fatigue", "Difficulty Breathing"]

# # optional_cols = [
# #     "Age_binned",
# #     "Gender",
# #     "Blood Pressure",
# #     "Cholesterol Level",
# #     "Outcome Variable"
# # ]

# # # keep only columns that exist
# # cols = [c for c in required_cols + optional_cols if c in df.columns]
# # df = df[cols]

# # # ------------------------------------------------------------
# # # 4. ENCODE CATEGORICAL VARIABLES
# # # ------------------------------------------------------------
# # mappings = {}
# # df_encoded = pd.DataFrame()

# # for col in df.columns:
# #     codes, uniques = pd.factorize(df[col].astype(str).str.strip())
# #     df_encoded[col] = codes
# #     mappings[col] = {k: v for v, k in enumerate(uniques)}

# # print("\n=== Category Mappings ===")
# # for k, v in mappings.items():
# #     print(k, v)

# # # ------------------------------------------------------------
# # # 5. BUILD ONTOLOGY-DRIVEN BN STRUCTURE (DYNAMIC)
# # # ------------------------------------------------------------
# # edges = [
# #     ("Fever", "Disease"),
# #     ("Cough", "Disease"),
# #     ("Fatigue", "Disease"),
# #     ("Difficulty Breathing", "Disease"),
# # ]

# # if "Age_binned" in df.columns:
# #     edges.append(("Age_binned", "Disease"))

# # if "Gender" in df.columns:
# #     edges.append(("Gender", "Disease"))

# # if "Outcome Variable" in df.columns:
# #     edges.append(("Disease", "Outcome Variable"))

# #     if "Blood Pressure" in df.columns:
# #         edges.append(("Blood Pressure", "Outcome Variable"))

# #     if "Cholesterol Level" in df.columns:
# #         edges.append(("Cholesterol Level", "Outcome Variable"))

# # model = BayesianNetwork(edges)

# # # ------------------------------------------------------------
# # # 6. TRAIN WITH BAYESIAN ESTIMATOR (SMOOTHING)
# # # ------------------------------------------------------------
# # model.fit(
# #     df_encoded,
# #     estimator=BayesianEstimator,
# #     prior_type="BDeu",
# #     equivalent_sample_size=5
# # )

# # print("\n=== CPDs Learned ===")
# # for cpd in model.get_cpds():
# #     print(cpd)

# # # ------------------------------------------------------------
# # # 7. INFERENCE ENGINE
# # # ------------------------------------------------------------
# # infer = VariableElimination(model)

# # def encode_evidence(evidence_dict):
# #     encoded = {}
# #     for k, v in evidence_dict.items():
# #         if k not in mappings:
# #             continue  # ignore unsupported evidence
# #         if v not in mappings[k]:
# #             raise ValueError(f"{v} not valid for {k}. Options: {list(mappings[k].keys())}")
# #         encoded[k] = mappings[k][v]
# #     return encoded

# # # ------------------------------------------------------------
# # # 8. EXAMPLE QUERY
# # # ------------------------------------------------------------
# # raw_evidence = {
# #     "Fever": "No",
# #     "Cough": "No",
# #     "Fatigue": "Yes",
# #     "Difficulty Breathing": "No",
# #     "Age_binned": "senior",
# #     "Gender": "Male"
# # }

# # evidence = encode_evidence(raw_evidence)

# # result = infer.query(variables=["Disease"], evidence=evidence)

# # # ------------------------------------------------------------
# # # 9. SHOW ONLY NON-ZERO PROBABILITIES (TOP-K)
# # # ------------------------------------------------------------
# # probs = result.values
# # diseases = list(mappings["Disease"].keys())

# # pairs = [(diseases[i], probs[i]) for i in range(len(probs)) if probs[i] > 0]
# # pairs.sort(key=lambda x: x[1], reverse=True)

# # print("\n=== Top Diseases ===")
# # for d, p in pairs[:10]:
# #     print(f"{d} : {p:.4f}")




















# # import pandas as pd
# # from pgmpy.models import BayesianNetwork
# # from pgmpy.estimators import BayesianEstimator
# # from pgmpy.inference import VariableElimination

# # # ------------------------------------------------------------
# # # 1. LOAD DATA
# # # ------------------------------------------------------------
# # df = pd.read_csv(
# #     r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (6)\train_disease.csv"
# # ).copy()

# # # ------------------------------------------------------------
# # # 2. HANDLE AGE (OPTIONAL)
# # # ------------------------------------------------------------
# # if "Age" in df.columns:
# #     age_bins = [0, 22, 30, 60, 120]
# #     age_labels = ["child", "young_adult", "adult", "senior"]
# #     df["Age_binned"] = pd.cut(df["Age"], bins=age_bins, labels=age_labels)
# # else:
# #     df["Age_binned"] = "unknown"

# # # ------------------------------------------------------------
# # # 3. SELECT AVAILABLE COLUMNS
# # # ------------------------------------------------------------
# # required_cols = ["Disease", "Fever", "Cough", "Fatigue", "Difficulty Breathing"]

# # optional_cols = [
# #     "Age_binned",
# #     "Gender",
# #     "Blood Pressure",
# #     "Cholesterol Level",
# #     "Outcome Variable"
# # ]

# # cols = [c for c in required_cols + optional_cols if c in df.columns]
# # df = df[cols].dropna().copy()

# # # ------------------------------------------------------------
# # # 4. ENCODE CATEGORICAL VARIABLES
# # # ------------------------------------------------------------
# # mappings = {}
# # df_encoded = pd.DataFrame()

# # for col in df.columns:
# #     codes, uniques = pd.factorize(df[col].astype(str).str.strip())
# #     df_encoded[col] = codes
# #     mappings[col] = {k: v for v, k in enumerate(uniques)}

# # # ------------------------------------------------------------
# # # 5. DROP CONSTANT / EMPTY COLUMNS (CRITICAL)
# # # ------------------------------------------------------------
# # valid_cols = []
# # for col in df_encoded.columns:
# #     if df_encoded[col].nunique() > 1:
# #         valid_cols.append(col)
# #     else:
# #         print(f"Dropping constant column: {col}")

# # df_encoded = df_encoded[valid_cols]
# # mappings = {k: v for k, v in mappings.items() if k in valid_cols}

# # print("\n=== Active Columns ===")
# # print(df_encoded.columns.tolist())

# # # ------------------------------------------------------------
# # # 6. BUILD ONTOLOGY-DRIVEN BN STRUCTURE (SAFE)
# # # ------------------------------------------------------------
# # edges = []

# # def safe_edge(a, b):
# #     if a in df_encoded.columns and b in df_encoded.columns:
# #         edges.append((a, b))

# # # Symptoms → Disease
# # safe_edge("Fever", "Disease")
# # safe_edge("Cough", "Disease")
# # safe_edge("Fatigue", "Disease")
# # safe_edge("Difficulty Breathing", "Disease")

# # # Demographics → Disease
# # safe_edge("Age_binned", "Disease")
# # safe_edge("Gender", "Disease")

# # # Disease → Outcome
# # safe_edge("Disease", "Outcome Variable")

# # # Health indicators → Outcome
# # safe_edge("Blood Pressure", "Outcome Variable")
# # safe_edge("Cholesterol Level", "Outcome Variable")

# # model = BayesianNetwork(edges)

# # print("\n=== BN Edges ===")
# # print(model.edges())

# # # ------------------------------------------------------------
# # # 7. TRAIN WITH BAYESIAN ESTIMATOR (SMOOTHING)
# # # ------------------------------------------------------------
# # model.fit(
# #     df_encoded,
# #     estimator=BayesianEstimator,
# #     prior_type="BDeu",
# #     equivalent_sample_size=5
# # )

# # # ------------------------------------------------------------
# # # 8. INFERENCE ENGINE
# # # ------------------------------------------------------------
# # infer = VariableElimination(model)

# # def encode_evidence(evidence_dict):
# #     encoded = {}
# #     for k, v in evidence_dict.items():
# #         if k not in mappings:
# #             continue
# #         if v not in mappings[k]:
# #             raise ValueError(f"{v} not valid for {k}. Options: {list(mappings[k].keys())}")
# #         encoded[k] = mappings[k][v]
# #     return encoded

# # # ------------------------------------------------------------
# # # 9. EXAMPLE QUERY
# # # ------------------------------------------------------------
# # raw_evidence = {
# #     "Fever": "No",
# #     "Cough": "No",
# #     "Fatigue": "Yes",
# #     "Difficulty Breathing": "No",
# #     "Age_binned": "senior",
# #     "Gender": "Male"
# # }

# # evidence = encode_evidence(raw_evidence)

# # result = infer.query(variables=["Disease"], evidence=evidence)

# # # ------------------------------------------------------------
# # # 10. SHOW TOP DISEASES (NON-ZERO)
# # # ------------------------------------------------------------
# # probs = result.values
# # diseases = list(mappings["Disease"].keys())

# # pairs = [(diseases[i], probs[i]) for i in range(len(probs)) if probs[i] > 0]
# # pairs.sort(key=lambda x: x[1], reverse=True)

# # print("\n=== Top Diseases ===")
# # for d, p in pairs[:10]:
# #     print(f"{d} : {p:.4f}")



















































# import pandas as pd
# from pgmpy.models import BayesianNetwork
# from pgmpy.estimators import BayesianEstimator
# from pgmpy.inference import VariableElimination

# # ------------------------------------------------------------
# # 1. LOAD DATA
# # ------------------------------------------------------------
# df = pd.read_csv(r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (7)\training.csv").copy()

# # ------------------------------------------------------------
# # 2. BASIC VALIDATION
# # ------------------------------------------------------------
# if "Disease" not in df.columns:
#     raise ValueError("Dataset MUST contain a 'Disease' column")

# # ------------------------------------------------------------
# # 3. HANDLE AGE (ONLY IF PRESENT)
# # ------------------------------------------------------------
# if "Age" in df.columns:
#     df["Age_binned"] = pd.cut(
#         df["Age"],
#         bins=[0, 22, 30, 60, 120],
#         labels=["child", "young_adult", "adult", "senior"]
#     )

# # ------------------------------------------------------------
# # 4. KEEP ONLY RELEVANT COLUMNS
# # ------------------------------------------------------------
# candidate_cols = [
#     "Disease",
#     "Fever",
#     "Cough",
#     "Fatigue",
#     "Difficulty Breathing",
#     "Age_binned",
#     "Gender",
#     "Blood Pressure",
#     "Cholesterol Level",
#     "Outcome Variable"
# ]

# cols = [c for c in candidate_cols if c in df.columns]
# df = df[cols].dropna().copy()

# # ------------------------------------------------------------
# # 5. ENCODE CATEGORICALS
# # ------------------------------------------------------------
# df_encoded = pd.DataFrame()
# mappings = {}

# for col in df.columns:
#     codes, uniques = pd.factorize(df[col].astype(str))
#     df_encoded[col] = codes
#     mappings[col] = {k: v for v, k in enumerate(uniques)}

# # ------------------------------------------------------------
# # 6. DROP CONSTANT COLUMNS (EXCEPT Disease)
# # ------------------------------------------------------------
# valid_cols = []
# for col in df_encoded.columns:
#     if col == "Disease":
#         valid_cols.append(col)
#     elif df_encoded[col].nunique() > 1:
#         valid_cols.append(col)
#     else:
#         print(f"Dropping constant column: {col}")

# df_encoded = df_encoded[valid_cols]
# mappings = {k: v for k, v in mappings.items() if k in valid_cols}

# # ------------------------------------------------------------
# # 7. FINAL SANITY CHECK
# # ------------------------------------------------------------
# if df_encoded["Disease"].nunique() < 2:
#     raise ValueError(
#         "Disease column has <2 unique values. BN cannot be trained."
#     )

# symptom_cols = [c for c in df_encoded.columns if c != "Disease"]

# if len(symptom_cols) == 0:
#     raise ValueError(
#         "No usable symptom columns found. Dataset is not suitable for BN."
#     )

# print("\nActive columns:", df_encoded.columns.tolist())

# # ------------------------------------------------------------
# # 8. BUILD BN STRUCTURE
# # ------------------------------------------------------------
# edges = [(c, "Disease") for c in symptom_cols if c != "Outcome Variable"]

# model = BayesianNetwork(edges)

# print("\nBN Edges:", model.edges())

# # ------------------------------------------------------------
# # 9. TRAIN
# # ------------------------------------------------------------
# model.fit(
#     df_encoded,
#     estimator=BayesianEstimator,
#     prior_type="BDeu",
#     equivalent_sample_size=5
# )

# # ------------------------------------------------------------
# # 10. INFERENCE
# # ------------------------------------------------------------
# infer = VariableElimination(model)

# def encode_evidence(evidence):
#     return {
#         k: mappings[k][v]
#         for k, v in evidence.items()
#         if k in mappings and v in mappings[k]
#     }

# raw_evidence = {
#     "Fever": "No",
#     "Cough": "No",
#     "Fatigue": "Yes",
#     "Difficulty Breathing": "No",
#     "Headache" : "No",
#     "Stomach Ache" : "Yes",
# }

# evidence = encode_evidence(raw_evidence)

# result = infer.query(["Disease"], evidence=evidence)

# # ------------------------------------------------------------
# # 11. SHOW RESULTS
# # ------------------------------------------------------------
# probs = result.values
# diseases = list(mappings["Disease"].keys())

# print("\nTop diseases:")
# for i in sorted(range(len(probs)), key=lambda x: probs[x], reverse=True)[:10]:
#     print(diseases[i], ":", round(probs[i], 4))



























































import pandas as pd
from pgmpy.models import BayesianNetwork
from pgmpy.estimators import BayesianEstimator
from pgmpy.inference import VariableElimination

# ------------------------------------------------------------
# 1. LOAD DATA
# ------------------------------------------------------------
df = pd.read_csv(
    r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (6)\train_disease.csv"
)

# ------------------------------------------------------------
# 2. IDENTIFY COLUMNS (ADAPTER LOGIC)
# ------------------------------------------------------------
disease_col = "prognosis"

# symptom columns = all binary columns except disease & medicine
symptom_cols = [
    c for c in df.columns
    if c not in [disease_col, "medicine"]
    and df[c].nunique() == 2
]

df = df[symptom_cols + [disease_col]].dropna()

print(f"Using {len(symptom_cols)} symptom columns")

# ------------------------------------------------------------
# 3. ENCODE CATEGORICALS (DISEASE ONLY)
# ------------------------------------------------------------
df_encoded = df.copy()

# encode disease labels
df_encoded[disease_col], disease_labels = pd.factorize(df_encoded[disease_col])
disease_map = {k: v for v, k in enumerate(disease_labels)}

print("\nDisease mapping:")
print(disease_map)

# ------------------------------------------------------------
# 4. BUILD BN STRUCTURE (SYMPTOMS → DISEASE)
# ------------------------------------------------------------
edges = [(s, disease_col) for s in symptom_cols]

model = BayesianNetwork(edges)

# ------------------------------------------------------------
# 5. TRAIN BN (WITH SMOOTHING)
# ------------------------------------------------------------
model.fit(
    df_encoded,
    estimator=BayesianEstimator,
    prior_type="BDeu",
    equivalent_sample_size=10
)

# ------------------------------------------------------------
# 6. INFERENCE
# ------------------------------------------------------------
infer = VariableElimination(model)

# ------------------------------------------------------------
# 7. EXAMPLE QUERY
# ------------------------------------------------------------
raw_evidence = {
    "itching": 1,
    "skin_rash": 1,
    "nodal_skin_eruptions": 1,
    "fatigue": 0,
    "high_fever": 0,
}

# keep only valid symptoms
evidence = {k: v for k, v in raw_evidence.items() if k in symptom_cols}

result = infer.query(
    variables=[disease_col],
    evidence=evidence
)

# ------------------------------------------------------------
# 8. SHOW TOP DISEASES
# ------------------------------------------------------------
probs = result.values
reverse_disease_map = {v: k for k, v in disease_map.items()}

pairs = [(reverse_disease_map[i], probs[i]) for i in range(len(probs))]
pairs.sort(key=lambda x: x[1], reverse=True)

print("\n=== Top Diseases ===")
for d, p in pairs[:10]:
    print(f"{d} : {p:.4f}")
