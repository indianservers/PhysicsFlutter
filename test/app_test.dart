import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';
import 'package:physics_atelier/features/lab_workspace/workspace.dart';
import 'package:physics_atelier/core/rendering/apparatus.dart';

Future<LocalNotebook> notebook() async {
  SharedPreferences.setMockInitialValues({});
  // Web/desktop preference adapter permits a real repository test without a native DB host.
  final old = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = TargetPlatform.windows;
  final store = LocalNotebook();
  await store.initialize();
  debugDefaultTargetPlatformOverride = old;
  return store;
}

void main() {
  testWidgets(
    'Numeric entry validates input and owns its controller through dismissal',
    (tester) async {
      double? value;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => NumericInputDialog(
                    label: 'Reading',
                    initial: 0,
                    min: -1,
                    max: 1,
                    onApply: (v) => value = v,
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      for (int i = 0; i < 2; i++) {
        await tester.tap(find.text('Open'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'NaN');
        await tester.tap(find.text('Apply'));
        await tester.pumpAndSettle();
        expect(
          find.text('Enter a finite number in the stated range.'),
          findsOneWidget,
        );
        await tester.enterText(find.byType(TextField), '0.053');
        await tester.tap(find.text('Apply'));
        await tester.pump(const Duration(milliseconds: 30));
        await tester.pumpAndSettle();
        expect(value, .053);
      }
    },
  );
  testWidgets('Single zero reading with unknown resolution renders safely', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 240,
            child: CustomPaint(
              painter: ApparatusPainter(5, a: 0, samples: [0]),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  });
  testWidgets('First-use home, search, studio and every unique destination', (
    tester,
  ) async {
    final store = await notebook();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [notebookProvider.overrideWithValue(store)],
        child: const PhysicsApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your first discovery starts here'), findsOneWidget);
    expect(store.completed, isEmpty);
    await tester.enterText(find.byKey(const Key('search')), 'Vernier');
    await tester.pumpAndSettle();
    expect(find.text('Vernier Caliper'), findsOneWidget);
    await tester.tap(find.text('Vernier Caliper'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Learn').last);
    await tester.pumpAndSettle();
    expect(find.text('Learning objectives'), findsOneWidget);
    await tester.tap(find.text('Experiment').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('workspace-camera')), findsOneWidget);
    final List<String> paths = [];
    for (final s in studios) {
      router.go('/studio/${s.id}');
      await tester.pumpAndSettle();
      expect(find.text(s.title), findsWidgets);
    }
    for (final e in allEntries) {
      router.go('/lab/${e.id}');
      await tester.pumpAndSettle();
      expect(find.text(e.title), findsWidgets);
      if (!e.tool) {
        await tester.tap(find.text('Formulas').last);
        await tester.pumpAndSettle();
      }
      paths.add(router.routeInformationProvider.value.uri.path);
    }
    expect(paths.toSet().length, 102);
    router.go('/');
    await tester.pumpAndSettle();
  });
  testWidgets(
    'Small viewport and large text do not overflow across lab sections',
    (tester) async {
      tester.view.physicalSize = const Size(640, 1136);
      tester.view.devicePixelRatio = 2;
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = await notebook();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: const PhysicsApp(),
          ),
        ),
      );
      for (final e in studios[1].entries) {
        router.go('/lab/${e.id}');
        await tester.pumpAndSettle();
        for (final section in [
          'Experiment',
          'Visualize',
          'Formulas',
          'Results',
          'Learn',
        ]) {
          await tester.tap(find.text(section).last);
          await tester.pumpAndSettle();
        }
      }
      router.go('/');
      await tester.pumpAndSettle();
    },
  );
}
