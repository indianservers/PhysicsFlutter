import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/home/studio_registry.dart';

import 'app_test.dart' show notebook;

Future<void> showHomeItem(WidgetTester t, Finder item) async {
  final scrollable = find
      .descendant(
        of: find.byKey(const PageStorageKey('home-catalogue')),
        matching: find.byType(Scrollable),
      )
      .first;
  await t.scrollUntilVisible(item, 200, scrollable: scrollable);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Phone search results remain visible above the keyboard', (
    t,
  ) async {
    t.view.physicalSize = const Size(720, 1280);
    t.view.devicePixelRatio = 2;
    t.view.viewInsets = const FakeViewPadding(bottom: 520);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    addTearDown(t.view.resetViewInsets);
    final store = await notebook();
    await t.pumpWidget(
      ProviderScope(
        overrides: [notebookProvider.overrideWithValue(store)],
        child: const PhysicsApp(),
      ),
    );
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('search')), 'Vernier');
    await t.pumpAndSettle();
    expect(
      find.byKey(const Key('search-result-s01-e01')).hitTestable(),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('search-result-s01-e01')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('workspace-camera')), findsOneWidget);
    expect(t.takeException(), isNull);
    router.go('/');
    await t.pumpAndSettle();
  });

  test('Home presentation uses all 17 canonical identities exactly once', () {
    expect(homeStudios.length, 17);
    expect(homeStudios.map((s) => s.studio.id).toSet().length, 17);
    expect(homeStudios.map((s) => s.studio), studios);
    for (final s in homeStudios) {
      expect(s.count, s.studio.entries.length);
      expect(s.route, '/studio/${s.studio.id}');
    }
  });
  testWidgets('Every studio opens and back preserves catalogue scroll', (
    t,
  ) async {
    final store = await notebook();
    await t.pumpWidget(
      ProviderScope(
        overrides: [notebookProvider.overrideWithValue(store)],
        child: const PhysicsApp(),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('home-resume')), findsNothing);
    for (final s in homeStudios) {
      final item = find.byKey(Key('home-studio-${s.studio.id}'));
      await showHomeItem(t, item);
      final view = t.widget<CustomScrollView>(
        find.byKey(const PageStorageKey('home-catalogue')),
      );
      final offset = view.controller!.offset;
      await t.tap(item);
      await t.pumpAndSettle();
      expect(find.text(s.studio.title), findsWidgets);
      router.pop();
      await t.pumpAndSettle();
      expect(view.controller!.offset, closeTo(offset, 1));
      expect(t.takeException(), isNull, reason: s.studio.id);
    }
    router.go('/');
    await t.pumpAndSettle();
  });
  testWidgets('Search, empty reset, filters, real resume and saved labs work', (
    t,
  ) async {
    final store = await notebook();
    await store.visit('s01-e01');
    await store.toggleFavorite('s01-e01');
    await t.pumpWidget(
      ProviderScope(
        overrides: [notebookProvider.overrideWithValue(store)],
        child: const PhysicsApp(),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byKey(const Key('home-resume')), findsOneWidget);
    await t.enterText(find.byKey(const Key('search')), 'Vernier');
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('search-result-s01-e01')));
    await t.pumpAndSettle();
    router.pop();
    await t.pumpAndSettle();
    expect(
      t.widget<TextField>(find.byKey(const Key('search'))).controller!.text,
      'Vernier',
    );
    await t.enterText(
      find.byKey(const Key('search')),
      'no such scientific discovery',
    );
    await t.pumpAndSettle();
    expect(find.text('No discoveries found'), findsOneWidget);
    await t.tap(find.byKey(const Key('home-clear-search')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('home-filter-Waves')));
    await t.pumpAndSettle();
    expect(
      find.text(
        '${homeStudios.where((s) => s.categories.contains('Waves')).length} studios',
      ),
      findsOneWidget,
    );
    await t.tap(find.byKey(const Key('home-nav-saved')));
    await t.pumpAndSettle();
    expect(find.text('Vernier Caliper'), findsOneWidget);
    await t.tap(find.byTooltip('Remove Vernier Caliper from saved'));
    await t.pumpAndSettle();
    expect(store.favorites, isEmpty);
    expect(find.text('Your collection starts here'), findsOneWidget);
    await t.tap(find.text('Explore all studios'));
    await t.pumpAndSettle();
    expect(find.text('17 studios'), findsOneWidget);
    expect(t.takeException(), isNull);
    router.go('/');
    await t.pumpAndSettle();
  });
  testWidgets(
    'Small phone, 200% text and tablet have no clipped layout errors',
    (t) async {
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final size in [
        const Size(320, 568),
        const Size(390, 844),
        const Size(1024, 768),
      ]) {
        for (final scale in [1.0, 2.0]) {
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          t.platformDispatcher.textScaleFactorTestValue = scale;
          await t.pumpAndSettle();
          await showHomeItem(t, find.byKey(const Key('home-studio-s16')));
          expect(t.takeException(), isNull, reason: '$size $scale');
          final scroll = t
              .widget<CustomScrollView>(
                find.byKey(const PageStorageKey('home-catalogue')),
              )
              .controller!;
          scroll.jumpTo(0);
          await t.pumpAndSettle();
          expect(t.takeException(), isNull, reason: '$size $scale top');
        }
      }
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
