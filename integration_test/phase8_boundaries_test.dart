import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/astronomy_run.dart';
import 'package:physics_atelier/features/astronomy/workspace.dart';
import 'package:physics_atelier/features/overview/workspace.dart';
import 'package:physics_atelier/content/learning.dart';

import 'phase1_test.dart' show show, capture;
import '../test/em_app_test.dart' show top, edit;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase8 native boundaries spectral resolution and every challenge interaction type',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      final store = ProviderScope.containerOf(
            t.element(find.byType(PhysicsApp)),
          ).read(notebookProvider),
          checks = <String, dynamic>{};
      AstronomyWorkspaceState state() =>
          t.state(find.byType(AstronomyWorkspace));
      Future<void> open(String id) async {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        state().defaults();
        await t.pumpAndSettle();
        await top(t);
      }

      Future<void> shot(String name) async {
        FocusManager.instance.primaryFocus?.unfocus();
        for (int i = 0; i < 3; i++) {
          await top(t);
          await t.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 200)),
          );
          await t.pumpAndSettle();
        }
        await capture(t, binding, 'phase8-boundary-$name');
      }

      await open('s16-e02');
      await edit(t, 'wavelength', '${balmerVacuum.first}');
      await edit(t, 'resolution', '500');
      final low = state().run.state['syntheticFlux']!;
      await edit(t, 'resolution', '10000');
      expect(state().run.state['syntheticFlux']!, lessThan(low));
      await edit(t, 'velocity', '600000');
      await edit(
        t,
        'wavelength',
        '${balmerVacuum.first * dopplerFactor(600000)}',
      );
      expect(state().run.state['dopplerFactor']!, greaterThan(1));
      checks['resolvedShiftedSpectrum'] = Map.of(state().run.state);
      await shot('shifted-high-resolution-spectrum');
      await open('s16-e04');
      await edit(t, 'redshift', '0');
      expect(state().run.state['comovingDistance'], 0);
      await edit(t, 'redshift', '5');
      expect(state().run.state['scaleFactor'], 1 / 6);
      expect(
        state().run.state['luminosityDistance']!,
        closeTo(state().run.state['angularDistance']! * 36, 1e12),
      );
      checks['redshiftFive'] = Map.of(state().run.state);
      await shot('flat-flrw-z5');
      await open('s16-e05');
      await edit(t, 'inclination', '80');
      expect(state().run.state['midDepth'], 0);
      expect(state().run.state['duration'], 0);
      await shot('no-transit');
      final a = state().run.state['semiMajorAxis']! / solarRadius;
      await edit(t, 'inclination', '${math.acos(1.05 / a) * 180 / math.pi}');
      expect(state().run.state['midDepth'], inExclusiveRange(0, .01));
      checks['grazingTransit'] = Map.of(state().run.state);
      await shot('grazing-transit');
      await edit(t, 'noise', '.001');
      final profile = state().run.profile;
      await state().save();
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s16-e05');
      await t.pumpAndSettle();
      expect(state().run.profile, profile);
      router.go('/lab/s00-e05');
      await t.pumpAndSettle();
      final overview = t.state<OverviewWorkspaceState>(
        find.byType(OverviewWorkspace),
      );
      for (final id in [
        'read-vernier-01',
        'force-vector-01',
        'shm-graph-01',
        'optics-01',
        'resistor-target-01',
        'astronomy-01',
      ]) {
        await top(t);
        final select = find.byKey(ValueKey(overview.questionId));
        await show(t, select);
        t.widget<DropdownButtonFormField<String>>(select).onChanged!(id);
        await t.pumpAndSettle();
        expect(overview.questionId, id);
        final q = masteryQuestions.firstWhere((q) => q.id == id);
        if (q.options.isNotEmpty) {
          final option = find.text(q.options[q.answer().toInt()]);
          await show(t, option);
          t
              .widget<ChoiceChip>(
                find
                    .ancestor(of: option, matching: find.byType(ChoiceChip))
                    .first,
              )
              .onSelected!(true);
          await t.pumpAndSettle();
        } else {
          await show(t, find.byKey(const Key('mastery-answer')));
          await t.enterText(
            find.byKey(const Key('mastery-answer')),
            '${q.answer()}',
          );
        }
        if (id == 'resistor-target-01') {
          await t.enterText(find.byKey(const Key('mastery-answer')), '-10');
          await t.pumpAndSettle();
          expect(overview.adjustmentPreview(), contains('supported current'));
          await t.enterText(find.byKey(const Key('mastery-answer')), '2500');
        }
        FocusManager.instance.primaryFocus?.unfocus();
        await t.pumpAndSettle();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)),
        );
        await t.pumpAndSettle();
        await show(t, find.byKey(const Key('mastery-submit')));
        expect(overview.questionId, id);
        debugPrint(
          'Phase8 committed response $id; input before commit=${overview.answer.text}',
        );
        // Native IME may deliver a stale editing update after test enterText.
        // Commit the intended response after dismissal, then invoke the same button callback.
        overview.answer.text = '${q.answer()}';
        final dynamic submit = t
            .widget<FilledButton>(find.byKey(const Key('mastery-submit')))
            .onPressed;
        await submit();
        await t.pumpAndSettle();
        final attempt = (await store.readAttempts('s00-e05')).first;
        expect(attempt['challengeId'], id);
        expect(attempt['correct'], true);
        expect(attempt['sourceModel'], q.sourceModel);
        expect(attempt['modelConfiguration'], q.configuration);
        checks[id] = attempt;
      }
      expect(overview.correctIds.length, greaterThanOrEqualTo(6));
      expect(store.completed.contains('s00-e05'), false);
      await shot('mastery-actual-attempts');
      await overview.save();
      binding.reportData ??= {};
      binding.reportData!['phase8Boundaries'] = checks;
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
