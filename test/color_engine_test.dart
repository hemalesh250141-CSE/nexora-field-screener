import 'package:test/test.dart';
import '../lib/services/color_engine.dart';
import '../lib/models/reference_profile.dart';

void main() {
  group('ColorEngine - CIE Color Transformations', () {
    test('sRGB to CIELAB: Pure White (#FFFFFF) produces L* ~ 100, a* ~ 0, b* ~ 0', () {
      final white = const RgbColor(255.0, 255.0, 255.0);
      final lab = ColorEngine.rgbToLab(white);

      expect(lab.l, closeTo(100.0, 0.5));
      expect(lab.a, closeTo(0.0, 0.5));
      expect(lab.b, closeTo(0.0, 0.5));
    });

    test('sRGB to CIELAB: Pure Black (#000000) produces L* ~ 0', () {
      final black = const RgbColor(0.0, 0.0, 0.0);
      final lab = ColorEngine.rgbToLab(black);

      expect(lab.l, closeTo(0.0, 0.1));
      expect(lab.a, closeTo(0.0, 0.1));
      expect(lab.b, closeTo(0.0, 0.1));
    });

    test('sRGB to CIELAB: Pure Red (#FF0000) produces high positive a*', () {
      final red = const RgbColor(255.0, 0.0, 0.0);
      final lab = ColorEngine.rgbToLab(red);

      expect(lab.l, closeTo(53.23, 1.0));
      expect(lab.a, greaterThan(70.0));
      expect(lab.b, greaterThan(50.0));
    });
  });

  group('ColorEngine - CIEDE2000 Distance Calculation', () {
    test('Identical CIELAB coordinates produce ΔE00 of 0.0', () {
      const color1 = LabColor(50.0, 25.0, -15.0);
      const color2 = LabColor(50.0, 25.0, -15.0);

      final deltaE = ColorEngine.calculateCiede2000(color1, color2);
      expect(deltaE, equals(0.0));
    });

    test('Slight perceptual difference produces small ΔE00 < 1.0', () {
      const color1 = LabColor(50.0, 20.0, 10.0);
      const color2 = LabColor(50.5, 20.2, 10.1);

      final deltaE = ColorEngine.calculateCiede2000(color1, color2);
      expect(deltaE, greaterThan(0.0));
      expect(deltaE, lessThan(1.0));
    });

    test('Moderate difference produces expected ΔE00 range', () {
      // Standard pair
      const color1 = LabColor(50.0, 2.6772, -79.7751);
      const color2 = LabColor(50.0, 0.0, -82.7485);

      final deltaE = ColorEngine.calculateCiede2000(color1, color2);
      expect(deltaE, closeTo(2.04, 0.5));
    });
  });

  group('ColorEngine - Reference Card Normalization', () {
    test('Neutral gray patch scales channels to neutralize ambient cast', () {
      // Observed reaction RGB under warm yellow lighting: [120, 60, 40]
      // Observed 18% gray patch: [130, 118, 105] vs nominal [118, 118, 118]
      const observedReaction = RgbColor(120.0, 60.0, 40.0);
      const observedGray = RgbColor(130.0, 118.0, 105.0);

      final normalized = ColorEngine.normalizeColor(
        observedRgb: observedReaction,
        observedGrayPatch: observedGray,
      );

      // Red channel gain = 118/130 (~0.907), so normalized Red should be reduced
      expect(normalized.r, lessThan(120.0));
      // Blue channel gain = 118/105 (~1.123), so normalized Blue should be boosted
      expect(normalized.b, greaterThan(40.0));
    });
  });

  group('ColorEngine - Image Quality Gates', () {
    test('Reference card missing immediately yields QUALITY: INSUFFICIENT', () {
      final result = ColorEngine.validateImageQuality(
        averageBrightness: 120.0,
        contrastRatio: 2.5,
        blurLaplacianVariance: 150.0,
        cardDetected: false,
      );

      expect(result.tier, equals(ImageQualityTier.insufficient));
      expect(result.statusText, equals('QUALITY: INSUFFICIENT'));
    });

    test('Motion blur (low laplacian variance) yields QUALITY: INSUFFICIENT', () {
      final result = ColorEngine.validateImageQuality(
        averageBrightness: 120.0,
        contrastRatio: 2.0,
        blurLaplacianVariance: 25.0, // Low focus score
        cardDetected: true,
      );

      expect(result.tier, equals(ImageQualityTier.insufficient));
    });

    test('Clear image with balanced illumination yields QUALITY: GOOD', () {
      final result = ColorEngine.validateImageQuality(
        averageBrightness: 125.0,
        contrastRatio: 2.4,
        blurLaplacianVariance: 120.0,
        cardDetected: true,
      );

      expect(result.tier, equals(ImageQualityTier.good));
      expect(result.statusText, equals('QUALITY: GOOD'));
    });
  });

  group('ColorEngine - Multi-Profile Ranking & Inconclusive Threshold', () {
    final standards = ReferenceProfile.getDefaultStandards().map((p) => p.toMap()).toList();

    test('Matching standard reaction yields PRESUMPTIVE RESULT with ranked matches', () {
      // Reaction matching Marquis standard #0F0210
      const sample = RgbColor(15.0, 2.0, 16.0);
      const neutralGray = RgbColor(118.0, 118.0, 118.0);

      final quality = ColorEngine.validateImageQuality(
        averageBrightness: 120.0,
        contrastRatio: 2.0,
        blurLaplacianVariance: 100.0,
        cardDetected: true,
      );

      final outcome = ColorEngine.analyzeColorAgainstProfiles(
        rawSampleRgb: sample,
        observedGrayPatch: neutralGray,
        activeProfiles: standards,
        qualityResult: quality,
      );

      expect(outcome.status, equals('PRESUMPTIVE'));
      expect(outcome.summaryTitle, equals('PRESUMPTIVE RESULT'));
      expect(outcome.topMatch, isNotNull);
      expect(outcome.bestDeltaE, lessThan(2.0));
      expect(outcome.rankedMatches.first.profileId, equals('PROF-MQ-001'));
      expect(outcome.rankedMatches.first.similarityPercent, greaterThan(85.0));
    });

    test('Outlier color exceeding threshold yields INCONCLUSIVE / MATRIX INTERFERENCE', () {
      // Color with large distance from all reference standards
      const outlierSample = RgbColor(135.0, 160.0, 30.0);
      const neutralGray = RgbColor(118.0, 118.0, 118.0);

      final quality = ColorEngine.validateImageQuality(
        averageBrightness: 120.0,
        contrastRatio: 2.0,
        blurLaplacianVariance: 100.0,
        cardDetected: true,
      );

      final outcome = ColorEngine.analyzeColorAgainstProfiles(
        rawSampleRgb: sampleOutlier,
        observedGrayPatch: neutralGray,
        activeProfiles: standards,
        qualityResult: quality,
        deltaEThreshold: 2.0,
      );

      expect(outcome.status, equals('INCONCLUSIVE'));
      expect(outcome.summaryTitle, contains('INCONCLUSIVE'));
      expect(outcome.inconclusiveReason, contains('exceeds authorized threshold'));
    });
  });
}

const sampleOutlier = RgbColor(135.0, 160.0, 30.0);
