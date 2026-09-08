import '../services/color_engine.dart';

/// Authorized Forensic Spot-Test Reference Profile
/// Synthetic, non-hazardous reference standards derived from validated forensic spectrophotometry.
class ReferenceProfile {
  final String profileId;
  final String displayName;
  final String category;
  final String reagentName;
  final String functionalGroupTarget;
  final String referenceHex;
  final LabColor referenceLab;
  final double toleranceDeltaE;
  final String version;
  final String calibrationSource;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReferenceProfile({
    required this.profileId,
    required this.displayName,
    required this.category,
    required this.reagentName,
    required this.functionalGroupTarget,
    required this.referenceHex,
    LabColor? referenceLab,
    this.toleranceDeltaE = 2.0,
    this.version = 'v1.0',
    this.calibrationSource = 'NCFS-REFERENCE-LAB-2026',
    this.active = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : referenceLab = referenceLab ?? ColorEngine.rgbToLab(RgbColor.fromHex(referenceHex)),
        createdAt = createdAt ?? DateTime.now().toUtc(),
        updatedAt = updatedAt ?? DateTime.now().toUtc();

  Map<String, dynamic> toMap() {
    return {
      'profileId': profileId,
      'displayName': displayName,
      'category': category,
      'reagentName': reagentName,
      'functionalGroupTarget': functionalGroupTarget,
      'referenceHex': referenceHex,
      'referenceLab': referenceLab.toMap(),
      'toleranceDeltaE': toleranceDeltaE,
      'version': version,
      'calibrationSource': calibrationSource,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ReferenceProfile.fromMap(Map<String, dynamic> map) {
    LabColor? lab;
    if (map['referenceLab'] != null) {
      final m = map['referenceLab'] as Map<String, dynamic>;
      lab = LabColor(
        (m['l'] as num).toDouble(),
        (m['a'] as num).toDouble(),
        (m['b'] as num).toDouble(),
      );
    }
    return ReferenceProfile(
      profileId: map['profileId'] as String,
      displayName: map['displayName'] as String,
      category: map['category'] as String,
      reagentName: map['reagentName'] as String,
      functionalGroupTarget: map['functionalGroupTarget'] as String? ?? 'Forensic Standard',
      referenceHex: map['referenceHex'] as String,
      referenceLab: lab,
      toleranceDeltaE: (map['toleranceDeltaE'] as num?)?.toDouble() ?? 2.0,
      version: map['version'] as String? ?? 'v1.0',
      calibrationSource: map['calibrationSource'] as String? ?? 'NCFS-REFERENCE-LAB-2026',
      active: map['active'] as bool? ?? true,
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt'] as String) : null,
    );
  }

  /// Default baseline reference dataset
  /// Safe synthetic reference profiles matching standard presumptive spot-test chromatic outcomes
  static List<ReferenceProfile> getDefaultStandards() {
    return [
      ReferenceProfile(
        profileId: 'PROF-MQ-001',
        displayName: 'Reference Profile 101 (Purple-Black)',
        category: 'Phenethylamine / Entactogen Analogue',
        reagentName: 'Marquis Reagent',
        functionalGroupTarget: 'Aromatic ring with methylenedioxy bridge & amine',
        referenceHex: '#0F0210',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-MQ-002',
        displayName: 'Reference Profile 102 (Orange-Brown)',
        category: 'Phenethylamine / Primary Amine Stimulant',
        reagentName: 'Marquis Reagent',
        functionalGroupTarget: 'Primary amine on aliphatic side chain',
        referenceHex: '#7E3D11',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-MQ-003',
        displayName: 'Reference Profile 103 (Dark Red-Brown)',
        category: 'Phenethylamine / Secondary Amine Stimulant',
        reagentName: 'Marquis Reagent',
        functionalGroupTarget: 'Secondary amine on aliphatic side chain',
        referenceHex: '#6E1F00',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-MQ-004',
        displayName: 'Reference Profile 104 (Deep Violet)',
        category: 'Morphinan Core / Phenolic Esters',
        reagentName: 'Marquis Reagent',
        functionalGroupTarget: 'Morphinan skeleton with phenolic esters',
        referenceHex: '#2A0835',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-MC-001',
        displayName: 'Reference Profile 201 (Dark Blue-Green)',
        category: 'Morphinan Core / Alkaloid Standard',
        reagentName: 'Mecke Reagent',
        functionalGroupTarget: 'Morphinan core aromatic oxidation',
        referenceHex: '#0B4F42',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-MD-001',
        displayName: 'Reference Profile 301 (Dark Brown / Orange)',
        category: 'Arylcyclohexylamine / Dissociative Standard',
        reagentName: 'Mandelin Reagent',
        functionalGroupTarget: 'Secondary amine & ketone group oxidation',
        referenceHex: '#512E1A',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-EH-001',
        displayName: 'Reference Profile 401 (Pink to Deep Violet)',
        category: 'Ergoline / Indole Ring Core Standard',
        reagentName: 'Ehrlich Reagent',
        functionalGroupTarget: 'Indole ring aromatic electrophilic substitution',
        referenceHex: '#5B2C6F',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-SM-001',
        displayName: 'Reference Profile 501 (Deep Cobalt Blue)',
        category: 'Secondary Aliphatic Amine Standard',
        reagentName: "Simon's (A + B)",
        functionalGroupTarget: 'Secondary amine group (-NH-R)',
        referenceHex: '#1B4F72',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-SC-001',
        displayName: 'Reference Profile 601 (Bright Blue Precipitate)',
        category: 'Tropane Alkaloid / Tertiary Amine Standard',
        reagentName: 'Scott Reagent (Cobalt Thiocyanate)',
        functionalGroupTarget: 'Tertiary amine / ester complexation',
        referenceHex: '#154360',
        toleranceDeltaE: 2.0,
      ),
      ReferenceProfile(
        profileId: 'PROF-DL-001',
        displayName: 'Reference Profile 701 (Violet / Chloroform Phase)',
        category: 'Cannabinoid / Phenolic Ring Standard',
        reagentName: 'Duquenois-Levine Reagent',
        functionalGroupTarget: 'Phenolic ring condensation with vanillin',
        referenceHex: '#4A235A',
        toleranceDeltaE: 2.0,
      ),
    ];
  }
}
