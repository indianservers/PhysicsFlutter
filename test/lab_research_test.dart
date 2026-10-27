import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/content/lab_research_profiles.dart';
import 'package:physics_atelier/features/workbench/lab_research.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'app_test.dart' show notebook;

Future<void> openResearch(WidgetTester t) async {
  await t.tap(find.byTooltip('Lab options').last);
  await t.pumpAndSettle();
  await t.ensureVisible(find.text('Lab-specific tools'));
  await t.pumpAndSettle();
  await t.tap(find.text('Lab-specific tools'));
  await t.pumpAndSettle();
}

void main() {
  test(
    'Every physical lab has five distinct, tailored reviewed suggestions',
    () {
      final ids = allEntries
          .where((e) => e.interactive)
          .map((e) => e.id)
          .toSet();
      expect(labResearchProfiles.keys.toSet(), ids);
      expect(ids.length, 116);
      expect(
        labResearchProfiles.values.expand((p) => p.suggestions).length,
        580,
      );
      for (final p in labResearchProfiles.values) {
        expect(p.suggestions.toSet().length, 5, reason: p.id);
        expect(p.watchKeys, isNotEmpty);
        expect(p.focusValue.isFinite, true);
        expect(p.prompt, startsWith('Explain'));
      }
    },
  );
  testWidgets(
    'All 116 sources support their five targeted tools without creating trials or mastery',
    (t) async {
      t.view.physicalSize = const Size(720, 1280);
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final store = await notebook();
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      for (final e in allEntries.where((e) => e.interactive)) {
        router.go('/lab/${e.id}');
        await t.pumpAndSettle();
        final source = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        final before = jsonDecode(
          jsonEncode(source.captureConfiguration!()),
        ) as Map<String, dynamic>;
        debugPrint('RESEARCH_TEST ${e.id}');
        await openResearch(t);
        final sheet = t.widget<LabResearchSheet>(find.byType(LabResearchSheet));
        final session = sheet.session, p = session.profile;
        expect(session.control(p.focusKey), isNotNull, reason: e.id);
        expect(session.control(p.plotKey), isNotNull, reason: e.id);
        await t.scrollUntilVisible(
          find.byKey(const Key('research-apply-focus')).hitTestable(),
          120,
          scrollable: find
              .descendant(
                of: find.byKey(const Key('research-setup-scroll')),
                matching: find.byWidgetPredicate(
                  (w) =>
                      w is Scrollable && w.axisDirection == AxisDirection.down,
                ),
              )
              .first,
        );
        await t.pumpAndSettle();
        await t.ensureVisible(find.byKey(const Key('research-apply-focus')));
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('research-apply-focus')));
        await t.pumpAndSettle();
        expect(session.undo, isNotNull, reason: '${e.id} focus setup');
        expect(
          session.control(p.focusKey)!.value,
          closeTo(p.focusValue, 1e-9),
          reason: e.id,
        );
        expect(
          session.undoSetup(),
          true,
          reason: '${e.id} restores actual source',
        );
        await t.pumpAndSettle();
        expect(
          source.captureConfiguration!()['parameters'] ??
              source.captureConfiguration!()['a'],
          before['parameters'] ?? before['a'],
          reason: e.id,
        );
        await t.ensureVisible(find.text('Compare').last);
        await t.tap(find.text('Compare').last);
        await t.pumpAndSettle();
        if (p.compareKey != null) {
          expect(
            session.apply(p.compareKey!, p.compareA!),
            true,
            reason: '${e.id} A',
          );
          await t.pumpAndSettle();
        }
        final readyA = source.canRecord();
        expect(session.captureComparison(false), readyA, reason: e.id);
        if (p.compareKey != null) {
          expect(
            session.apply(p.compareKey!, p.compareB!),
            true,
            reason: '${e.id} B',
          );
          await t.pumpAndSettle();
        }
        final readyB = source.canRecord();
        expect(session.captureComparison(true), readyB, reason: e.id);
        await t.pumpAndSettle();
        await t.ensureVisible(find.text('Watch').last);
        await t.tap(find.text('Watch').last);
        await t.pumpAndSettle();
        expect(find.text(p.watchTitle), findsOneWidget, reason: e.id);
        expect(
          session.readings().where((r) => p.watchKeys.contains(r.label)),
          isNotEmpty,
          reason: e.id,
        );
        await t.ensureVisible(find.text('Plot').last);
        await t.tap(find.text('Plot').last);
        await t.pumpAndSettle();
        if (!['s01-e03', 's01-e04', 's01-e05'].contains(e.id)) {
          expect(
            session.capturePoint(p.plotKey, p.plotReading),
            true,
            reason: '${e.id} explicit model point',
          );
          await t.pumpAndSettle();
          final point = session.points.single;
          expect(point.x, session.control(p.plotKey)!.value);
          expect(
            point.y,
            double.parse(
              session
                  .readings()
                  .firstWhere((r) => r.label == p.plotReading)
                  .value,
            ),
          );
          expect(
            ResearchPoint.fromJson(point.toJson()).toJson(),
            point.toJson(),
          );
        }
        await t.ensureVisible(find.text('Explain').last);
        await t.tap(find.text('Explain').last);
        await t.pumpAndSettle();
        session.claim = 'Source-specific observation for ${e.title}';
        session.reasoning = p.prompt;
        session.question = 'Which assumption limits this model?';
        expect(await session.save(), true, reason: e.id);
        expect(
          jsonDecode(
            store.preferences.getString(session.preferenceKey)!,
          )['labId'],
          e.id,
        );
        await t.tap(find.byTooltip('Close lab-specific tools'));
        await t.pumpAndSettle();
        expect(source.restoreConfiguration!(before), true, reason: e.id);
        await t.pumpAndSettle();
        expect(t.takeException(), isNull, reason: e.id);
      }
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      router.go('/');
      await t.pumpAndSettle();
    },
  );
  testWidgets(
    'Research captures protect data, reject invalid states and preserve corrupt originals',
    (t) async {
      final store = await notebook();
      await store.preferences.setString(
        'lab-research:s02-e08',
        'old incompatible worksheet',
      );
      await t.pumpWidget(
        ProviderScope(
          overrides: [notebookProvider.overrideWithValue(store)],
          child: const PhysicsApp(),
        ),
      );
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      await openResearch(t);
      final s = t
          .widget<LabResearchSheet>(find.byType(LabResearchSheet))
          .session;
      expect(s.retainedWorksheet, 'old incompatible worksheet');
      expect(s.captureComparison(false), true);
      expect(s.apply('extension', .12), true);
      expect(s.captureComparison(true), true);
      expect(double.parse(s.a!.reading('force')!.value), 4);
      expect(double.parse(s.b!.reading('force')!.value), 6);
      expect(s.capturePoint('extension', 'force'), true);
      expect(
        s.capturePoint('stiffness', 'force'),
        false,
        reason: 'mixed axes rejected',
      );
      expect(s.apply('extension', 100), false, reason: 'bounds respected');
      var mode = 'first';
      final guarded = LabResearchSession(
        profile: s.profile,
        store: store,
        controls: s.controls,
        readings: s.readings,
        configuration: () => {...s.configuration(), 'mode': mode},
        restore: s.restore,
        valid: s.valid,
        pause: s.pause,
      );
      expect(guarded.capturePoint('extension', 'force'), true);
      mode = 'second';
      expect(
        guarded.capturePoint('extension', 'force'),
        false,
        reason: 'different experiment modes require separate plot series',
      );
      final mixed = guarded.document();
      final next = Map<String, dynamic>.from(guarded.points.first.toJson());
      next['snapshot'] = {
        ...Map<String, dynamic>.from(next['snapshot']),
        'mode': 'different mode',
      };
      mixed['points'] = [guarded.points.first.toJson(), next];
      expect(
        guarded.load(jsonEncode(mixed)),
        false,
        reason: 'stored mixed-mode series is rejected atomically',
      );
      expect(guarded.points.length, 1);
      guarded.dispose();
      final old = jsonEncode(s.document());
      expect(s.load(jsonEncode({...s.document(), 'claim': 42})), false);
      expect(jsonEncode(s.document()), old, reason: 'restore is atomic');
      s.claim = 'Force follows extension';
      s.reasoning =
          'A 50 N/m spring at 0.12 m has 6 N restoring-force magnitude.';
      expect(await s.save(), true);
      expect(
        store.preferences
            .getKeys()
            .where((k) => k.startsWith('lab-research-backup:s02-e08:'))
            .length,
        1,
      );
      expect(store.trials, isEmpty);
      expect(store.completed, isEmpty);
      final saved = store.preferences.getString(s.preferenceKey)!;
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
      router.go('/lab/s02-e08');
      await t.pumpAndSettle();
      await openResearch(t);
      final reopened = t
          .widget<LabResearchSheet>(find.byType(LabResearchSheet))
          .session;
      expect(jsonEncode(reopened.document()), saved);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/lab/s02-e07');
      await t.pumpAndSettle();
      await openResearch(t);
      final rolling = t
          .widget<LabResearchSheet>(find.byType(LabResearchSheet))
          .session;
      rolling.apply('friction', 0);
      await t.pumpAndSettle();
      expect(rolling.captureComparison(false), false);
      expect(rolling.a, isNull);
      expect(rolling.capturePoint('incline', 'speed'), false);
      expect(rolling.points, isEmpty);
      await t.tap(find.byTooltip('Close lab-specific tools'));
      await t.pumpAndSettle();
      router.go('/');
      await t.pumpAndSettle();
    },
  );
}
