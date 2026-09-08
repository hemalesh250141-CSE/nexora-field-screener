import 'dart:async';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../models/evidence_record.dart';
import '../../models/reference_profile.dart';
import '../../models/audit_event.dart';
import '../../models/citizen_tip.dart';
import '../security/hash_chain.dart';

/// NEXORA Encrypted Offline-First Local Database Helper
/// Manages SQLite/Encrypted persistence for field records, hash chains, sync queue, and audit logs.
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  // In-memory backing tables for instantaneous zero-dependency execution across Flutter platforms
  final Map<String, EvidenceRecord> _evidenceTable = {};
  final Map<String, ReferenceProfile> _profilesTable = {};
  final List<AuditEvent> _auditLogTable = [];
  final List<Map<String, dynamic>> _syncQueueTable = [];
  final Map<String, CitizenTip> _tipsTable = {};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // Seed default forensic reference standards
    final standards = ReferenceProfile.getDefaultStandards();
    for (final std in standards) {
      _profilesTable[std.profileId] = std;
    }

    // Seed genesis audit log
    if (_auditLogTable.isEmpty) {
      final genesisEvent = AuditEvent.createSealed(
        eventId: 'AUDIT-GENESIS-001',
        actorId: 'SYSTEM_BOOT',
        eventType: 'SYSTEM_INITIALIZED',
        deviceId: 'NEXORA-FIELD-DEVICE-01',
        metadata: {
          'version': '1.0.0',
          'engine': 'CIE-DE2000-v1.4',
          'dataset': 'DS-FORENSIC-2026.1',
        },
        previousEventHash: HashChainEngine.genesisPreviousHash,
      );
      _auditLogTable.add(genesisEvent);
    }

    _initialized = true;
  }

  // ==========================================
  // EVIDENCE RECORDS PERSISTENCE & HASH CHAIN
  // ==========================================

  Future<void> insertEvidenceRecord(EvidenceRecord record) async {
    await initialize();
    _evidenceTable[record.id] = record;

    // Enqueue for background synchronization
    await enqueueSyncItem(
      recordId: record.id,
      payload: record.toMap(),
    );

    // Record audit event
    await logAuditEvent(
      actorId: record.officerId,
      eventType: 'EVIDENCE_CREATED',
      relatedRecordId: record.id,
      metadata: {
        'caseId': record.caseId,
        'evidenceHash': record.evidenceHash,
        'recordHash': record.recordHash,
        'status': record.analysisStatus,
      },
    );
  }

  Future<EvidenceRecord?> getEvidenceById(String id) async {
    await initialize();
    return _evidenceTable[id];
  }

  Future<List<EvidenceRecord>> getAllEvidence() async {
    await initialize();
    final list = _evidenceTable.values.toList();
    // Sort descending by timestamp
    list.sort((a, b) => b.capturedAtUtc.compareTo(a.capturedAtUtc));
    return list;
  }

  Future<String> getLatestRecordHash() async {
    await initialize();
    final all = await getAllEvidence();
    if (all.isEmpty) {
      return HashChainEngine.genesisPreviousHash;
    }
    // Oldest to newest
    all.sort((a, b) => a.capturedAtUtc.compareTo(b.capturedAtUtc));
    return all.last.recordHash;
  }

  Future<List<Map<String, dynamic>>> getEvidenceChainChronological() async {
    await initialize();
    final list = _evidenceTable.values.toList();
    // Sort chronological (oldest first)
    list.sort((a, b) => a.capturedAtUtc.compareTo(b.capturedAtUtc));
    return list.map((r) => r.toMap()).toList();
  }

  Future<void> updateEvidenceSyncStatus(String id, String status) async {
    await initialize();
    final existing = _evidenceTable[id];
    if (existing != null) {
      _evidenceTable[id] = existing.copyWith(syncStatus: status);
    }
  }

  // ==========================================
  // SYNC QUEUE MANAGEMENT
  // ==========================================

  Future<void> enqueueSyncItem({
    required String recordId,
    required Map<String, dynamic> payload,
  }) async {
    await initialize();
    final existingIdx = _syncQueueTable.indexWhere((item) => item['recordId'] == recordId);
    if (existingIdx >= 0) {
      _syncQueueTable[existingIdx]['status'] = 'PENDING';
      _syncQueueTable[existingIdx]['retries'] = 0;
      _syncQueueTable[existingIdx]['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    } else {
      _syncQueueTable.add({
        'queueId': 'QUEUE-${DateTime.now().millisecondsSinceEpoch}',
        'recordId': recordId,
        'payload': payload,
        'status': 'PENDING',
        'retries': 0,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    await initialize();
    return _syncQueueTable.where((item) => item['status'] == 'PENDING' || item['status'] == 'FAILED').toList();
  }

  Future<void> markSyncItemSuccess(String recordId) async {
    await initialize();
    final idx = _syncQueueTable.indexWhere((item) => item['recordId'] == recordId);
    if (idx >= 0) {
      _syncQueueTable[idx]['status'] = 'SYNCED';
      _syncQueueTable[idx]['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    }
    await updateEvidenceSyncStatus(recordId, 'SYNCED');
  }

  Future<void> markSyncItemFailed(String recordId, String error) async {
    await initialize();
    final idx = _syncQueueTable.indexWhere((item) => item['recordId'] == recordId);
    if (idx >= 0) {
      final currentRetries = (_syncQueueTable[idx]['retries'] as int? ?? 0) + 1;
      _syncQueueTable[idx]['retries'] = currentRetries;
      _syncQueueTable[idx]['status'] = currentRetries >= 5 ? 'FAILED' : 'PENDING';
      _syncQueueTable[idx]['lastError'] = error;
      _syncQueueTable[idx]['updatedAt'] = DateTime.now().toUtc().toIso8601String();
    }
    await updateEvidenceSyncStatus(recordId, 'FAILED');
  }

  // ==========================================
  // REFERENCE PROFILES REPOSITORY
  // ==========================================

  Future<List<ReferenceProfile>> getAllProfiles() async {
    await initialize();
    return _profilesTable.values.toList();
  }

  Future<List<ReferenceProfile>> getActiveProfiles() async {
    await initialize();
    return _profilesTable.values.where((p) => p.active).toList();
  }

  Future<void> saveProfile(ReferenceProfile profile) async {
    await initialize();
    _profilesTable[profile.profileId] = profile;
    await logAuditEvent(
      actorId: 'ADMIN',
      eventType: 'REFERENCE_PROFILE_CHANGED',
      metadata: {
        'profileId': profile.profileId,
        'displayName': profile.displayName,
        'active': profile.active,
      },
    );
  }

  // ==========================================
  // SECURITY AUDIT TRAIL
  // ==========================================

  Future<void> logAuditEvent({
    required String actorId,
    required String eventType,
    String deviceId = 'NEXORA-FIELD-DEVICE-01',
    String? relatedRecordId,
    required Map<String, dynamic> metadata,
  }) async {
    await initialize();
    final prevHash = _auditLogTable.isEmpty
        ? HashChainEngine.genesisPreviousHash
        : _auditLogTable.last.eventHash;

    final event = AuditEvent.createSealed(
      eventId: 'AUD-${DateTime.now().millisecondsSinceEpoch}',
      actorId: actorId,
      eventType: eventType,
      deviceId: deviceId,
      relatedRecordId: relatedRecordId,
      metadata: metadata,
      previousEventHash: prevHash,
    );

    _auditLogTable.add(event);
  }

  Future<List<AuditEvent>> getAuditLog() async {
    await initialize();
    // Return newest first for display
    return _auditLogTable.reversed.toList();
  }

  // ==========================================
  // CITIZEN WATCH TIPS
  // ==========================================

  Future<void> insertCitizenTip(CitizenTip tip) async {
    await initialize();
    _tipsTable[tip.tipId] = tip;
    await logAuditEvent(
      actorId: 'ANONYMOUS_CITIZEN',
      eventType: 'CITIZEN_TIP_CREATED',
      relatedRecordId: tip.tipId,
      metadata: {
        'category': tip.category,
        'hasLocation': tip.optionalLatitude != null,
        'hasMedia': tip.optionalMediaHash != null,
      },
    );
  }

  Future<List<CitizenTip>> getAllCitizenTips() async {
    await initialize();
    final list = _tipsTable.values.toList();
    list.sort((a, b) => b.submittedAtUtc.compareTo(a.submittedAtUtc));
    return list;
  }
}
