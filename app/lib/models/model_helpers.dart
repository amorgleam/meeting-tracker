import 'dart:convert';

/// Safely parses booleans from SQLite INTEGER (0/1), PostgreSQL BOOLEAN, or JSON strings.
bool parseSqlBool(dynamic val, {bool defaultValue = false}) {
  if (val == null) return defaultValue;
  if (val is bool) return val;
  if (val is int) return val != 0;
  if (val is num) return val != 0;
  if (val is String) {
    final lower = val.trim().toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'yes') return true;
    if (lower == 'false' || lower == '0' || lower == 'no' || lower.isEmpty) return false;
  }
  return defaultValue;
}

/// Safely parses ISO-8601 date strings or DateTime objects.
DateTime parseIsoDate(dynamic val, {DateTime? fallback}) {
  if (val is DateTime) return val;
  if (val is String && val.isNotEmpty) {
    final parsed = DateTime.tryParse(val);
    if (parsed != null) return parsed;
  }
  return fallback ?? DateTime.now();
}

DateTime? parseNullableIsoDate(dynamic val) {
  if (val == null) return null;
  if (val is DateTime) return val;
  if (val is String && val.isNotEmpty) {
    return DateTime.tryParse(val);
  }
  return null;
}

/// Safely parses string ID lists from JSON arrays or encoded JSON strings.
List<String> parseIdList(dynamic val) {
  if (val == null) return [];
  if (val is List) {
    return val.map((e) => e.toString()).toList();
  }
  if (val is String && val.isNotEmpty) {
    try {
      final decoded = jsonDecode(val);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
  }
  return [];
}
