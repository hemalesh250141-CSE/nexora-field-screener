import 'dart:convert';
import '../services/color_engine.dart';

/// NEXORA Forensic Evidence Record Model
/// Sealed, append-only, tamper-evident record of field testing.
class EvidenceRecord {
  final String id;
  final String caseId;
  final String officerId;
  final String capturedAtUtc;
  final double gpsLatitude;
  final double gpsLongitude;
  final double gpsAccuracy;
  final String rawImageHash;
  final String evidenceHash;
  final String previousRecordHash;
  final String recordHash;
  final int recordVersion;
  final String analysisStatus; // 'PRESUMPTIVE' or 'INCONCLUSIVE'
  final List<ProfileMatchResult> possibleMatches;
  final String confidence;
  final double deltaE;
  final String imageQuality;
  final String calibrationQuality;
  final String engineVersion;
  final String referenceDatasetVersion;
  final String syncStatus; // 'PENDING_SYNC', 'SYNCING', 'SYNCED', 'FAILED'
  final String integrityStatus; // 'INTEGRITY VERIFIED', 'INTEGRITY FAILURE'
  final String canonicalPayload;
  final String? sampleColorHex;
  final String? reagentUsed;
  final String? officerNotes;

  const EvidenceRecord({
    required this.id,
    required this.caseId,
    required this.officerId,
    required this.capturedAtUtc,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.gpsAccuracy,
    required this.rawImageHash,
    required this.evidenceHash,
    required this.previousRecordHash,
    required this.recordHash,
    this.recordVersion = 1,
    required this.analysisStatus,
    required this.possibleMatches,
    required this.confidence,
    required this.deltaE,
    required this.imageQuality,
    required this.calibrationQuality,
    required this.engineVersion,
    required this.referenceDatasetVersion,
    this.syncStatus = 'PENDING_SYNC',
    this.integrityStatus = 'INTEGRITY VERIFIED',
    required this.canonicalPayload,
    this.sampleColorHex,
    this.reagentUsed,
    this.officerNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'caseId': caseId,
      'officerId': officerId,
      'capturedAtUtc': capturedAtUtc,
      'gpsLatitude': gpsLatitude,
      'gpsLongitude': gpsLongitude,
      'gpsAccuracy': gpsAccuracy,
      'rawImageHash': rawImageHash,
      'evidenceHash': evidenceHash,
      'previousRecordHash': previousRecordHash,
      'recordHash': recordHash,
      'recordVersion': recordVersion,
      'analysisStatus': analysisStatus,
      'possibleMatches': jsonEncode(possibleMatches.map((m) => m.toMap()).toList()),
      'confidence': confidence,
      'deltaE': deltaE,
      'imageQuality': imageQuality,
      'calibrationQuality': calibrationQuality,
      'engineVersion': engineVersion,
      'referenceDatasetVersion': referenceDatasetVersion,
      'syncStatus': syncStatus,
      'integrityStatus': integrityStatus,
      'canonicalPayload': canonicalPayload,
      'sampleColorHex': sampleColorHex,
      'reagentUsed': reagentUsed,
      'officerNotes': officerNotes,
    };
  }

  factory EvidenceRecord.fromMap(Map<String, dynamic> map) {
    List<ProfileMatchResult> matches = [];
    if (map['possibleMatches'] != null) {
      dynamic raw = map['possibleMatches'];
      if (raw is String) {
        try {
          final decoded = jsonDecode(raw) as List;
          matches = decoded.map((item) {
            final m = item as Map<String, dynamic>;
            final obs = m['observedLab'] as Map<String, dynamic>;
            final ref = m['referenceLab'] as Map<String, dynamic>;
            return ProfileMatchResult(
              profileId: m['profileId'] as String,
              displayName: m['displayName'] as String,
              category: m['category'] as String,
              reagentName: m['reagentName'] as String,
              deltaE00: (m['deltaE00'] as num).toDouble(),
              similarityPercent: (m['similarityPercent'] as num).toDouble(),
              confidenceRating: m['confidenceRating'] as String,
              observedLab: LabColor(
                (obs['l'] as num).toDouble(),
                (obs['a'] as num).toDouble(),
                (obs['b'] as num).toDouble(),
              ),
              referenceLab: LabColor(
                (ref['l'] as num).toDouble(),
                (ref['a'] as num).toDouble(),
                (ref['b'] as num).toDouble(),
              ),
            );
          }).toList();
        } catch (_) {}
      } else if (raw is List) {
        // Direct list
      }
    }

    return EvidenceRecord(
      id: map['id'] as String,
      caseId: map['caseId'] as String,
      officerId: map['officerId'] as String,
      capturedAtUtc: map['capturedAtUtc'] as String,
      gpsLatitude: (map['gpsLatitude'] as num).toDouble(),
      gpsLongitude: (map['gpsLongitude'] as num).toDouble(),
      gpsAccuracy: (map['gpsAccuracy'] as num).toDouble(),
      rawImageHash: map['rawImageHash'] as String,
      evidenceHash: map['evidenceHash'] as String,
      previousRecordHash: map['previousRecordHash'] as String,
      recordHash: map['recordHash'] as String,
      recordVersion: (map['recordVersion'] as int?) ?? 1,
      analysisStatus: map['analysisStatus'] as String,
      possibleMatches: matches,
      confidence: map['confidence'] as String,
      deltaE: (map['deltaE'] as num).toDouble(),
      imageQuality: map['imageQuality'] as String,
      calibrationQuality: map['calibrationQuality'] as String,
      engineVersion: map['engineVersion'] as String,
      referenceDatasetVersion: map['referenceDatasetVersion'] as String,
      syncStatus: map['syncStatus'] as String? ?? 'PENDING_SYNC',
      integrityStatus: map['integrityStatus'] as String? ?? 'INTEGRITY VERIFIED',
      canonicalPayload: map['canonicalPayload'] as String,
      sampleColorHex: map['sampleColorHex'] as String?,
      reagentUsed: map['reagentUsed'] as String?,
      officerNotes: map['officerNotes'] as String?,
    );
  }

  EvidenceRecord copyWith({
    String? syncStatus,
    String? integrityStatus,
    String? officerNotes,
  }) {
    return EvidenceRecord(
      id: id,
      caseId: caseId,
      officerId: officerId,
      capturedAtUtc: capturedAtUtc,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      gpsAccuracy: gpsAccuracy,
      rawImageHash: rawImageHash,
      evidenceHash: evidenceHash,
      previousRecordHash: previousRecordHash,
      recordHash: recordHash,
      recordVersion: recordVersion,
      analysisStatus: analysisStatus,
      possibleMatches: possibleMatches,
      confidence: confidence,
      deltaE: deltaE,
      imageQuality: imageQuality,
      calibrationQuality: calibrationQuality,
      engineVersion: engineVersion,
      referenceDatasetVersion: referenceDatasetVersion,
      syncStatus: syncStatus ?? this.syncStatus,
      integrityStatus: integrityStatus ?? this.integrityStatus,
      canonicalPayload: canonicalPayload,
      sampleColorHex: sampleColorHex,
      reagentUsed: reagentUsed,
      officerNotes: officerNotes ?? this.officerNotes,
    );
  }
}
