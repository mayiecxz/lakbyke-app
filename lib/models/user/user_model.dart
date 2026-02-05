/// User model representing account information (aligned with userTable schema)
class UserModel {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String role;
  final String? userRole;
  final String serviceTag;
  final int? createdAt;
  final String? accountStatus;
  final String? dateUpdated;

  UserModel({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.role,
    this.userRole,
    required this.serviceTag,
    this.createdAt,
    this.accountStatus,
    this.dateUpdated,
  });

  /// Create UserModel from Firebase Realtime Database snapshot (userTable)
  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      middleName: data['middleName'],
      role: data['role'] ?? data['userRole'] ?? '',
      userRole: data['userRole'],
      serviceTag: data['serviceTag'] ?? '',
      createdAt: data['createdAt'] is int
          ? data['createdAt'] as int
          : (data['createdAt'] is num ? (data['createdAt'] as num).toInt() : null),
      accountStatus: data['accountStatus'] as String?,
      dateUpdated: data['dateUpdated'] as String?,
    );
  }

  /// Convert UserModel to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      if (middleName != null) 'middleName': middleName,
      'role': role,
      if (userRole != null) 'userRole': userRole,
      'serviceTag': serviceTag,
      if (createdAt != null) 'createdAt': createdAt,
      if (accountStatus != null) 'accountStatus': accountStatus,
      if (dateUpdated != null) 'dateUpdated': dateUpdated,
    };
  }

  /// Get full display name
  String get displayName {
    String name = firstName;
    if (middleName != null && middleName!.isNotEmpty) {
      name += ' $middleName';
    }
    if (lastName.isNotEmpty) {
      name += ' $lastName';
    }
    return name.trim().isEmpty ? 'User' : name.trim();
  }

  /// Get role for display (prefers userRole over role)
  String get displayRole {
    return userRole ?? role;
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? middleName,
    String? role,
    String? userRole,
    String? serviceTag,
    int? createdAt,
    String? accountStatus,
    String? dateUpdated,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      role: role ?? this.role,
      userRole: userRole ?? this.userRole,
      serviceTag: serviceTag ?? this.serviceTag,
      createdAt: createdAt ?? this.createdAt,
      accountStatus: accountStatus ?? this.accountStatus,
      dateUpdated: dateUpdated ?? this.dateUpdated,
    );
  }
}
