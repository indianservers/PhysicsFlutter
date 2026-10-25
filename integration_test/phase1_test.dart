import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

Future<void> capture(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  String name,
) async {
  await tester.pumpAndSettle();
  final boundary =
      appCaptureKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    binding.reportData ??= {'images': <String, String>{}};
    (binding.reportData!['images'] as Map<String, String>)[name] = base64Encode(
      bytes!.buffer.asUint8List(),
    );
    image.dispose();
  });
  debugPrint('Captured $name');
}

Future<void> show(WidgetTester tester, Finder target) async {
  final scroll = find.byType(Scrollable).first;
  tester.state<ScrollableState>(scroll).position.jumpTo(0);
  await tester.pumpAndSettle();
  for (int i = 0; i < 40 && target.evaluate().isEmpty; i++) {
    final position = tester.state<ScrollableState>(scroll).position;
    position.jumpTo((position.pixels + 250).clamp(0, position.maxScrollExtent));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
}

Future<void> top(WidgetTester tester) async {
  tester
      .state<ScrollableState>(find.byType(Scrollable).first)
      .position
      .jumpTo(0);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Android Phase 1: navigate, manipulate, record, restore and export',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      await capture(tester, binding, '01-home');
      router.go('/studio/s01');
      await tester.pumpAndSettle();
      await capture(tester, binding, '02-measurement');
      for (int k = 0; k < 6; k++) {
        debugPrint('Testing Measurement lab $k');
        router.go('/lab/s01-e${k.toString().padLeft(2, '0')}');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Experiment').last);
        await tester.pumpAndSettle();
        await show(tester, find.text('Reset'));
        await tester.tap(find.text('Reset'));
        await tester.pumpAndSettle();
        await top(tester);
        if (k == 4) {
          await show(tester, find.text('Start timing'));
          await tester.tap(find.text('Start timing'));
          await tester.pump(const Duration(milliseconds: 500));
          await tester.tap(find.text('Pause'));
          await tester.pumpAndSettle();
        }
        if (k == 5) {
          await show(tester, find.text('Add reading'));
          for (final x in ['0.053', '0.054', '0.052']) {
            await tester.tap(find.text('Add reading'));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(TextField).last, x);
            await tester.tap(find.text('Apply'));
            await tester.pumpAndSettle();
          }
        }
        if (k < 3) {
          await show(tester, find.text('Reveal answer'));
          await tester.tap(find.text('Reveal answer'));
          await tester.pumpAndSettle();
        }
        // Scroll back to apparatus for the deliverable image, then record genuine state.
        await top(tester);
        await capture(tester, binding, '0${k + 3}-lab-$k');
        await show(tester, find.byKey(const Key('record-trial')));
        await tester.tap(find.byKey(const Key('record-trial')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Results').last);
        await tester.pumpAndSettle();
        await show(tester, find.text('Export actual trials as CSV'));
        expect(find.text('Export actual trials as CSV'), findsOneWidget);
        await show(tester, find.text('Reopen configuration'));
        await tester.tap(find.text('Reopen configuration').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Formulas').last);
        await tester.pumpAndSettle();
        await show(tester, find.text('Current substitution'));
        expect(find.text('Current substitution'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      router.go('/notebook');
      await tester.pumpAndSettle();
      expect(find.textContaining('recorded trials'), findsOneWidget);
      await capture(tester, binding, '09-notebook');
      final fresh = LocalNotebook();
      await fresh.initialize();
      expect(fresh.trials.length, greaterThanOrEqualTo(8));
      final csv = csvEncode(fresh.trials);
      expect(csv, contains('configuration_json'));
      binding.reportData!['csv'] = csv;
      await tester.tap(find.byTooltip('Export all trials as CSV'));
      await tester.pump(const Duration(seconds: 2));
      debugPrint('Native CSV share sheet opened; waiting for host inspection.');
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 12)),
      );
    },
  );
}
