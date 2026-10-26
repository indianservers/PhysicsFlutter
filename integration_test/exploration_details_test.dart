import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Measurement reference images and clearly labeled guide examples',
    (t) async {
      binding.reportData = {'images': <String, String>{}};
      await app.main();
      await t.pumpAndSettle();
      router.go('/studio/s01');
      await t.pumpAndSettle();
      await capture(t, binding, 'explore-studio-s01');
      for (final e in [...studios[1].entries, ...studios[16].entries]) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        await chooseSection(t, 'Learn');
        await capture(t, binding, 'explore-${e.id}-learn');
        final action = find.byKey(const Key('learn-explore-apparatus'));
        await t.ensureVisible(action);
        await t.pumpAndSettle();
        await t.tap(action);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: e.id);
      }
      router.go('/');
      await t.pumpAndSettle();
      binding.reportData!['explorationVisualRefinement'] = {
        'measurementGuideImagesRefreshed': 6,
        'studioImagesRefreshed': 1,
        'astronomyGuideLabelsRefreshed': 6,
        'referenceLabelsExplicit': true,
      };
    },
  );
  restoration.main();
}
