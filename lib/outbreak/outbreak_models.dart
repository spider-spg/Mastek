enum OutbreakLevel { none, watch, warning, high }

class OutbreakAlert {
  OutbreakAlert({
    required this.regionCode,
    required this.day,
    required this.level,
    required this.clusterId,
    required this.title,
    required this.details,
    required this.measures,
    required this.todayCount,
    required this.baseline,
  });

  final String regionCode;
  /// Day bucket: UTC days since epoch.
  final int day;
  final OutbreakLevel level;
  /// Stable identifier for the symptom cluster (e.g. "respiratory").
  final String clusterId;
  final String title;
  final String details;
  final List<String> measures;

  final int todayCount;
  final double baseline;
}
