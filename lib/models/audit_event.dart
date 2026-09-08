import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Immutable Security Audit Event Model
class AuditEvent {
  final String eventId;
  final String actorId;
  final String eventType;
  final String timestampUtc;
  final String deviceId;
  final String? relatedRecordId;
  final Map<String, dynamic> metadata;
  final String eventHash;
  final String previousEventHash;

  const AuditEvent({
    required this.eventId,
    required this.actorId,
    required this.eventType,
    required this.timestampUtc,
    required this.deviceId,
    this.relatedRecordId,
    required this.metadata,
    required this.eventHash,
    required this.previousEventHash,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'actorId': actorId,
      'eventType': eventType,
      'timestampUtc': timestampUtc,
      'deviceId': deviceId,
      'relatedRecordId': relatedRecordId,
      'metadata': jsonEncode(metadata),
      'eventHash': eventHash,
      'previousEventHash': previousEventHash,
    };
  }

  factory AuditEvent.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> meta = {};
    if (map['metadata'] != null) {
      if (map['metadata'] is String) {
        try {
          meta = jsonDecode(map['metadata'] as String);
        } catch (_) {}
      } else if (map['metadata'] is Map) {
        meta = Map<String, dynamic>.from(map['metadata']);
      }
    }

    return AuditEvent(
      eventId: map['eventId'] as String,
      actorId: map['actorId'] as String,
      eventType: map['eventType'] as String,
      timestampUtc: map['timestampUtc'] as String,
      deviceId: map['deviceId'] as String,
      relatedRecordId: map['relatedRecordId'] as String?,
      metadata: meta,
      eventHash: map['eventHash'] as String,
      previousEventHash: map['previousEventHash'] as String,
    );
  }

  /// Factory helper to create a sealed audit event with automatic SHA-256 calculation
  static AuditEvent createSealed({
    required String eventId,
    required String actorId,
    required String eventType,
    required String deviceId,
    String? relatedRecordId,
    required Map<String, dynamic> metadata,
    required String previousEventHash,
  }) {
    final timestamp = DateTime.now().toUtc().toIso8601String();
    final canonicalString =
        '$eventId|$actorId|$eventType|$timestamp|$deviceId|${relatedRecordId ?? ""}|$previousEventHash|${jsonEncode(metadata)}';
    final eventHash = sha256.convert(utf8.encode(canonicalString)).toString();

    return AuditEvent(
      eventId: eventId,
      actorId: actorId,
      eventType: eventType,
      timestampUtc: timestamp,
      deviceId: deviceId,
      relatedRecordId: relatedRecordId,
      metadata: metadata,
      eventHash: eventHash,
      previousEventHash: previousEventHash,
    );
  }
}
