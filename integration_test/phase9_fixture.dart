import 'dart:convert';

// Optional private baseline travels only through local --dart-define-from-file.
// Empty defaults keep analysis and fresh-repository tests independent of user data.
Map<String, dynamic> decodeFixture(String encoded) => Map<String, dynamic>.from(
  jsonDecode(utf8.decode(base64Decode(encoded))) as Map,
);
final originalSessions = decodeFixture(
  const String.fromEnvironment(
    'PHASE9_ORIGINAL_SESSIONS',
    defaultValue: 'e30=',
  ),
);
final originalPreferences = decodeFixture(
  const String.fromEnvironment(
    'PHASE9_ORIGINAL_PREFERENCES',
    defaultValue: 'e30=',
  ),
);
final priorEvidence = decodeFixture(
  const String.fromEnvironment('PHASE9_PRIOR_EVIDENCE', defaultValue: 'e30='),
);
