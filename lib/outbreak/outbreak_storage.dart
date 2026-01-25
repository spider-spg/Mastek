import 'package:cloud_firestore/cloud_firestore.dart';

/// Privacy-safe backend storage for outbreak analytics.
///
/// Stores ONLY aggregated counts per (regionCode, day). Never stores PII, chat text,
/// GPS, names, phone, email, or exact timestamps.
class OutbreakStorage {
  OutbreakStorage({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  // Data model:
  // outbreak_counts_v1/{region}/days/{day}
  // {
  //   region: "411", day: 20000,
  //   schemaVersion: 1,
  //   totalReports: 12,
  //   counts: { "S01": 4, "S02": 6 }
  // }

  DocumentReference<Map<String, dynamic>> dayDoc({required String regionCode, required int day}) {
    return _firestore.collection('outbreak_counts_v1').doc(regionCode).collection('days').doc(day.toString());
  }

  Future<Map<String, dynamic>?> getDay({required String regionCode, required int day}) async {
    final snap = await dayDoc(regionCode: regionCode, day: day).get();
    return snap.data();
  }

  Future<void> incrementCounts({
    required String regionCode,
    required int day,
    required List<String> symptomCodes,
  }) async {
    final ref = dayDoc(regionCode: regionCode, day: day);

    final updates = <String, dynamic>{
      'region': regionCode,
      'day': day,
      'schemaVersion': 1,
      'totalReports': FieldValue.increment(1),
    };

    for (final code in symptomCodes.toSet()) {
      updates['counts.$code'] = FieldValue.increment(1);
    }

    await ref.set(updates, SetOptions(merge: true));
  }
}
