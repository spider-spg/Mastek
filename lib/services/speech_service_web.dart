class RecognitionResult {
  final String recognizedWords;
  final String? localeId;
  final bool finalResult;

  RecognitionResult(this.recognizedWords, this.localeId, this.finalResult);
}

class SpeechService {
  // Web stub: speech not supported in this simple scaffold.
  Future<bool> initialize() async => false;

  void listen(void Function(RecognitionResult) onResult) {
    // No-op on web. Could be extended to use Web Speech API via JS interop.
  }

  Future<void> stop() async {}
}
