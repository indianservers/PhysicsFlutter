import '../test/ui_navigation.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/core/physics/thermal_library.dart';
import 'package:physics_atelier/core/physics/optical_library.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';
import 'package:physics_atelier/features/material_bench/workspace.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Spherometer, six Measurement labs and shared material/optical benches on Android',
    (t) async {
      binding.reportData = {'images': <String, String>{}};
      await app.main();
      await t.pumpAndSettle();
      final store = ProviderScope.containerOf(
            t.element(find.byType(PhysicsApp)),
          ).read(notebookProvider),
          oldCount = ProviderScope.containerOf(
            t.element(find.byType(PhysicsApp)),
          ).read(notebookProvider).trials.length;
      router.go('/lab/s01-e03');
      await t.pumpAndSettle();
      final dynamic state = t.state(find.byType(Workspace));
      final e = state.experiment;
      e.reset();
      e.note = 'Simulated QA: Spherometer plane and curved contacts.';
      e.changed();
      await t.pumpAndSettle();
      await capture(t, binding, 'spherometer-after-plane');
      expect(find.byType(NavigationBar), findsNothing);
      expect(
        find.byKey(const Key('sphero-numeric')).hitTestable(),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('sphero-numeric')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '-3');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(e.a, 0);
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(e.spherometer.reference, 0);
      t
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .onChanged!(1);
      await t.pumpAndSettle();
      // Actual knob gesture must move the same model; then use exact contact entry.
      final area = t.getRect(find.byKey(const Key('spherometer-apparatus'))),
          fit = math.min(area.width / 440, area.height / 290),
          origin =
              area.topLeft +
              Offset(
                (area.width - 440 * fit) / 2,
                (area.height - 290 * fit) / 2,
              );
      final start = e.a;
      await t.dragFrom(
        origin + const Offset(220, 90) * fit,
        const Offset(0, -30),
      );
      await t.pumpAndSettle();
      expect(e.a, greaterThan(start));
      await t.tap(find.byKey(const Key('sphero-numeric')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField), '-3');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      expect(e.a, closeTo(.00044, 1e-12));
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(e.result, greaterThan(0));
      await capture(t, binding, 'spherometer-after-perspective');
      final before = jsonEncode(e.toJson());
      await tapViewportTool(t, 'Pan / zoom camera');
      await t.pumpAndSettle();
      await t.drag(
        find.byKey(const Key('workspace-camera')),
        const Offset(20, 10),
      );
      await t.pumpAndSettle();
      expect(jsonEncode(e.toJson()), before);
      await tapViewportTool(t, 'Fit apparatus / reset view');
      await tapViewportTool(t, 'Manipulate apparatus');
      await t.pumpAndSettle();
      for (final view in ['Top', 'Section', 'Perspective']) {
        await t.tap(find.text(view));
        await t.pumpAndSettle();
        await capture(t, binding, 'spherometer-after-${view.toLowerCase()}');
      }
      final savedReading = e.a;
      await tapViewportTool(t, 'Workspace panes');
      await t.pumpAndSettle();
      await t.tap(find.text('Full-screen Scene').last);
      await t.pumpAndSettle();
      await capture(t, binding, 'spherometer-after-fullscreen');
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(e.a, savedReading);
      await t.tap(find.byTooltip('Scale magnifier'));
      await t.pumpAndSettle();
      await capture(t, binding, 'spherometer-after-scale');
      await t.tap(find.byTooltip('Back').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Reveal / Check'));
      await t.pumpAndSettle();
      await capture(t, binding, 'spherometer-after-check');
      await t.tap(find.text('Close check'));
      await t.pumpAndSettle();
      t
          .widget<DropdownButtonFormField<int>>(
            find.byType(DropdownButtonFormField<int>),
          )
          .onChanged!(2);
      await t.pumpAndSettle();
      e.setA(-.003);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      expect(e.result, lessThan(0));
      await capture(t, binding, 'spherometer-after-concave');
      final measurements = <String, bool>{};
      for (int i = 0; i < 6; i++) {
        final id = 's01-e0$i';
        router.go('/lab/$id');
        await t.pumpAndSettle();
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.byTooltip('Reset').hitTestable(), findsOneWidget);
        await capture(t, binding, 'libraries-measurement-$id');
        measurements[id] = true;
      }
      router.go('/lab/s13-e01');
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Thermal material library'));
      await t.pumpAndSettle();
      var bench = t.state<MaterialBenchState>(
        find.byType(MaterialBenchWorkspace),
      );
      final thermalModes = <String, bool>{};
      for (final mode in ThermalBench.modes) {
        bench.thermal = ThermalBench()
          ..mode = mode
          ..note = 'Simulated QA: $mode';
        if (mode == ThermalBench.modes[2]) {
          bench.thermal.materials = ['ptfe', 'soda-lime'];
        }
        bench.changed();
        await t.pumpAndSettle();
        expect(bench.error, isEmpty);
        await t.tap(find.byKey(const Key('record-trial')));
        await t.pumpAndSettle();
        await t.pump(const Duration(seconds: 2));
        await capture(
          t,
          binding,
          'libraries-thermal-${ThermalBench.modes.indexOf(mode)}',
        );
        thermalModes[mode] = true;
      }
      bench.thermal = ThermalBench()..overlay = true;
      bench.changed();
      await t.pumpAndSettle();
      await capture(t, binding, 'libraries-thermal-overlay');
      await tapViewportTool(t, 'Workspace panes');
      await t.pumpAndSettle();
      await t.tap(find.text('Scene + Graph').last);
      await t.pumpAndSettle();
      await capture(t, binding, 'libraries-thermal-profile-graph');
      router.go('/lab/s09-e01');
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Optical component library'));
      await t.pumpAndSettle();
      bench = t.state<MaterialBenchState>(find.byType(MaterialBenchWorkspace));
      final optics = <String, dynamic>{};
      for (final component in opticalComponents) {
        bench.optical = OpticalBench()
          ..components = [
            PlacedOptic(
              component.id,
              material: component.category == 'Liquid-containing element'
                  ? 'water'
                  : 'bk7',
            ),
          ]
          ..wavelength = 589.3
          ..source = const OVec(-2, .1)
          ..direction = const OVec(1, 0)
          ..note = 'Simulated QA: ${component.name}';
        bench.selected = 0;
        if (component.id == 'corner') {
          bench.optical.source = const OVec(1.5, 1.4, 1.3);
          bench.optical.direction = const OVec(-1, -1, -1);
        }
        bench.changed();
        await t.pumpAndSettle();
        expect(bench.error, isEmpty);
        expect(
          bench.traced.first.segments.any((s) => s.event != 'exit'),
          isTrue,
        );
        expect(bench.traced.first.accounted, closeTo(1, 1e-8));
        await capture(t, binding, 'libraries-optic-${component.id}');
        optics[component.id] = {
          'rendered': true,
          'surfaceInteraction': true,
          'powerAccounted': bench.traced.first.accounted,
          'scope': component.status,
        };
      }
      final presets = <String, bool>{};
      for (int i = 0; i < MaterialBenchState.investigations.length; i++) {
        bench.investigation(i);
        await t.pumpAndSettle();
        expect(bench.error, isEmpty);
        expect(
          bench.traced.first.segments.any((s) => s.event != 'exit'),
          isTrue,
        );
        await capture(t, binding, 'libraries-investigation-$i');
        presets[MaterialBenchState.investigations[i]] = true;
      }
      bench.optical.note = 'Simulated QA: 3D return direction';
      await t.tap(find.byKey(const Key('record-trial')));
      await t.pumpAndSettle();
      final imageBytes = await t.runAsync(bench.captureWorkspaceImage);
      expect(imageBytes!.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
      final trial = store.trials.last;
      expect(Trial.fromJson(trial.toJson()).value, trial.value);
      bench.investigation(0);
      expect(bench.restore(trial.configuration), isTrue);
      expect(bench.optical.components.single.component, 'corner');
      binding.reportData!['librariesAudit'] = {
        'measurementLabs': measurements,
        'thermalModes': thermalModes,
        'thermalRecords': thermalMaterials.map((m) => m.toJson()).toList(),
        'opticalComponents': optics,
        'guidedPresets': presets,
        'newExplicitQaTrials': store.trials.length - oldCount,
        'qualification': 'Android emulator native rendering and targeted interactions. Optical sections and 3D scope are explicitly labeled; unavailable thermal properties disabled.',
      };
      router.go('/');
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  restoration.main();
}
