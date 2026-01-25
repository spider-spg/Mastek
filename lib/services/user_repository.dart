import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  DocumentReference<Map<String, dynamic>> userDoc(String uid) => _users.doc(uid);

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUser(String uid) => userDoc(uid).snapshots();

  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(String uid) => userDoc(uid).get();

  /// Creates the user document the first time we see this Firebase user.
  ///
  /// This guarantees your app can always fetch profile fields from `users/{uid}`.
  Future<void> ensureUserDocument(User user, {String? phone, String? email}) async {
    final ref = userDoc(user.uid);
    final snap = await ref.get();

    final base = <String, dynamic>{
      'uid': user.uid,
      'email': email ?? user.email,
      'phone': phone ?? user.phoneNumber,
      'isAnonymous': user.isAnonymous,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (!snap.exists) {
      await ref.set(
        {
          ...base,
          'createdAt': FieldValue.serverTimestamp(),
          'profileCompleted': false,
        },
        SetOptions(merge: true),
      );
      return;
    }

    await ref.set(base, SetOptions(merge: true));
  }
}
