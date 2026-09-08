import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../models/audit_event.dart';

/// Immutable Security Audit Trail Screen
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  List<AuditEvent> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudit();
  }

  Future<void> _loadAudit() async {
    setState(() => _isLoading = true);
    final list = await DatabaseHelper().getAuditLog();
    if (mounted) {
      setState(() {
        _events = list;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('IMMUTABLE AUDIT LOG'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadAudit,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _events.isEmpty
              ? const Center(
                  child: Text(
                    'AUDIT TRAIL EMPTY',
                    style: TextStyle(fontFamily: 'monospace', color: NexoraColors.textMuted),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final ev = _events[idx];
                    return Container(
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
                                ev.eventType,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: NexoraColors.tacticalKhaki,
                                ),
                              ),
                              Text(
                                ev.timestampUtc.length > 19
                                    ? ev.timestampUtc.substring(11, 19)
                                    : ev.timestampUtc,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10,
                                  color: NexoraColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Actor: ${ev.actorId} • Device: ${ev.deviceId}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: NexoraColors.pureWhite,
                            ),
                          ),
                          if (ev.relatedRecordId != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Related Record: ${ev.relatedRecordId}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textSecondary),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            color: NexoraColors.classicBlack,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event Hash: ${ev.eventHash}',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: NexoraColors.textMuted),
                                ),
                                Text(
                                  'Prev Hash:  ${ev.previousEventHash}',
                                  style: const TextStyle(fontFamily: 'monospace', fontSize: 8, color: NexoraColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
