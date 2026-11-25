import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/institutional_theme.dart';
import '../state/app_state.dart';
import '../models/app_settings_model.dart';
import '../sync/sync_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late TextEditingController _serverUrlController;
  late TextEditingController _orgNameController;
  late TextEditingController _orgSubtitleController;
  late TextEditingController _primaryHexController;
  late TextEditingController _accentHexController;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppState>().settings;
    _serverUrlController = TextEditingController(text: settings.serverUrl);
    _orgNameController = TextEditingController(text: settings.organizationName);
    _orgSubtitleController = TextEditingController(text: settings.organizationSubtitle);
    _primaryHexController = TextEditingController(text: settings.primaryColorHex);
    _accentHexController = TextEditingController(text: settings.accentColorHex);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _orgNameController.dispose();
    _orgSubtitleController.dispose();
    _primaryHexController.dispose();
    _accentHexController.dispose();
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

                    // INSTITUTIONAL THEME COLOR PALETTE
                    const Text(
                      'INSTITUTIONAL THEME COLOR PALETTE',
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
                      'Select from verified classic institutional palettes. Changes reflect immediately across all screens and PDF exports.',
                      style: TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                    ),
                    const SizedBox(height: 14),

                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      children: InstitutionalTheme.presetPalettes.map((palette) {
                        final isSelected = settings.themePaletteName == palette['name'];
                        final primColor = InstitutionalTheme.parseHex(palette['primary'], InstitutionalTheme.primaryNavy);
                        final accColor = InstitutionalTheme.parseHex(palette['accent'], InstitutionalTheme.goldAccent);

                        return InkWell(
                          onTap: () {
                            _primaryHexController.text = palette['primary']!;
                            _accentHexController.text = palette['accent']!;
                            appState.updateSettings(
                              settings.copyWith(
                                primaryColorHex: palette['primary'],
                                accentColorHex: palette['accent'],
                                themePaletteName: palette['name'],
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Theme switched to ${palette['name']}'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(3),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : InstitutionalTheme.creamSurface,
                              border: Border.all(
                                color: isSelected ? primColor : InstitutionalTheme.borderLedger,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: primColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 1.5),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: accColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  palette['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? primColor : InstitutionalTheme.textDark,
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 6),
                                  Icon(Icons.check_circle, size: 14, color: primColor),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _primaryHexController,
                            decoration: const InputDecoration(
                              labelText: 'Primary Color Hex (e.g. #1F3A5F)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _accentHexController,
                            decoration: const InputDecoration(
                              labelText: 'Accent Color Hex (e.g. #B8923A)',
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            final prim = _primaryHexController.text.trim();
                            final acc = _accentHexController.text.trim();
                            appState.updateSettings(
                              settings.copyWith(
                                primaryColorHex: prim.isNotEmpty ? prim : settings.primaryColorHex,
                                accentColorHex: acc.isNotEmpty ? acc : settings.accentColorHex,
                                themePaletteName: 'Custom Palette',
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Custom palette applied.')),
                            );
                          },
                          child: const Text('APPLY HEX'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),
                    const Divider(),
                    const SizedBox(height: 24),

                    // ORGANIZATION LETTERHEAD & PDF BRANDING
                    const Text(
                      'OFFICIAL ORGANIZATION LETTERHEAD & PDF BANNER',
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
                      'Upload your organization high-resolution letterhead banner, customize alignment, and scale for formal PDF meeting proceedings and audit exports.',
                      style: TextStyle(fontSize: 12.5, color: InstitutionalTheme.textBody),
                    ),
                    const SizedBox(height: 14),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include Official Letterhead on PDF Exports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('When enabled, the header banner will be rendered prominently at the top of generated PDFs.', style: TextStyle(fontSize: 12)),
                      value: settings.enableLetterhead,
                      activeColor: InstitutionalTheme.primaryNavy,
                      onChanged: (val) {
                        appState.updateSettings(settings.copyWith(enableLetterhead: val));
                      },
                    ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _orgNameController,
                            decoration: const InputDecoration(labelText: 'Organization / Institution Name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _orgSubtitleController,
                            decoration: const InputDecoration(labelText: 'Department / Sub-header (e.g. Office of Secretariat)'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          icon: const Icon(Icons.save, color: InstitutionalTheme.primaryNavy),
                          tooltip: 'Save Header Titles',
                          onPressed: () {
                            appState.updateSettings(
                              settings.copyWith(
                                organizationName: _orgNameController.text.trim(),
                                organizationSubtitle: _orgSubtitleController.text.trim(),
                              ),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Organization letterhead titles saved.')),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    if (settings.letterheadBase64 != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: InstitutionalTheme.borderLedger),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'LETTERHEAD BANNER PREVIEW',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: InstitutionalTheme.primaryNavy),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: InstitutionalTheme.creamSurface,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    'ALIGNMENT: ${settings.letterheadAlignment}',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: InstitutionalTheme.textMuted),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              height: settings.letterheadHeight,
                              alignment: settings.letterheadAlignment == 'LEFT'
                                  ? Alignment.centerLeft
                                  : (settings.letterheadAlignment == 'RIGHT' ? Alignment.centerRight : Alignment.center),
                              decoration: BoxDecoration(
                                color: InstitutionalTheme.creamBackground,
                                border: Border.all(color: InstitutionalTheme.borderLedger, style: BorderStyle.solid),
                              ),
                              child: Image.memory(
                                base64Decode(settings.letterheadBase64!),
                                fit: settings.letterheadAlignment == 'FULL_WIDTH' ? BoxFit.fitWidth : BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Alignment selection
                            const Text('BANNER ALIGNMENT & SIZING:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                {'label': 'Full Width (Banner)', 'val': 'FULL_WIDTH'},
                                {'label': 'Center Aligned', 'val': 'CENTER'},
                                {'label': 'Left Aligned', 'val': 'LEFT'},
                                {'label': 'Right Aligned', 'val': 'RIGHT'},
                              ].map((opt) {
                                final isSel = settings.letterheadAlignment == opt['val'];
                                return ChoiceChip(
                                  label: Text(opt['label'] as String),
                                  selected: isSel,
                                  selectedColor: InstitutionalTheme.primaryNavy,
                                  labelStyle: TextStyle(
                                    color: isSel ? Colors.white : InstitutionalTheme.textDark,
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (val) {
                                    if (val) {
                                      appState.updateSettings(settings.copyWith(letterheadAlignment: opt['val'] as String));
                                    }
                                  },
                                );
                              }).toList(),
                            ),

                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Text('Height: ${settings.letterheadHeight.toInt()} pt', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                Expanded(
                                  child: Slider(
                                    value: settings.letterheadHeight.clamp(40.0, 140.0),
                                    min: 40.0,
                                    max: 140.0,
                                    divisions: 10,
                                    label: '${settings.letterheadHeight.toInt()} pt',
                                    activeColor: InstitutionalTheme.primaryNavy,
                                    onChanged: (val) {
                                      appState.updateSettings(settings.copyWith(letterheadHeight: val));
                                    },
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _pickLetterheadImage(context, appState),
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('REPLACE BANNER IMAGE'),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                  onPressed: () {
                                    appState.updateSettings(
                                      settings.copyWith(
                                        letterheadBase64: null,
                                        enableLetterhead: false,
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.delete_outline, size: 16),
                                  label: const Text('REMOVE LETTERHEAD'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: InstitutionalTheme.creamSurface,
                          border: Border.all(color: InstitutionalTheme.borderLedger, style: BorderStyle.solid),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.image_outlined, size: 36, color: InstitutionalTheme.textMuted),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No Letterhead Uploaded',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: InstitutionalTheme.primaryNavy),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Upload a high-resolution PNG or JPG header graphic to brand your PDF outputs.',
                                    style: TextStyle(fontSize: 11.5, color: InstitutionalTheme.textBody),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _pickLetterheadImage(context, appState),
                              icon: const Icon(Icons.upload_file, size: 16),
                              label: const Text('UPLOAD LETTERHEAD'),
                            ),
                          ],
                        ),
                      ),
                    ],

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
                          onPressed: () async {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Connecting to server and initiating sync...')),
                            );
                            final success = await SyncService.instance.sync();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success ? 'Synchronization successful with server.' : 'Sync completed or server is offline/sleeping.'),
                                  backgroundColor: success ? InstitutionalTheme.statusCompleted : InstitutionalTheme.primaryNavy,
                                ),
                              );
                            }
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

  Future<void> _pickLetterheadImage(BuildContext context, AppState appState) async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
      );

      if (file != null) {
        final bytes = await file.readAsBytes();

        if (bytes.isNotEmpty) {
          final base64Str = base64Encode(bytes);
          appState.updateSettings(
            appState.settings.copyWith(
              letterheadBase64: base64Str,
              enableLetterhead: true,
            ),
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Official letterhead image uploaded and configured for PDF exports.'),
                backgroundColor: InstitutionalTheme.statusCompleted,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
