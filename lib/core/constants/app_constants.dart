/// NEXORA System & Forensic Constants
class AppConstants {
  AppConstants._();

  static const String appName = 'NEXORA';
  static const String appTagline = 'Digital Field Testing Companion';
  static const String engineVersion = 'CIE-DE2000-v1.4';
  static const String referenceDatasetVersion = 'DS-FORENSIC-2026.1';
  static const String canonicalPayloadVersion = '1.0';

  /// Statutory Mandatory Notice
  static const String statutoryDisclaimer =
      'Presumptive Field Screener Only — Confirmatory Lab Testing (GC-MS) Statutorily Mandated.';

  /// Presumptive output terminology (Mandatory scientific standard)
  static const String presumptiveResultHeader = 'PRESUMPTIVE RESULT';
  static const String possibleMatchesHeader = 'Possible matching reference profiles';
  static const String inconclusiveHeader = 'INCONCLUSIVE';

  /// Threshold for color difference: ΔE00 > 2.0 indicates inconclusive / matrix interference
  static const double defaultDeltaEThreshold = 2.0;

  /// Default burst capture frame count
  static const int defaultFrameBurstCount = 5;

  /// Offline Sync Policies
  static const int maxSyncRetries = 5;
  static const Duration initialSyncBackoff = Duration(seconds: 3);
  static const Duration maxSyncBackoff = Duration(minutes: 5);

  /// User Roles
  static const String roleOfficer = 'OFFICER';
  static const String roleSupervisor = 'SUPERVISOR';
  static const String roleAdmin = 'ADMIN';

  /// Verification States
  static const String integrityVerified = 'INTEGRITY VERIFIED';
  static const String integrityFailure = 'INTEGRITY FAILURE';
}
