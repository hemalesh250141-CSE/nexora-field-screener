import 'dart:math' as math;

/// CIE Color Representations
class RgbColor {
  final double r;
  final double g;
  final double b;

  const RgbColor(this.r, this.g, this.b);

  factory RgbColor.fromHex(String hex) {
    String cleanHex = hex.replaceAll('#', '').trim();
    if (cleanHex.length == 6) {
      final int val = int.parse(cleanHex, radix: 16);
      return RgbColor(
        ((val >> 16) & 0xFF).toDouble(),
        ((val >> 8) & 0xFF).toDouble(),
        (val & 0xFF).toDouble(),
      );
    } else {
      throw ArgumentError('Invalid hex color format: $hex');
    }
  }

  String toHex() {
    int ri = r.round().clamp(0, 255);
    int gi = g.round().clamp(0, 255);
    int bi = b.round().clamp(0, 255);
    return '#${ri.toRadixString(16).padLeft(2, '0')}${gi.toRadixString(16).padLeft(2, '0')}${bi.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
  }

  Map<String, dynamic> toMap() => {'r': r, 'g': g, 'b': b, 'hex': toHex()};
}

class XyzColor {
  final double x;
  final double y;
  final double z;

  const XyzColor(this.x, this.y, this.z);

  Map<String, dynamic> toMap() => {'x': x, 'y': y, 'z': z};
}

class LabColor {
  final double l;
  final double a;
  final double b;

  const LabColor(this.l, this.a, this.b);

  Map<String, dynamic> toMap() => {'l': l, 'a': a, 'b': b};
}

enum ImageQualityTier { good, acceptable, insufficient }

class ImageQualityResult {
  final ImageQualityTier tier;
  final double brightness;
  final double contrast;
  final double blurScore;
  final String statusText;
  final List<String> notices;

  const ImageQualityResult({
    required this.tier,
    required this.brightness,
    required this.contrast,
    required this.blurScore,
    required this.statusText,
    required this.notices,
  });

  Map<String, dynamic> toMap() => {
        'tier': tier.name.toUpperCase(),
        'brightness': brightness,
        'contrast': contrast,
        'blurScore': blurScore,
        'statusText': statusText,
        'notices': notices,
      };
}

class ProfileMatchResult {
  final String profileId;
  final String displayName;
  final String category;
  final String reagentName;
  final double deltaE00;
  final double similarityPercent;
  final String confidenceRating;
  final LabColor observedLab;
  final LabColor referenceLab;

  const ProfileMatchResult({
    required this.profileId,
    required this.displayName,
    required this.category,
    required this.reagentName,
    required this.deltaE00,
    required this.similarityPercent,
    required this.confidenceRating,
    required this.observedLab,
    required this.referenceLab,
  });

  Map<String, dynamic> toMap() => {
        'profileId': profileId,
        'displayName': displayName,
        'category': category,
        'reagentName': reagentName,
        'deltaE00': double.parse(deltaE00.toStringAsFixed(3)),
        'similarityPercent': double.parse(similarityPercent.toStringAsFixed(1)),
        'confidenceRating': confidenceRating,
        'observedLab': observedLab.toMap(),
        'referenceLab': referenceLab.toMap(),
      };
}

class ForensicAnalysisOutcome {
  final String status; // 'PRESUMPTIVE' or 'INCONCLUSIVE'
  final String summaryTitle;
  final List<ProfileMatchResult> rankedMatches;
  final ProfileMatchResult? topMatch;
  final double bestDeltaE;
  final RgbColor rawRgb;
  final RgbColor normalizedRgb;
  final LabColor normalizedLab;
  final ImageQualityResult imageQuality;
  final String calibrationQuality;
  final String engineVersion;
  final String datasetVersion;
  final String? inconclusiveReason;

  const ForensicAnalysisOutcome({
    required this.status,
    required this.summaryTitle,
    required this.rankedMatches,
    this.topMatch,
    required this.bestDeltaE,
    required this.rawRgb,
    required this.normalizedRgb,
    required this.normalizedLab,
    required this.imageQuality,
    required this.calibrationQuality,
    required this.engineVersion,
    required this.datasetVersion,
    this.inconclusiveReason,
  });

