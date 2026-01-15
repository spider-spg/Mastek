# def apply_user_confirmation(state: dict, confirmed: dict) -> dict:
#     for k, v in confirmed.get("symptoms", {}).items():
#         if k in state["symptoms"]:
#             state["symptoms"][k] = float(v)

#     for k, v in confirmed.get("risk_factors", {}).items():
#         if k in state["risk_factors"]:
#             state["risk_factors"][k] = int(v)

#     state["context"]["symptom_count"] = sum(
#         1 for v in state["symptoms"].values() if v > 0
#     )

#     return state



def apply_user_confirmation(state: dict, confirmed: dict) -> dict:
    """
    confirmed format example:

    {
      "symptoms": {
        "fever": 1.0,
        "cough": 0.0
      },
      "risk_factors": {
        "smoker": 0.3,
        "alcohol_use": 0.7
      }
    }
    """

    # ---- Symptoms (0.0 – 1.0) ----
    for k, v in confirmed.get("symptoms", {}).items():
        if k in state["symptoms"]:
            state["symptoms"][k] = float(v)

    # ---- Risk factors (graded) ----
    for k, v in confirmed.get("risk_factors", {}).items():
        if k in state["risk_factors"]:
            state["risk_factors"][k] = float(v)

    # ---- Recompute context ----
    state["context"]["symptom_count"] = sum(
        1 for v in state["symptoms"].values() if v > 0
    )

    return state
