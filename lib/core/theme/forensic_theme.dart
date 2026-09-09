import 'package:flutter/material.dart';
import '../constants/color_constants.dart';

/// NEXORA Official Forensic/Government Theme Configuration
class ForensicTheme {
  ForensicTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: NexoraColors.backgroundBlack,
      primaryColor: NexoraColors.tacticalKhaki,
      colorScheme: const ColorScheme.dark(
        primary: NexoraColors.tacticalKhaki,
        onPrimary: NexoraColors.textInverse,
        secondary: NexoraColors.deepBrown,
        onSecondary: NexoraColors.pureWhite,
        surface: NexoraColors.cardDark,
        onSurface: NexoraColors.textPrimary,
        error: NexoraColors.alertRed,
        onError: NexoraColors.pureWhite,
      ),
      fontFamily: 'monospace',
      appBarTheme: const AppBarTheme(
        backgroundColor: NexoraColors.classicBlack,
        foregroundColor: NexoraColors.pureWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'monospace',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: NexoraColors.pureWhite,
        ),
      ),
      cardTheme: const CardThemeData(
        color: NexoraColors.cardDark,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: NexoraColors.borderSubtle, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(2)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: NexoraColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: NexoraColors.tacticalKhaki,
          foregroundColor: NexoraColors.textInverse,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 13,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: NexoraColors.tacticalKhaki,
          side: const BorderSide(color: NexoraColors.tacticalKhaki, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(2)),
          ),
          textStyle: const TextStyle(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            fontSize: 13,
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: NexoraColors.classicBlack,
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: NexoraColors.borderSubtle, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: NexoraColors.borderSubtle, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: NexoraColors.tacticalKhaki, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(2)),
          borderSide: BorderSide(color: NexoraColors.alertRed, width: 1),
        ),
        labelStyle: TextStyle(
          color: NexoraColors.textSecondary,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
        hintStyle: TextStyle(
          color: NexoraColors.textMuted,
          fontSize: 13,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
