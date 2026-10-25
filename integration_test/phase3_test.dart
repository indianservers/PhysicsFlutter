import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/advanced.dart';
import 'package:physics_atelier/features/advanced/curriculum.dart';

import 'phase1_test.dart' show capture, show, top;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase 3 native Android: all 18 labs, actual records, prediction, notes and replay',
    (tester) async {
      final baseline = LocalNotebook();
      await baseline.initialize();
      final oldIds = baseline.trials.map((t) => t.id).toSet(),
          oldCompleted = Set<String>.of(baseline.completed);
      await app.main();
      await tester.pumpAndSettle();
      for (final entry in allEntries.where((e) => e.advanced)) {
        final kind = (entry.studioIndex - 5) * 6 + entry.index,
            lesson = advancedLessons[kind];
        debugPrint('Phase3 checking ${entry.id} ${entry.title}');
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
        await tester.tap(find.text(entry.title).last);
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
        if (!(kind >= 6 && kind <= 8)) {
          await show(tester, find.byKey(const Key('play-advanced')));
          await tester.tap(find.byKey(const Key('play-advanced')));
          await tester.pump(const Duration(milliseconds: 180));
          await tester.tap(find.byKey(const Key('play-advanced')));
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const Key('step-advanced')));
          await tester.pumpAndSettle();
          await show(tester, find.byKey(const Key('replay-advanced')));
          await tester.tap(find.byKey(const Key('replay-advanced')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextField).last,
            kind >= 9 && kind <= 11
                ? '2400'
                : kind == 3
                ? '.8'
                : '1.2',
          );
          await tester.tap(find.text('Apply'));
          await tester.pumpAndSettle();
        }
        await top(tester);
        await capture(tester, binding, 'phase3-${entry.id}');
        await show(tester, find.byKey(const Key('record-advanced')));
        await tester.enterText(
          find.byType(TextField).last,
          'Phase 3 verified ${entry.id} observation',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('record-advanced')));
        await tester.pumpAndSettle();
        final fresh = LocalNotebook();
        await fresh.initialize();
        final trial = fresh.trials.lastWhere((t) => t.labId == entry.id);
        expect(trial.model, advancedVersion);
        expect(trial.note, contains(entry.id));
        final params = Map<String, double>.from(
          (trial.configuration['parameters'] as Map).map(
            (k, v) => MapEntry(k, (v as num).toDouble()),
          ),
        );
        final oracle = AdvancedRun(kind, params)
          ..seek(
            (trial.configuration['ticks'] as int) *
                AdvancedRun.dt *
                (kind >= 9 && kind <= 11 ? 480 : 1),
          );
        expect(
          trial.value,
          closeTo(oracle.state[lesson.metric]!, mathTolerance(trial.value)),
        );
        expect(
          (trial.configuration['currentState'] as Map).values.every(
            (x) => (x as num).isFinite,
          ),
          isTrue,
        );
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
            .clearSnackBars();
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('predict-advanced')));
        await tester.tap(find.byKey(const Key('predict-advanced')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byType(TextField).last,
          trial.value.toString(),
        );
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        expect(
          find.textContaining('Correct · reference answer'),
          findsOneWidget,
        );
        await tester.tap(find.text('Visualize').last);
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('cursor-advanced')));
        await tester.tap(find.byKey(const Key('cursor-advanced')));
        await tester.pumpAndSettle();
        await capture(tester, binding, 'phase3-graph-${entry.id}');
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
        // A real route away and back must reopen the persisted state paused.
        router.go('/studio/${studios[entry.studioIndex].id}');
        await tester.pumpAndSettle();
        await show(tester, find.text(entry.title));
        await tester.tap(find.text(entry.title).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Experiment').last);
        await tester.pumpAndSettle();
        expect(find.text('Pause'), findsNothing);
      }
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Pause'), findsNothing);
      final saved = LocalNotebook();
      await saved.initialize();
      expect(saved.trials.map((t) => t.id).toSet().containsAll(oldIds), isTrue);
      expect(saved.completed.containsAll(oldCompleted), isTrue);
      final trials = saved.trials
          .where((t) => t.model == advancedVersion)
          .toList();
      expect(trials.map((t) => t.labId).toSet().length, 18);
      binding.reportData!['csv'] = csvEncode(trials);
      binding.reportData!['csvFile'] = 'phase3-verified-results.csv';
      binding.reportData!['phase3Validation'] = {
        'earlierTrialIdsPreserved': oldIds.length,
        'earlierCompletionIdsPreserved': oldCompleted.length,
        'newLabsVerified': 18,
        'model': advancedVersion,
        'device': 'Android 17 API37 emulator-5556 x86_64 16KB, 720x1280@320dpi',
        'mode': 'debug software-rendered native integration',
        'notesAndReplay': true,
      };
    },
  );
}

double mathTolerance(double value) => value.abs() * 1e-10 + 1e-8;
