import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> speak(String text) => _tts.speak(text);

  Future<void> stop() => _tts.stop();
}
