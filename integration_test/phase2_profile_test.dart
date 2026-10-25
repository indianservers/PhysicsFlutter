import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';

import 'phase1_test.dart' show show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Profile representative live dynamics scenes on the available emulator',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      expect(kProfileMode, true);
      for (final id in ['s02-e00', 's03-e05', 's04-e05']) {
        router.go('/lab/$id');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Experiment').last);
        await tester.pumpAndSettle();
        await show(tester, find.text('Reset'));
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('play-dynamics')));
        await tester.tap(find.byKey(const Key('play-dynamics')));
        await tester.pump();
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .jumpTo(0);
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        final frames = <FrameTiming>[];
        void collect(List<FrameTiming> values) => frames.addAll(values);
        SchedulerBinding.instance.addTimingsCallback(collect);
        for (int i = 0; i < 90; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 1)),
        );
        SchedulerBinding.instance.removeTimingsCallback(collect);
        expect(frames, isNotEmpty);
        double percentile(List<double> values, double p) {
          values.sort();
          return values[((values.length - 1) * p).round()];
        }

        binding.reportData ??= {};
        binding.reportData![id] = {
          'frameCount': frames.length,
          'medianBuildMs': percentile(
            frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList(),
            .5,
          ),
          'p95BuildMs': percentile(
            frames.map((f) => f.buildDuration.inMicroseconds / 1000).toList(),
            .95,
          ),
          'medianRasterMs': percentile(
            frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList(),
            .5,
          ),
          'p95RasterMs': percentile(
            frames.map((f) => f.rasterDuration.inMicroseconds / 1000).toList(),
            .95,
          ),
          'p95TotalMs': percentile(
            frames.map((f) => f.totalSpan.inMicroseconds / 1000).toList(),
            .95,
          ),
          'framesOver16_67Ms': frames
              .where((f) => f.totalSpan.inMicroseconds > 16670)
              .length,
        };
        await tester.tap(find.text('Learn').last);
        await tester.pumpAndSettle();
      }
      binding.reportData!['environment'] = 'Android 17 API37 x86_64 emulator, 720x1280@320dpi; profile mode; Skia/OpenGL; host RTX3050. Not a physical mid-range device.';
    },
  );
}
