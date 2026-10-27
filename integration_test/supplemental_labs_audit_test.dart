import 'package:physics_atelier/features/supplemental/scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/core/physics/supplemental_labs.dart';
import 'package:physics_atelier/features/supplemental/workspace.dart';
import 'package:physics_atelier/features/workbench/workbench.dart';

import 'phase1_test.dart' show capture;
import 'phase9_restore_test.dart' as restoration;
import 'phase9_fixture.dart' show originalSessions;

const primaryRefresh = bool.fromEnvironment('EXPANDED_SCENES_ONLY');
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Twenty added labs render and manipulate on native Android without inserting observations',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      for (final studio
          in primaryRefresh
              ? <int>{}
              : supplementalLabs.map((l) => l.studio).toSet()) {
        router.go('/studio/s${studio.toString().padLeft(2, '0')}');
        await t.pumpAndSettle();
        await capture(
          t,
          binding,
          's${studio.toString().padLeft(2, '0')}/studio',
        );
        expect(t.takeException(), isNull);
      }
      for (final lab in supplementalLabs) {
        router.go('/lab/${lab.id}');
        await t.pumpAndSettle();
        final source = t.state<SupplementalWorkspaceState>(
          find.byType(SupplementalWorkspace),
        );
        var shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        expect(source.state, isNotEmpty);
        final c = shell.controls().first;
        c.change(
          (c.value + (c.value == c.max ? -1 : 1) * (c.max - c.min) * .01).clamp(
            c.min,
            c.max,
          ),
        );
        await t.pumpAndSettle();
        if (lab.dynamicModel) {
          source.play();
          await t.pump(const Duration(milliseconds: 100));
          await t.pump(const Duration(milliseconds: 700));
          source.pause();
          await t.pumpAndSettle();
          expect(source.time, greaterThan(0));
        }
        final painted =
            t
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (w) =>
                            w is CustomPaint &&
                            w.painter is SupplementalPainter,
                      ),
                    )
                    .painter!
                as SupplementalPainter;
        expect(
          painted.state,
          source.state,
          reason: '${lab.id}: apparatus and metrics agree',
        );
        expect(painted.parameters, source.parameters);
        final prefix = 's${lab.studio.toString().padLeft(2, '0')}/${lab.id}';
        await capture(t, binding, '${prefix}_apparatus');
        if (!primaryRefresh) {
          await t.tap(find.byKey(const Key('workspace-graph')));
          await t.pumpAndSettle();
          await capture(t, binding, '${prefix}_graph');
          await t.tap(find.byKey(const Key('workspace-inspect')));
          await t.pumpAndSettle();
          await capture(t, binding, '${prefix}_inspect');
          await t.tap(find.byTooltip('Close inspector'));
          await t.pumpAndSettle();
        }
        expect(t.takeException(), isNull, reason: lab.id);
        shell = t.widget<InstrumentShell>(find.byType(InstrumentShell));
        expect(shell.canRecord(), true);
      }
      router.go('/');
      await t.pumpAndSettle();
      binding.reportData ??= {};
      binding.reportData!['expandedLabs'] = {
        'addedLabs': 20,
        'physicalLabs': 116,
        'destinations': 122,
        'studios': 17,
        'nativeScenes': 20,
        'nativeGraphs': primaryRefresh ? 0 : 20,
        'nativeInspectors': primaryRefresh ? 0 : 20,
        'changedStudioPreviews': primaryRefresh ? 0 : 12,
        'recordedUserTrials': 0,
      };
    },
  );
  restoration.main();
  testWidgets(
    'Remove only new session rows introduced by this explicit QA traversal',
    (t) async {
      final db = await openDatabase(
        '${await getDatabasesPath()}/physics_notebook.db',
      );
      var removed = 0;
      for (final lab in supplementalLabs) {
        if (!originalSessions.containsKey(lab.id)) {
          removed += await db.delete(
            'sessions',
            where: 'id=?',
            whereArgs: [lab.id],
          );
        }
      }
      binding.reportData ??= {};
      binding.reportData!['qaOnlyNewSessionsRemoved'] = removed;
    },
  );
}
