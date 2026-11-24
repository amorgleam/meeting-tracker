import 'package:flutter/material.dart';
import '../theme/institutional_theme.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final bool isOverridden;
  final VoidCallback? onTap;
  final bool isCompact;

  const StatusChip({
    super.key,
    required this.status,
    this.isOverridden = false,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = InstitutionalTheme.getStatusColor(status);
    final bgColor = InstitutionalTheme.getStatusBgColor(status);

    Widget chip = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 10,
        vertical: isCompact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(2), // Formal institutional look, no round bubbles
        border: Border.all(color: statusColor.withOpacity(0.8), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isCompact ? 6 : 8,
            height: isCompact ? 6 : 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.rectangle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: statusColor,
              fontSize: isCompact ? 10 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
          if (isOverridden) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: InstitutionalTheme.statusOverride,
                borderRadius: BorderRadius.circular(2),
              ),
              child: const Text(
                'OVERRIDE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(2),
        child: chip,
      );
    }

    return chip;
  }
}
