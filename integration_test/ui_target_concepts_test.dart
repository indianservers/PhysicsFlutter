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
import 'package:physics_atelier/features/workbench/workbench.dart';
import 'package:physics_atelier/features/waves/workspace.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Supplement concept-visible reference setups and benches', (
    t,
  ) async {
    await app.main();
    await t.pumpAndSettle();
    final root =
        '${(await getExternalStorageDirectory())!.path}/ui-target-20261028';
    final manifestFile = File('$root/manifest.json');
    final rows = jsonDecode(await manifestFile.readAsString()) as List;
    Future<void> shot(String id, String name) async {
      await t.pumpAndSettle();
      final row = rows.firstWhere((r) => r['id'] == id) as Map;
      final boundary =
          appCaptureKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      await t.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('$root/${row['folder']}/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
      });
      if (!(row['files'] as List).contains('$name.png'))
        (row['files'] as List).add('$name.png');
      await manifestFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(rows),
      );
      debugPrint('SUPPLEMENT $id $name');
    }

    router.go('/lab/s01-e02');
    await t.pumpAndSettle();
    var shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
    final opening = shell.controls().first;
    opening.change(opening.min);
    await t.pumpAndSettle();
    await shot('s01-e02', '05_wire_contact_reading');

    router.go('/lab/s01-e03');
    await t.pumpAndSettle();
    final dynamic sphere = t.state(find.byType(Workspace));
    sphere.experiment.spherometer.surface = 1;
    sphere.experiment.spherometer.view = 'Section';
    sphere.experiment.setA(sphere.experiment.spherometer.contactStop);
    await t.pumpAndSettle();
    await shot('s01-e03', '05_curved_surface_contact_section');

    router.go('/lab/s01-e05');
    await t.pumpAndSettle();
    final dynamic uncertainty = t.state(find.byType(Workspace));
    uncertainty.experiment.samples = <double>[.100, .101, .099, .1005, .1002];
    uncertainty.experiment.resolution = .001;
    uncertainty.experiment.changed();
    await t.pumpAndSettle();
    await shot('s01-e05', '05_example_readings_error_bars');
    (rows.firstWhere((r) => r['id'] == 's01-e05') as Map)['exampleDataset'] =
        <double>[.100, .101, .099, .1005, .1002];

    router.go('/lab/s09-e01');
    await t.pumpAndSettle();
    final dynamic refraction = t.state(find.byType(WaveWorkspace));
    refraction.updateMany(<String, double>{'n1': 1.0, 'n2': 1.5, 'angle': 40});
    await t.pumpAndSettle();
    await shot('s09-e01', '05_refracted_ray');

    for (final id in ['s09-e02', 's09-e03']) {
      router.go('/lab/$id');
      await t.pumpAndSettle();
      final dynamic optics = t.state(find.byType(WaveWorkspace));
      optics.chooseMode(0);
      optics.updateMany(<String, double>{'u': .3, 'focal': .15});
      await t.pumpAndSettle();
      await shot(id, '05_real_image_ray_construction');
    }
    for (final id in ['s09-e00', 's09-e01', 's09-e02', 's09-e03', 's13-e01']) {
      router.go('/lab/$id/bench');
      await t.pumpAndSettle();
      await shot(id, '06_material_optical_bench');
    }
    router.go('/');
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
