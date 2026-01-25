/// Predefined symptom codes for privacy-safe aggregation.
///
/// Only these codes are ever written to outbreak analytics storage.
class SymptomCodes {
  // Core examples (extend as needed).
  static const fever = 'S01';
  static const cough = 'S02';
  static const soreThroat = 'S03';
  static const shortBreath = 'S04';
  static const chestPain = 'S05';
  static const vomiting = 'S06';
  static const diarrhea = 'S07';
  static const rash = 'S08';
  static const fatigue = 'S09';
  static const bleeding = 'S10';

  static const Map<String, String> analyzerKeyToCode = {
    // Keys coming from SymptomAnalyzer
    'fever': fever,
    'cough': cough,
    'throat': soreThroat,
    'breath': shortBreath,
    'chest': chestPain,
    'vomit': vomiting,
    'diarrhea': diarrhea,
    'rash': rash,
    'fatigue': fatigue,
    'bleed': bleeding,
  };

  static List<String> toCodes(Iterable<String> analyzerKeys) {
    final out = <String>[];
    for (final key in analyzerKeys) {
      final code = analyzerKeyToCode[key];
      if (code != null) out.add(code);
    }
    return out.toSet().toList(growable: false);
  }
}
