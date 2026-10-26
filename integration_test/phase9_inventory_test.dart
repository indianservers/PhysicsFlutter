import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';
import 'package:physics_atelier/features/dynamics/workspace.dart';
import 'package:physics_atelier/features/dynamics/curriculum.dart'
    show Parameter;
import 'package:physics_atelier/features/advanced/workspace.dart';
import 'package:physics_atelier/features/waves/workspace.dart';
import 'package:physics_atelier/features/electromagnetism/workspace.dart';
import 'package:physics_atelier/features/electronics_thermal/workspace.dart';
import 'package:physics_atelier/features/fluid_modern/workspace.dart';
import 'package:physics_atelier/features/astronomy/workspace.dart';

import 'phase1_test.dart' show capture, top;
import 'phase9_fixture.dart' show originalSessions, priorEvidence;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase9 all102 running destinations computed trials and saved state',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      final store = ProviderScope.containerOf(
        t.element(find.byType(PhysicsApp)),
      ).read(notebookProvider);
      final originalTrials = store.trials.length;
      binding.reportData = {'images': <String, String>{}};
      const startAt = int.fromEnvironment('START_AT', defaultValue: 0);
      final rows = <String, dynamic>{if (startAt > 0) ...priorEvidence};
      binding.reportData!['phase9Inventory'] = {
        'entries': rows,
        'originalTrials': originalTrials,
      };
      await capture(t, binding, 'phase9-home');
      for (final studio in startAt == 0 ? studios : <Studio>[]) {
        router.go('/studio/${studio.id}');
        await t.pumpAndSettle();
        await capture(t, binding, 'phase9-studio-${studio.id}');
      }
      for (final entry in allEntries.skip(startAt)) {
        debugPrint('PHASE9_ENTRY ${entry.id} ${entry.title}');
        final original = originalSessions[entry.id] == null
            ? await store.readSession(entry.id)
            : Map<String, dynamic>.from(originalSessions[entry.id]);
        router.go('/lab/${entry.id}');
        await t.pumpAndSettle();
        if (entry.tool) {
          await capture(t, binding, 'phase9-entry-${entry.id}');
          rows[entry.id] = {
            'route': '/lab/${entry.id}',
            'rendered': true,
            'qualification': 'Tool interactions covered by phase8 native and phase9 focused regression; route screenshot is not completion proof',
          };
          router.go('/');
          await t.pumpAndSettle();
          if (original != null) await store.saveSession(entry.id, original);
          continue;
        }
        final sections = <String>[];
        for (final tab in [
          'Learn',
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
        ]) {
          await t.tap(find.text(tab).last);
          await t.pumpAndSettle();
          // Build content below the fold as well as the initial screen.
          final scroll = find.byType(Scrollable).first;
          final pos = t.state<ScrollableState>(scroll).position;
          pos.jumpTo(pos.maxScrollExtent);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '${entry.id} $tab');
          sections.add(tab);
        }
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        await top(t);
        final Type type = entry.astronomy
            ? AstronomyWorkspace
            : entry.fluidModern
            ? FMWorkspace
            : entry.electronicsThermal
            ? ETWorkspace
            : entry.electromagnetism
            ? EMWorkspace
            : entry.wavesOptics
            ? WaveWorkspace
            : entry.advanced
            ? AdvancedWorkspace
            : entry.dynamics
            ? DynamicsWorkspace
            : Workspace;
        final dynamic w = t.state(find.byType(type));
        final count = store.trials.length;
        Map<String, dynamic> before, after;
        if (entry.studioIndex == 1) {
          final dynamic e = w.experiment;
          before = Map<String, dynamic>.from(e.toJson());
          if (entry.index == 5) {
            e.samples = <double>[.021, .022, .023];
            e.changed();
          } else {
            e.setA(
              (e.a as double) +
                  (entry.index == 0
                      ? .001
                      : entry.index == 1
                      ? .0001
                      : .00001),
            );
          }
          if (entry.index == 4) {
            e.start();
            await t.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 250)),
            );
            e.pause();
          }
          e.note = 'Phase9 explicit native calculation verification; simulated observation.';
          e.checkPrediction(e.result as double);
          after = Map<String, dynamic>.from(e.toJson());
          await w.record();
        } else {
          before = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(w.configuration())),
          );
          if (entry.id == 's10-e04') {
            w.pause();
            w.circuit.parts.first.value += .1;
            w.restart();
          } else {
            final controls = List<Parameter>.from(w.lesson.controls);
            final c = controls.firstWhere(
              (p) => !['count', 'turns', 'closed', 'seed'].contains(p.key),
              orElse: () => controls.first,
            );
            final double current = w.parameters[c.key] as double;
            final double delta =
                [
                  'count',
                  'turns',
                  'closed',
                  'seed',
                  'inputA',
                  'inputB',
                  'n',
                  'upper',
                  'lower',
                ].contains(c.key)
                ? 1.0
                : (c.max - c.min) * .01;
            final double value = (current + delta)
                .clamp(c.min, c.max)
                .toDouble();
            final nextValue = value == current ? current - delta : value;
            if (entry.advanced || entry.wavesOptics || entry.electromagnetism) {
              w.updateMany(<String, double>{c.key: nextValue});
            } else {
              w.update(c.key, nextValue);
            }
          }
          w.notes.text = 'Phase9 explicit native calculation verification; simulated observation.';
          after = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(w.configuration())),
          );
          expect(
            jsonEncode(
              before[entry.id == 's10-e04' ? 'circuit' : 'parameters'],
            ),
            isNot(
              jsonEncode(
                after[entry.id == 's10-e04' ? 'circuit' : 'parameters'],
              ),
            ),
            reason: '${entry.id} actual parameter update',
          );
          await w.record();
        }
        await t.pumpAndSettle();
        expect(
          store.trials.length,
          greaterThan(count),
          reason: '${entry.id} must compute a valid record',
        );
        final trial = store.trials[count];
        expect(trial.value.isFinite, true);
        expect(trial.labId, entry.id);
        expect(trial.note, contains('Phase9 explicit'));
        final saved = await store.readSession(entry.id);
        expect(saved, isNotNull);
        final encoded = csvEncode([trial]);
        expect(encoded, contains(entry.id));
        expect(encoded, contains(trial.model));
        await top(t);
        await capture(t, binding, 'phase9-entry-${entry.id}');
        router.go('/');
        await t.pumpAndSettle();
        router.go('/lab/${entry.id}');
        await t.pumpAndSettle();
        final dynamic restored = t.state(find.byType(type));
        final Map<String, dynamic> replay = Map<String, dynamic>.from(
          entry.studioIndex == 1
              ? restored.experiment.toJson()
              : restored.configuration(),
        );
        for (final key
            in entry.studioIndex == 1
                ? ['a', 'b', 'note']
                : ['parameters', 'notes']) {
          expect(
            jsonEncode(replay[key]),
            jsonEncode(saved![key]),
            reason: '${entry.id} reopen $key',
          );
        }
        rows[entry.id] = {
          'route': '/lab/${entry.id}',
          'sections': sections,
          'parameterChanged': true,
          'finiteCalculatedTrial': true,
          'trialModel': trial.model,
          'quantity': trial.quantity,
          'unit': trial.unit,
          'value': trial.value,
          'saveReopen': true,
          'csvEncoded': true,
          'screenshot': 'phase9-entry-${entry.id}.png',
        };
        router.go('/');
        await t.pumpAndSettle();
        if (original != null) await store.saveSession(entry.id, original);
      }
      expect(rows.length, 102);
      binding.reportData!['phase9Inventory'] = {
        'entries': rows,
        'originalTrials': originalTrials,
        'currentTrials': store.trials.length,
        'qualification': 'Automated control/model callbacks, native computed persistence and rendered sections; not independent human visual/science certification',
      };
    },
    timeout: const Timeout(Duration(minutes: 45)),
  );
}
