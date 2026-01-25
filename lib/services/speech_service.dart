// Conditional export: uses mobile implementation when not running on web.
export 'speech_service_mobile.dart' if (dart.library.html) 'speech_service_web.dart';
