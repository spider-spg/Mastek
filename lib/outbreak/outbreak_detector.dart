import 'symptom_codes.dart';
import 'outbreak_models.dart';
import 'outbreak_storage.dart';

class _ClusterConfig {
  const _ClusterConfig({required this.title, required this.codes, required this.measures});

  final String title;
  final List<String> codes;
  final List<String> measures;
}

class OutbreakDetector {
  OutbreakDetector({OutbreakStorage? storage}) : _storage = storage ?? OutbreakStorage();

  final OutbreakStorage _storage;

  static int todayDayUtc() {
    final now = DateTime.now().toUtc();
    final utc = DateTime.utc(now.year, now.month, now.day);
    return utc.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
  }

  Future<List<OutbreakAlert>> detectForRegion({required String regionCode}) async {
    final today = todayDayUtc();

    // Rolling 7-day window: today and previous 6 days.
    final days = List<int>.generate(7, (i) => today - (6 - i));

    final dayData = <int, Map<String, dynamic>>{};
    for (final d in days) {
      final data = await _storage.getDay(regionCode: regionCode, day: d);
      if (data != null) {
        dayData[d] = data;
      }
    }

    Map<String, int> countsForDay(int d) {
      final raw = dayData[d]?['counts'];
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v is num) ? v.toInt() : 0));
      }
      return const <String, int>{};
    }

    final todayCounts = countsForDay(today);
    final baselineDays = [for (final d in days) if (d != today) d];

    double baselineForCodes(List<String> codes) {
      if (baselineDays.isEmpty) return 0;
      var sum = 0;
      for (final d in baselineDays) {
        final c = countsForDay(d);
        sum += codes.fold<int>(0, (acc, code) => acc + (c[code] ?? 0));
      }
      return sum / baselineDays.length;
    }

    int todayCountForCodes(List<String> codes) {
      return codes.fold<int>(0, (acc, code) => acc + (todayCounts[code] ?? 0));
    }

    OutbreakLevel classify({required int todayCount, required double baseline}) {
      // Avoid division noise for very low baselines.
      final b = baseline < 1 ? 1.0 : baseline;
      final ratio = todayCount / b;

      // Minimum activity threshold.
      if (todayCount < 5) return OutbreakLevel.none;

      if (ratio >= 3.0) return OutbreakLevel.high;
      if (ratio >= 2.0) return OutbreakLevel.warning;
      if (ratio >= 1.5) return OutbreakLevel.watch;
      return OutbreakLevel.none;
    }

    // Symptom clusters -> prevention measures.
    final clusters = <String, _ClusterConfig>{
      'respiratory': const _ClusterConfig(
        title: 'Respiratory symptoms rising',
        codes: [SymptomCodes.fever, SymptomCodes.cough, SymptomCodes.shortBreath, SymptomCodes.soreThroat],
        measures: [
          'Wear a mask in crowded places',
          'Improve ventilation indoors',
          'Wash hands frequently',
          'Stay home if unwell and avoid close contact',
        ],
      ),
      'gastro': const _ClusterConfig(
        title: 'Stomach illness signals rising',
        codes: [SymptomCodes.vomiting, SymptomCodes.diarrhea, SymptomCodes.fever],
        measures: [
          'Drink safe/boiled water',
          'Wash hands before eating and after toilet',
          'Avoid street food temporarily',
          'Seek care if dehydrated or symptoms persist',
        ],
      ),
      'rash_fever': const _ClusterConfig(
        title: 'Fever with rash signals rising',
        codes: [SymptomCodes.rash, SymptomCodes.fever],
        measures: [
          'Avoid close contact with symptomatic people',
          'Keep children home if fever/rash appears',
          'Consult a clinician for fever + rash',
        ],
      ),
    };

    final alerts = <OutbreakAlert>[];

    for (final entry in clusters.entries) {
      final clusterId = entry.key;
      final cfg = entry.value;

      final tc = todayCountForCodes(cfg.codes);
      final bl = baselineForCodes(cfg.codes);
      final level = classify(todayCount: tc, baseline: bl);
      if (level == OutbreakLevel.none) continue;

      final ratio = tc / (bl < 1 ? 1.0 : bl);
      final details = 'Today: $tc reports. Baseline: ${bl.toStringAsFixed(1)}. Increase: ${ratio.toStringAsFixed(1)}x.';

      alerts.add(
        OutbreakAlert(
          regionCode: regionCode,
          day: today,
          level: level,
          clusterId: clusterId,
          title: cfg.title,
          details: details,
          measures: cfg.measures,
          todayCount: tc,
          baseline: bl,
        ),
      );
    }

    // Sort highest severity first.
    alerts.sort((a, b) => b.level.index.compareTo(a.level.index));
    return alerts;
  }
}
