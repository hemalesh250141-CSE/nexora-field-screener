import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';
import '../models/evidence_record.dart';
import 'status_indicator_badge.dart';

/// Rigid government forensic data table for test records
class ForensicDataTable extends StatelessWidget {
  final List<EvidenceRecord> records;
  final Function(EvidenceRecord record)? onRecordSelected;

  const ForensicDataTable({
    super.key,
    required this.records,
    this.onRecordSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: NexoraColors.cardDark,
          border: Border.all(color: NexoraColors.borderSubtle),
        ),
        child: const Text(
          'NO EVIDENCE RECORDS LOGGED IN VAULT',
          style: TextStyle(
            fontFamily: 'monospace',
            color: NexoraColors.textMuted,
            fontSize: 12,
            letterSpacing: 1.1,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: NexoraColors.cardDark,
        border: Border.all(color: NexoraColors.borderSubtle),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(NexoraColors.classicBlack),
          headingTextStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.0,
            color: NexoraColors.tacticalKhaki,
          ),
          dataTextStyle: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 11,
            color: NexoraColors.textPrimary,
          ),
          columnSpacing: 16,
          horizontalMargin: 12,
          columns: const [
            DataColumn(label: Text('TEST ID')),
            DataColumn(label: Text('CASE ID')),
            DataColumn(label: Text('TIME (UTC)')),
            DataColumn(label: Text('COORDINATES')),
            DataColumn(label: Text('RESULT')),
            DataColumn(label: Text('INTEGRITY')),
            DataColumn(label: Text('SYNC')),
          ],
          rows: records.asMap().entries.map((entry) {
            final idx = entry.key;
            final rec = entry.value;
            final isAlt = idx % 2 == 1;

            final timeStr = rec.capturedAtUtc.length > 19
                ? rec.capturedAtUtc.substring(11, 19)
                : rec.capturedAtUtc;
            final coords = '${rec.gpsLatitude.toStringAsFixed(3)}, ${rec.gpsLongitude.toStringAsFixed(3)}';

            return DataRow(
              color: WidgetStateProperty.all(isAlt ? NexoraColors.tableRowAlt : NexoraColors.cardDark),
              onSelectChanged: (_) => onRecordSelected?.call(rec),
              cells: [
                DataCell(Text(rec.id, style: const TextStyle(fontWeight: FontWeight.w700))),
                DataCell(Text(rec.caseId)),
                DataCell(Text(timeStr)),
                DataCell(Text(coords)),
                DataCell(StatusIndicatorBadge(status: rec.analysisStatus, small: true)),
                DataCell(StatusIndicatorBadge(status: rec.integrityStatus, small: true)),
                DataCell(StatusIndicatorBadge(status: rec.syncStatus, small: true)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
