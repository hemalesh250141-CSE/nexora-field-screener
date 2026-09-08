import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'canonical_serializer.dart';

/// Cryptographic Sealing & SHA-256 Hashing Service
/// Implements court-admissible canonical evidence sealing.
class HashService {
  HashService._();

  /// Computes SHA-256 hex digest of raw binary bytes (e.g. image file bytes)
  static String hashBytes(Uint8List bytes) {
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Computes SHA-256 hex digest of a UTF-8 string
  static String hashString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Constructs the canonical evidence payload and calculates its SHA-256 seal.
  ///
  /// Statutory Formula:
  /// Evidence Hash = SHA-256(Raw Image Hash + GPS Lat/Long + UTC Timestamp + Officer Badge ID + Case ID)
  static Map<String, dynamic> generateEvidencePayload({
    required String rawImageHash,
    required double latitude,
    required double longitude,
    required double accuracy,
    required String capturedAtUtc,
    required String officerBadgeId,
    required String caseId,
    String version = '1.0',
  }) {
    final canonicalMap = {
      'algorithm': 'SHA-256',
      'version': version,
      'caseId': caseId,
      'officerBadgeId': officerBadgeId,
      'capturedAtUtc': capturedAtUtc,
      'rawImageHash': rawImageHash,
      'gps': {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      },
    };

    final canonicalJson = CanonicalSerializer.serialize(canonicalMap);
    final evidenceHash = hashString(canonicalJson);

    return {
      'canonicalPayload': canonicalJson,
      'evidenceHash': evidenceHash,
      'algorithm': 'SHA-256',
      'version': version,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Verifies an evidence hash against a canonical payload
  static bool verifyEvidenceHash({
    required String evidenceHash,
    required String canonicalPayload,
  }) {
    final calculated = hashString(canonicalPayload);
    return calculated.toLowerCase() == evidenceHash.toLowerCase();
  }
}
