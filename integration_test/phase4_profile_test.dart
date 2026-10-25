import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/waves/scene.dart';

import 'phase1_test.dart' show show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Profile actual coherent field, FFT and detector updates', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    expect(kProfileMode, true);
    for (final id in ['s08-e02', 's08-e04', 's09-e05']) {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      await show(tester, find.text('Restore documented defaults'));
      await tester.tap(find.text('Restore documented defaults'));
      await tester.pumpAndSettle();
      if (id != 's09-e05') {
        await show(tester, find.byKey(const Key('play-waves')));
        await tester.tap(find.byKey(const Key('play-waves')));
        await tester.pump();
      }
      ValueChanged<double>? moveDetector;
      if (id == 's09-e05') {
        await show(tester, find.byKey(const Key('slider-probe')));
        moveDetector = tester
            .widget<Slider>(find.byKey(const Key('slider-probe')))
            .onChanged;
      }
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .jumpTo(0);
      await tester.pump();
      final model = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<WavePainter>()
          .first
          .run;
      final startTicks = model.ticks;
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 2)),
      );
      final frames = <FrameTiming>[];
      void collect(List<FrameTiming> f) => frames.addAll(f);
      SchedulerBinding.instance.addTimingsCallback(collect);
      for (int i = 0; i < 90; i++) {
        if (id == 's09-e05') {
          // Drive the real public detector slider while the apparatus stays visible.
          moveDetector!((i % 45 - 22) * .001);
        }
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 1)),
      );
      SchedulerBinding.instance.removeTimingsCallback(collect);
      expect(frames, isNotEmpty);
      if (id != 's09-e05') {
        expect(model.ticks, greaterThan(startTicks));
        expect(
          model.finished,
          false,
          reason: 'Profile must measure an active physical model',
        );
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
        'startTicks': startTicks,
        'endTicks': model.ticks,
        'medianBuildMs': stat((f) => f.buildDuration.inMicroseconds / 1000, .5),
        'p95BuildMs': stat((f) => f.buildDuration.inMicroseconds / 1000, .95),
        'medianRasterMs': stat(
          (f) => f.rasterDuration.inMicroseconds / 1000,
          .5,
        ),
        'p95RasterMs': stat((f) => f.rasterDuration.inMicroseconds / 1000, .95),
        'p95TotalMs': stat((f) => f.totalSpan.inMicroseconds / 1000, .95),
        'framesOver16_67Ms': frames
            .where((f) => f.totalSpan.inMicroseconds > 16670)
            .length,
        'activity': id == 's09-e05'
            ? '90 actual detector-slider updates, same cached intensity curve'
            : 'Animated physical model, fixed clock and bounded cached sampling',
      };
      await tester.tap(find.text('Learn').last);
      await tester.pumpAndSettle();
    }
    binding.reportData!['profileFile'] = 'phase4-profile.json';
    binding.reportData!['environment'] = 'Physics_Phase3 emulator-5556, Android 17 API37 x86_64 16KB, 720x1280@320dpi, 2 cores 2048 MB; profile Skia/OpenGL host RTX3050. Not a physical mid-range device.';
  });
}
