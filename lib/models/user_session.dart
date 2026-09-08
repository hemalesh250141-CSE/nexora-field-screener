/// Authenticated User & RBAC Session Model
class UserSession {
  final String badgeId;
  final String fullName;
  final String role; // 'OFFICER', 'SUPERVISOR', 'ADMIN'
  final String token;
  final String stationId;
  final DateTime authenticatedAt;

  const UserSession({
    required this.badgeId,
    required this.fullName,
    required this.role,
    required this.token,
    required this.stationId,
    required this.authenticatedAt,
  });

  bool get isOfficer => role == 'OFFICER';
  bool get isSupervisor => role == 'SUPERVISOR';
  bool get isAdmin => role == 'ADMIN';

  bool get canCreateFieldTest => isOfficer || isAdmin;
  bool get canReviewAllEvidence => isSupervisor || isAdmin;
  bool get canManageReferenceProfiles => isAdmin;
  bool get canViewAuditTrail => isSupervisor || isAdmin;

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'fullName': fullName,
      'role': role,
      'token': token,
      'stationId': stationId,
      'authenticatedAt': authenticatedAt.toIso8601String(),
    };
  }

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      badgeId: map['badgeId'] as String,
      fullName: map['fullName'] as String,
      role: map['role'] as String,
      token: map['token'] as String,
      stationId: map['stationId'] as String,
      authenticatedAt: DateTime.parse(map['authenticatedAt'] as String),
    );
  }
}
