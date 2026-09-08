import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/evidence_record.dart';
import '../../widgets/status_indicator_badge.dart';
import 'evidence_detail_screen.dart';

/// Chronological Test History Screen
class TestHistoryScreen extends StatefulWidget {
  const TestHistoryScreen({super.key});

  @override
  State<TestHistoryScreen> createState() => _TestHistoryScreenState();
}

class _TestHistoryScreenState extends State<TestHistoryScreen> {
  List<EvidenceRecord> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final all = await DatabaseHelper().getAllEvidence();
    if (mounted) {
      setState(() {
        _records = all;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('FIELD TEST AUDIT TIMELINE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? const Center(
                  child: Text(
                    'NO TEST HISTORY RECORDED',
                    style: TextStyle(fontFamily: 'monospace', color: NexoraColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _records.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final rec = _records[idx];
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => EvidenceDetailScreen(record: rec),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: NexoraColors.cardDark,
                          border: Border.all(color: NexoraColors.borderSubtle),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  rec.id,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: NexoraColors.tacticalKhaki,
                                  ),
                                ),
                                StatusIndicatorBadge(status: rec.analysisStatus, small: true),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Case: ${rec.caseId} • Officer: ${rec.officerId}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NexoraColors.pureWhite,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'UTC: ${rec.capturedAtUtc}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: NexoraColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'GPS: ${rec.gpsLatitude.toStringAsFixed(4)}, ${rec.gpsLongitude.toStringAsFixed(4)} (±${rec.gpsAccuracy.toStringAsFixed(1)}m)',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: NexoraColors.textMuted,
                                  ),
                                ),
                                StatusIndicatorBadge(status: rec.syncStatus, small: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
