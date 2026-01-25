import '../services/firebase_bootstrap.dart';
import 'outbreak_region_service.dart';
import 'outbreak_storage.dart';

class OutbreakAnalyticsService {
  OutbreakAnalyticsService({OutbreakRegionService? regionService, OutbreakStorage? storage})
      : _regionService = regionService ?? OutbreakRegionService(),
        _storage = storage ?? OutbreakStorage();

  final OutbreakRegionService _regionService;
  final OutbreakStorage _storage;

  static int dayNumberUtc(DateTime dt) {
    final u = dt.toUtc();
    final utc = DateTime.utc(u.year, u.month, u.day);
    return utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  /// Reports aggregated counts for the current day.
  ///
  /// No PII is read or written. If Firebase isn't ready or region isn't set,
  /// this is a no-op.
  Future<void> reportToday({required List<String> symptomCodes}) async {
    if (!FirebaseBootstrap.isReady) return;
    if (symptomCodes.isEmpty) return;

    final region = await _regionService.getRegionCode();
    if (region == null) return;

    final day = dayNumberUtc(DateTime.now().toUtc());
    await _storage.incrementCounts(regionCode: region, day: day, symptomCodes: symptomCodes);
  }
}
