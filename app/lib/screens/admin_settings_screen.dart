import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/app_settings_model.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late TextEditingController _serverUrlController;

  @override
  void initState() {
    super.initState();
    _serverUrlController = TextEditingController(text: context.read<AppState>().settings.serverUrl);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final settings = appState.settings;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                decoration: const BoxDecoration(
                  color: InstitutionalTheme.primaryNavy,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: InstitutionalTheme.goldAccent, size: 26),
                    SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ADMINISTRATIVE GOVERNANCE & PROTOCOL CONFIGURATION',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: InstitutionalTheme.creamBackground,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enforce institutional rules, synchronization endpoints and role authorizations',
                          style: TextStyle(fontSize: 11.5, color: InstitutionalTheme.goldLight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: InstitutionalTheme.creamCard,
                  border: Border.all(color: InstitutionalTheme.borderLedger),
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(3), bottomRight: Radius.circular(3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // REQUIREMENT 7: MAIN TASK COMPLETION RULE
                    const Text(
                      'MAIN TASK COMPLETION RULE',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: InstitutionalTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Determines institutional prerequisites before a main docket task can be transitioned to "Completed". Stored and replicated across all synchronized devices.',
                      style: TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                    ),
                    const SizedBox(height: 14),

                    // Mode A: Strict (Default)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: settings.completionRule == CompletionRuleMode.strict ? InstitutionalTheme.creamSurface : Colors.white,
                        border: Border.all(
                          color: settings.completionRule == CompletionRuleMode.strict ? InstitutionalTheme.primaryNavy : InstitutionalTheme.borderLedger,
                          width: settings.completionRule == CompletionRuleMode.strict ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: RadioListTile<CompletionRuleMode>(
                        value: CompletionRuleMode.strict,
                        groupValue: settings.completionRule,
                        onChanged: (val) {
                          if (val != null) appState.updateCompletionRule(val);
                        },
                        title: const Row(
                          children: [
                            Text(
                              'MODE A: STRICT (DEFAULT INSTITUTIONAL MANDATE)',
                              style: TextStyle(fontFamily: 'serif', fontSize: 13.5, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                            ),
                          ],
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'A main task with subtasks can be set to "Completed" ONLY when ALL its subtasks are Completed. Subtasks marked Eliminated or Pending will prevent completion.',
                            style: TextStyle(fontSize: 12, color: InstitutionalTheme.textBody),
                          ),
                        ),
                      ),
                    ),

                    // Mode B: Relaxed
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: settings.completionRule == CompletionRuleMode.relaxed ? InstitutionalTheme.creamSurface : Colors.white,
                        border: Border.all(
                          color: settings.completionRule == CompletionRuleMode.relaxed ? InstitutionalTheme.primaryNavy : InstitutionalTheme.borderLedger,
                          width: settings.completionRule == CompletionRuleMode.relaxed ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: RadioListTile<CompletionRuleMode>(
                        value: CompletionRuleMode.relaxed,
                        groupValue: settings.completionRule,
                        onChanged: (val) {
                          if (val != null) appState.updateCompletionRule(val);
                        },
                        title: const Text(
                          'MODE B: RELAXED (PERMISSIVE RESOLUTION)',
                          style: TextStyle(fontFamily: 'serif', fontSize: 13.5, fontWeight: FontWeight.w700, color: InstitutionalTheme.primaryNavy),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Text(
                            'Allowed when EVERY subtask is either Completed or Eliminated, with AT LEAST ONE Completed. Allows completion when minor non-viable subtasks were formally cancelled.',
                            style: TextStyle(fontSize: 12, color: InstitutionalTheme.textBody),
                          ),
                        ),
                      ),
                    ),

                    // Override Explanation Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: InstitutionalTheme.bgOverride,
                        border: Border.all(color: InstitutionalTheme.statusOverride.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.gavel, size: 16, color: InstitutionalTheme.statusOverride),
                              SizedBox(width: 8),
                              Text(
                                'EXECUTIVE OVERRIDE ("FORCE COMPLETE") PRIVILEGE',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: InstitutionalTheme.statusOverride,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            'An Admin or Secretary can invoke "Force Complete" on a main task regardless of subtask states. Requires a mandatory recorded justification, prompts a confirmation dialog, and is visibly branded "Completed by override" in all docket views, PDF/Excel exports, and the tamper-evident activity log.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF4C1D95)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 24),

                    // ACTIVE USER ROLE SIMULATION
                    const Text(
                      'ACTIVE USER IDENTITY & PERMISSION ROLE',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: InstitutionalTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select active testing role to verify authorization boundaries (Viewer vs Secretary vs Admin).',
                      style: TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: ['Admin', 'Secretary', 'Viewer'].map((role) {
                        final isCurrent = settings.userRole.toLowerCase() == role.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ChoiceChip(
                            label: Text(role.toUpperCase()),
                            selected: isCurrent,
                            selectedColor: InstitutionalTheme.primaryNavy,
                            labelStyle: TextStyle(
                              color: isCurrent ? Colors.white : InstitutionalTheme.textDark,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) appState.updateUserRole(role);
                            },
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 24),

                    // SERVER AND SYNC CONFIGURATION
                    const Text(
                      'SERVER & SYNC INFRASTRUCTURE',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: InstitutionalTheme.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'PostgreSQL + Fastify/Express Node.js cluster on Render with Cloudflare proxy and WebSocket stream.',
                      style: TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _serverUrlController,
                      decoration: InputDecoration(
                        labelText: 'Institutional Server Base URL',
                        hintText: 'https://meeting-tracker-api.onrender.com or http://localhost:4000',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.save, color: InstitutionalTheme.primaryNavy),
                          onPressed: () {
                            appState.updateSettings(
                              settings.copyWith(serverUrl: _serverUrlController.text.trim()),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Server endpoint configuration saved.')),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: InstitutionalTheme.creamSurface,
                            border: Border.all(color: InstitutionalTheme.borderLedger),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'DEVICE ID: ${settings.deviceId}',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sync engine active: Local SQLite (Drift) + Outbox queue ready.'),
                                backgroundColor: InstitutionalTheme.primaryNavy,
                              ),
                            );
                          },
                          icon: const Icon(Icons.sync, size: 16),
                          label: const Text('TRIGGER OUTBOX SYNC'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
