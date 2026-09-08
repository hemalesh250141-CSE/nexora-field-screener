import 'canonical_serializer.dart';
import 'hash_service.dart';

/// Append-Only Cryptographic Hash Chain Engine
/// Guarantees that completed evidence cannot be silently modified or deleted.
class HashChainEngine {
  HashChainEngine._();

  static const String genesisPreviousHash =
      '0000000000000000000000000000000000000000000000000000000000000000';

  /// Calculates the immutable Record Hash linking to the previous record in the chain.
  ///
  /// RecordHash = SHA-256(Record ID + Evidence Hash + Previous Record Hash + Timestamp + Officer ID)
  static String calculateRecordHash({
    required String recordId,
    required String evidenceHash,
    required String previousRecordHash,
    required String timestampUtc,
    required String officerId,
    required int recordVersion,
  }) {
    final payload = {
      'recordId': recordId,
      'evidenceHash': evidenceHash,
      'previousRecordHash': previousRecordHash,
      'timestampUtc': timestampUtc,
      'officerId': officerId,
      'recordVersion': recordVersion,
    };

    final canonicalString = CanonicalSerializer.serialize(payload);
    return HashService.hashString(canonicalString);
  }

  /// Verifies an individual record's hash
  static bool verifyRecord({
    required String recordId,
    required String evidenceHash,
    required String previousRecordHash,
    required String timestampUtc,
    required String officerId,
    required int recordVersion,
    required String expectedRecordHash,
  }) {
    final computed = calculateRecordHash(
      recordId: recordId,
      evidenceHash: evidenceHash,
      previousRecordHash: previousRecordHash,
      timestampUtc: timestampUtc,
      officerId: officerId,
      recordVersion: recordVersion,
    );
    return computed.toLowerCase() == expectedRecordHash.toLowerCase();
  }

  /// Verifies the continuity and integrity of an entire hash chain of records.
  /// Returns a verification report map with status, total records, and index of first tamper if any.
  static Map<String, dynamic> verifyChain(List<Map<String, dynamic>> records) {
    if (records.isEmpty) {
      return {
        'status': 'INTEGRITY VERIFIED',
        'valid': true,
        'recordsChecked': 0,
        'message': 'Chain is empty. Genesis ready.',
      };
    }

    String expectedPrevious = genesisPreviousHash;

    for (int i = 0; i < records.length; i++) {
      final rec = records[i];
      final recordId = rec['id'] as String;
      final evidenceHash = rec['evidenceHash'] as String;
      final previousHash = rec['previousRecordHash'] as String;
      final timestampUtc = rec['capturedAtUtc'] as String;
      final officerId = rec['officerId'] as String;
      final recordVersion = (rec['recordVersion'] as int?) ?? 1;
      final recordHash = rec['recordHash'] as String;

      // 1. Verify previous hash pointer matches previous link
      if (previousHash.toLowerCase() != expectedPrevious.toLowerCase()) {
        return {
          'status': 'INTEGRITY FAILURE',
          'valid': false,
          'recordsChecked': i + 1,
          'failedIndex': i,
          'failedRecordId': recordId,
          'reason': 'Hash chain broken. Expected previous hash $expectedPrevious, got $previousHash',
        };
      }

      // 2. Recalculate this record's hash
      final calculatedHash = calculateRecordHash(
        recordId: recordId,
        evidenceHash: evidenceHash,
        previousRecordHash: previousHash,
        timestampUtc: timestampUtc,
        officerId: officerId,
        recordVersion: recordVersion,
      );

      if (calculatedHash.toLowerCase() != recordHash.toLowerCase()) {
        return {
          'status': 'INTEGRITY FAILURE',
          'valid': false,
          'recordsChecked': i + 1,
          'failedIndex': i,
          'failedRecordId': recordId,
          'reason': 'Content altered! Calculated hash $calculatedHash does not match sealed hash $recordHash',
        };
      }

      expectedPrevious = recordHash;
    }

    return {
      'status': 'INTEGRITY VERIFIED',
      'valid': true,
      'recordsChecked': records.length,
      'message': 'All ${records.length} records verified. Chain of custody is intact.',
    };
  }

  /// Demonstration utility for SIH Judges:
  /// Alters a copy of a record (e.g. changing 1 coordinate or timestamp byte) and runs verification
  /// to demonstrate mathematical tamper detection.
  static Map<String, dynamic> simulateTamperingDemonstration(List<Map<String, dynamic>> originalChain) {
    if (originalChain.isEmpty) {
      return {
        'error': 'Cannot run tamper demo on empty chain. Create at least one evidence record first.'
      };
    }

    // Deep copy the chain
    final clonedChain = originalChain.map((r) => Map<String, dynamic>.from(r)).toList();

    // Select the last record and alter its evidenceHash by changing a single character
    final lastIdx = clonedChain.length - 1;
    final target = clonedChain[lastIdx];
    final originalHash = target['evidenceHash'] as String;

    // Flip the first character
    final tamperedHash = (originalHash.startsWith('a') ? 'b' : 'a') + originalHash.substring(1);
    target['evidenceHash'] = tamperedHash;

    // Run verification on the tampered copy
    final verificationResult = verifyChain(clonedChain);

    return {
      'demonstration': 'TAMPER DETECTION TEST',
      'targetRecordId': target['id'],
      'originalEvidenceHash': originalHash,
      'tamperedEvidenceHash': tamperedHash,
      'verificationResult': verificationResult,
      'tamperDetected': !verificationResult['valid'],
    };
  }
}