  Map<String, dynamic> toMap() => {
        'status': status,
        'summaryTitle': summaryTitle,
        'rankedMatches': rankedMatches.map((m) => m.toMap()).toList(),
        'topMatch': topMatch?.toMap(),
        'bestDeltaE': double.parse(bestDeltaE.toStringAsFixed(3)),
        'rawRgb': rawRgb.toMap(),
        'normalizedRgb': normalizedRgb.toMap(),
        'normalizedLab': normalizedLab.toMap(),
        'imageQuality': imageQuality.toMap(),
        'calibrationQuality': calibrationQuality,
        'engineVersion': engineVersion,
        'datasetVersion': datasetVersion,
        'inconclusiveReason': inconclusiveReason,
      };
}

/// NEXORA Mathematical Color Science Engine
/// Rigorous implementation of CIE standards: RGB -> XYZ -> CIELAB -> CIEDE2000.
class ColorEngine {
  ColorEngine._();

  // D65 Standard Illuminant Reference White Point (2° standard observer)
  static const double xn = 0.95047;
  static const double yn = 1.00000;
  static const double zn = 1.08883;

  // Nominal 18% Neutral Gray Patch (sRGB [118, 118, 118])
  static const RgbColor nominalNeutralGray = RgbColor(118.0, 118.0, 118.0);

  /// 1. Converts standard sRGB to Linear RGB (Inverse Companding)
  static double _sRgbToLinear(double channel) {
    final double v = channel / 255.0;
    if (v <= 0.04045) {
      return v / 12.92;
    } else {
      return math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }
  }

  /// 2. Converts Linear RGB to CIE XYZ (D65 illuminant)
  static XyzColor rgbToXyz(RgbColor rgb) {
    final double rLin = _sRgbToLinear(rgb.r);
    final double gLin = _sRgbToLinear(rgb.g);
    final double bLin = _sRgbToLinear(rgb.b);

    final double x = 0.4124564 * rLin + 0.3575761 * gLin + 0.1804375 * bLin;
    final double y = 0.2126729 * rLin + 0.7151522 * gLin + 0.0721750 * bLin;
    final double z = 0.0193339 * rLin + 0.1191920 * gLin + 0.9503041 * bLin;

    return XyzColor(x, y, z);
  }

  /// 3. Converts CIE XYZ to CIE L*a*b* (CIELAB 1976)
  static LabColor xyzToLab(XyzColor xyz) {
    double f(double t) {
      const double epsilon = 216.0 / 24389.0; // ~0.008856
      const double kappa = 24389.0 / 27.0; // ~903.3
      if (t > epsilon) {
        return math.pow(t, 1.0 / 3.0).toDouble();
      } else {
        return (kappa * t + 16.0) / 116.0;
      }
    }

    final double fx = f(xyz.x / xn);
    final double fy = f(xyz.y / yn);
    final double fz = f(xyz.z / zn);

    final double l = (116.0 * fy) - 16.0;
    final double a = 500.0 * (fx - fy);
    final double b = 200.0 * (fy - fz);

    return LabColor(l, a, b);
  }

  /// Convenience helper: sRGB directly to CIELAB
  static LabColor rgbToLab(RgbColor rgb) {
    final xyz = rgbToXyz(rgb);
    return xyzToLab(xyz);
  }

