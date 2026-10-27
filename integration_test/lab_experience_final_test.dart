import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';
import 'package:physics_atelier/features/astronomy/hr_diagram.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Final Android primary layouts, specialist tools and native generated sound',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      var primary = 0;
      for (final studio in studios) {
        final folder =
            '${(studios.indexOf(studio) + 1).toString().padLeft(2, '0')}_${studio.id}';
        for (final entry in studio.entries) {
          router.go('/lab/${entry.id}');
          await t.pumpAndSettle();
          if (entry.interactive) {
            await t.tap(find.byKey(const Key('workspace-scene')));
            await t.pumpAndSettle();
          }
          await capture(
            t,
            binding,
            '$folder/${entry.id}_${entry.interactive ? 'apparatus' : 'tool'}',
          );
          primary++;
          expect(t.takeException(), isNull, reason: entry.id);
        }
      }
      for (final id in ['s08-e00', 's10-e04', 's16-e01']) {
        final studioIndex = int.parse(id.substring(1, 3));
        final folder =
            '${(studioIndex + 1).toString().padLeft(2, '0')}_s${studioIndex.toString().padLeft(2, '0')}';
        router.go('/lab/$id');
        await t.pumpAndSettle();
        final before = t
            .widget<InstrumentShell>(find.byType(InstrumentShell))
            .controls()
            .map((c) => c.value)
            .toList();
        await t.tap(find.byKey(const Key('workspace-inspect')));
        await t.pumpAndSettle();
        await capture(t, binding, '$folder/${id}_inspect');
        if (id == 's08-e00') {
          await t.ensureVisible(find.text('Wavelength ruler'));
          await t.pumpAndSettle();
          await capture(t, binding, '$folder/${id}_ruler');
        } else if (id == 's10-e04') {
          await t.ensureVisible(find.text('Schematic / component readings'));
          await t.pumpAndSettle();
          await t.tap(find.text('Schematic / component readings'));
          await t.pumpAndSettle();
          await t.ensureVisible(find.text('Circuit schematic'));
          await t.pumpAndSettle();
          await capture(t, binding, '$folder/${id}_schematic');
        } else {
          await t.ensureVisible(find.byType(HRDiagram));
          await t.pumpAndSettle();
          await capture(t, binding, '$folder/${id}_hr');
        }
        await t.tap(find.byTooltip('Close inspector'));
        await t.pumpAndSettle();
        expect(
          t
              .widget<InstrumentShell>(find.byType(InstrumentShell))
              .controls()
              .map((c) => c.value)
              .toList(),
          before,
        );
        expect(t.takeException(), isNull, reason: id);
      }
      router.go('/lab/s08-e04');
      await t.pumpAndSettle();
      await t.tap(find.byKey(const Key('workspace-inspect')));
      await t.pumpAndSettle();
      final audio = find.byKey(const Key('generated-audio-play'));
      await t.ensureVisible(audio);
      await t.pumpAndSettle();
      await t.tap(audio);
      await t.pumpAndSettle();
      expect(
        find.textContaining('Playing a 2-second').evaluate().isNotEmpty ||
            find.textContaining('Preview finished.').evaluate().isNotEmpty,
        isTrue,
      );
      await t.tap(find.text('Mute / stop'));
      await t.pumpAndSettle();
      expect(find.text('Preview stopped.'), findsOneWidget);
      await capture(t, binding, '09_s08/s08-e04_audio');
      await t.tap(find.byTooltip('Close inspector'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      expect(primary, 102);
      binding.reportData!['finalExperienceAudit'] = {
        'primaryViews': primary,
        'wavelengthRuler': true,
        'circuitSchematic': true,
        'hrDiagram': true,
        'nativeGeneratedAudioPlayAndStop': true,
      };
    },
  );
  restoration.main();
}
