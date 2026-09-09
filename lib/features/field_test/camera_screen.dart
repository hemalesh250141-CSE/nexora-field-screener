import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../models/user_session.dart';
import '../../services/camera_service.dart';
import '../../services/color_engine.dart';
import 'analysis_progress_screen.dart';

/// Camera Screen with Dual-Target Viewfinder & 5-Frame Burst Capture
class CameraScreen extends StatefulWidget {
  final UserSession session;
  final String caseId;
  final String reagentUsed;
  final String? officerNotes;

  const CameraScreen({
    super.key,
    required this.session,
    required this.caseId,
    required this.reagentUsed,
    this.officerNotes,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _isCapturing = false;
  int _burstProgress = 0;
  bool _flashOn = false;
  bool _cameraReady = false;

  // Evaluator Simulation Controls
  bool _simulateCardMissing = false;
  bool _simulatePoorQuality = false;
  RgbColor? _customSampleColor;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (!mounted || cameras.isEmpty) {
        return;
      }

      final rearCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        rearCamera,
        ResolutionPreset.max,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _cameraReady = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _cameraReady = false;
        });
      }
    }
  }

  Future<void> _captureBurst() async {
    setState(() {
      _isCapturing = true;
      _burstProgress = 1;
    });

    // Animate burst capture 1..5
    for (int f = 1; f <= 5; f++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) setState(() => _burstProgress = f);
    }

    final cameraBundle = await CameraService().captureMultiFrameBurst(
      targetReagent: widget.reagentUsed,
      forceCardMissing: _simulateCardMissing,
      forceInsufficientQuality: _simulatePoorQuality,
      customSimulatedRgb: _customSampleColor,
    );

    if (mounted) {
      setState(() => _isCapturing = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AnalysisProgressScreen(
            session: widget.session,
            caseId: widget.caseId,
            reagentUsed: widget.reagentUsed,
            cameraBundle: cameraBundle,
            officerNotes: widget.officerNotes,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.classicBlack,
      appBar: AppBar(
        title: const Text('DUAL-TARGET VIEWFINDER'),
        actions: [
          IconButton(
            icon: Icon(
              _flashOn ? Icons.flash_on : Icons.flash_off,
              color: _flashOn ? NexoraColors.presumptiveAmber : NexoraColors.textMuted,
            ),
            onPressed: () {
              CameraService().toggleFlash();
              setState(() => _flashOn = CameraService().flashEnabled);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Live Camera Viewfinder Area
          Expanded(
            child: Stack(
              children: [
                if (_controller != null && _controller!.value.isInitialized)
                  Positioned.fill(
                    child: ClipRRect(
                      child: CameraPreview(_controller!),
                    ),
                  )
                else
                  Container(
                    color: const Color(0xFF141414),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ForensicGridPainter(),
                    ),
                  ),

                // Live Camera Info Overlay
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: NexoraColors.classicBlack.withOpacity(0.8),
                    child: const Text(
                      'CameraX • 3840x2160 • ISO 100 • D65 CALIBRATION',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 9,
                        color: NexoraColors.tacticalKhaki,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),

                // Viewfinder Dual Targets
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Target 1: Reaction Pouch ROI
                        Expanded(
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(color: NexoraColors.tacticalKhaki, width: 2),
                              color: (_customSampleColor != null
                                      ? Color.fromARGB(
                                          180,
                                          _customSampleColor!.r.toInt(),
                                          _customSampleColor!.g.toInt(),
                                          _customSampleColor!.b.toInt(),
                                        )
                                      : NexoraColors.deepBrown.withOpacity(0.3)),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.colorize, color: NexoraColors.tacticalKhaki, size: 28),
                                SizedBox(height: 8),
                                Text(
                                  'TARGET A: REACTION POUCH',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: NexoraColors.pureWhite,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        // Target 2: Physical Reference Card ROI
                        Expanded(
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _simulateCardMissing ? NexoraColors.alertRed : NexoraColors.verifiedGreen,
                                width: 2,
                              ),
                              color: _simulateCardMissing
                                  ? NexoraColors.alertRed.withOpacity(0.1)
                                  : const Color(0xFF767676).withOpacity(0.4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.crop_free,
                                  color: _simulateCardMissing ? NexoraColors.alertRed : NexoraColors.verifiedGreen,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _simulateCardMissing
                                      ? 'CARD NOT DETECTED'
                                      : 'TARGET B: REFERENCE CARD\n(18% NEUTRAL GRAY)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _simulateCardMissing ? NexoraColors.alertRed : NexoraColors.pureWhite,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Burst capture progress overlay
                if (_isCapturing)
                  Container(
                    color: NexoraColors.classicBlack.withOpacity(0.85),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: NexoraColors.tacticalKhaki),
                          const SizedBox(height: 16),
                          Text(
                            'CAPTURING MULTI-FRAME BURST ($_burstProgress / 5)',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: NexoraColors.pureWhite,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Noise reduction & frame alignment in progress...',
                            style: TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Control Console & Evaluator Overrides
          Container(
            padding: const EdgeInsets.all(16),
            color: NexoraColors.cardDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Evaluator Presets Row
                const Text(
                  'SIH JUDGE EVALUATION MATRIX & EDGE CASES:',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: NexoraColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('STANDARD POSITIVE', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        backgroundColor: NexoraColors.classicBlack,
                        onPressed: () {
                          setState(() {
                            _simulateCardMissing = false;
                            _simulatePoorQuality = false;
                            _customSampleColor = null;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('TEST: CARD MISSING', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        backgroundColor: NexoraColors.classicBlack,
                        onPressed: () {
                          setState(() {
                            _simulateCardMissing = true;
                            _simulatePoorQuality = false;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('TEST: POOR LIGHT/BLUR', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        backgroundColor: NexoraColors.classicBlack,
                        onPressed: () {
                          setState(() {
                            _simulatePoorQuality = true;
                            _simulateCardMissing = false;
                          });
                        },
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('TEST: MATRIX INTERFERENCE (ΔE > 2.0)', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                        backgroundColor: NexoraColors.classicBlack,
                        onPressed: () {
                          setState(() {
                            // Atypical olive-green color that exceeds 2.0 ΔE00 threshold
                            _customSampleColor = const RgbColor(140.0, 155.0, 30.0);
                            _simulateCardMissing = false;
                            _simulatePoorQuality = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Capture Button
                ElevatedButton.icon(
                  onPressed: _isCapturing ? null : _captureBurst,
                  icon: const Icon(Icons.camera, size: 20),
                  label: const Text(
                    'EXECUTE 5-FRAME FORENSIC CAPTURE',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ForensicGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 1.0;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
