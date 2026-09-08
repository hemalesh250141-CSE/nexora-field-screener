import 'package:test/test.dart';
import '../lib/core/storage/database_helper.dart';
import '../lib/core/security/hash_chain.dart';
import '../lib/models/evidence_record.dart';

void main() {
  group('DatabaseHelper & HashChainEngine', () {
    setUp(() async {
      await DatabaseHelper().initialize();
    });

    test('Genesis link has expected 64-zero initial previous hash', () async {
      final initialHash = await DatabaseHelper().getLatestRecordHash();
      expect(initialHash, equals(HashChainEngine.genesisPreviousHash));
    });

    test('Sequential evidence records form valid, unbroken hash chain', () async {
      // Record 1
      const rec1Id = 'TEST-REC-001';
      const evidenceHash1 = '1111111111111111111111111111111111111111111111111111111111111111';
      final prevHash1 = HashChainEngine.genesisPreviousHash;
      final recordHash1 = HashChainEngine.calculateRecordHash(
        recordId: rec1Id,
        evidenceHash: evidenceHash1,
        previousRecordHash: prevHash1,
        timestampUtc: '2026-09-08T10:00:00.000Z',
        officerId: 'BADGE-104',
        recordVersion: 1,
      );

      final record1 = EvidenceRecord(
        id: rec1Id,
        caseId: 'CASE-001',
        officerId: 'BADGE-104',
        capturedAtUtc: '2026-09-08T10:00:00.000Z',
        gpsLatitude: 13.0827,
        gpsLongitude: 80.2707,
        gpsAccuracy: 3.4,
        rawImageHash: 'RAW_IMAGE_HASH_1',
        evidenceHash: evidenceHash1,
        previousRecordHash: prevHash1,
        recordHash: recordHash1,
        analysisStatus: 'PRESUMPTIVE',
        possibleMatches: const [],
        confidence: 'HIGH SIMILARITY',
        deltaE: 0.8,
        imageQuality: 'QUALITY: GOOD',
        calibrationQuality: 'CALIBRATED',
        engineVersion: 'CIE-DE2000-v1.4',
        referenceDatasetVersion: 'DS-FORENSIC-2026.1',
        canonicalPayload: '{"caseId":"CASE-001"}',
      );

      await DatabaseHelper().insertEvidenceRecord(record1);

      // Record 2 (chained to Record 1)
      const rec2Id = 'TEST-REC-002';
      const evidenceHash2 = '2222222222222222222222222222222222222222222222222222222222222222';
      final prevHash2 = recordHash1;
      final recordHash2 = HashChainEngine.calculateRecordHash(
        recordId: rec2Id,
        evidenceHash: evidenceHash2,
        previousRecordHash: prevHash2,
        timestampUtc: '2026-09-08T10:05:00.000Z',
        officerId: 'BADGE-104',
        recordVersion: 1,
      );

      final record2 = EvidenceRecord(
        id: rec2Id,
        caseId: 'CASE-001',
        officerId: 'BADGE-104',
        capturedAtUtc: '2026-09-08T10:05:00.000Z',
        gpsLatitude: 13.0828,
        gpsLongitude: 80.2708,
        gpsAccuracy: 3.2,
        rawImageHash: 'RAW_IMAGE_HASH_2',
        evidenceHash: evidenceHash2,
        previousRecordHash: prevHash2,
        recordHash: recordHash2,
        analysisStatus: 'PRESUMPTIVE',
        possibleMatches: const [],
        confidence: 'HIGH SIMILARITY',
        deltaE: 0.5,
        imageQuality: 'QUALITY: GOOD',
        calibrationQuality: 'CALIBRATED',
        engineVersion: 'CIE-DE2000-v1.4',
        referenceDatasetVersion: 'DS-FORENSIC-2026.1',
        canonicalPayload: '{"caseId":"CASE-001-B"}',
      );

      await DatabaseHelper().insertEvidenceRecord(record2);

      // Verify full chain
      final chain = await DatabaseHelper().getEvidenceChainChronological();
      final report = HashChainEngine.verifyChain(chain);

      expect(report['valid'], isTrue);
      expect(report['status'], equals('INTEGRITY VERIFIED'));
      expect(report['recordsChecked'], greaterThanOrEqualTo(2));
    });

    test('Tamper Detection: modifying 1 character in chain triggers INTEGRITY FAILURE', () async {
      final chain = await DatabaseHelper().getEvidenceChainChronological();
      expect(chain.isNotEmpty, isTrue);

      final tamperReport = HashChainEngine.simulateTamperingDemonstration(chain);

      expect(tamperReport['tamperDetected'], isTrue);
      final verResult = tamperReport['verificationResult'] as Map<String, dynamic>;
      expect(verResult['status'], equals('INTEGRITY FAILURE'));
      expect(verResult['valid'], isFalse);
    });
  });
}
