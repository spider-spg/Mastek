# data/feature_assembler.py

import numpy as np


def assemble_features(feature_dict: dict, use_rule_priors: bool) -> np.ndarray:
    """
    Combines feature channels into a flat ML vector.
    """

    X = []
    X.extend(feature_dict["symptoms"])
    X.extend(feature_dict["meta"])

    if use_rule_priors:
        X.extend(feature_dict["rule_priors"])

    return np.asarray(X, dtype=np.float32)
