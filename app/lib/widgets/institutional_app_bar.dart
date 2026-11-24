import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';

class InstitutionalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const InstitutionalAppBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final todayStr = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());
    final isWide = MediaQuery.of(context).size.width >= 700;

    return AppBar(
      backgroundColor: InstitutionalTheme.primaryNavy,
      elevation: 0,
      title: Row(
        children: [
          Flexible(
            child: Text(
              title.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: InstitutionalTheme.creamBackground,
              ),
            ),
          ),
          if (isWide) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                border: Border.all(color: InstitutionalTheme.goldAccent.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                todayStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: InstitutionalTheme.goldLight,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        // Role pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0x33B8923A),
            border: Border.all(color: InstitutionalTheme.goldAccent, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Center(
            child: Text(
              'ROLE: ${appState.settings.userRole.toUpperCase()}',
              style: const TextStyle(
                color: InstitutionalTheme.goldLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}
