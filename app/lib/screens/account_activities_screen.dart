import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/account_activity_model.dart';

class AccountActivitiesScreen extends StatefulWidget {
  const AccountActivitiesScreen({super.key});

  @override
  State<AccountActivitiesScreen> createState() => _AccountActivitiesScreenState();
}

class _AccountActivitiesScreenState extends State<AccountActivitiesScreen> {
  String _selectedCategory = 'ALL'; // ALL, AUTH, ACCOUNTS, DOCKET
  String _selectedEmailFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshAdminAccountsAndActivities();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (!appState.isAdmin) {
      return const Center(
        child: Text(
          'RESTRICTED: Account Activities are accessible only to the Administrator account.',
          style: TextStyle(fontWeight: FontWeight.bold, color: InstitutionalTheme.statusEliminated),
        ),
      );
    }

    final activities = appState.accountActivities;
    final docketLogs = appState.activityLogs;
    final accounts = appState.accounts;
    final dateFmt = DateFormat('yyyy-MM-dd HH:mm:ss');

    final filteredActivities = activities.where((a) {
      if (_selectedEmailFilter != 'ALL' && a.actorEmail.toLowerCase() != _selectedEmailFilter.toLowerCase()) {
        return false;
      }
      if (_selectedCategory == 'AUTH') {
        return a.actionType.startsWith('LOGIN') || a.actionType == 'LOGOUT';
      }
      if (_selectedCategory == 'ACCOUNTS') {
        return a.actionType == 'MEMBER_ENROLLED' || a.actionType == 'PASSWORD_CHANGED';
      }
      return true;
    }).toList();

    final loginSuccessCount = activities.where((a) => a.actionType == 'LOGIN_SUCCESS').length;
    final pwChangesCount = activities.where((a) => a.actionType == 'PASSWORD_CHANGED').length;

