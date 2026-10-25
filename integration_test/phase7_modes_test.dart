import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/fluid_modern/workspace.dart';

import '../test/fm_app_test.dart' show fmScene, fmMode;
import '../test/em_app_test.dart' show top, edit;
import 'phase1_test.dart' show capture, show;

class LifecycleTrace extends WidgetsBindingObserver {
  final events = <AppLifecycleState>[];
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    events.add(state);
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase 7 physical boundaries distributions and actual OS lifecycle',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      dynamic workspace() => t.state(find.byType(FMWorkspace));
      Future<void> open(String id) async {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        await show(t, find.text('Restore defaults'));
        await t.tap(find.text('Restore defaults'));
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
        await capture(t, binding, 'phase7-mode-$name');
      }

      Future<void> advance(double time) async {
        workspace().pause();
        workspace().run.seek(time);
        workspace().tick.value++;
        await t.pumpAndSettle();
        await top(t);
      }

      Future<void> histogram() async {
        await t.tap(find.text('Visualize').last);
        await t.pumpAndSettle();
        final field = find.byType(DropdownButtonFormField<String>);
        await show(t, field);
        t.widget<DropdownButtonFormField<String>>(field).onChanged!(
          'Detections histogram',
        );
        await t.pumpAndSettle();
      }

