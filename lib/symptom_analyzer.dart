enum Urgency { low, medium, high }

class AnalysisResult {
  final Urgency urgency;
  final double confidence; // 0..1
  final String explanation; // human-readable reasons
  final String summary; // short summary for TTS
  final List<String> matchedKeys; // analyzer symptom groups (no raw user text)

  AnalysisResult({
    required this.urgency,
    required this.confidence,
    required this.explanation,
    required this.summary,
    required this.matchedKeys,
  });
}

class SymptomAnalyzer {
  // Simple keyword-based rules. Extendable to use ML/NLP backend.
  static final Map<String, List<String>> _rules = {
    'fever': ['fever', 'temperature', 'hot', 'chills'],
    'cough': ['cough', 'dry cough', 'wet cough'],
    'throat': ['sore throat', 'throat pain', 'scratchy throat'],
    'breath': ['shortness of breath', 'breathless', 'dyspnea', 'spo2', 'spO2'],
    'chest': ['chest pain', 'pressure in chest', 'heart'],
    'bleed': ['bleed', 'blood', 'vomit blood'],
    'vomit': ['vomit', 'vomiting', 'nausea'],
    'diarrhea': ['diarrhea', 'loose motion', 'loose motions'],
    'rash': ['rash', 'red spots', 'skin rash'],
    'severe': ['unconscious', 'collapse', 'seizure'],
    'fatigue': ['fatigue', 'tired', 'weakness'],
  };

  static AnalysisResult analyze(String text) {
    final t = text.toLowerCase();
    final matches = <String>[];
    for (final entry in _rules.entries) {
      for (final kw in entry.value) {
        if (t.contains(kw)) {
          matches.add(entry.key);
          break;
        }
      }
    }

    // Determine urgency with simple heuristic
    Urgency urgency = Urgency.low;
    final reasons = <String>[];

    if (matches.contains('severe')) {
      urgency = Urgency.high;
      reasons.add('Severe event keywords detected');
    }
    if (matches.contains('breath') || matches.contains('chest') || matches.contains('bleed')) {
      urgency = Urgency.high;
      reasons.add('Respiratory / chest / bleeding symptoms');
    }
    if (matches.contains('fever') && matches.contains('fatigue')) {
      if (urgency != Urgency.high) urgency = Urgency.medium;
      reasons.add('Fever + fatigue: possible infection');
    }
    if (matches.isEmpty) {
      reasons.add('No clear rule-matched symptoms');
    }

    // Confidence heuristic: fraction of distinct matched rule groups
    final confidence = (matches.toSet().length / (_rules.length)).clamp(0.0, 1.0);

    final explanation = 'Matched: ${matches.join(', ')}. Reasons: ${reasons.join('; ')}.';
    final summary = _buildSummary(urgency, confidence, matches);

    return AnalysisResult(
      urgency: urgency,
      confidence: confidence,
      explanation: explanation,
      summary: summary,
      matchedKeys: matches.toSet().toList(growable: false),
    );
  }

  static String _buildSummary(Urgency u, double conf, List<String> matches) {
    final urgencyText = u == Urgency.high ? 'High urgency' : (u == Urgency.medium ? 'Medium urgency' : 'Low urgency');
    final confPct = (conf * 100).toStringAsFixed(0);
    final matchText = matches.isEmpty ? 'no specific symptoms recognized' : matches.join(', ');
    return '$urgencyText with $confPct percent confidence. Recognized: $matchText.';
  }
}
