import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';

import 'phase1_test.dart' show capture, show, top;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 3 limiting modes, articulated scenes and lifecycle', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    Future<void> open(String id) async {
      router.go('/lab/$id');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
    }

    Future<void> number(String key, String value) async {
      await show(tester, find.byKey(Key('edit-$key')));
      await tester.tap(find.byKey(Key('edit-$key')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, value);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    Future<void> replay(String t) async {
      await show(tester, find.byKey(const Key('replay-advanced')));
      await tester.tap(find.byKey(const Key('replay-advanced')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, t);
      await tester.tap(find.text('Apply'));
      await tester.pumpAndSettle();
    }

    Future<void> snap(String name) async {
      await top(tester);
      await capture(tester, binding, 'phase3-mode-$name');
    }

    await open('s05-e05');
    await number('input', '0');
    await show(tester, find.textContaining('Output/input ratio undefined'));
    expect(find.textContaining('Output/input ratio undefined'), findsOneWidget);
    await snap('zero-input');
    await open('s06-e03');
    await show(tester, find.text('Circular reference'));
    await tester.tap(find.text('Circular reference'));
    await tester.pumpAndSettle();
    await replay('2400');
    await snap('circular-orbit');
    await number('vt', '0');
    await number('vr', '-4');
    await replay('4000');
    await show(tester, find.textContaining('Surface collision'));
    expect(find.textContaining('Surface collision'), findsOneWidget);
    await snap('surface-impact');
    await open('s07-e01');
    await number('angle', '70');
    await number('v0', '2');
    await number('g', '1');
    await show(tester, find.textContaining('Angular velocity limited'));
    expect(find.textContaining('Angular velocity limited'), findsOneWidget);
    await replay('8');
    await snap('large-angle-taut');
    await open('s07-e03');
    for (final mode in ['Critical', 'Overdamped']) {
      await show(tester, find.text(mode));
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      await replay('1');
      await snap(mode.toLowerCase());
    }
    await open('s07-e04');
    await number('b', '0');
    await show(tester, find.text('Drive at natural frequency'));
    await tester.tap(find.text('Drive at natural frequency'));
    await tester.pumpAndSettle();
    await replay('20');
    await show(tester, find.textContaining('No finite steady amplitude'));
    expect(find.textContaining('No finite steady amplitude'), findsOneWidget);
    await snap('undamped-resonance');
    await open('s07-e05');
    for (final mode in ['In phase', 'Out of phase', 'One-mass release']) {
      await show(tester, find.text(mode));
      await tester.tap(find.text(mode));
      await tester.pumpAndSettle();
      await replay('1');
      await snap(mode.replaceAll(' ', '-').toLowerCase());
    }
    await show(tester, find.byKey(const Key('play-advanced')));
    await tester.tap(find.byKey(const Key('play-advanced')));
    await tester.pump(const Duration(milliseconds: 100));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.text('Pause'), findsNothing);
    // Build the same stack as a user's home-to-lab navigation, then issue Back.
    router.go('/');
    await tester.pumpAndSettle();
    router.push('/lab/s07-e05');
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('search')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
