import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
import joblib

# Load data
df = pd.read_csv(r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (7)\training.csv")

X = df.drop(["prognosis","medicine"], axis=1)
y = df["prognosis"]

le = LabelEncoder()
y = le.fit_transform(y)

# Train
model = RandomForestClassifier(
    n_estimators=200,
    random_state=42,
    n_jobs=-1
)

model.fit(X, y)
# after X is created
feature_order = list(X.columns)

joblib.dump(model, "disease_model.pkl")
joblib.dump(feature_order, "feature_order.pkl")
joblib.dump(le, "label_encoder.pkl")

print("Model + feature order saved")

# Save
joblib.dump(model, "disease_model.pkl")
print("Model trained & saved")




