import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../models/citizen_tip.dart';

/// Anonymous Tip Submission Confirmation Screen
class SubmissionConfirmationScreen extends StatelessWidget {
  final CitizenTip tip;

  const SubmissionConfirmationScreen({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NexoraColors.verifiedGreen.withOpacity(0.15),
                    border: Border.all(color: NexoraColors.verifiedGreen, width: 2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: NexoraColors.verifiedGreen,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TIP SUBMITTED SUCCESSFULLY',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    color: NexoraColors.pureWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your observation has been encrypted and securely routed to authorized field intake.',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: NexoraColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Anonymous Receipt Box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NexoraColors.cardDark,
                    border: Border.all(color: NexoraColors.tacticalKhaki),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'ANONYMOUS TRACKING REFERENCE ID',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: NexoraColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        tip.tipId,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: NexoraColors.tacticalKhaki,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Category: ${tip.category}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.textSecondary),
                      ),
                      Text(
                        'Timestamp: ${tip.submittedAtUtc}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: NexoraColors.textMuted),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('RETURN TO PORTAL'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
