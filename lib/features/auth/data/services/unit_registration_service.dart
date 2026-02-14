import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Result of verifying a unit registration token.
sealed class VerifyTokenResult {}

class VerifyTokenSuccess extends VerifyTokenResult {
  final String serviceTag;
  VerifyTokenSuccess(this.serviceTag);
}

class VerifyTokenNotFound extends VerifyTokenResult {}

class VerifyTokenInvalidUnit extends VerifyTokenResult {
  /// Unit found but serviceTag does not start with MNT (not valid for cyclist signup).
  VerifyTokenInvalidUnit();
}

class VerifyTokenInvalidFormat extends VerifyTokenResult {}

class VerifyTokenAlreadyUsed extends VerifyTokenResult {
  /// Token is valid but its serviceTag is already in userTable (account exists).
  VerifyTokenAlreadyUsed();
}

/// Verifies a unit registration token (e.g. from QR scan) against Firebase
/// and returns the associated service tag if valid.
///
/// Firebase structure: [unitRegistration] has children keyed by push ID,
/// each with [token], [serviceTag], [dateCreated]. We read the node and
/// find the child whose [token] matches; [serviceTag] must start with "MNT"
/// for cyclist signup. No index required.
class UnitRegistrationService {
  UnitRegistrationService._();
  static final UnitRegistrationService instance = UnitRegistrationService._();

  final DatabaseReference _ref = FirebaseDatabase.instance.ref('unitRegistration');
  final DatabaseReference _userTableRef = FirebaseDatabase.instance.ref('userTable');

  /// UUID format expected for token (e.g. e4eb7820-ca33-4690-b258-a6a68eea3422).
  static final RegExp _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Verifies [token] and returns a [VerifyTokenResult].
  /// - Scanned value must be in UUID format.
  /// - A record with that [token] must exist under [unitRegistration].
  /// - The record's [serviceTag] must start with "MNT" for cyclist signup.
  Future<VerifyTokenResult> verifyTokenAndGetServiceTag(String token) async {
    final trimmed = token.trim();
    if (trimmed.isEmpty) return VerifyTokenInvalidFormat();

    if (!_uuidPattern.hasMatch(trimmed)) {
      return VerifyTokenInvalidFormat();
    }

    debugPrint('UnitRegistrationService: Verifying token: $trimmed');

    final snapshot = await _ref.get();

    if (!snapshot.exists || snapshot.value == null) {
      debugPrint('UnitRegistrationService: No unitRegistration data or empty.');
      return VerifyTokenNotFound();
    }

    final value = snapshot.value;
    if (value is! Map) {
      debugPrint('UnitRegistrationService: snapshot.value is not a Map.');
      return VerifyTokenNotFound();
    }

    for (final entry in value.entries) {
      final raw = entry.value;
      if (raw is! Map) continue;
      final data = Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
      final childToken = data['token']?.toString().trim();
      final serviceTag = data['serviceTag']?.toString().trim();

      if (childToken != trimmed) continue;

      if (serviceTag == null || serviceTag.isEmpty) {
        debugPrint('UnitRegistrationService: Match found but serviceTag missing.');
        return VerifyTokenNotFound();
      }
      if (!serviceTag.toUpperCase().startsWith('MNT')) {
        debugPrint('UnitRegistrationService: Match found but serviceTag does not start with MNT: $serviceTag');
        return VerifyTokenInvalidUnit();
      }
      // Cross-reference: token is already used if this serviceTag exists in userTable
      final used = await _isServiceTagUsedInUserTable(serviceTag);
      if (used) {
        debugPrint('UnitRegistrationService: serviceTag already used in userTable: $serviceTag');
        return VerifyTokenAlreadyUsed();
      }
      debugPrint('UnitRegistrationService: Match found, serviceTag: $serviceTag');
      return VerifyTokenSuccess(serviceTag);
    }

    debugPrint('UnitRegistrationService: No child with matching token.');
    return VerifyTokenNotFound();
  }

  /// Returns true if any user in userTable has this [serviceTag].
  Future<bool> _isServiceTagUsedInUserTable(String serviceTag) async {
    try {
      final snapshot = await _userTableRef.get();
      if (!snapshot.exists || snapshot.value == null) return false;
      final value = snapshot.value;
      if (value is! Map) return false;
      for (final entry in value.entries) {
        final raw = entry.value;
        if (raw is! Map) continue;
        final data = Map<String, dynamic>.from(raw.map((k, v) => MapEntry(k.toString(), v)));
        final existingTag = data['serviceTag']?.toString().trim();
        if (existingTag == serviceTag) return true;
      }
      return false;
    } catch (e) {
      debugPrint('UnitRegistrationService: Error checking userTable: $e');
      return false;
    }
  }
}
