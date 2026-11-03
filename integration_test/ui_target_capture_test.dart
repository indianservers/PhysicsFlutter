import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

String safe(String s) => s
    .replaceAll(RegExp(r'[^a-zA-Z0-9 -]'), '')
    .trim()
    .replaceAll(RegExp(r' +'), '_');
const startStudio = int.fromEnvironment('START_STUDIO', defaultValue: 0);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Capture every lab for UI review', (t) async {
    await app.main();
    await t.pumpAndSettle();
    final root = Directory(
      '${(await getExternalStorageDirectory())!.path}/ui-target-20261028',
    );
    await root.create(recursive: true);
    final manifest = <Map<String, dynamic>>[];
    Future<void> shot(String path) async {
      await t.pumpAndSettle();
      final boundary =
          appCaptureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('${root.path}/$path.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      debugPrint('UI_TARGET $path');
    }

    for (final studio in studios) {
      if (int.parse(studio.id.substring(1)) < startStudio) continue;
      for (final entry in studio.entries) {
        final folder =
            '${studio.id}_${safe(studio.title)}/${entry.id}_${safe(entry.title)}';
        final row = <String, dynamic>{
          'id': entry.id,
          'studio': studio.title,
          'lab': entry.title,
          'concept': entry.principle,
          'formula': entry.formula,
          'folder': folder,
          'files': <String>[],
        };
        manifest.add(row);
        try {
          router.go('/lab/${entry.id}');
          await t.pumpAndSettle();
          if (entry.interactive) {
            await t.tap(find.byKey(const Key('workspace-scene')));
            await t.pumpAndSettle();
            var shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
            shell.pause();
            shell.reset();
            await t.pumpAndSettle();
            await shot('$folder/01_apparatus');
            (row['files'] as List).add('01_apparatus.png');
            shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
            final controls = shell.controls();
            if (controls.isNotEmpty) {
              final c = controls.first;
              c.change((c.min + (c.max - c.min) * .6).clamp(c.min, c.max));
              row['interaction'] =
                  '${c.label}: ${c.value} -> ${c.min + (c.max - c.min) * .6} ${c.unit}';
              await t.pumpAndSettle();
            }
            shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
            if (shell.dynamicModel()) {
              shell.play();
              await t.pump(const Duration(milliseconds: 16));
              for (var i = 0; i < 12; i++) {
                await t.pump(const Duration(milliseconds: 50));
              }
              shell.pause();
              await t.pumpAndSettle();
              row['simulationAdvanced'] = true;
            }
            await shot('$folder/02_concept_interaction');
            (row['files'] as List).add('02_concept_interaction.png');
            row['readings'] = t
                .widget<InstrumentShell>(find.byType(InstrumentShell))
                .readings()
                .map((r) => '${r.label}: ${r.value} ${r.unit}')
                .toList();
            await t.tap(find.byKey(const Key('workspace-graph')));
            await t.pumpAndSettle();
            await shot('$folder/03_graph');
            (row['files'] as List).add('03_graph.png');
            await t.tap(find.byKey(const Key('workspace-scene')));
            await t.pumpAndSettle();
            await t.tap(find.byKey(const Key('workspace-inspect')));
            await t.pumpAndSettle();
            await shot('$folder/04_controls_readings');
            (row['files'] as List).add('04_controls_readings.png');
            await t.tap(find.byTooltip('Close inspector'));
            await t.pumpAndSettle();
          } else {
            await shot('$folder/01_learning_tool');
            (row['files'] as List).add('01_learning_tool.png');
          }
          final error = t.takeException();
          if (error != null) row['renderWarning'] = error.toString();
        } catch (e) {
          row['error'] = e.toString();
          debugPrint('UI_TARGET_ERROR ${entry.id}: $e');
          while (t.takeException() != null) {}
        }
        await t.runAsync(
          () => File(
            '${root.path}/manifest.json',
          ).writeAsString(const JsonEncoder.withIndent('  ').convert(manifest)),
        );
      }
    }
    router.go('/');
    await t.pumpAndSettle();
    expect(
      manifest.length,
      allEntries.where((e) => e.studioIndex >= startStudio).length,
    );
  }, timeout: const Timeout(Duration(minutes: 40)));
}
