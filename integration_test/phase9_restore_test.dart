import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

import 'phase9_fixture.dart' show originalSessions, originalPreferences;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Restore original configurations and navigation preferences after explicit QA actions',
    (t) async {
      final store = LocalNotebook();
      await store.initialize();
      for (final entry in originalSessions.entries) {
        await store.saveSession(
          entry.key,
          Map<String, dynamic>.from(entry.value),
        );
      }
      for (final key
          in store.preferences
              .getKeys()
              .where(
                (k) =>
                    (k.startsWith('workspace:') ||
                        k.startsWith('workspaceGuide:')) &&
                    !originalPreferences.containsKey(k),
              )
              .toList()) {
        await store.preferences.remove(key);
      }
      for (final entry in originalPreferences.entries) {
        final value = entry.value;
        if (value is List) {
          await store.preferences.setStringList(
            entry.key,
            List<String>.from(value),
          );
        } else if (value is String) {
          await store.preferences.setString(entry.key, value);
        } else if (value is bool) {
          await store.preferences.setBool(entry.key, value);
        } else if (value is int) {
          await store.preferences.setInt(entry.key, value);
        }
      }
      for (final entry in originalSessions.entries) {
        expect(await store.readSession(entry.key), entry.value);
      }
      binding.reportData ??= {};
      binding.reportData!.addAll({
        'phase9Restoration': {
          'originalSessionsRestored': originalSessions.length,
          'originalPreferencesRestored': originalPreferences.length,
          'trialsAfterExplicitValidation': store.trials.length,
          'recoveryMessage': store.recoveryMessage,
        },
      });
    },
  );
}
