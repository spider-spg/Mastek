import 'package:speech_to_text/speech_to_text.dart' as stt;

class RecognitionResult {
  final String recognizedWords;
  final String? localeId;
  final bool finalResult;

  RecognitionResult(this.recognizedWords, this.localeId, this.finalResult);
}

class SpeechService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  Future<bool> initialize() => _speech.initialize();

  void listen(void Function(RecognitionResult) onResult) {
    _speech.listen(onResult: (val) {
      // Some versions of `speech_to_text` do not expose `localeId` on the
      // recognition result. Use null for locale when it's unavailable.
      final r = RecognitionResult(val.recognizedWords, null, val.finalResult);
      onResult(r);
    });
  }

  Future<void> stop() => _speech.stop();
}
