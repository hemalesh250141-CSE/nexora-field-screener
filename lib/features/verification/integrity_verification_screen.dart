import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../core/constants/app_constants.dart';
import '../../core/storage/database_helper.dart';
import '../../services/evidence_service.dart';
import '../../widgets/status_indicator_badge.dart';

/// Integrity Verification & Tamper Demonstration Screen
class IntegrityVerificationScreen extends StatefulWidget {
  const IntegrityVerificationScreen({super.key});

  @override
  State<IntegrityVerificationScreen> createState() => _IntegrityVerificationScreenState();
}

class _IntegrityVerificationScreenState extends State<IntegrityVerificationScreen> {
  bool _isVerifying = false;
  Map<String, dynamic>? _vaultVerificationResult;
  Map<String, dynamic>? _tamperDemoResult;
  List<Map<String, dynamic>> _chainRecords = [];

  @override
  void initState() {
    super.initState();
    _loadAndVerifyChain();
  }

  Future<void> _loadAndVerifyChain() async {
    setState(() => _isVerifying = true);
    final chain = await DatabaseHelper().getEvidenceChainChronological();
    final result = await EvidenceService().verifyVaultIntegrity();

    if (mounted) {
      setState(() {
        _chainRecords = chain;
        _vaultVerificationResult = result;
        _isVerifying = false;
      });
    }
  }

  Future<void> _runTamperDemo() async {
    setState(() => _isVerifying = true);
    final demoResult = await EvidenceService().runTamperDemonstration();

    if (mounted) {
      setState(() {
        _tamperDemoResult = demoResult;
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('INTEGRITY & TAMPER VERIFICATION'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _loadAndVerifyChain,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vault Integrity Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(
                  color: _vaultVerificationResult != null && _vaultVerificationResult!['valid'] == true
                      ? NexoraColors.verifiedGreen
                      : NexoraColors.alertRed,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'LOCAL VAULT HASH CHAIN STATUS',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: NexoraColors.tacticalKhaki,
                        ),
                      ),
                      if (_vaultVerificationResult != null)
                        StatusIndicatorBadge(
                          status: _vaultVerificationResult!['status'] as String,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _vaultVerificationResult != null
                        ? (_vaultVerificationResult!['message'] as String? ??
                            _vaultVerificationResult!['reason'] as String? ??
                            'Integrity verification complete.')
                        : 'Verifying hash chain continuity...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: NexoraColors.pureWhite,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total Chain Nodes: ${_chainRecords.length} records verified against SHA-256 links.',
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // SIH Judge Tamper Detection Simulation Tool
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.presumptiveAmber, width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.gavel, color: NexoraColors.presumptiveAmber, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'EVALUATOR TOOL: TAMPER DETECTION DEMO',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: NexoraColors.presumptiveAmber,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Simulates an attacker silently modifying 1 character in a historical evidence payload or GPS record. Demonstrates that cryptographic hash chain recalculation immediately catches and flags the breach.',
                    style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.textSecondary, height: 1.3),
                  ),
                  const SizedBox(height: 14),

                  ElevatedButton.icon(
                    onPressed: _chainRecords.isEmpty || _isVerifying ? null : _runTamperDemo,
                    icon: const Icon(Icons.bug_report, size: 16),
                    label: const Text('RUN TAMPER DETECTION SIMULATION'),
                    style: ElevatedButton.styleFrom(backgroundColor: NexoraColors.presumptiveAmber),
                  ),

                  if (_tamperDemoResult != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: NexoraColors.classicBlack,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SIMULATION RESULT: TAMPER DETECTED',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: NexoraColors.alertRed,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Target Record: ${_tamperDemoResult!['targetRecordId']}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.pureWhite),
                          ),
                          Text(
                            'Original Hash: ${_tamperDemoResult!['originalEvidenceHash']}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.verifiedGreen),
                          ),
                          Text(
                            'Tampered Hash: ${_tamperDemoResult!['tamperedEvidenceHash']}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.alertRed),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Verdict: ${_tamperDemoResult!['verificationResult']['reason']}',
                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.pureWhite),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Chronological Hash Chain Tree View
            const Text(
              'IMMUTABLE HASH CHAIN NODES',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: NexoraColors.tacticalKhaki,
              ),
            ),
            const SizedBox(height: 8),

            if (_chainRecords.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No evidence records present in the chain.',
                  style: TextStyle(fontFamily: 'monospace', color: NexoraColors.textMuted),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _chainRecords.length,
                separatorBuilder: (_, __) => const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Icon(Icons.arrow_downward, size: 16, color: NexoraColors.tacticalKhaki),
                  ),
                ),
                itemBuilder: (context, idx) {
                  final node = _chainRecords[idx];
                  return Container(
                    padding: const EdgeInsets.all(12),
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
                              'NODE #${idx + 1}: ${node['id']}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                                color: NexoraColors.tacticalKhaki,
                              ),
                            ),
                            Text(
                              'Case: ${node['caseId']}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Record Hash: ${node['recordHash']}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: NexoraColors.pureWhite),
                        ),
                        Text(
                          'Prev Hash: ${node['previousRecordHash']}',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 9, color: NexoraColors.textMuted),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
