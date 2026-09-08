import 'dart:async';
import 'package:uuid/uuid.dart';
import '../models/evidence_record.dart';
import '../core/constants/app_constants.dart';
import '../core/security/hash_service.dart';
import '../core/security/hash_chain.dart';
import '../core/storage/database_helper.dart';
import 'color_engine.dart';
import 'camera_service.dart';
import 'location_service.dart';

/// NEXORA Evidence Orchestration & Integrity Management Service
class EvidenceService {
  static final EvidenceService _instance = EvidenceService._internal();
  factory EvidenceService() => _instance;
  EvidenceService._internal();

  final _uuid = const Uuid();

  /// Executes the end-to-end Field Test Analysis and Cryptographic Sealing Workflow
  Future<EvidenceRecord> executeFieldTestWorkflow({
    required String caseId,
    required String officerId,
    required String reagentUsed,
    required CameraCaptureBundle cameraBundle,
    required GpsLocationResult locationResult,
    String? officerNotes,
    double deltaEThreshold = AppConstants.defaultDeltaEThreshold,
  }) async {
    // 1. Audit: Test Started
    await DatabaseHelper().logAuditEvent(
      actorId: officerId,
      eventType: 'TEST_STARTED',
      metadata: {'caseId': caseId, 'reagent': reagentUsed},
    );

    // 2. Validate Image Quality
    final qualityResult = ColorEngine.validateImageQuality(
      averageBrightness: cameraBundle.estimatedBrightness,
      contrastRatio: cameraBundle.estimatedContrast,
      blurLaplacianVariance: cameraBundle.estimatedBlurScore,
      cardDetected: cameraBundle.referenceCardDetected,
    );

    // 3. Retrieve Active Reference Profiles
    final activeProfiles = await DatabaseHelper().getActiveProfiles();
    final profilesMaps = activeProfiles.map((p) => p.toMap()).toList();

    // 4. Run Color Science Engine
    final analysisOutcome = ColorEngine.analyzeColorAgainstProfiles(
      rawSampleRgb: cameraBundle.averagedSampleRgb,
      observedGrayPatch: cameraBundle.detectedGrayPatchRgb,
      activeProfiles: profilesMaps,
      qualityResult: qualityResult,
      deltaEThreshold: deltaEThreshold,
      engineVersion: AppConstants.engineVersion,
      datasetVersion: AppConstants.referenceDatasetVersion,
    );

    // 5. Generate Evidence Hash (Statutory Canonical Formula)
    final recordId = 'EV-${_uuid.v4().substring(0, 8).toUpperCase()}';
    final capturedAtUtc = cameraBundle.capturedAt.toIso8601String();

    final payloadBundle = HashService.generateEvidencePayload(
      rawImageHash: cameraBundle.rawImageHash,
      latitude: locationResult.latitude,
      longitude: locationResult.longitude,
      accuracy: locationResult.accuracyMeters,
      capturedAtUtc: capturedAtUtc,
      officerBadgeId: officerId,
      caseId: caseId,
      version: AppConstants.canonicalPayloadVersion,
    );

    final evidenceHash = payloadBundle['evidenceHash'] as String;
    final canonicalPayload = payloadBundle['canonicalPayload'] as String;

    // 6. Link into Immutable Append-Only Hash Chain
    final previousRecordHash = await DatabaseHelper().getLatestRecordHash();

    final recordHash = HashChainEngine.calculateRecordHash(
      recordId: recordId,
      evidenceHash: evidenceHash,
      previousRecordHash: previousRecordHash,
      timestampUtc: capturedAtUtc,
      officerId: officerId,
      recordVersion: 1,
    );

    // 7. Assemble Complete Forensic Evidence Record
    final evidenceRecord = EvidenceRecord(
      id: recordId,
      caseId: caseId,
      officerId: officerId,
      capturedAtUtc: capturedAtUtc,
      gpsLatitude: locationResult.latitude,
      gpsLongitude: locationResult.longitude,
      gpsAccuracy: locationResult.accuracyMeters,
      rawImageHash: cameraBundle.rawImageHash,
      evidenceHash: evidenceHash,
      previousRecordHash: previousRecordHash,
      recordHash: recordHash,
      recordVersion: 1,
      analysisStatus: analysisOutcome.status,
      possibleMatches: analysisOutcome.rankedMatches,
      confidence: analysisOutcome.topMatch?.confidenceRating ?? 'INCONCLUSIVE',
      deltaE: analysisOutcome.bestDeltaE,
      imageQuality: qualityResult.statusText,
      calibrationQuality: analysisOutcome.calibrationQuality,
      engineVersion: AppConstants.engineVersion,
      referenceDatasetVersion: AppConstants.referenceDatasetVersion,
      syncStatus: 'PENDING_SYNC',
      integrityStatus: AppConstants.integrityVerified,
      canonicalPayload: canonicalPayload,
      sampleColorHex: analysisOutcome.normalizedRgb.toHex(),
      reagentUsed: reagentUsed,
      officerNotes: officerNotes,
    );

    // 8. Persist to Encrypted Local Database
    await DatabaseHelper().insertEvidenceRecord(evidenceRecord);

    return evidenceRecord;
  }

  /// Verifies the full chain of custody across all stored evidence records
  Future<Map<String, dynamic>> verifyVaultIntegrity() async {
    final chain = await DatabaseHelper().getEvidenceChainChronological();
    return HashChainEngine.verifyChain(chain);
  }

  /// Developer/SIH Demonstration Mode:
  /// Simulates a single-bit alteration on a copy of a record to prove instant tampering detection.
  Future<Map<String, dynamic>> runTamperDemonstration() async {
    final chain = await DatabaseHelper().getEvidenceChainChronological();
    return HashChainEngine.simulateTamperingDemonstration(chain);
  }
}
