import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/waves/workspace.dart';
import 'package:physics_atelier/features/waves/microphone.dart';

import 'app_test.dart' show notebook;

Future<void> show(WidgetTester tester, Finder target) async {
  bool absent() {
    try {
      return target.evaluate().isEmpty;
    } on StateError {
      return true;
    }
  }

  Finder verticalScroll() {
    final sheet = find.byType(BottomSheet);
    final all = sheet.evaluate().isEmpty
        ? find.byType(Scrollable)
        : find.descendant(of: sheet, matching: find.byType(Scrollable));
    return all
            .evaluate()
            .where(
              (e) =>
                  tester
                      .state<ScrollableState>(find.byWidget(e.widget))
                      .position
                      .axis ==
                  Axis.vertical,
            )
            .isEmpty
        ? all.first
        : find.byWidget(
            all
                .evaluate()
                .firstWhere(
                  (e) =>
                      tester
                          .state<ScrollableState>(find.byWidget(e.widget))
                          .position
                          .axis ==
                      Axis.vertical,
                )
                .widget,
          );
  }

  Future<void> scan() async {
    if (find.byType(Scrollable).evaluate().isEmpty) return;
    final scroll = verticalScroll();
    final p = tester.state<ScrollableState>(scroll).position;
    p.jumpTo(0);
    await tester.pumpAndSettle();
    for (int i = 0; i < 65 && absent() && p.pixels < p.maxScrollExtent; i++) {
      p.jumpTo((p.pixels + 250).clamp(0, p.maxScrollExtent));
      await tester.pumpAndSettle();
    }
  }

  final existingSheet = find.byType(BottomSheet);
  if (!absent() &&
      existingSheet.evaluate().isNotEmpty &&
      find.descendant(of: existingSheet, matching: target).evaluate().isEmpty &&
      find.byTooltip('Close controls').evaluate().isNotEmpty) {
    await tester.tap(find.byTooltip('Close controls'));
    await tester.pumpAndSettle();
  }
  await scan();
  if (absent() &&
      target.describeMatch(Plurality.one).contains('Reopen configuration') &&
      find.byIcon(Icons.chevron_right).evaluate().isNotEmpty &&
      find.textContaining('recorded trials').evaluate().isNotEmpty) {
    await tester.tap(find.byIcon(Icons.chevron_right).first);
    await tester.pumpAndSettle();
  }
  if (absent() && find.byType(BottomSheet).evaluate().isEmpty) {
    final more = find.byTooltip('More controls and guided investigation');
    final mode = find.byTooltip('Practice mode and topic');
    final help = find.byTooltip('Tool notes and help');
    final opener = more.evaluate().isNotEmpty
        ? more
        : mode.evaluate().isNotEmpty
        ? mode
        : help;
    if (opener.evaluate().isNotEmpty) {
      await tester.tap(opener.first);
      await tester.pumpAndSettle();
      await scan();
    }
  }
  await tester.ensureVisible(target.first);
  await tester.pumpAndSettle();
}

class DeniedMicrophone extends LiveMicrophone {
  @override
  Future<void> start() async {
    status = 'Microphone permission denied. Generated mode works offline.';
    notifyListeners();
  }
}

void main() {
  test(
    'Native analysis callback can cross a real isolate without recorder state',
    () async {
      final spectrum = await compute(analyzePcm, (
        List<double>.filled(2048, 0),
        48000,
      ));
      expect(spectrum.sampleRate, 48000);
      expect(spectrum.amplitudes.length, 1025);
      expect(spectrum.rms, 0);
      expect(spectrum.peaks, isEmpty);
    },
  );
  testWidgets(
    'All twelve labs five sections, lower controls, 160% text and landscape',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final entry in allEntries.where((e) => e.wavesOptics)) {
        router.go('/lab/${entry.id}');
        await tester.pumpAndSettle();
        for (final tab in [
          'Learn',
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
        ]) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
          final scroll = find.byType(Scrollable).first;
          for (int i = 0; i < 50; i++) {
            final p = tester.state<ScrollableState>(scroll).position;
            if (p.pixels >= p.maxScrollExtent) break;
            p.jumpTo((p.pixels + 350).clamp(0, p.maxScrollExtent));
            await tester.pumpAndSettle();
          }
        }
      }
      tester.view.physicalSize = const Size(1280, 720);
      router.go('/lab/s09-e02');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
  testWidgets('Edit step prediction note record and actual restored input', (
    tester,
  ) async {
    final store = await notebook();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notebookProvider.overrideWithValue(store)],
        child: const PhysicsApp(),
      ),
    );
    router.go('/lab/s08-e00');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Experiment').last);
    await tester.pumpAndSettle();
    await show(tester, find.byKey(const Key('edit-frequency')));
    await tester.tap(find.byKey(const Key('edit-frequency')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '3');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    await show(tester, find.byKey(const Key('step-waves')));
    await tester.tap(find.byKey(const Key('step-waves')));
    await tester.pumpAndSettle();
    await show(tester, find.byKey(const Key('record-waves')));
    await tester.enterText(find.byType(TextField).last, 'Wave observation');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('record-waves')));
    await tester.pumpAndSettle();
    expect(store.trials.last.value, closeTo(1.2, 1e-12));
    expect(store.trials.last.configuration['ticks'], 1);
    expect(store.trials.last.note, 'Wave observation');
    await tester.pump(const Duration(seconds: 4));
    await show(tester, find.byKey(const Key('predict-waves')));
    await tester.tap(find.byKey(const Key('predict-waves')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '1.2');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Correct · reference'), findsOneWidget);
    await tester.tap(find.text('Results').last);
    await tester.pumpAndSettle();
    await show(tester, find.text('Reopen configuration'));
    await tester.tap(find.text('Reopen configuration').first);
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsNothing);
    await show(tester, find.byKey(const Key('edit-frequency')));
    expect(find.text('3.00000 Hz ✎'), findsOneWidget);
    router.go('/');
    await tester.pumpAndSettle();
  });
  testWidgets(
    'Denied microphone never fabricates a live trace and generated mode still works',
    (tester) async {
      final store = await notebook(), mic = DeniedMicrophone();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notebookProvider.overrideWithValue(store),
            liveMicrophoneProvider.overrideWithValue(mic),
          ],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s08-e04');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      await show(tester, find.text('Device microphone input'));
      await tester.tap(find.text('Device microphone input'));
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('start-microphone')));
      await tester.tap(find.byKey(const Key('start-microphone')));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Microphone permission denied'),
        findsOneWidget,
      );
      expect(mic.active, isFalse);
      await show(tester, find.byKey(const Key('record-waves')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('record-waves')))
            .onPressed,
        isNull,
      );
      await show(tester, find.text('Device microphone input'));
      await tester.tap(find.text('Device microphone input'));
      await tester.pumpAndSettle();
      await show(tester, find.byKey(const Key('record-waves')));
      await tester.tap(find.byKey(const Key('record-waves')));
      await tester.pumpAndSettle();
      expect(store.trials.last.value, 440);
      expect(store.trials.last.configuration['input'], 'generated/model');
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
}
