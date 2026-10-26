import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/astronomy/workspace.dart';
import 'package:physics_atelier/features/overview/compare_workspace.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase8 actual active astronomy and comparison profile', (
    t,
  ) async {
    await app.main();
    await t.pumpAndSettle();
    expect(kProfileMode, true);
    for (final id in [
      's16-e00',
      's16-e01',
      's16-e05',
      'comparison0',
      'comparison4',
    ]) {
      late int Function() ticks;
      late void Function() pause;
      if (id.startsWith('s16')) {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await t.tap(find.text('Experiment').last);
        await t.pumpAndSettle();
        final state = t.state<AstronomyWorkspaceState>(
          find.byType(AstronomyWorkspace),
        );
        state.defaults();
        await t.pumpAndSettle();
        state.play();
        ticks = () => state.run.ticks;
        pause = state.pause;
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
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      SchedulerBinding.instance.removeTimingsCallback(collect);
      expect(frames, isNotEmpty);
      expect(ticks(), greaterThan(start));
      double percentile(double Function(FrameTiming) read, double q) {
        final values = frames.map(read).toList()..sort();
        return values[((values.length - 1) * q).round()];
      }

      binding.reportData ??= {};
      binding.reportData![id] = {
        'frameCount': frames.length,
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
        'activity': '90 requested active playback frames; actual model coordinate/ticks advanced',
      };
      pause();
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    }
    binding.reportData!['profileFile'] = 'phase8-profile.json';
    binding.reportData!['environment'] = 'Dedicated emulator-5556, Physics_Phase3, Android17 API37 x86_64 16KB,720x1280@320dpi,2 cores/2048MB; profile Skia/OpenGL host RTX3050. Not physical-device performance.';
  });
}
