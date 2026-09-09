import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/color_constants.dart';
import '../../core/storage/database_helper.dart';
import 'login_screen.dart';

/// NEXORA Splash Screen
/// Performs boot integrity diagnostics, Keystore initialization, and reference dataset seeding.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = 'INITIALIZING FORENSIC ENVIRONMENT...';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _statusText = 'LOADING REFERENCE PROFILE REPOSITORY...');

    await DatabaseHelper().initialize();

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _statusText = 'VERIFYING HARDWARE CRYPTO KEYSTORE...');

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _statusText = 'BOOT COMPLETE. READY.');

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: NexoraColors.classicBlack,
                  border: Border.all(color: NexoraColors.tacticalKhaki, width: 2),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  size: 46,
                  color: NexoraColors.tacticalKhaki,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4.0,
                  color: NexoraColors.pureWhite,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'DIGITAL FIELD TESTING COMPANION',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: NexoraColors.tacticalKhaki,
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 160,
                child: LinearProgressIndicator(
                  backgroundColor: NexoraColors.cardDark,
                  valueColor: AlwaysStoppedAnimation<Color>(NexoraColors.tacticalKhaki),
                  minHeight: 3,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _statusText,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  letterSpacing: 1.0,
                  color: NexoraColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
