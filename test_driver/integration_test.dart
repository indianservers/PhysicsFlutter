import 'dart:io';
import 'dart:convert';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  writeResponseOnFailure: true,
  responseDataCallback: (data) async {
    final dir = Directory('screenshots');
    await dir.create(recursive: true);
    for (final entry
        in (data?['images'] as Map<String, dynamic>? ?? {}).entries) {
      await File('${dir.path}/${entry.key}.png')
          .writeAsBytes(base64Decode(entry.value));
    }
    if (data?['csv'] != null) {
      await File('${dir.path}/${data?['csvFile'] ?? 'verified-results.csv'}')
          .writeAsString(data!['csv']);
    }
    if (data?['phase2Performance'] != null) {
      await File('${dir.path}/phase2-performance.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(data!['phase2Performance']),
      );
    }
    if (data?['environment'] != null) {
      final profile = Map<String, dynamic>.from(data!)..remove('images');
      await File('${dir.path}/${data['profileFile'] ?? 'phase2-profile.json'}')
          .writeAsString(const JsonEncoder.withIndent('  ').convert(profile));
    }
    if (data?['phase3Validation'] != null) {
      await File('${dir.path}/phase3-validation.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(data!['phase3Validation']),
      );
    }
    if (data?['phase3Preservation'] != null) {
      await File('${dir.path}/phase3-preservation-native.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(data!['phase3Preservation']),
      );
    }
    for (final key in [
      'phase4Validation',
      'phase4Microphone',
      'phase4MicrophoneDenied',
      'phase4Modes',
      'phase5Validation',
      'phase5Modes',
      'phase6Validation',
      'phase6Modes',
      'phase6Storage',
      'phase7Validation',
      'phase7Modes',
      'phase7Storage',
      'phase8Validation',
      'phase8Storage',
      'phase8Boundaries',
      'phase9Inventory',
      'phase9Storage',
      'phase9Journeys',
      'phase9Restoration',
      'micrometerAudit',
    ]) {
      if (data?[key] != null) {
        await File(
          '${dir.path}/$key.json',
        ).writeAsString(const JsonEncoder.withIndent('  ').convert(data![key]));
      }
    }
  },
);