  /// 4. CIEDE2000 Color Difference Formula (ISO/CIE 11664-6:2014)
  /// Sharma-Wu-Dalal Implementation
  static double calculateCiede2000(LabColor lab1, LabColor lab2) {
    final double l1 = lab1.l;
    final double a1 = lab1.a;
    final double b1 = lab1.b;

    final double l2 = lab2.l;
    final double a2 = lab2.a;
    final double b2 = lab2.b;

    final double c1 = math.sqrt(a1 * a1 + b1 * b1);
    final double c2 = math.sqrt(a2 * a2 + b2 * b2);
    final double cBar = (c1 + c2) / 2.0;

    final double cBar7 = math.pow(cBar, 7).toDouble();
    final double gFactor = 0.5 * (1.0 - math.sqrt(cBar7 / (cBar7 + 6103515625.0))); // 25^7 = 6103515625

    final double a1Prime = (1.0 + gFactor) * a1;
    final double a2Prime = (1.0 + gFactor) * a2;

    final double c1Prime = math.sqrt(a1Prime * a1Prime + b1 * b1);
    final double c2Prime = math.sqrt(a2Prime * a2Prime + b2 * b2);

    double h1Prime = math.atan2(b1, a1Prime) * 180.0 / math.pi;
    if (h1Prime < 0) h1Prime += 360.0;

    double h2Prime = math.atan2(b2, a2Prime) * 180.0 / math.pi;
    if (h2Prime < 0) h2Prime += 360.0;

    final double deltaLPrime = l2 - l1;
    final double deltaCPrime = c2Prime - c1Prime;

    double deltaHPrimeVal;
    if (c1Prime * c2Prime == 0) {
      deltaHPrimeVal = 0.0;
    } else if ((h2Prime - h1Prime).abs() <= 180.0) {
      deltaHPrimeVal = h2Prime - h1Prime;
    } else if (h2Prime - h1Prime > 180.0) {
      deltaHPrimeVal = (h2Prime - h1Prime) - 360.0;
    } else {
      deltaHPrimeVal = (h2Prime - h1Prime) + 360.0;
    }

    final double deltaHPrime = 2.0 *
        math.sqrt(c1Prime * c2Prime) *
        math.sin((deltaHPrimeVal / 2.0) * math.pi / 180.0);

    final double lBarPrime = (l1 + l2) / 2.0;
    final double cBarPrime = (c1Prime + c2Prime) / 2.0;

    double hBarPrime;
    if (c1Prime * c2Prime == 0) {
      hBarPrime = h1Prime + h2Prime;
    } else if ((h1Prime - h2Prime).abs() <= 180.0) {
      hBarPrime = (h1Prime + h2Prime) / 2.0;
    } else if (h1Prime + h2Prime < 360.0) {
      hBarPrime = (h1Prime + h2Prime + 360.0) / 2.0;
    } else {
      hBarPrime = (h1Prime + h2Prime - 360.0) / 2.0;
    }

    final double t = 1.0 -
        0.17 * math.cos((hBarPrime - 30.0) * math.pi / 180.0) +
        0.24 * math.cos((2.0 * hBarPrime) * math.pi / 180.0) +
        0.32 * math.cos((3.0 * hBarPrime + 6.0) * math.pi / 180.0) -
        0.20 * math.cos((4.0 * hBarPrime - 63.0) * math.pi / 180.0);

    final double deltaTheta =
        30.0 * math.exp(-math.pow((hBarPrime - 275.0) / 25.0, 2));

    final double cBarPrime7 = math.pow(cBarPrime, 7).toDouble();
    final double rc = 2.0 * math.sqrt(cBarPrime7 / (cBarPrime7 + 6103515625.0));

    final double sl = 1.0 +
        (0.015 * math.pow(lBarPrime - 50.0, 2)) /
            math.sqrt(20.0 + math.pow(lBarPrime - 50.0, 2));
    final double sc = 1.0 + 0.045 * cBarPrime;
    final double sh = 1.0 + 0.015 * cBarPrime * t;
    final double rt = -rc * math.sin(2.0 * deltaTheta * math.pi / 180.0);

    const double kl = 1.0;
    const double kc = 1.0;
    const double kh = 1.0;

    final double lTerm = deltaLPrime / (kl * sl);
    final double cTerm = deltaCPrime / (kc * sc);
    final double hTerm = deltaHPrime / (kh * sh);

    final double deltaE00Sq =
        (lTerm * lTerm) + (cTerm * cTerm) + (hTerm * hTerm) + (rt * cTerm * hTerm);

    return math.sqrt(math.max(0.0, deltaE00Sq));
  }

  /// 5. Reference Card Calibration & Color Normalization
  /// Normalizes observed reaction RGB using neutral-gray patch gains.
  static RgbColor normalizeColor({
    required RgbColor observedRgb,
    required RgbColor observedGrayPatch,
    RgbColor nominalGray = nominalNeutralGray,
  }) {
    // Prevent division by zero
    final double gR = observedGrayPatch.r > 1.0 ? nominalGray.r / observedGrayPatch.r : 1.0;
    final double gG = observedGrayPatch.g > 1.0 ? nominalGray.g / observedGrayPatch.g : 1.0;
    final double gB = observedGrayPatch.b > 1.0 ? nominalGray.b / observedGrayPatch.b : 1.0;

    final double normR = (observedRgb.r * gR).clamp(0.0, 255.0);
    final double normG = (observedRgb.g * gG).clamp(0.0, 255.0);
    final double normB = (observedRgb.b * gB).clamp(0.0, 255.0);

    return RgbColor(normR, normG, normB);
  }

