import 'package:test/test.dart';
import '../lib/core/security/canonical_serializer.dart';
import '../lib/core/security/hash_service.dart';

void main() {
  group('CanonicalSerializer & HashService', () {
    test('Canonical serialization sorts dictionary keys lexicographically', () {
      final mapA = {'z': 1, 'a': 2, 'm': 3};
      final mapB = {'a': 2, 'm': 3, 'z': 1};

      final serialA = CanonicalSerializer.serialize(mapA);
      final serialB = CanonicalSerializer.serialize(mapB);

      expect(serialA, equals(serialB));
      expect(serialA, equals('{"a":2,"m":3,"z":1}'));
    });

    test('Canonical serialization formats nested structures deterministically', () {
      final payload = {
        'version': '1.0',
        'algorithm': 'SHA-256',
        'gps': {
          'latitude': 13.082700,
          'longitude': 80.270700,
          'accuracy': 3.40,
        },
        'caseId': 'CASE-2026-0891',
      };

      final serialized = CanonicalSerializer.serialize(payload);
      expect(serialized, startsWith('{"algorithm":"SHA-256","caseId":"CASE-2026-0891","gps":{"accuracy":3.4,"latitude":13.0827,"longitude":80.2707},"version":"1.0"}'));
    });

    test('Statutory Evidence Hash Generation produces 64-char hex digest', () {
      final bundle = HashService.generateEvidencePayload(
        rawImageHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        latitude: 13.0827,
        longitude: 80.2707,
        accuracy: 3.4,
        capturedAtUtc: '2026-09-08T14:30:00.000Z',
        officerBadgeId: 'BADGE-104',
        caseId: 'CASE-2026-0891',
      );

      final evidenceHash = bundle['evidenceHash'] as String;
      expect(evidenceHash.length, equals(64));
      expect(bundle['algorithm'], equals('SHA-256'));

      // Verify payload
      final isValid = HashService.verifyEvidenceHash(
        evidenceHash: evidenceHash,
        canonicalPayload: bundle['canonicalPayload'] as String,
      );
      expect(isValid, isTrue);
    });

    test('Avalanche Effect: 1-byte alteration completely changes evidence hash', () {
      final bundleA = HashService.generateEvidencePayload(
        rawImageHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        latitude: 13.082700,
        longitude: 80.270700,
        accuracy: 3.4,
        capturedAtUtc: '2026-09-08T14:30:00.000Z',
        officerBadgeId: 'BADGE-104',
        caseId: 'CASE-2026-0891',
      );

      // Alter coordinate by 0.000001 (1 meter on ground)
      final bundleB = HashService.generateEvidencePayload(
        rawImageHash: 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        latitude: 13.082701,
        longitude: 80.270700,
        accuracy: 3.4,
        capturedAtUtc: '2026-09-08T14:30:00.000Z',
        officerBadgeId: 'BADGE-104',
        caseId: 'CASE-2026-0891',
      );

      final hashA = bundleA['evidenceHash'] as String;
      final hashB = bundleB['evidenceHash'] as String;

      expect(hashA, isNot(equals(hashB)));
    });
  });
}
