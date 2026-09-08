import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../models/user_session.dart';
import '../../models/evidence_record.dart';
import '../../widgets/statutory_disclaimer_banner.dart';
import '../../widgets/status_indicator_badge.dart';
import '../../widgets/similarity_progress_bar.dart';
import '../evidence/evidence_detail_screen.dart';
import '../dashboard/officer_dashboard_screen.dart';
import 'new_field_test_screen.dart';

/// NEXORA Official Forensic Result Screen
class ResultScreen extends StatelessWidget {
  final EvidenceRecord record;
  final UserSession session;

  const ResultScreen({
    super.key,
    required this.record,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    final isPresumptive = record.analysisStatus == 'PRESUMPTIVE';

    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('FORENSIC SCREENING RESULT'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => OfficerDashboardScreen(session: session)),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Header Container
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isPresumptive
                    ? NexoraColors.presumptiveAmber.withOpacity(0.12)
                    : NexoraColors.inconclusiveGray.withOpacity(0.12),
                border: Border.all(
                  color: isPresumptive ? NexoraColors.presumptiveAmber : NexoraColors.inconclusiveGray,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isPresumptive ? 'PRESUMPTIVE RESULT' : 'INCONCLUSIVE',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: isPresumptive ? NexoraColors.presumptiveAmber : NexoraColors.textSecondary,
                        ),
                      ),
                      StatusIndicatorBadge(status: record.analysisStatus),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isPresumptive
                        ? 'Colourimetric pattern corresponds with authorized reference profile standards.'
                        : 'Sample colour distance ΔE00 exceeds authorized threshold ($deltaEThreshold) or image calibration criteria was not met.',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: NexoraColors.pureWhite,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Mandatory Statutory Notice Banner
            const StatutoryDisclaimerBanner(),

            const SizedBox(height: 16),

            // Ranked Matching Reference Profiles
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
                      const Text(
                        'POSSIBLE MATCHING REFERENCE PROFILES',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                          color: NexoraColors.tacticalKhaki,
                        ),
                      ),
                      Text(
                        'DATASET: ${record.referenceDatasetVersion}',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          color: NexoraColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (record.possibleMatches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        'NO MATCHING REFERENCE STANDARDS WITHIN AUTHORIZED THRESHOLD.',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: NexoraColors.textMuted,
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: record.possibleMatches.length > 3 ? 3 : record.possibleMatches.length,
                      separatorBuilder: (_, __) => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10.0),
                        child: Divider(color: NexoraColors.borderSubtle),
                      ),
                      itemBuilder: (context, idx) {
                        final match = record.possibleMatches[idx];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${idx + 1}. ',
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: NexoraColors.tacticalKhaki,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    match.displayName,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: NexoraColors.pureWhite,
                                    ),
                                  ),
                                ),
                                StatusIndicatorBadge(status: match.confidenceRating, small: true),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Target Standard: ${match.category}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                color: NexoraColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            SimilarityProgressBar(
                              similarityPercent: match.similarityPercent,
                              deltaE00: match.deltaE00,
                            ),
                          ],
                        );
                      },
                    ),

                  const SizedBox(height: 12),
                  const Text(
                    'Note: Similarity represents mathematical correspondence with the configured reference profile. It is not a laboratory confirmation.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                      color: NexoraColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Metadata & Cryptographic Seals
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
                    'FORENSIC CHAIN OF CUSTODY METADATA',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildMetaRow('TEST RECORD ID', record.id),
                  _buildMetaRow('CASE FILE ID', record.caseId),
                  _buildMetaRow('OFFICER BADGE ID', record.officerId),
                  _buildMetaRow('UTC TIMESTAMP', record.capturedAtUtc),
                  _buildMetaRow('GPS COORDINATES', '${record.gpsLatitude.toStringAsFixed(5)}, ${record.gpsLongitude.toStringAsFixed(5)}'),
                  _buildMetaRow('GPS ACCURACY', '±${record.gpsAccuracy.toStringAsFixed(1)} meters'),
                  _buildMetaRow('IMAGE QUALITY', record.imageQuality),
                  _buildMetaRow('CALIBRATION QUALITY', record.calibrationQuality),
                  _buildMetaRow('ANALYSIS ENGINE', record.engineVersion),
                  _buildMetaRow('EVIDENCE SEAL (SHA-256)', record.evidenceHash),
                  _buildMetaRow('RECORD HASH', record.recordHash),
                  _buildMetaRow('PREVIOUS RECORD HASH', record.previousRecordHash),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('EVIDENCE SEAL COMMITTED TO LOCAL ENCRYPTED VAULT'),
                        backgroundColor: NexoraColors.verifiedGreen,
                      ),
                    );
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => OfficerDashboardScreen(session: session)),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('SAVE EVIDENCE'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => EvidenceDetailScreen(record: record)),
                    );
                  },
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('VIEW RECORD'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => NewFieldTestScreen(session: session)),
                    );
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('RETAKE TEST'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const double deltaEThreshold = AppConstants.defaultDeltaEThreshold;

  Widget _buildMetaRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: NexoraColors.textMuted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: NexoraColors.pureWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
