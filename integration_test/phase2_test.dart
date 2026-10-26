import '../test/ui_navigation.dart';

import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/dynamics.dart';
import 'package:physics_atelier/features/dynamics/curriculum.dart';
import 'package:physics_atelier/features/measurement/experiment.dart';

import 'phase1_test.dart' show show, top;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final timings = <FrameTiming>[];
  testWidgets(
    'Phase 2 Android: migration, all 18 live labs, recordings and restoration',
    (tester) async {
      final path =
          '${await getDatabasesPath()}/phase2-migration-${DateTime.now().microsecondsSinceEpoch}.db';
      final old = await openDatabase(
        path,
        version: 2,
        onCreate: (db, v) async {
          await db.execute(
            'CREATE TABLE trials(id TEXT PRIMARY KEY,body TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE TABLE sessions(id TEXT PRIMARY KEY,body TEXT NOT NULL)',
          );
        },
      );
      final fixture = Trial(
        id: 'phase1-fixture',
        labId: 's01-e00',
        quantity: 'length',
        unit: 'm',
        value: .054,
        resolution: .001,
        configuration: Experiment(0).toJson(),
      );
      await old.insert('trials', {
        'id': fixture.id,
        'body': jsonEncode(fixture.toJson()),
      });
      await old.close();
      final migrated = LocalNotebook(databasePath: path);
      await migrated.initialize();
      expect(migrated.trials.single.toJson(), fixture.toJson());
      final migratedDb = await openDatabase(path);
      expect(await migratedDb.getVersion(), 3);
      expect(
        await migratedDb.rawQuery(
          "SELECT name FROM sqlite_master WHERE name='challenge_attempts'",
        ),
        isNotEmpty,
      );
      await migratedDb.close();
      await app.main();
      await tester.pumpAndSettle();
      SchedulerBinding.instance.addTimingsCallback(timings.addAll);
      final initial = LocalNotebook();
      await initial.initialize();
      final oldIds = initial.trials
          .where((t) => t.labId.startsWith('s01-'))
          .map((t) => t.id)
          .toSet();
      Future<void> capture(String name) async {
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
            .clearSnackBars();
        await tester.pumpAndSettle();
        final boundary =
            appCaptureKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          binding.reportData ??= {'images': <String, String>{}};
          (binding.reportData!['images'] as Map<String, String>)[name] =
              base64Encode(bytes!.buffer.asUint8List());
          image.dispose();
        });
        debugPrint('Captured $name');
      }

      for (final entry in allEntries.where((e) => e.dynamics)) {
        final kind = (entry.studioIndex - 2) * 6 + entry.index;
        debugPrint('Checking ${entry.title}');
        router.go('/');
        await tester.pumpAndSettle();
        await top(tester);
        await tester.enterText(
          find.byKey(const Key('search')),
          entry.title.substring(0, 4),
        );
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await show(tester, find.text(entry.title));
        await tester.tap(find.text(entry.title).first);
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Experiment');
        await tester.pumpAndSettle();
        final parameter = lessons[kind].controls.firstWhere(
          (p) => p.max > p.min,
        );
        await show(tester, find.byKey(Key('edit-${parameter.key}')));
        await tester.tap(find.byKey(Key('edit-${parameter.key}')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          ((parameter.initial + parameter.max * .01).clamp(
            parameter.min,
            parameter.max,
          )).toString(),
        );
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('play-dynamics')));
        await tester.tap(find.byKey(const Key('play-dynamics')));
        await tester.pump(const Duration(milliseconds: 180));
        await tester.tap(find.byKey(const Key('play-dynamics')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('step-dynamics')));
        await tester.pumpAndSettle();
        await show(tester, find.text('Time scrubber / deterministic replay'));
        await tester.tap(find.text('Time scrubber / deterministic replay'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).last, '2');
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        await top(tester);
        await capture('phase2-${entry.id}-${entry.index + 1}');
        await show(tester, find.byKey(const Key('record-dynamics')));
        await tester.tap(find.byKey(const Key('record-dynamics')));
        await tester.pumpAndSettle();
        final fresh = LocalNotebook();
        await fresh.initialize();
        final trial = fresh.trials.lastWhere((t) => t.labId == entry.id);
        expect(trial.model, dynamicsVersion);
        expect(trial.configuration['ticks'], greaterThan(0));
        final params = Map<String, double>.from(
          (trial.configuration['parameters'] as Map).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        );
        final oracle = DynamicsRun(
          kind,
          params,
          mode: trial.configuration['mode'],
        )..seek((trial.configuration['ticks'] as int) * DynamicsRun.dt);
        expect(
          trial.value,
          closeTo(oracle.state[lessons[kind].metric] ?? 0, 1e-9),
        );
        await show(tester, find.byKey(const Key('predict-dynamics')));
        await tester.tap(find.byKey(const Key('predict-dynamics')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          trial.value.toString(),
        );
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Visualize');
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('graph-cursor')));
        await tester.tap(find.byKey(const Key('graph-cursor')));
        await tester.pumpAndSettle();
        await chooseSection(tester, 'Formulas');
        await tester.pumpAndSettle();
        await show(tester, find.text('Worked example'));
        expect(find.text('Worked example'), findsOneWidget);
        await chooseSection(tester, 'Results');
        await tester.pumpAndSettle();
        await show(tester, find.text('Reopen configuration'));
        await tester.tap(find.text('Reopen configuration').first);
        await tester.pumpAndSettle();
        expect(find.text('Pause'), findsNothing);
        expect(tester.takeException(), isNull);
      }
      SchedulerBinding.instance.removeTimingsCallback(timings.addAll);
      final finalStore = LocalNotebook();
      await finalStore.initialize();
      expect(
        finalStore.trials
            .where((t) => t.labId.startsWith('s01-'))
            .map((t) => t.id)
            .toSet()
            .containsAll(oldIds),
        true,
      );
      expect(
        finalStore.trials
            .where((t) => t.model == dynamicsVersion)
            .map((t) => t.labId)
            .toSet()
            .length,
        18,
      );
      binding.reportData!['csv'] = csvEncode(
        finalStore.trials.where((t) => t.model == dynamicsVersion).toList(),
      );
      binding.reportData!['csvFile'] = 'phase2-verified-results.csv';
      final totals =
          timings.map((t) => t.totalSpan.inMicroseconds / 1000).toList()
            ..sort();
      binding.reportData!['phase2Performance'] = {
        'mode': 'debug integration; software rendering',
        'frameCount': totals.length,
        'medianTotalMs': totals.isEmpty ? null : totals[totals.length ~/ 2],
        'p95TotalMs': totals.isEmpty
            ? null
            : totals[((totals.length - 1) * .95).round()],
        'framesOver16_67ms': totals.where((t) => t > 16.67).length,
        'migrationFixturePreserved': true,
        'measurementIdsPreserved': oldIds.length,
      };
    },
  );
}