    return Container(
      color: InstitutionalTheme.creamBackground,
      child: Column(
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: InstitutionalTheme.creamSurface,
              border: Border(bottom: BorderSide(color: InstitutionalTheme.borderLedger, width: 1.5)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ADMIN ACCOUNT ACTIVITIES & SECURITY AUDIT',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: InstitutionalTheme.primaryNavy,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Comprehensive log of sign-ins, member account provisioning, password updates, and docket actions',
                        style: TextStyle(fontSize: 12, color: InstitutionalTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => appState.refreshAdminAccountsAndActivities(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('REFRESH AUDIT LOG'),
                ),
              ],
            ),
          ),

          // KPI Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            color: Colors.white,
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _metricTile('TOTAL ACCOUNT EVENTS', activities.length.toString(), InstitutionalTheme.primaryNavy),
                _metricTile('SUCCESSFUL SIGN-INS', loginSuccessCount.toString(), InstitutionalTheme.statusCompleted),
                _metricTile('PASSWORD CHANGES', pwChangesCount.toString(), InstitutionalTheme.goldDark),
                _metricTile('PROVISIONED ACCOUNTS', accounts.length.toString(), InstitutionalTheme.statusPending),
                _metricTile('DOCKET STATE CHANGES', docketLogs.length.toString(), InstitutionalTheme.textDark),
              ],
            ),
          ),
          const Divider(height: 1),

          // Filter Controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: InstitutionalTheme.creamSurface,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final cat in [
                  ('ALL', 'All Account Events'),
                  ('AUTH', 'Sign-Ins & Logouts'),
                  ('ACCOUNTS', 'Enrollments & Passwords'),
                  ('DOCKET', 'Member Task Actions'),
                ])
                  ChoiceChip(
                    label: Text(cat.$2),
                    selected: _selectedCategory == cat.$1,
                    selectedColor: InstitutionalTheme.primaryNavy,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _selectedCategory == cat.$1 ? Colors.white : InstitutionalTheme.textDark,
                    ),
                    onSelected: (_) => setState(() => _selectedCategory = cat.$1),
                  ),
                if (_selectedCategory != 'DOCKET') ...[
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: _selectedEmailFilter,
                    underline: const SizedBox(),
                    style: const TextStyle(fontSize: 12, color: InstitutionalTheme.primaryNavy, fontWeight: FontWeight.w600),
                    items: [
                      const DropdownMenuItem(value: 'ALL', child: Text('Filter Account: All Users')),
                      ...accounts.map(
                        (a) => DropdownMenuItem(
                          value: a.email,
                          child: Text('${a.name} (${a.email})'),
                        ),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedEmailFilter = val);
                    },
                  ),
                ],
              ],
            ),
          ),

          // Activity Register Table
          Expanded(
            child: _selectedCategory == 'DOCKET'
                ? _buildDocketLogsList(docketLogs, dateFmt)
                : _buildAccountActivitiesList(filteredActivities, dateFmt),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActivitiesList(List<AccountActivity> items, DateFormat dateFmt) {
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No account activity events recorded for the selected filter.',
          style: TextStyle(color: InstitutionalTheme.textMuted),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final color = _actionColor(item.actionType);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: InstitutionalTheme.borderLedger),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 145,
                child: Text(
                  dateFmt.format(item.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: InstitutionalTheme.textMuted),
                ),
              ),
              Container(
                width: 140,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                margin: const EdgeInsets.only(right: 14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  item.actionType,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.actorName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: InstitutionalTheme.primaryNavy),
                        ),
                        const SizedBox(width: 8),
                        if (item.actorEmail.isNotEmpty)
                          Text(
                            '(${item.actorEmail})',
                            style: const TextStyle(fontSize: 11.5, color: InstitutionalTheme.textMuted),
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: InstitutionalTheme.creamSurface,
                            border: Border.all(color: InstitutionalTheme.borderLedger),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            item.actorRole.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.details.isNotEmpty ? item.details : item.targetInfo,
                      style: const TextStyle(fontSize: 12.5, color: InstitutionalTheme.textDark),
                    ),
                    if (item.platform.isNotEmpty || item.deviceId.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Device: ${item.deviceId} • Platform: ${item.platform}${item.ipAddress.isNotEmpty ? ' • IP: ${item.ipAddress}' : ''}',
                        style: const TextStyle(fontSize: 10.5, color: InstitutionalTheme.textMuted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocketLogsList(List docketLogs, DateFormat dateFmt) {
    if (docketLogs.isEmpty) {
      return const Center(
        child: Text('No docket task actions recorded yet.', style: TextStyle(color: InstitutionalTheme.textMuted)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: docketLogs.length,
      itemBuilder: (context, index) {
        final log = docketLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: InstitutionalTheme.borderLedger),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 145,
                child: Text(
                  dateFmt.format(log.timestamp.toLocal()),
                  style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: InstitutionalTheme.textMuted),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${log.userName}  •  ${log.taskTitle}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: InstitutionalTheme.primaryNavy),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${log.oldState} → ${log.newState}${log.note.isNotEmpty ? '  (${log.note})' : ''}',
                      style: const TextStyle(fontSize: 12, color: InstitutionalTheme.textDark),
                    ),
                  ],
                ),
              ),
              Text(
                log.deviceId,
                style: const TextStyle(fontSize: 10.5, fontFamily: 'monospace', color: InstitutionalTheme.textMuted),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: InstitutionalTheme.creamSurface,
        border: Border.all(color: InstitutionalTheme.borderLedger),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: InstitutionalTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Color _actionColor(String actionType) {
    switch (actionType) {
      case 'LOGIN_SUCCESS':
        return InstitutionalTheme.statusCompleted;
      case 'LOGIN_FAILED':
        return InstitutionalTheme.statusEliminated;
      case 'MEMBER_ENROLLED':
        return InstitutionalTheme.primaryNavy;
      case 'PASSWORD_CHANGED':
        return InstitutionalTheme.goldDark;
      default:
        return InstitutionalTheme.textMuted;
    }
  }
}
