import sys
import os
import pandas as pd
from sklearn.model_selection import train_test_split

PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, PROJECT_ROOT)

INPUT_CSV = "data/training.csv"
OUTPUT_DIR = "data/output"
LABEL_COL = "prognosis"
RANDOM_SEED = 42


def main():
    df = pd.read_csv(INPUT_CSV)

    if LABEL_COL not in df.columns:
        raise ValueError(f"Dataset must contain '{LABEL_COL}' column")

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    label_counts = df[LABEL_COL].value_counts()
    rare_labels = label_counts[label_counts < 2].index

    if len(rare_labels) > 0:
        print("Removing rare classes:", list(rare_labels))
        df = df[~df[LABEL_COL].isin(rare_labels)]

    train_df, temp_df = train_test_split(
        df,
        test_size=0.30,
        stratify=df[LABEL_COL],
        random_state=RANDOM_SEED
    )

    val_df, test_df = train_test_split(
        temp_df,
        test_size=0.50,
        stratify=temp_df[LABEL_COL],
        random_state=RANDOM_SEED
    )

    train_df.to_csv(f"{OUTPUT_DIR}/train.csv", index=False)
    val_df.to_csv(f"{OUTPUT_DIR}/val.csv", index=False)
    test_df.to_csv(f"{OUTPUT_DIR}/test.csv", index=False)

    print("Dataset split complete:")
    print(f"Train: {len(train_df)}")
    print(f"Val:   {len(val_df)}")
    print(f"Test:  {len(test_df)}")


if __name__ == "__main__":
    main()
