import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../sync/sync_service.dart';
import '../models/connected_device_model.dart';

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
        // Connected Devices & Sync Status indicator
        ValueListenableBuilder<List<ConnectedDevice>>(
          valueListenable: SyncService.instance.connectedDevicesNotifier,
          builder: (context, devices, _) {
            final count = devices.length;
            return InkWell(
              onTap: () => _showConnectedDevicesDialog(context, appState, devices),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x22FFFFFF),
                  border: Border.all(
                    color: count > 0 ? const Color(0xFF4ADE80) : InstitutionalTheme.goldAccent,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.devices,
                      size: 13,
                      color: count > 0 ? const Color(0xFF4ADE80) : InstitutionalTheme.goldLight,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '$count ${count == 1 ? 'DEVICE' : 'DEVICES'}',
                      style: const TextStyle(
                        color: InstitutionalTheme.creamBackground,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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

  void _showConnectedDevicesDialog(
    BuildContext context,
    AppState appState,
    List<ConnectedDevice> devices,
  ) {
    appState.refreshConnectedDevices();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: InstitutionalTheme.creamBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(3),
          side: const BorderSide(color: InstitutionalTheme.primaryNavy, width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.devices, color: InstitutionalTheme.primaryNavy, size: 20),
            SizedBox(width: 8),
            Text(
              'CONNECTED DEVICES',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: InstitutionalTheme.primaryNavy,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 480,
          child: devices.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No remote sync devices currently reported. Verify your server connection or trigger a sync in Settings.',
                    style: TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: devices.map((d) {
                    final isSelf = d.deviceId == appState.settings.deviceId;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: isSelf ? InstitutionalTheme.primaryNavy : InstitutionalTheme.borderLedger,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            d.platform.toLowerCase().contains('win')
                                ? Icons.desktop_windows
                                : (d.platform.toLowerCase().contains('android')
                                    ? Icons.phone_android
                                    : Icons.public),
                            size: 18,
                            color: InstitutionalTheme.primaryNavy,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${d.deviceName}${isSelf ? ' (This Device)' : ''}',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
                                ),
                                Text(
                                  '${d.platform} • ${d.userName} (${d.userRole}) • ${d.transport.toUpperCase()}',
                                  style: const TextStyle(fontSize: 11, color: InstitutionalTheme.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Text(
                              'ONLINE',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF1E7E34)),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              appState.setNavIndex(9); // Open Settings
            },
            child: const Text('OPEN SETTINGS'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }
}