      final checks = <String, dynamic>{};
      await open('s14-e00');
      final absolute = fmScene(t).run.state['absolutePressure'];
      await edit(t, 'referencePressure', '100000');
      expect(fmScene(t).run.state['absolutePressure'], absolute);
      checks['pressure'] = Map.of(fmScene(t).run.state);
      await shot('gauge-versus-absolute');
      await open('s14-e01');
      await fmMode(t, 1);
      await edit(t, 'deltaPressure', '0');
      await edit(t, 'areaRight', '.03');
      await edit(t, 'oilVolume', '.0008');
      expect(fmScene(t).run.state['volumeResidual']!, closeTo(0, 1e-12));
      expect(fmScene(t).run.state['pressureBalance']!, closeTo(0, 1e-8));
      checks['twoFluid'] = Map.of(fmScene(t).run.state);
      await shot('volume-conserving-interface');
      await open('s14-e02');
      expect(fmScene(t).run.state['submergedFraction'], closeTo(.7, 1e-12));
      await fmMode(t, 1);
      await edit(t, 'bottomDepth', '.05');
      expect(
        fmScene(t).run.state['buoyantForce']!,
        lessThan(fmScene(t).run.state['weight']!),
      );
      await shot('held-partial-immersion');
      await fmMode(t, 0);
      await edit(t, 'objectDensity', '2000');
      expect(fmScene(t).run.state['supportForceUp']!, greaterThan(0));
      await shot('denser-bottom-supported');
      await open('s14-e03');
      await edit(t, 'radius2', '.007');
      await advance(2);
      expect(fmScene(t).run.state['continuityResidual'], closeTo(0, 1e-12));
      checks['continuity'] = Map.of(fmScene(t).run.state);
      await shot('actual-pipe-area-flow');
      await open('s14-e04');
      await edit(t, 'radius2', '.003');
      await edit(t, 'flow', '.0005');
      expect(fmScene(t).run.invalid, isNotEmpty);
      checks['invalidVenturi'] = fmScene(t).run.invalid;
      await shot('venturi-invalid-pressure');
      await open('s14-e04');
      await edit(t, 'elevation', '.02');
      expect(fmScene(t).run.invalid, isEmpty);
      checks['elevatedVenturi'] = Map.of(fmScene(t).run.state);
      await shot('calculated-piezometer-heads');
      await open('s14-e05');
      await edit(t, 'radius', '.001');
      await edit(t, 'viscosity', '.001');
      expect(fmScene(t).run.invalid, contains('Re'));
      await shot('stokes-rejected-reynolds');
      await open('s14-e05');
      await advance(fmScene(t).run.maxTime);
      expect(fmScene(t).run.state['position'], closeTo(.2, 1e-10));
      checks['stokesArrival'] = Map.of(fmScene(t).run.state);
      await shot('stokes-arrival');
      await open('s15-e00');
      await edit(t, 'n', '3');
      await edit(t, 'seed', '741');
      await show(t, find.byKey(const Key('sample-batch')));
      await t.tap(find.byKey(const Key('sample-batch')));
      await t.pumpAndSettle();
      await top(t);
      final histogramBefore = List.of(fmScene(t).run.histogram),
          positionsBefore = List.of(fmScene(t).run.positions);
      await t.tap(find.byTooltip('Save session'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s15-e00');
      await t.pumpAndSettle();
      await t.tap(find.text('Experiment').last);
      await t.pumpAndSettle();
      expect(fmScene(t).run.histogram, histogramBefore);
      expect(fmScene(t).run.positions, positionsBefore);
      checks['seededWellReplay'] = true;
      await histogram();
      await shot('stationary-well-histogram');
      await open('s15-e01');
      await edit(t, 'wavelength', '8e-7');
      await edit(t, 'intensity', '100');
      expect(fmScene(t).run.state['current'], 0);
      expect(fmScene(t).run.state['emitting'], 0);
      await shot('below-photoelectric-threshold');
      await edit(t, 'wavelength', '4e-7');
      final stopping = fmScene(t).run.state['stoppingPotential']!;
      await edit(t, 'bias', '${-stopping - .1}');
      expect(fmScene(t).run.state['current'], 0);
      checks['stoppingBias'] = Map.of(fmScene(t).run.state);
      await shot('retarding-bias-stops-current');
      await open('s15-e02');
      await show(t, find.byKey(const Key('sample-batch')));
      await t.tap(find.byKey(const Key('sample-batch')));
      await t.pumpAndSettle();
      await top(t);
      expect(fmScene(t).run.measurementCount, 100);
      checks['matterDetections'] = Map.of(fmScene(t).run.state);
      await histogram();
      await shot('matter-wave-histogram');
      await open('s15-e03');
      await fmMode(t, 1);
      await edit(t, 'upper', '3');
      expect(fmScene(t).run.state['wavelength']! * 1e9, closeTo(656.47, .02));
      await shot('hydrogen-vacuum-halpha');
      await fmMode(t, 4);
      expect(fmScene(t).run.state['absorption'], 1);
      await shot('hydrogen-absorption');
      await open('s15-e04');
      await fmMode(t, 3);
      expect(fmScene(t).run.state['atomicMassU'], 12);
      checks['carbon12'] = Map.of(fmScene(t).run.state);
      await shot('sourced-carbon-isotope');
      await open('s15-e05');
      await edit(t, 'initialN', '1000000000');
      await edit(t, 'efficiency', '0');
      await edit(t, 'background', '0');
      await advance(fmScene(t).run.maxTime * .1);
      expect(fmScene(t).run.decays, greaterThan(0));
      expect(fmScene(t).run.detected, 0);
      expect(fmScene(t).run.background, 0);
      checks['activityNotCounts'] = Map.of(fmScene(t).run.state);
      await shot('activity-not-detected-counts');
      final trace = LifecycleTrace();
      WidgetsBinding.instance.addObserver(trace);
      workspace().play();
      await t.pump();
      await t.pump(const Duration(milliseconds: 80));
      debugPrint('PHASE7_READY_FOR_OS_BACKGROUND');
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
      await t.pump();
      expect(trace.events, contains(AppLifecycleState.paused));
      expect(trace.events.last, AppLifecycleState.resumed);
      expect(workspace().ticker.isActive, false);
      final paused = fmScene(t).run.time;
      await t.pump(const Duration(milliseconds: 300));
      expect(fmScene(t).run.time, paused);
      WidgetsBinding.instance.removeObserver(trace);
      checks['actualOSBackgroundResume'] = trace.events
          .map((s) => s.name)
          .toList();
      binding.reportData ??= {};
      binding.reportData!['phase7Modes'] = checks;
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
