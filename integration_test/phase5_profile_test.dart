import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/features/electromagnetism/workspace.dart';

import 'phase1_test.dart' show show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Profile cached 3-source contours, 12-component graph and Boris trail',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      expect(kProfileMode, true);
      for (final id in ['s10-e02', 's10-e04', 's11-e01']) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await chooseSection(t, 'Experiment');
        await t.pumpAndSettle();
        await show(t, find.text('Restore documented defaults'));
        await t.tap(find.text('Restore documented defaults'));
        await t.pumpAndSettle();
        final dynamic workspace = t.state(find.byType(EMWorkspace));
        ValueChanged<double>? change;
        Object? cached;
        if (id == 's10-e02') {
          workspace.parameters['count'] = 3.0;
          workspace.parameters['q3'] = 3e-9;
          workspace.restart();
          await t.pumpAndSettle();
          cached = (workspace.run as EMRun).contours;
          await show(t, find.byKey(const Key('slider-probeX')));
          change = t
              .widget<Slider>(find.byKey(const Key('slider-probeX')))
              .onChanged;
        } else if (id == 's10-e04') {
          final graph = CircuitGraph.example(2);
          for (int i = 0; i < 5; i++) {
            final p = CircuitPart(
              'Stress$i',
              'resistor',
              value: 10.0 + 5 * i,
              x: .3 + .1 * i,
              y: .3 + .1 * i,
            );
            graph.parts.add(p);
            graph.wires.addAll([
              [p.a, 'B1:a'],
              [p.b, 'B1:b'],
            ]);
          }
          workspace.circuit = graph;
          workspace.restart();
          await t.pumpAndSettle();
          expect((workspace.run as EMRun).network!.valid, true);
          cached = (workspace.run as EMRun).network;
          await show(t, find.byKey(const Key('layout-x')));
          change = t
              .widget<Slider>(find.byKey(const Key('layout-x')))
              .onChanged;
        } else {
          (workspace.run as EMRun).seek(6e-6);
          workspace.tick.value++;
          await t.pumpAndSettle();
          await show(t, find.byKey(const Key('play-em')));
          await t.tap(find.byKey(const Key('play-em')));
          await t.pump();
        }
        t
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        final start = (workspace.run as EMRun).ticks, frames = <FrameTiming>[];
        void collect(List<FrameTiming> values) => frames.addAll(values);
        SchedulerBinding.instance.addTimingsCallback(collect);
        for (int i = 0; i < 90; i++) {
          if (id == 's10-e02') {
            change!(.18 + (i % 30) * .001);
          } else if (id == 's10-e04') {
            change!(.2 + (i % 45) * .01);
          }
          await t.pump(const Duration(milliseconds: 16));
        }
        await t.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        SchedulerBinding.instance.removeTimingsCallback(collect);
        expect(frames, isNotEmpty);
        final run = workspace.run as EMRun;
        if (id == 's10-e02') expect(identical(cached, run.contours), true);
        if (id == 's10-e04') expect(identical(cached, run.network), true);
        if (id == 's11-e01') {
          expect(run.ticks, greaterThan(start));
          expect(run.finished, false);
        }
        double percentile(List<double> v, double p) {
          v.sort();
          return v[((v.length - 1) * p).round()];
        }

        double stat(double Function(FrameTiming) f, double p) =>
            percentile(frames.map(f).toList(), p);
        binding.reportData ??= {};
        binding.reportData![id] = {
          'frameCount': frames.length,
          'startTicks': start,
          'endTicks': run.ticks,
          'medianBuildMs': stat(
            (f) => f.buildDuration.inMicroseconds / 1000,
            .5,
          ),
          'p95BuildMs': stat((f) => f.buildDuration.inMicroseconds / 1000, .95),
          'medianRasterMs': stat(
            (f) => f.rasterDuration.inMicroseconds / 1000,
            .5,
          ),
          'p95RasterMs': stat(
            (f) => f.rasterDuration.inMicroseconds / 1000,
            .95,
          ),
          'p95TotalMs': stat((f) => f.totalSpan.inMicroseconds / 1000, .95),
          'framesOver16_67Ms': frames
              .where((f) => f.totalSpan.inMicroseconds > 16670)
              .length,
          'activity': id == 's10-e02'
              ? '90 actual probe-control edits, three sources, cached contour/line geometry'
              : id == 's10-e04'
              ? '90 layout-control edits, solved 12-part graph, cached MNA solution'
              : 'Active B-only Boris run, bounded 3-D trail and real physical clock',
          'parts': id == 's10-e04' ? run.circuit.parts.length : null,
          'fieldTraces': run.lines.length,
          'contourSegments': run.contours.length,
          'trailPoints': run.trail.length,
        };
        await chooseSection(t, 'Learn');
        await t.pumpAndSettle();
      }
      binding.reportData!['profileFile'] = 'phase5-profile.json';
      binding.reportData!['environment'] = 'Dedicated Physics_Phase3 emulator-5556; Android 17 API37 x86_64 16KB, 720x1280@320dpi, 2 cores 2048 MB; profile Skia/OpenGL, host RTX3050. Not physical-device performance.';
    },
  );
}
