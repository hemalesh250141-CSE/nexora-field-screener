import 'package:flutter/material.dart';
import '../core/constants/color_constants.dart';

/// Clean rigid forensic metric display card
class ForensicMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const ForensicMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.subValue,
    this.icon,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = accentColor ?? NexoraColors.borderSubtle;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: NexoraColors.cardDark,
          border: Border.all(color: border, width: 1),
          borderRadius: BorderRadius.circular(2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: NexoraColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (icon != null)
                  Icon(
                    icon,
                    size: 16,
                    color: accentColor ?? NexoraColors.tacticalKhaki,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: accentColor ?? NexoraColors.pureWhite,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (subValue != null) ...[
              const SizedBox(height: 4),
              Text(
                subValue!,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: NexoraColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
