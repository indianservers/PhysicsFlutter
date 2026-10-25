import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/waves_optics.dart';
import 'package:physics_atelier/features/waves/curriculum.dart';

import 'phase1_test.dart' show capture, show, top;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 4 Android all 12 labs, real observations and old data', (
    tester,
  ) async {
    final baseline = LocalNotebook();
    await baseline.initialize();
    final originals = {for (final t in baseline.trials) t.id: t.toJson()};
    // Actual SQLite v2→v3 upgrade, retaining a real earlier record and note/session.
    final path =
        '${await getDatabasesPath()}/phase4-migration-${DateTime.now().microsecondsSinceEpoch}.db';
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
    final legacy = baseline.trials.first;
    await old.insert('trials', {
      'id': legacy.id,
      'body': jsonEncode(legacy.toJson()),
    });
    await old.insert('sessions', {
      'id': legacy.labId,
      'body': jsonEncode({
        'version': 1,
        'state': {'note': 'retained migration fixture'},
      }),
    });
    await old.close();
    final migrated = LocalNotebook(databasePath: path);
    await migrated.initialize();
    expect(migrated.trials.single.toJson(), legacy.toJson());
    expect(
      (await migrated.readSession(legacy.labId))!['note'],
      'retained migration fixture',
    );
    final db = await openDatabase(path);
    expect(await db.getVersion(), 3);
    expect(
      await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE name='challenge_attempts'",
      ),
      isNotEmpty,
    );
    await db.close();
    await app.main();
    await tester.pumpAndSettle();
    for (final entry in allEntries.where((e) => e.wavesOptics)) {
      final kind = (entry.studioIndex - 8) * 6 + entry.index,
          lesson = waveLessons[kind];
      debugPrint('Phase4 checking ${entry.id}: ${entry.title}');
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
      await show(tester, find.byKey(Key('search-result-${entry.id}')));
      await tester.tap(find.byKey(Key('search-result-${entry.id}')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      final parameter = lesson.controls.first;
      await show(tester, find.byKey(Key('edit-${parameter.key}')));
      await tester.tap(find.byKey(Key('edit-${parameter.key}')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        (parameter.initial * 1.02).toString(),
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      if (kind < 6) {
        await show(tester, find.byKey(const Key('play-waves')));
        await tester.tap(find.byKey(const Key('play-waves')));
        await tester.pump(const Duration(milliseconds: 180));
        await tester.tap(find.byKey(const Key('play-waves')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('step-waves')));
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('replay-waves')));
        await tester.tap(find.byKey(const Key('replay-waves')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          kind == 3
              ? '.0012'
              : kind == 4
              ? '.0008'
              : kind == 5
              ? '1'
              : '.12',
        );
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
      }
      await top(tester);
      await capture(tester, binding, 'phase4-${entry.id}');
      await show(tester, find.byKey(const Key('record-waves')));
      await tester.enterText(
        find.byType(TextField).last,
        'Phase4 native observation ${entry.id}',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('record-waves')));
      await tester.pumpAndSettle();
      final fresh = LocalNotebook();
      await fresh.initialize();
      final trial = fresh.trials.lastWhere((t) => t.labId == entry.id);
      expect(trial.model, waveOpticsVersion);
      expect(trial.note, contains(entry.id));
      final parameters = Map<String, double>.from(
            (trial.configuration['parameters'] as Map).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ),
          ),
          oracle = WaveOpticsRun(
            kind,
            parameters,
            mode: trial.configuration['mode'],
          );
      oracle.seek(
        (trial.configuration['ticks'] as int) *
            WaveOpticsRun.dt *
            oracle.timeScale,
      );
      expect(
        trial.value,
        closeTo(oracle.state[lesson.metric]!, trial.value.abs() * 1e-10 + 1e-9),
      );
      ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
          .clearSnackBars();
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('predict-waves')));
      await tester.tap(find.byKey(const Key('predict-waves')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        trial.value.toString(),
      );
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Correct · reference'), findsOneWidget);
      await tester.tap(find.text('Visualize').last);
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('cursor-waves')));
      await tester.tap(find.byKey(const Key('cursor-waves')));
      await tester.pumpAndSettle();
      await capture(tester, binding, 'phase4-graph-${entry.id}');
      await tester.tap(find.text('Formulas').last);
      await tester.pumpAndSettle();
      await show(tester, find.text('Worked example'));
      expect(find.text('Worked example'), findsOneWidget);
      await tester.tap(find.text('Results').last);
      await tester.pumpAndSettle();
      await show(tester, find.text('Reopen configuration'));
      await tester.tap(find.text('Reopen configuration').first);
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsNothing);
      expect(tester.takeException(), isNull);
      router.go('/studio/${studios[entry.studioIndex].id}');
      await tester.pumpAndSettle();
      await show(tester, find.text(entry.title));
      await tester.tap(find.text(entry.title).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsNothing);
    }
    final after = LocalNotebook();
    await after.initialize();
    for (final entry in originals.entries) {
      expect(
        after.trials.firstWhere((t) => t.id == entry.key).toJson(),
        entry.value,
      );
    }
    final trials = after.trials
        .where((t) => t.model == waveOpticsVersion)
        .toList();
    expect(trials.map((t) => t.labId).toSet().length, 12);
    binding.reportData!['csv'] = csvEncode(trials);
    binding.reportData!['csvFile'] = 'phase4-verified-results.csv';
    binding.reportData!['phase4Validation'] = {
      'newLabsVerified': 12,
      'originalTrialsExactlyPreserved': originals.length,
      'actualSQLiteV2MigrationPreserved': true,
      'model': waveOpticsVersion,
      'device': 'Physics_Phase3 emulator-5556, Android 17 API37 x86_64 16KB, 720x1280@320dpi, 2 cores, 2048 MB',
      'rendering': 'debug software rendering',
      'source':
          'Generated wave/optical calculations; microphone verified separately',
    };
  });
}
