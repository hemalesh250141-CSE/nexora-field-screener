import 'dart:async';
import '../models/user_session.dart';
import '../core/storage/database_helper.dart';
import '../core/storage/encrypted_storage_service.dart';

/// NEXORA Authentication & RBAC Service
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  UserSession? _currentSession;
  UserSession? get currentSession => _currentSession;

  bool get isAuthenticated => _currentSession != null;

  // Pre-configured authorized accounts for field testing
  static final Map<String, Map<String, dynamic>> _authorizedAccounts = {
    'BADGE-104': {
      'password': 'Password@123',
      'fullName': 'Officer K. Sharma',
      'role': 'OFFICER',
      'stationId': 'ZONAL-NARCOTICS-BUREAU-04',
    },
    'SUPER-201': {
      'password': 'Super@123',
      'fullName': 'Supervisor R. Menon',
      'role': 'SUPERVISOR',
      'stationId': 'CENTRAL-FORENSICS-HQ',
    },
    'ADMIN-001': {
      'password': 'Admin@123',
      'fullName': 'Forensic Director V. Rao',
      'role': 'ADMIN',
      'stationId': 'NATIONAL-STANDARDS-HQ',
    },
  };

  /// Authenticates with Badge ID and password
  Future<UserSession> login({
    required String badgeId,
    required String password,
  }) async {
    // 250ms authentication delay
    await Future.delayed(const Duration(milliseconds: 250));

    final normalizedBadge = badgeId.trim().toUpperCase();
    final account = _authorizedAccounts[normalizedBadge];

    if (account == null || account['password'] != password) {
      await DatabaseHelper().logAuditEvent(
        actorId: normalizedBadge,
        eventType: 'LOGIN_FAILURE',
        metadata: {'reason': 'Invalid badge or credentials'},
      );
      throw Exception('Authentication Failed: Invalid Badge ID or Password.');
    }

    final session = UserSession(
      badgeId: normalizedBadge,
      fullName: account['fullName'] as String,
      role: account['role'] as String,
      token: 'NEXORA_JWT_${DateTime.now().millisecondsSinceEpoch}_${account['role']}',
      stationId: account['stationId'] as String,
      authenticatedAt: DateTime.now().toUtc(),
    );

    _currentSession = session;

    // Securely cache token
    await EncryptedStorageService().writeSecure('auth_token', session.token);
    await EncryptedStorageService().writeSecure('user_role', session.role);
    await EncryptedStorageService().writeSecure('badge_id', session.badgeId);

    // Audit log
    await DatabaseHelper().logAuditEvent(
      actorId: normalizedBadge,
      eventType: 'LOGIN_SUCCESS',
      metadata: {'role': session.role, 'station': session.stationId},
    );

    return session;
  }

  /// Logs out officer and purges active tokens
  Future<void> logout() async {
    if (_currentSession != null) {
      await DatabaseHelper().logAuditEvent(
        actorId: _currentSession!.badgeId,
        eventType: 'LOGOUT',
        metadata: {'role': _currentSession!.role},
      );
    }
    _currentSession = null;
    await EncryptedStorageService().clearAll();
  }
}
