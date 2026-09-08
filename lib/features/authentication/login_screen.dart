import 'package:flutter/material.dart';
import '../../core/constants/color_constants.dart';
import '../../services/auth_service.dart';
import '../dashboard/officer_dashboard_screen.dart';
import '../citizen_watch/citizen_watch_screen.dart';

/// NEXORA Dual-Portal Authentication Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _badgeController = TextEditingController(text: 'BADGE-104');
  final _passwordController = TextEditingController(text: 'Password@123');
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = await AuthService().login(
        badgeId: _badgeController.text,
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OfficerDashboardScreen(session: session),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _fillPreset(String badge, String pass) {
    _badgeController.text = badge;
    _passwordController.text = pass;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NexoraColors.backgroundBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NexoraColors.cardDark,
                      border: Border.all(color: NexoraColors.borderStrong),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                border: Border.all(color: NexoraColors.tacticalKhaki),
                              ),
                              child: const Icon(Icons.shield, color: NexoraColors.tacticalKhaki, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NEXORA',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2.0,
                                    color: NexoraColors.pureWhite,
                                  ),
                                ),
                                Text(
                                  'OFFICER ACCESS PORTAL',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: NexoraColors.tacticalKhaki,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Authorized law enforcement access only. All authentication attempts and session activities are cryptographically sealed in the audit trail.',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 11,
                            color: NexoraColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Authentication Form
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NexoraColors.cardDark,
                      border: Border.all(color: NexoraColors.borderSubtle),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'OFFICER CREDENTIALS',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                            color: NexoraColors.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _badgeController,
                          decoration: const InputDecoration(
                            labelText: 'OFFICER BADGE ID',
                            hintText: 'e.g. BADGE-104',
                            prefixIcon: Icon(Icons.badge_outlined, color: NexoraColors.tacticalKhaki, size: 18),
                          ),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'PASSWORD',
                            hintText: 'Enter authorization passcode',
                            prefixIcon: Icon(Icons.lock_outline, color: NexoraColors.tacticalKhaki, size: 18),
                          ),
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: NexoraColors.alertRed.withOpacity(0.15),
                              border: Border.all(color: NexoraColors.alertRed),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: NexoraColors.alertRed, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      color: NexoraColors.pureWhite,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: NexoraColors.textInverse),
                                )
                              : const Text('AUTHENTICATE SESSION'),
                        ),

                        const SizedBox(height: 16),

                        // Preset quick selectors for SIH evaluators
                        const Text(
                          'EVALUATOR DEMO PRESETS (RBAC):',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: NexoraColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ActionChip(
                              label: const Text('OFFICER: 104', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                              backgroundColor: NexoraColors.classicBlack,
                              side: const BorderSide(color: NexoraColors.borderSubtle),
                              onPressed: () => _fillPreset('BADGE-104', 'Password@123'),
                            ),
                            ActionChip(
                              label: const Text('SUPERVISOR: 201', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                              backgroundColor: NexoraColors.classicBlack,
                              side: const BorderSide(color: NexoraColors.borderSubtle),
                              onPressed: () => _fillPreset('SUPER-201', 'Super@123'),
                            ),
                            ActionChip(
                              label: const Text('ADMIN: 001', style: TextStyle(fontSize: 10, fontFamily: 'monospace')),
                              backgroundColor: NexoraColors.classicBlack,
                              side: const BorderSide(color: NexoraColors.borderSubtle),
                              onPressed: () => _fillPreset('ADMIN-001', 'Admin@123'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Portal B: Citizen Watch
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CitizenWatchScreen()),
                      );
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                    label: const Text('ACCESS CITIZEN WATCH (ANONYMOUS TIP PORTAL)'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
