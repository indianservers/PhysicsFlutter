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
      await File('${dir.path}/verified-results.csv')
          .writeAsString(data!['csv']);
    }
  },
);
