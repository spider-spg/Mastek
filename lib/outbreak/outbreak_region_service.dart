import 'package:shared_preferences/shared_preferences.dart';

class OutbreakRegionService {
  static const _key = 'outbreak.regionCode';

  Future<String?> getRegionCode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_key);
    if (v == null || v.trim().isEmpty) return null;
    return v.trim();
  }

  /// Stores only a coarse region code (e.g. first 3 digits of PIN).
  Future<void> setRegionFromPin(String pin) async {
    final digits = pin.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 3) {
      throw ArgumentError('PIN must have at least 3 digits');
    }
    final region = digits.substring(0, 3);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, region);
  }
}
