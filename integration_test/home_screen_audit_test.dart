import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/home/studio_registry.dart';

import '../test/home_screen_test.dart' show showHomeItem;
import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Home artwork, all17 studio links, scroll restoration and search on Android',
    (t) async {
      binding.reportData = {'images': <String, String>{}};
      await app.main();
      await t.pumpAndSettle();
      final store = ProviderScope.containerOf(
        t.element(find.byType(PhysicsApp)),
      ).read(notebookProvider);
      final trialCount = store.trials.length;
      for (final path in [
        'assets/home/hero.webp',
        ...homeStudios.map((s) => s.artwork),
      ]) {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(),
          targetWidth: 512,
        );
        final frame = await codec.getNextFrame();
        expect(frame.image.width, greaterThan(0));
        frame.image.dispose();
        codec.dispose();
      }
      await capture(t, binding, 'home-redesign-top');
      for (final s in homeStudios) {
        final card = find.byKey(Key('home-studio-${s.studio.id}'));
        await showHomeItem(t, card);
        final controller = t
            .widget<CustomScrollView>(
              find.byKey(const PageStorageKey('home-catalogue')),
            )
            .controller!;
        final offset = controller.offset;
        await t.tap(card);
        await t.pumpAndSettle();
        expect(find.text(s.studio.title), findsWidgets);
        router.pop();
        await t.pumpAndSettle();
        expect(controller.offset, closeTo(offset, 1));
        expect(t.takeException(), isNull, reason: s.studio.id);
      }
      final controller = t
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('home-catalogue')),
          )
          .controller!;
      controller.jumpTo(controller.position.maxScrollExtent / 2);
      await capture(t, binding, 'home-redesign-middle');
      controller.jumpTo(controller.position.maxScrollExtent);
      await capture(t, binding, 'home-redesign-bottom');
      controller.jumpTo(0);
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const Key('search')), 'Vernier');
      await t.pumpAndSettle();
      await capture(t, binding, 'home-redesign-search');
      await t.ensureVisible(find.byKey(const Key('search-result-s01-e01')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const Key('search-result-s01-e01')).hitTestable(),
        findsOneWidget,
      );
      await t.tap(find.byKey(const Key('search-result-s01-e01')));
      await t.pumpAndSettle();
      router.pop();
      await t.pumpAndSettle();
      expect(
        t.widget<TextField>(find.byKey(const Key('search'))).controller!.text,
        'Vernier',
      );
      await t.tap(find.byKey(const Key('home-clear-search')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('home-nav-saved')));
      await t.pumpAndSettle();
      await capture(t, binding, 'home-redesign-saved');
      await t.tap(find.byKey(const Key('home-nav-settings')));
      await t.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      router.go('/');
      await t.pumpAndSettle();
      expect(store.trials.length, trialCount);
      binding.reportData!['homeAudit'] = {
        'studiosOpened': 17,
        'scrollRestorations': 17,
        'artworkDecoded': 18,
        'searchAndSavedNavigation': true,
        'trialCountUnchanged': true,
      };
    },
  );
  restoration.main();
}
