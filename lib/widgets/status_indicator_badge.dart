import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';

/// Clean forensic status badge for tables, headers, and cards
class StatusIndicatorBadge extends StatelessWidget {
  final String status;
  final bool small;

  const StatusIndicatorBadge({
    super.key,
    required this.status,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color border;
    Color text;

    final upper = status.toUpperCase();

    if (upper.contains('VERIFIED') || upper.contains('SYNCED') || upper.contains('GOOD')) {
      bg = NexoraColors.verifiedGreen.withOpacity(0.18);
      border = NexoraColors.verifiedGreen;
      text = const Color(0xFF34D399);
    } else if (upper.contains('PRESUMPTIVE') || upper.contains('MODERATE') || upper.contains('ACCEPTABLE')) {
      bg = NexoraColors.presumptiveAmber.withOpacity(0.18);
      border = NexoraColors.presumptiveAmber;
      text = const Color(0xFFFBBF24);
    } else if (upper.contains('FAILURE') || upper.contains('ALERT') || upper.contains('FAILED') || upper.contains('INSUFFICIENT')) {
      bg = NexoraColors.alertRed.withOpacity(0.18);
      border = NexoraColors.alertRed;
      text = const Color(0xFFF87171);
    } else if (upper.contains('PENDING') || upper.contains('SYNCING')) {
      bg = NexoraColors.syncBlue.withOpacity(0.18);
      border = NexoraColors.syncBlue;
      text = const Color(0xFF60A5FA);
    } else {
      // INCONCLUSIVE / UNKNOWN
      bg = NexoraColors.inconclusiveGray.withOpacity(0.18);
      border = NexoraColors.inconclusiveGray;
      text = NexoraColors.textSecondary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        upper,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: text,
        ),
      ),
    );
  }
}