  /// 6. Image Quality Assessment Engine
  static ImageQualityResult validateImageQuality({
    required double averageBrightness,
    required double contrastRatio,
    required double blurLaplacianVariance,
    required bool cardDetected,
  }) {
    final List<String> notices = [];
    ImageQualityTier tier = ImageQualityTier.good;

    if (!cardDetected) {
      notices.add('Reference card neutral patch not detected in field of view.');
      return const ImageQualityResult(
        tier: ImageQualityTier.insufficient,
        brightness: 0.0,
        contrast: 0.0,
        blurScore: 0.0,
        statusText: 'QUALITY: INSUFFICIENT',
        notices: ['Reference card missing or unreadable'],
      );
    }

    if (averageBrightness < 40.0) {
      notices.add('Severe underexposure detected (low ambient lighting).');
      tier = ImageQualityTier.insufficient;
    } else if (averageBrightness > 230.0) {
      notices.add('Severe overexposure / glare clipping detected.');
      tier = ImageQualityTier.insufficient;
    } else if (averageBrightness < 60.0 || averageBrightness > 205.0) {
      notices.add('Marginal exposure conditions.');
      if (tier != ImageQualityTier.insufficient) tier = ImageQualityTier.acceptable;
    }

    if (contrastRatio < 1.3) {
      notices.add('Low scene contrast ratio.');
      if (tier != ImageQualityTier.insufficient) tier = ImageQualityTier.acceptable;
    }

    if (blurLaplacianVariance < 45.0) {
      notices.add('Motion blur or camera instability detected.');
      tier = ImageQualityTier.insufficient;
    } else if (blurLaplacianVariance < 90.0) {
      notices.add('Acceptable camera focus.');
      if (tier != ImageQualityTier.insufficient) tier = ImageQualityTier.acceptable;
    }

    String statusText = tier == ImageQualityTier.good
        ? 'QUALITY: GOOD'
        : tier == ImageQualityTier.acceptable
            ? 'QUALITY: ACCEPTABLE'
            : 'QUALITY: INSUFFICIENT';

    return ImageQualityResult(
      tier: tier,
      brightness: averageBrightness,
      contrast: contrastRatio,
      blurScore: blurLaplacianVariance,
      statusText: statusText,
      notices: notices,
    );
  }

  /// Converts ΔE00 into a forensic percentage similarity score [0% - 100%]
  static double calculateSimilarity(double deltaE00) {
    if (deltaE00 <= 0.0) return 100.0;
    // Standard perceptual decay curve: ΔE <= 1.0 is ~95-100%, ΔE=2.0 is ~80%, ΔE=5 is ~45%
    double sim = 100.0 / (1.0 + 0.12 * math.pow(deltaE00, 1.4));
    return sim.clamp(0.0, 100.0);
  }

  static String getConfidenceRating(double deltaE00) {
    if (deltaE00 <= 1.2) {
      return 'HIGH SIMILARITY';
    } else if (deltaE00 <= 2.0) {
      return 'MODERATE SIMILARITY';
    } else if (deltaE00 <= 3.5) {
      return 'LOW SIMILARITY';
    } else {
      return 'INCONCLUSIVE';
    }
  }

