import pandas as pd

df = pd.read_csv(r"C:\Users\dhruv\OneDrive\Desktop\Symptomate😂\archive (7)\training.csv")
print(df.shape)
print(df.columns.tolist())
print(df.head(3))
print(df.nunique())
