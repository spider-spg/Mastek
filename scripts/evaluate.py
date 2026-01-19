import sys
from pathlib import Path
import pandas as pd
import numpy as np
import joblib
from sklearn.metrics import confusion_matrix

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from scorer.predict import predict_proba
from controller.confidence import normalize_confidence

DATA_PATH = "data/training.csv"  # change to training.csv if needed
LABEL_COL = "prognosis"
CONF_THRESHOLD = 0.40   # demo-tuned


def main():
    df = pd.read_csv(DATA_PATH)

    artifacts = joblib.load("scorer/artifacts/disease_model.pkl")
    feature_order = artifacts["feature_order"]
    diseases = artifacts["diseases"]

    y_true = []
    y_pred = []
    abstained = 0

    for _, row in df.iterrows():
        true_label = row[LABEL_COL]
        y_true.append(true_label)

        X = [row.get(f, 0) for f in feature_order]

        raw = predict_proba(X)
        conf = normalize_confidence(raw)

        topk = sorted(conf.items(), key=lambda x: x[1], reverse=True)
        top1, top1_conf = topk[0]

        if top1_conf < CONF_THRESHOLD:
            abstained += 1
            y_pred.append("ABSTAIN")
        else:
            y_pred.append(top1)

    total = len(y_true)

    # accuracy only on non-abstained
    filtered = [(t, p) for t, p in zip(y_true, y_pred) if p != "ABSTAIN"]
    correct = sum(t == p for t, p in filtered)
    evaluated = len(filtered)

    top1_acc = correct / max(evaluated, 1)
    abstain_rate = abstained / total

    print("\n=== Phase B Evaluation ===")
    print(f"Total samples: {total}")
    print(f"Evaluated (non-abstained): {evaluated}")
    print(f"Top-1 Accuracy (non-abstained): {top1_acc:.3f}")
    print(f"Abstention Rate: {abstain_rate:.3f}")

    # confusion matrix (non-abstained only)
    if evaluated > 0:
        labels = sorted(set(y_true))
        cm = confusion_matrix(
            [t for t, p in filtered],
            [p for t, p in filtered],
            labels=labels
        )

        print("\nConfusion Matrix (rows=true, cols=pred):")
        print("Labels:", labels)
        print(cm)


if __name__ == "__main__":
    main()
