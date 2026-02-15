import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Single source for reading the current user's service tag from Firebase.
/// Used by HomeRepository, TransactionRepository, KwhRepository.
Future<String?> getServiceTagFromFirebase(
  FirebaseAuth auth,
  FirebaseDatabase database,
) async {
  try {
    final userId = auth.currentUser?.uid;
    if (userId == null) return null;

    final snapshot = await database.ref('userTable/$userId/serviceTag').get();
    if (snapshot.exists) {
      return snapshot.value as String?;
    }
    return null;
  } catch (e) {
    return null;
  }
}
