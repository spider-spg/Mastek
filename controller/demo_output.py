def demo_decision(confidence_dict, k=3):
    topk = sorted(confidence_dict.items(), key=lambda x: x[1], reverse=True)[:k]
    top1_disease, top1_conf = topk[0]

    if top1_conf < 0.25:
        return {
            "mode": "suggestion",
            "topk": topk,
            "note": "Low confidence — showing best matches"
        }

    return {
        "mode": "prediction",
        "top1": top1_disease,
        "confidence": top1_conf,
        "topk": topk
    }
