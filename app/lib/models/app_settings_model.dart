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

  AppSettings({
    this.completionRule = CompletionRuleMode.strict,
    this.serverUrl = 'http://localhost:4000',
    this.userRole = 'Admin',
    this.currentUserName = 'Arthur Pendelton (Sec-Gen)',
    this.currentUserId = 'user-admin-01',
    this.deviceId = 'dev-win-01',
  });

  AppSettings copyWith({
    CompletionRuleMode? completionRule,
    String? serverUrl,
    String? userRole,
    String? currentUserName,
    String? currentUserId,
    String? deviceId,
  }) {
    return AppSettings(
      completionRule: completionRule ?? this.completionRule,
      serverUrl: serverUrl ?? this.serverUrl,
      userRole: userRole ?? this.userRole,
      currentUserName: currentUserName ?? this.currentUserName,
      currentUserId: currentUserId ?? this.currentUserId,
      deviceId: deviceId ?? this.deviceId,
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
    );
  }
}
