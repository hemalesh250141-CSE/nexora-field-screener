import 'package:test/test.dart';
import '../lib/core/storage/database_helper.dart';

void main() {
  group('DatabaseHelper - Sync Queue & Idempotency', () {
    setUp(() async {
      await DatabaseHelper().initialize();
    });

    test('Enqueueing evidence record marks status PENDING in queue', () async {
      const recordId = 'SYNC-REC-001';
      final payload = {'id': recordId, 'caseId': 'CASE-SYNC-01'};

      await DatabaseHelper().enqueueSyncItem(recordId: recordId, payload: payload);
      final pending = await DatabaseHelper().getPendingSyncItems();

      final found = pending.any((item) => item['recordId'] == recordId && item['status'] == 'PENDING');
      expect(found, isTrue);
    });

    test('Marking sync item success transitions status to SYNCED', () async {
      const recordId = 'SYNC-REC-001';
      await DatabaseHelper().markSyncItemSuccess(recordId);

      final pending = await DatabaseHelper().getPendingSyncItems();
      final isStillPending = pending.any((item) => item['recordId'] == recordId);
      expect(isStillPending, isFalse);
    });

    test('Sync item failure increments retry count and logs error', () async {
      const recordId = 'SYNC-REC-002';
      final payload = {'id': recordId, 'caseId': 'CASE-SYNC-02'};

      await DatabaseHelper().enqueueSyncItem(recordId: recordId, payload: payload);
      await DatabaseHelper().markSyncItemFailed(recordId, 'Network unreachable (EHOSTUNREACH)');

      final pending = await DatabaseHelper().getPendingSyncItems();
      final item = pending.firstWhere((i) => i['recordId'] == recordId);

      expect(item['retries'], equals(1));
      expect(item['lastError'], contains('Network unreachable'));
    });
  });
}
