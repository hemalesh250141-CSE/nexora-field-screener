import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../models/user_session.dart';
import '../../models/evidence_record.dart';
import '../../services/camera_service.dart';
import '../../services/location_service.dart';
import '../../services/evidence_service.dart';
import 'result_screen.dart';

/// Step-by-Step Forensic Analysis & Cryptographic Sealing Sequence
class AnalysisProgressScreen extends StatefulWidget {
  final UserSession session;
  final String caseId;
  final String reagentUsed;
  final CameraCaptureBundle cameraBundle;
  final String? officerNotes;

  const AnalysisProgressScreen({
    super.key,
    required this.session,
    required this.caseId,
    required this.reagentUsed,
    required this.cameraBundle,
    this.officerNotes,
  });

  @override
  State<AnalysisProgressScreen> createState() => _AnalysisProgressScreenState();
}

class _AnalysisProgressScreenState extends State<AnalysisProgressScreen> {
  final List<String> _steps = [
    'IMAGE CAPTURE & 5-FRAME ALIGNMENT',
    'REFERENCE CALIBRATION & GRAY SAMPLING',
    'COLOUR NORMALIZATION (WHITE-BALANCE GAIN)',
    'LAB CONVERSION (D65 CIE L*a*b*)',
    'CIEDE2000 MATHEMATICAL ANALYSIS (ΔE00)',
    'REFERENCE DATASET COMPARISON & RANKING',
    'EVIDENCE SEAL (CANONICAL SHA-256 HASH)',
    'FINAL PRESUMPTIVE RESULT GENERATED',
  ];

  int _currentStepIndex = 0;
  EvidenceRecord? _generatedRecord;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _runAnalysisSequence();
  }

  Future<void> _runAnalysisSequence() async {
    try {
      // Step 0: Image capture verified
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStepIndex = 1);

      // Step 1: Reference Calibration
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStepIndex = 2);

      // Step 2: Color Normalization
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStepIndex = 3);

      // Step 3: CIELAB Conversion
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStepIndex = 4);

      // Step 4: CIEDE2000
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStepIndex = 5);

      // Step 5: Reference Comparison & GPS Capture
      final locationResult = await LocationService().getCurrentLocation();
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() => _currentStepIndex = 6);

      // Step 6: Evidence Seal & Chaining
      final record = await EvidenceService().executeFieldTestWorkflow(
        caseId: widget.caseId,
        officerId: widget.session.badgeId,
        reagentUsed: widget.reagentUsed,
        cameraBundle: widget.cameraBundle,
        locationResult: locationResult,
        officerNotes: widget.officerNotes,
      );

      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      setState(() {
        _currentStepIndex = 7;
        _generatedRecord = record;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ResultScreen(
              record: record,
              session: widget.session,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('FORENSIC ANALYSIS ENGINE'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.borderStrong),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EXECUTION PIPELINE: CIE-DE2000-v1.4',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Case: ${widget.caseId} • Reagent: ${widget.reagentUsed}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: NexoraColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Step progression list
            Expanded(
              child: ListView.separated(
                itemCount: _steps.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final isDone = index < _currentStepIndex;
                  final isCurrent = index == _currentStepIndex;

                  Color itemColor;
                  Widget iconWidget;

                  if (isDone) {
                    itemColor = NexoraColors.verifiedGreen;
                    iconWidget = const Icon(Icons.check, size: 16, color: NexoraColors.verifiedGreen);
                  } else if (isCurrent) {
                    itemColor = NexoraColors.tacticalKhaki;
                    iconWidget = const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: NexoraColors.tacticalKhaki,
                      ),
                    );
                  } else {
                    itemColor = NexoraColors.textMuted;
                    iconWidget = const Icon(Icons.circle_outlined, size: 14, color: NexoraColors.textMuted);
                  }

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrent ? NexoraColors.cardDark : NexoraColors.classicBlack,
                      border: Border.all(
                        color: isCurrent ? NexoraColors.tacticalKhaki : NexoraColors.borderSubtle,
                        width: isCurrent ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        iconWidget,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _steps[index],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: itemColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: NexoraColors.alertRed.withOpacity(0.2),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(fontFamily: 'monospace', color: NexoraColors.pureWhite),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
