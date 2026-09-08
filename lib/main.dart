import 'package:flutter/material.dart';
import 'core/theme/forensic_theme.dart';
import 'features/authentication/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NexoraApp());
}

class NexoraApp extends StatelessWidget {
  const NexoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXORA',
      debugShowCheckedModeBanner: false,
      theme: ForensicTheme.darkTheme,
      home: const SplashScreen(),
    );
  }
}
