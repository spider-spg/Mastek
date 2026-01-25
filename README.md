# Symptom Checker (Flutter)

Minimal multilingual voice & text symptom-checker chatbot scaffold.

Features included in this scaffold:
- Text + speech input using `speech_to_text`.
- Translation to English for analysis using `translator` package.
- TTS for replies using `flutter_tts`.
- Simple rule-based triage with urgency (Low / Medium / High) and confidence score.

How to run

1. Install Flutter SDK and ensure `flutter` is on PATH.
2. From the project folder run:

```bash
flutter pub get
flutter run
```

Notes
- This is a starting scaffold. Replace the rule-based `lib/symptom_analyzer.dart` with an ML/NLP backend or API for higher accuracy.
- For production, add proper localization, privacy notices, and clinical validation before deployment.
