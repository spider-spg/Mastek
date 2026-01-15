import sys
import os
import pandas as pd
from collections import defaultdict
import numpy as np
import joblib

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

from controller.confidence import normalize_confidence, get_top_k
from scorer.predict import predict_proba

TEST_CSV = "data/output/test.csv"
LABEL_COL = "prognosis"
TOP_K = 3
CONF_THRESHOLD = 0.75

ARTIFACT_PATH = "scorer/artifacts/disease_model.pkl"


def evaluate():
    df = pd.read_csv(TEST_CSV)

    artifacts = joblib.load(ARTIFACT_PATH)
    n_features = artifacts["n_features"]  # 🔒 SINGLE SOURCE OF TRUTH

    # 🔒 USE ONLY THE FIRST n_features (exact training space)
    feature_cols = [
        c for c in df.columns
        if c != LABEL_COL
    ][:n_features]

    total = len(df)
    top1_correct = 0
    top3_correct = 0
    abstained = 0

    confidence_buckets = defaultdict(lambda: {"correct": 0, "total": 0})

    for _, row in df.iterrows():
        true_label = row[LABEL_COL]

        X = row[feature_cols].astype(float).values.tolist()

        raw_scores = predict_proba(X)
        confidence = normalize_confidence(raw_scores)

        topk = get_top_k(confidence, k=TOP_K)
        top1_label, top1_conf = topk[0]
        topk_labels = [d for d, _ in topk]

        if top1_conf < CONF_THRESHOLD:
            abstained += 1

        if top1_label == true_label:
            top1_correct += 1

        if true_label in topk_labels:
            top3_correct += 1

        bucket = round(top1_conf, 1)
        confidence_buckets[bucket]["total"] += 1
        if top1_label == true_label:
            confidence_buckets[bucket]["correct"] += 1

    print("\n=== Evaluation Results ===")
    print(f"Total samples: {total}")
    print(f"Top-1 Accuracy: {top1_correct / total:.3f}")
    print(f"Top-3 Accuracy: {top3_correct / total:.3f}")
    print(f"Abstention Rate: {abstained / total:.3f}")

    print("\nConfidence vs Accuracy:")
    for b in sorted(confidence_buckets):
        stats = confidence_buckets[b]
        acc = stats["correct"] / max(stats["total"], 1)
        print(f"  {b:.1f} → {acc:.3f} ({stats['total']} samples)")


if __name__ == "__main__":
    evaluate()
