import '../test/ui_navigation.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;

import 'phase9_restore_test.dart' as restoration;

import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/astronomy/workspace.dart';
import 'package:physics_atelier/features/advanced/workspace.dart';
import 'package:physics_atelier/features/dynamics/curriculum.dart'
    show Parameter;
import 'package:physics_atelier/features/waves/workspace.dart';
import 'package:physics_atelier/features/electromagnetism/workspace.dart';
import 'package:physics_atelier/features/electronics_thermal/workspace.dart';
import 'package:physics_atelier/features/fluid_modern/workspace.dart';
import 'package:physics_atelier/features/overview/compare_workspace.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Compact workspace default Android renderer and camera profile', (
    t,
  ) async {
    await app.main();
    await t.pumpAndSettle();
    expect(kProfileMode, true);
    for (final id in [
      's10-e01',
      's08-e04',
      's16-e00',
      's16-e01',
      's16-e05',
      'comparison0',
      'comparison4',
    ]) {
      late int Function() ticks;
      late void Function() pause;
      dynamic activeState;
      bool staticInvestigation = false;
      int manipulations = 0;
      if (id.startsWith('s')) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await chooseSection(t, 'Experiment');
        await t.pumpAndSettle();
        final int studio = int.parse(id.substring(1, 3));
        final Type type = studio == 16
            ? AstronomyWorkspace
            : studio >= 14
            ? FMWorkspace
            : studio >= 12
            ? ETWorkspace
            : studio >= 10
            ? EMWorkspace
            : studio >= 8
            ? WaveWorkspace
            : AdvancedWorkspace;
        final dynamic state = t.state(find.byType(type));
        if (studio == 7) {
          state.reset();
        } else if (studio >= 12 && studio < 14) {
          state.reset();
        } else {
          state.defaults();
        }
        await t.pumpAndSettle();
        // Static field/circuit/diffraction investigations are profiled under
        // genuine parameter changes; dynamic cases use the shared clock.
        final bool staticCase = [
          's10-e01',
          's10-e04',
          's09-e05',
          's13-e01',
        ].contains(id);
        if (!staticCase) state.play();
        ticks = () => state.run.ticks as int;
        pause = () => state.pause();
        activeState = state;
        staticInvestigation = staticCase;
      } else {
        router.go('/lab/s00-e04');
        await t.pumpAndSettle();
        final state = t.state<CompareWorkspaceState>(
          find.byType(CompareWorkspace),
        );
        state.choose(int.parse(id.substring(id.length - 1)));
        await t.pumpAndSettle();
        state.play();
        ticks = () => (state.coordinate * 120).round();
        pause = state.pause;
      }
      await t.pump();
      t
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await t.pump();
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 2)));
      final start = ticks(), frames = <FrameTiming>[];
      void collect(List<FrameTiming> v) => frames.addAll(v);
      SchedulerBinding.instance.addTimingsCallback(collect);
      for (int i = 0; i < 90; i++) {
        if (staticInvestigation) {
          if (id == 's10-e04') {
            activeState.pause();
            activeState.circuit.parts.first.value =
                6.0 + math.sin((i + 1) / 10);
            activeState.restart();
          } else {
            final controls = List<Parameter>.from(activeState.lesson.controls);
            final c = controls.firstWhere(
              (c) => !['count', 'turns', 'closed', 'seed'].contains(c.key),
              orElse: () => controls.first,
            );
            final updates = <String, double>{
              c.key: c.initial + (c.max - c.min) * .01 * math.sin((i + 1) / 10),
            };
            if (id == 's13-e01') {
              activeState.update(c.key, updates[c.key]);
            } else {
              activeState.updateMany(updates);
            }
          }
          manipulations++;
        }
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      SchedulerBinding.instance.removeTimingsCallback(collect);
      expect(frames, isNotEmpty);
      if (staticInvestigation) {
        expect(manipulations, 90);
      } else {
        expect(ticks(), greaterThan(start));
      }
      double percentile(double Function(FrameTiming) read, double q) {
        final values = frames.map(read).toList()..sort();
        return values[((values.length - 1) * q).round()];
      }

      binding.reportData ??= {};
      binding.reportData![id] = {
        'frameCount': frames.length,
        'parameterManipulations': manipulations,
        'startTicks': start,
        'endTicks': ticks(),
        'medianBuildMs': percentile(
          (f) => f.buildDuration.inMicroseconds / 1000,
          .5,
        ),
        'p95BuildMs': percentile(
          (f) => f.buildDuration.inMicroseconds / 1000,
          .95,
        ),
        'medianRasterMs': percentile(
          (f) => f.rasterDuration.inMicroseconds / 1000,
          .5,
        ),
        'p95RasterMs': percentile(
          (f) => f.rasterDuration.inMicroseconds / 1000,
          .95,
        ),
        'p95TotalMs': percentile((f) => f.totalSpan.inMicroseconds / 1000, .95),
        'framesOver16_67Ms': frames
            .where((f) => f.totalSpan.inMicroseconds > 16670)
            .length,
        'activity': staticInvestigation
            ? '90 actual parameter updates with calculated model refresh'
            : '90 requested active playback frames; actual model coordinate/ticks advanced',
      };
      pause();
      await t.pumpAndSettle();
      final fixedTicks = ticks();
      await tapViewportTool(t, 'Workspace panes');
      await t.pumpAndSettle();
      await t.tap(find.text('Scene + Graph').last);
      await t.pumpAndSettle();
      frames.clear();
      SchedulerBinding.instance.addTimingsCallback(collect);
      for (int i = 0; i < 40; i++) {
        t
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) =>
                    w is IconButton &&
                    w.tooltip == (i.isEven ? 'Zoom in' : 'Zoom out'),
              ),
            )
            .onPressed!();
        final divider = find.byKey(const Key('pane-divider'));
        t.widget<GestureDetector>(divider).onPanUpdate!(
          DragUpdateDetails(
            globalPosition: Offset.zero,
            delta: Offset(0, i.isEven ? 5 : -5),
          ),
        );
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      SchedulerBinding.instance.removeTimingsCallback(collect);
      expect(
        ticks(),
        fixedTicks,
        reason: 'Camera/layout changes must not advance science',
      );
      binding.reportData![id]['cameraAndDivider'] = {
        'operations': 40,
        'unchangedScienceTicks': fixedTicks,
        'frameCount': frames.length,
        if (frames.isNotEmpty)
          'medianRasterMs': percentile(
            (f) => f.rasterDuration.inMicroseconds / 1000,
            .5,
          ),
        if (frames.isNotEmpty)
          'p95RasterMs': percentile(
            (f) => f.rasterDuration.inMicroseconds / 1000,
            .95,
          ),
      };
      router.go('/');
      await t.pumpAndSettle();
    }
    binding.reportData!['profileFile'] = 'workspace-after-default-profile.json';
    binding.reportData!['environment'] = 'Dedicated emulator-5556, Physics_Phase3, Android17 API37 x86_64 16KB,720x1280@320dpi,2 cores/2048MB; profile DEFAULT Android renderer host RTX3050; actual backend is recorded in engine startup log. Not physical-device performance.';
  });
  restoration.main();
}
