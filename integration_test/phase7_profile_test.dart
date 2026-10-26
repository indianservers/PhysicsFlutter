import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/fluid_modern_run.dart';
import 'package:physics_atelier/features/fluid_modern/workspace.dart';

import 'phase1_test.dart' show show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Profile live continuity Bernoulli matter detections and aggregate decay',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      expect(kProfileMode, true);
      for (final id in ['s14-e03', 's14-e04', 's15-e02', 's15-e05']) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await chooseSection(t, 'Experiment');
        await t.pumpAndSettle();
        await show(t, find.text('Restore defaults'));
        await t.tap(find.text('Restore defaults'));
        await t.pumpAndSettle();
        final dynamic workspace = t.state(find.byType(FMWorkspace));
        if (id == 's15-e05') {
          workspace.update('initialN', 1e9);
          workspace.update('background', 1.0);
        }
        workspace.play();
        await t.pump();
        t
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await t.pump();
        await t.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        final start = (workspace.run as FMRun).ticks, frames = <FrameTiming>[];
        void collect(List<FrameTiming> values) => frames.addAll(values);
        SchedulerBinding.instance.addTimingsCallback(collect);
        for (int i = 0; i < 90; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        await t.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        SchedulerBinding.instance.removeTimingsCallback(collect);
        expect(frames, isNotEmpty);
        final run = workspace.run as FMRun;
        expect(run.ticks, greaterThan(start));
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
          'activity': '90 active playback frames; actual physical clock and calculated apparatus',
          'sampleCount': run.samples.length,
          'profilePoints': run.profile.length,
        };
        await chooseSection(t, 'Learn');
        await t.pumpAndSettle();
      }
      binding.reportData!['profileFile'] = 'phase7-profile.json';
      binding.reportData!['environment'] = 'Dedicated Physics_Phase3 emulator-5556; Android 17 API37 x86_64 16KB, 720x1280@320dpi, 2 cores 2048 MB; profile Skia/OpenGL, host RTX3050. Not physical-device performance.';
    },
  );
}
