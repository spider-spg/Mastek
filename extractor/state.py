def merge_states(old_state: dict, new_state: dict) -> dict:
    # ---- Symptoms ----
    for k in old_state["symptoms"]:
        old_state["symptoms"][k] = max(
            old_state["symptoms"][k],
            new_state["symptoms"][k]
        )

    # ---- Risk factors ----
    for k in old_state["risk_factors"]:
        if k == "age_group":
            if new_state["risk_factors"][k] is not None:
                old_state["risk_factors"][k] = new_state["risk_factors"][k]
        else:
            old_state["risk_factors"][k] = max(
                old_state["risk_factors"][k],
                new_state["risk_factors"][k]
            )

    # ---- Context ----
    old_state["context"]["symptom_count"] = sum(
        1 for v in old_state["symptoms"].values() if v > 0
    )

    return old_state
