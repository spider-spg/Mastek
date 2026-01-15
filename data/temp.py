import numpy as np

d1 = np.load("data/output/ml_dataset_with_rules.npz")
d2 = np.load("data/output/ml_dataset_without_rules.npz")

print(d1["X"].shape, d1["y"].shape)
print(d2["X"].shape, d2["y"].shape)