  /// 7. Multi-Reference Profile Matching & Ranking
  static ForensicAnalysisOutcome analyzeColorAgainstProfiles({
    required RgbColor rawSampleRgb,
    required RgbColor observedGrayPatch,
    required List<Map<String, dynamic>> activeProfiles,
    required ImageQualityResult qualityResult,
    double deltaEThreshold = 2.0,
    String engineVersion = 'CIE-DE2000-v1.4',
    String datasetVersion = 'DS-FORENSIC-2026.1',
  }) {
    // 1. Check Image Quality Gate
    if (qualityResult.tier == ImageQualityTier.insufficient) {
      return ForensicAnalysisOutcome(
        status: 'INCONCLUSIVE',
        summaryTitle: 'INCONCLUSIVE (Image Quality Failure)',
        rankedMatches: const [],
        bestDeltaE: 999.0,
        rawRgb: rawSampleRgb,
        normalizedRgb: rawSampleRgb,
        normalizedLab: rgbToLab(rawSampleRgb),
        imageQuality: qualityResult,
        calibrationQuality: 'INSUFFICIENT',
        engineVersion: engineVersion,
        datasetVersion: datasetVersion,
        inconclusiveReason: 'Image quality insufficient: ${qualityResult.notices.join("; ")}',
      );
    }

    // 2. Normalize Color using neutral gray reference
    final normalizedRgb = normalizeColor(
      observedRgb: rawSampleRgb,
      observedGrayPatch: observedGrayPatch,
    );
    final observedLab = rgbToLab(normalizedRgb);

    // 3. Compute ΔE00 against all active reference profiles
    final List<ProfileMatchResult> results = [];

    for (final profile in activeProfiles) {
      final profileId = profile['profileId'] as String;
      final displayName = profile['displayName'] as String;
      final category = profile['category'] as String;
      final reagentName = profile['reagentName'] as String? ?? 'Spot Test';

      LabColor refLab;
      if (profile['referenceLab'] != null) {
        final labMap = profile['referenceLab'] as Map<String, dynamic>;
        refLab = LabColor(
          (labMap['l'] as num).toDouble(),
          (labMap['a'] as num).toDouble(),
          (labMap['b'] as num).toDouble(),
        );
      } else if (profile['referenceHex'] != null) {
        final refRgb = RgbColor.fromHex(profile['referenceHex'] as String);
        refLab = rgbToLab(refRgb);
      } else {
        continue;
      }

      final deltaE = calculateCiede2000(observedLab, refLab);
      final sim = calculateSimilarity(deltaE);
      final rating = getConfidenceRating(deltaE);

      results.add(ProfileMatchResult(
        profileId: profileId,
        displayName: displayName,
        category: category,
        reagentName: reagentName,
        deltaE00: deltaE,
        similarityPercent: sim,
        confidenceRating: rating,
        observedLab: observedLab,
        referenceLab: refLab,
      ));
    }

    // 4. Rank by lowest ΔE00 (highest similarity)
    results.sort((a, b) => a.deltaE00.compareTo(b.deltaE00));

    if (results.isEmpty) {
      return ForensicAnalysisOutcome(
        status: 'INCONCLUSIVE',
        summaryTitle: 'INCONCLUSIVE (No Reference Dataset)',
        rankedMatches: const [],
        bestDeltaE: 999.0,
        rawRgb: rawSampleRgb,
        normalizedRgb: normalizedRgb,
        normalizedLab: observedLab,
        imageQuality: qualityResult,
        calibrationQuality: 'ACCEPTABLE',
        engineVersion: engineVersion,
        datasetVersion: datasetVersion,
        inconclusiveReason: 'No authorized reference profiles available for comparison.',
      );
    }

    final top = results.first;

    // 5. Apply Forensic Threshold (ΔE00 > threshold -> INCONCLUSIVE)
    if (top.deltaE00 > deltaEThreshold) {
      return ForensicAnalysisOutcome(
        status: 'INCONCLUSIVE',
        summaryTitle: 'INCONCLUSIVE / MATRIX INTERFERENCE',
        rankedMatches: results,
        topMatch: top,
        bestDeltaE: top.deltaE00,
        rawRgb: rawSampleRgb,
        normalizedRgb: normalizedRgb,
        normalizedLab: observedLab,
        imageQuality: qualityResult,
        calibrationQuality: 'CALIBRATED',
        engineVersion: engineVersion,
        datasetVersion: datasetVersion,
        inconclusiveReason:
            'Observed colour difference (ΔE00 = ${top.deltaE00.toStringAsFixed(2)}) exceeds authorized threshold ($deltaEThreshold). Possible matrix interference or atypical profile.',
      );
    }

    // 6. Confirmed Presumptive Match
    return ForensicAnalysisOutcome(
      status: 'PRESUMPTIVE',
      summaryTitle: 'PRESUMPTIVE RESULT',
      rankedMatches: results,
      topMatch: top,
      bestDeltaE: top.deltaE00,
      rawRgb: rawSampleRgb,
      normalizedRgb: normalizedRgb,
      normalizedLab: observedLab,
      imageQuality: qualityResult,
      calibrationQuality: 'CALIBRATED',
      engineVersion: engineVersion,
      datasetVersion: datasetVersion,
    );
  }
}
