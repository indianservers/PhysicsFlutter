import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';

import '../test/em_app_test.dart' show edit, mode, scene, top;
import 'phase1_test.dart' show show, capture;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Phase 5 native graph builder, RC continuity and magnetic edge cases',
    (t) async {
      await app.main();
      await t.pumpAndSettle();
      Future<void> open(String id) async {
        router.go('/lab/$id');
        await t.pumpAndSettle();
        await chooseSection(t, 'Experiment');
        await t.pumpAndSettle();
        await show(t, find.text('Restore documented defaults'));
        await t.tap(find.text('Restore documented defaults'));
        await t.pumpAndSettle();
        await top(t);
      }

      Future<void> shot(String name) async {
        await top(t);
        await capture(t, binding, 'phase5-mode-$name');
      }

      Future<void> wire(String a, String b) async {
        await show(t, find.text('Connect these terminals'));
        t
            .widgetList<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .firstWhere((w) => w.decoration.labelText == 'Wire from terminal')
            .onChanged!(a);
        await t.pumpAndSettle();
        t
            .widgetList<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .firstWhere((w) => w.decoration.labelText == 'Wire to terminal')
            .onChanged!(b);
        await t.pumpAndSettle();
        await t.tap(find.byKey(const Key('connect-terminals')));
        await t.pumpAndSettle();
        await top(t);
      }

      await open('s10-e04');
      await show(t, find.byKey(const Key('example-2')));
      await t.tap(find.byKey(const Key('example-2')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.state['current'], closeTo(6 / (5 + 20 / 3), 1e-10));
      await shot('mixed-network');
      await show(t, find.byKey(const Key('add-part')));
      await t.tap(find.byKey(const Key('add-part')));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.invalid, contains('Floating'));
      await shot('floating-no-readings');
      await wire('C1:a', 'B1:a');
      await wire('C1:b', 'B1:b');
      expect(scene(t).run.invalid, isEmpty);
      expect(
        scene(t).run.state['current'],
        closeTo(6 / (5 + 20 / 3) + .4, 1e-10),
      );
      await shot('actual-wiring-changed-current');
      await wire('B1:a', 'B1:b');
      expect(scene(t).run.invalid, contains('short'));
      expect(scene(t).run.network!.currents, isEmpty);
      await shot('ideal-source-short');
      await open('s10-e05');
      final initialCharge = scene(t).run.state['charge'];
      await mode(t, 1);
      await edit(t, 'area', '.01');
      expect(scene(t).run.state['charge'], initialCharge);
      expect(scene(t).run.state['voltage'], closeTo(3, 1e-12));
      await shot('isolated-charge-held');
      await mode(t, 2);
      await show(t, find.byKey(const Key('replay-em')));
      await t.tap(find.byKey(const Key('replay-em')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '.75');
      await t.tap(find.text('Apply'));
      FocusManager.instance.primaryFocus?.unfocus();
      await t.pumpAndSettle();
      await top(t);
      final vc = scene(t).run.state['voltage'];
      await shot('rc-charging');
      await mode(t, 3);
      expect(scene(t).run.state['voltage'], vc);
      expect(scene(t).run.state['current']!, lessThan(0));
      await shot('rc-continuous-discharge');
      await open('s10-e01');
      await edit(t, 'probeX', '-.12');
      await edit(t, 'probeY', '0');
      expect(scene(t).run.invalid, isNotEmpty);
      await shot('excluded-source-probe');
      await open('s11-e01');
      final energy = scene(t).run.state['energy'];
      expect(scene(t).run.state['fy']!, lessThan(0));
      await show(t, find.byKey(const Key('replay-em')));
      await t.tap(find.byKey(const Key('replay-em')));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '0.000003');
      await t.tap(find.text('Apply'));
      await t.pumpAndSettle();
      await top(t);
      expect(scene(t).run.state['energy'], closeTo(energy!, energy * 1e-10));
      await shot('boris-helix');
      await edit(t, 'charge', '-1.602176634e-19');
      expect(scene(t).run.state['fy']!, greaterThan(0));
      await shot('negative-charge-force');
      await open('s11-e02');
      await edit(t, 'probeX', '.03');
      await edit(t, 'probeY', '0');
      expect(scene(t).run.state['field'], closeTo(33.33333333e-6, 1e-12));
      await shot('wire-reference');
      await open('s11-e03');
      await edit(t, 'length', '.5');
      await edit(t, 'radius', '.01');
      expect(scene(t).run.state.containsKey('longField'), true);
      await shot('long-solenoid-valid-reference');
      await open('s11-e04');
      await edit(t, 'initialZ', '.04');
      final forward = scene(t).run.state['emf']!;
      await edit(t, 'velocity', '-.12');
      expect(scene(t).run.state['emf'], closeTo(-forward, 1e-12));
      await shot('induction-reversed-motion');
      await edit(t, 'velocity', '0');
      expect(scene(t).run.state['emf'], 0);
      await shot('stationary-zero-emf');
      await open('s11-e05');
      final force = scene(t).run.state['force']!;
      await mode(t, 1);
      expect(scene(t).run.state['force']!, lessThan(force));
      await shot('air-core-comparison');
      await mode(t, 0);
      await edit(t, 'turns', '1000');
      await edit(t, 'current', '2');
      expect(scene(t).run.invalid, contains('0.3'));
      await shot('linear-core-validity');
      expect(t.takeException(), null);
      binding.reportData!['phase5Modes'] = {
        'actualTopologyAddWireShort': true,
        'floatingNoFabricatedMeters': true,
        'isolatedChargeAndRcContinuity': true,
        'sourceExclusion': true,
        'borisEnergyAndChargeDirection': true,
        'wireReference': true,
        'finiteLongSolenoid': true,
        'fluxMotionPolarityAndStationaryEmf': true,
        'airCoreAndLinearValidity': true,
      };
    },
  );
}
