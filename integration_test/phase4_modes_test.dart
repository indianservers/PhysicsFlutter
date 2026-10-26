import '../test/ui_navigation.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/waves/scene.dart';

import 'phase1_test.dart' show show, top, capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 4 native boundary conditions and model switches', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    WavePainter scene() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<WavePainter>()
        .first;
    Future<void> open(String id) async {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await chooseSection(tester, 'Experiment');
      await tester.pumpAndSettle();
      await show(tester, find.text('Restore documented defaults'));
      await tester.tap(find.text('Restore documented defaults'));
      await tester.pumpAndSettle();
      await top(tester);
    }

    Future<void> edit(String key, double value) async {
      await show(tester, find.byKey(Key('edit-$key')));
      await tester.tap(find.byKey(Key('edit-$key')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, value.toString());
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
      await top(tester);
    }

    Future<void> shot(String name) async {
      await top(tester);
      await capture(tester, binding, 'phase4-mode-$name');
    }

    Future<void> choose(String name) async {
      await show(tester, find.byKey(const Key('physical-model')));
      await tester.tap(find.byKey(const Key('physical-model')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
      await top(tester);
    }

    await open('s08-e02');
    await edit('phase', math.pi);
    await edit('probe', 0);
    await edit('z', .2);
    expect(scene().run.state['intensity']!, closeTo(0, 1e-12));
    await shot('coherent-cancellation');
    await open('s08-e03');
    await edit('harmonic', 3);
    expect(scene().run.state['nodeCount'], 4);
    expect(scene().run.profile.first['sum']!, closeTo(0, 1e-14));
    expect(scene().run.profile.last['sum']!, closeTo(0, 1e-14));
    await shot('third-harmonic');
    await open('s08-e04');
    await choose('Two tones');
    expect(scene().run.spectrum!.peaks.length, greaterThanOrEqualTo(2));
    await shot('two-tone-fft');
    await choose('Band-limited odd harmonics');
    expect(scene().run.spectrum!.peaks.length, greaterThanOrEqualTo(4));
    await shot('odd-harmonic-fft');
    await open('s09-e01');
    await show(tester, find.text('Critical-angle reference'));
    await tester.tap(find.text('Critical-angle reference'));
    await tester.pumpAndSettle();
    await top(tester);
    expect(scene().run.state['tir'], 0);
    expect(scene().run.state['transmittedAngle'], closeTo(90, 1e-5));
    await shot('critical-angle');
    await show(tester, find.text('Total internal reflection'));
    await tester.tap(find.text('Total internal reflection'));
    await tester.pumpAndSettle();
    await top(tester);
    expect(scene().run.state['tir'], 1);
    expect(scene().run.state.containsKey('transmittedAngle'), false);
    await shot('tir');
    for (final id in ['s09-e02', 's09-e03']) {
      await open(id);
      for (final factor in [2.0, 1.0, .5]) {
        await show(tester, find.text('u = ${factor}f magnitude'));
        await tester.tap(find.text('u = ${factor}f magnitude'));
        await tester.pumpAndSettle();
        await top(tester);
        expect(
          scene().run.state['imageType'],
          factor == 1
              ? 0
              : factor > 1
              ? 1
              : -1,
        );
        if (factor == 1) {
          expect(scene().run.state.containsKey('imageDistance'), false);
        }
        await shot('$id-object-${factor}f');
      }
      await choose(id == 's09-e02' ? 'Diverging thin lens' : 'Convex mirror');
      expect(scene().run.state['imageType'], -1);
      expect(scene().run.state['magnification']!, greaterThan(0));
      await shot('$id-diverging');
    }
    await open('s09-e05');
    final profile = scene().run.profile;
    await edit('probe', .012);
    expect(identical(profile, scene().run.profile), true);
    await shot('diffraction-detector');
    expect(tester.takeException(), null);
    binding.reportData!['phase4Modes'] = {
      'coherentCancellation': true,
      'fixedEndpointsAndHarmonic': true,
      'twoToneAndOddHarmonicFft': true,
      'criticalAndTir': true,
      'lensAndMirrorRealVirtualInfinity': true,
      'diffractionSharedProfileDetector': true,
    };
  });
}
