import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/security/hash_service.dart';
import '../../models/evidence_record.dart';
import '../../widgets/statutory_disclaimer_banner.dart';
import '../../widgets/status_indicator_badge.dart';

/// Comprehensive Chain of Custody & Forensic Evidence Detail Screen
class EvidenceDetailScreen extends StatefulWidget {
  final EvidenceRecord record;

  const EvidenceDetailScreen({super.key, required this.record});

  @override
  State<EvidenceDetailScreen> createState() => _EvidenceDetailScreenState();
}

class _EvidenceDetailScreenState extends State<EvidenceDetailScreen> {
  bool _isVerifying = false;
  String? _verificationReport;

  void _verifyNow() async {
    setState(() => _isVerifying = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final isHashValid = HashService.verifyEvidenceHash(
      evidenceHash: widget.record.evidenceHash,
      canonicalPayload: widget.record.canonicalPayload,
    );

    setState(() {
      _isVerifying = false;
      _verificationReport = isHashValid
          ? 'CRYPTOGRAPHIC VERIFICATION SUCCESS: Canonical payload recalculation matches sealed SHA-256 evidence hash perfectly.'
          : 'CRYPTOGRAPHIC VERIFICATION FAILURE: Payload has been modified! Hash mismatch detected.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.record;

    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: Text('RECORD: ${rec.id}'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(child: StatusIndicatorBadge(status: rec.integrityStatus)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const StatutoryDisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Overview Card
            Container(
              padding: const EdgeInsets.all(16),
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
                        'CASE: ${rec.caseId}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: NexoraColors.pureWhite,
                        ),
                      ),
                      StatusIndicatorBadge(status: rec.analysisStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Recorded by Officer ${rec.officerId} on ${rec.capturedAtUtc}',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Cryptographic Custody Verification Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.classicBlack,
                border: Border.all(color: NexoraColors.tacticalKhaki, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CRYPTOGRAPHIC INTEGRITY VERIFICATION',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _hashBlock('SEALED EVIDENCE HASH (SHA-256)', rec.evidenceHash),
                  const SizedBox(height: 8),
                  _hashBlock('PREVIOUS RECORD LINK HASH', rec.previousRecordHash),
                  const SizedBox(height: 8),
                  _hashBlock('IMMUTABLE RECORD HASH', rec.recordHash),
                  const SizedBox(height: 12),

                  ElevatedButton.icon(
                    onPressed: _isVerifying ? null : _verifyNow,
                    icon: const Icon(Icons.security, size: 16),
                    label: _isVerifying
                        ? const SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('RE-VERIFY CANONICAL SHA-256 SEAL'),
                  ),

                  if (_verificationReport != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      color: _verificationReport!.contains('SUCCESS')
                          ? NexoraColors.verifiedGreen.withOpacity(0.2)
                          : NexoraColors.alertRed.withOpacity(0.2),
                      child: Text(
                        _verificationReport!,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.pureWhite),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Field GPS & Geofence Coordinates
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'GEOSPATIAL & HARDWARE TELEMETRY',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow('LATITUDE', rec.gpsLatitude.toStringAsFixed(6)),
                  _infoRow('LONGITUDE', rec.gpsLongitude.toStringAsFixed(6)),
                  _infoRow('ACCURACY', '±${rec.gpsAccuracy.toStringAsFixed(1)} m'),
                  _infoRow('SYNC STATUS', rec.syncStatus),
                  _infoRow('RAW SENSOR HASH', rec.rawImageHash),
                  if (rec.reagentUsed != null) _infoRow('REAGENT KIT', rec.reagentUsed!),
                  if (rec.officerNotes != null) _infoRow('FIELD NOTES', rec.officerNotes!),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Canonical JSON Payload Inspection
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.borderSubtle),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DETERMINISTIC CANONICAL PAYLOAD',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NexoraColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: NexoraColors.classicBlack,
                    child: SelectableText(
                      rec.canonicalPayload,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: NexoraColors.tacticalKhaki,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hashBlock(String title, String hash) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: NexoraColors.textMuted, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        SelectableText(
          hash,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.pureWhite, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }
}
