import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/color_constants.dart';

/// Mandatory Statutory Disclaimer Banner
/// Must be rendered on all analysis results, reports, and evidence summaries.
class StatutoryDisclaimerBanner extends StatelessWidget {
  final bool compact;

  const StatutoryDisclaimerBanner({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: NexoraColors.deepBrown.withOpacity(0.4),
        border: Border.all(color: NexoraColors.presumptiveAmber, width: 1.5),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.gavel,
            color: NexoraColors.presumptiveAmber,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'STATUTORY FORENSIC NOTICE',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: NexoraColors.presumptiveAmber,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  AppConstants.statutoryDisclaimer,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: compact ? 11 : 12,
                    fontWeight: FontWeight.w600,
                    color: NexoraColors.pureWhite,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
