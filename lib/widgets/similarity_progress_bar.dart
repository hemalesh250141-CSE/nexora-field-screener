import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';

/// Clean linear similarity progress indicator for reference profile ranking
class SimilarityProgressBar extends StatelessWidget {
  final double similarityPercent;
  final double deltaE00;

  const SimilarityProgressBar({
    super.key,
    required this.similarityPercent,
    required this.deltaE00,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor;
    if (similarityPercent >= 85.0) {
      barColor = NexoraColors.verifiedGreen;
    } else if (similarityPercent >= 65.0) {
      barColor = NexoraColors.presumptiveAmber;
    } else {
      barColor = NexoraColors.inconclusiveGray;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SIMILARITY: ${similarityPercent.toStringAsFixed(1)}%',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: barColor,
              ),
            ),
            Text(
              'ΔE00: ${deltaE00.toStringAsFixed(2)}',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: NexoraColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: LinearProgressIndicator(
            value: (similarityPercent / 100.0).clamp(0.0, 1.0),
            backgroundColor: NexoraColors.classicBlack,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
