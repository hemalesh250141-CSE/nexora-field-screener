import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import 'citizen_tip_submission_screen.dart';

/// NEXORA Citizen Watch Public Community Portal
class CitizenWatchScreen extends StatelessWidget {
  const CitizenWatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      appBar: AppBar(
        title: const Text('CITIZEN WATCH PORTAL'),
        backgroundColor: NexoraColors.classicBlack,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Public banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: NexoraColors.cardDark,
                border: Border.all(color: NexoraColors.tacticalKhaki),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: NexoraColors.classicBlack,
                          border: Border.all(color: NexoraColors.tacticalKhaki),
                        ),
                        child: const Icon(Icons.remove_red_eye_outlined, color: NexoraColors.tacticalKhaki, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXORA CITIZEN WATCH',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: NexoraColors.pureWhite,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'ANONYMOUS COMMUNITY REPORTING',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: NexoraColors.tacticalKhaki,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Help keep your neighborhood safe by submitting anonymous community observations. No registration, personal identification, or contact info is requested.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: NexoraColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Privacy & Protections Guarantee
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NexoraColors.classicBlack,
                border: Border.all(color: NexoraColors.borderSubtle),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DATA PRIVACY & ANONYMITY PROTOCOL',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: NexoraColors.tacticalKhaki,
                    ),
                  ),
                  SizedBox(height: 8),
                  _FeatureBullet(text: 'Zero identity tracking: No names, phone numbers, or account creation.'),
                  _FeatureBullet(text: 'Cryptographic anonymous receipt ID generated upon submission.'),
                  _FeatureBullet(text: 'Optional GPS geotagging: only shared if explicitly enabled.'),
                  _FeatureBullet(text: 'Secure encrypted transmission directly to authorized zonal dispatch.'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CitizenTipSubmissionScreen()),
                );
              },
              icon: const Icon(Icons.send_outlined, size: 18),
              label: const Text('SUBMIT ANONYMOUS COMMUNITY TIP'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 13, fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final String text;
  const _FeatureBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 14, color: NexoraColors.verifiedGreen),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: NexoraColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
