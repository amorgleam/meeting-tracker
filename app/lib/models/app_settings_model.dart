enum CompletionRuleMode {
  strict,  // Mode A: Strict (DEFAULT) - all subtasks must be Completed
  relaxed, // Mode B: Relaxed - every subtask Completed or Eliminated (at least 1 Completed)
}

class AppSettings {
  final CompletionRuleMode completionRule;
  final String serverUrl;
  final String userRole; // 'Admin', 'Secretary', 'Viewer'
  final String currentUserName;
  final String currentUserId;
  final String deviceId;

  // Custom Organization Letterhead / PDF Header
  final bool enableLetterhead;
  final String? letterheadBase64;
  final String letterheadAlignment; // 'FULL_WIDTH', 'CENTER', 'LEFT', 'RIGHT'
  final double letterheadHeight;
  final String organizationName;
  final String organizationSubtitle;

  // Theme Customization
  final String primaryColorHex;
  final String accentColorHex;
  final String themePaletteName;

  AppSettings({
    this.completionRule = CompletionRuleMode.strict,
    this.serverUrl = 'http://localhost:4000',
    this.userRole = 'Admin',
    this.currentUserName = 'Arthur Pendelton (Sec-Gen)',
    this.currentUserId = 'user-admin-01',
    this.deviceId = 'dev-win-01',
    this.enableLetterhead = false,
    this.letterheadBase64,
    this.letterheadAlignment = 'FULL_WIDTH',
    this.letterheadHeight = 70.0,
    this.organizationName = 'INSTITUTIONAL STEERING COMMITTEE',
    this.organizationSubtitle = 'Office of the Secretariat & Executive Council',
    this.primaryColorHex = '#1F3A5F',
    this.accentColorHex = '#B8923A',
    this.themePaletteName = 'Executive Navy & Gold',
  });

  AppSettings copyWith({
    CompletionRuleMode? completionRule,
    String? serverUrl,
    String? userRole,
    String? currentUserName,
    String? currentUserId,
    String? deviceId,
    bool? enableLetterhead,
    String? letterheadBase64,
    String? letterheadAlignment,
    double? letterheadHeight,
    String? organizationName,
    String? organizationSubtitle,
    String? primaryColorHex,
    String? accentColorHex,
    String? themePaletteName,
  }) {
    return AppSettings(
      completionRule: completionRule ?? this.completionRule,
      serverUrl: serverUrl ?? this.serverUrl,
      userRole: userRole ?? this.userRole,
      currentUserName: currentUserName ?? this.currentUserName,
      currentUserId: currentUserId ?? this.currentUserId,
      deviceId: deviceId ?? this.deviceId,
      enableLetterhead: enableLetterhead ?? this.enableLetterhead,
      letterheadBase64: letterheadBase64 ?? this.letterheadBase64,
      letterheadAlignment: letterheadAlignment ?? this.letterheadAlignment,
      letterheadHeight: letterheadHeight ?? this.letterheadHeight,
      organizationName: organizationName ?? this.organizationName,
      organizationSubtitle: organizationSubtitle ?? this.organizationSubtitle,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      themePaletteName: themePaletteName ?? this.themePaletteName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'completion_rule': completionRule == CompletionRuleMode.strict ? 'Strict' : 'Relaxed',
      'server_url': serverUrl,
      'user_role': userRole,
      'current_user_name': currentUserName,
      'current_user_id': currentUserId,
      'device_id': deviceId,
      'enable_letterhead': enableLetterhead,
      'letterhead_base64': letterheadBase64,
      'letterhead_alignment': letterheadAlignment,
      'letterhead_height': letterheadHeight,
      'organization_name': organizationName,
      'organization_subtitle': organizationSubtitle,
      'primary_color_hex': primaryColorHex,
      'accent_color_hex': accentColorHex,
      'theme_palette_name': themePaletteName,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      completionRule: (json['completion_rule'] as String?)?.toLowerCase() == 'relaxed'
          ? CompletionRuleMode.relaxed
          : CompletionRuleMode.strict,
      serverUrl: json['server_url'] as String? ?? 'http://localhost:4000',
      userRole: json['user_role'] as String? ?? 'Admin',
      currentUserName: json['current_user_name'] as String? ?? 'Arthur Pendelton (Sec-Gen)',
      currentUserId: json['current_user_id'] as String? ?? 'user-admin-01',
      deviceId: json['device_id'] as String? ?? 'dev-win-01',
      enableLetterhead: json['enable_letterhead'] as bool? ?? false,
      letterheadBase64: json['letterhead_base64'] as String?,
      letterheadAlignment: json['letterhead_alignment'] as String? ?? 'FULL_WIDTH',
      letterheadHeight: (json['letterhead_height'] as num?)?.toDouble() ?? 70.0,
      organizationName: json['organization_name'] as String? ?? 'INSTITUTIONAL STEERING COMMITTEE',
      organizationSubtitle: json['organization_subtitle'] as String? ?? 'Office of the Secretariat & Executive Council',
      primaryColorHex: json['primary_color_hex'] as String? ?? '#1F3A5F',
      accentColorHex: json['accent_color_hex'] as String? ?? '#B8923A',
      themePaletteName: json['theme_palette_name'] as String? ?? 'Executive Navy & Gold',
    );
  }
}
