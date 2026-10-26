import '../test/ui_navigation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/electronics_thermal/workspace.dart';

import '../test/et_app_test.dart' show etScene, etMode;
import '../test/em_app_test.dart' show top, edit;
import 'phase1_test.dart' show capture, show;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Phase 6 operating boundaries live traces and process ledger', (
    t,
  ) async {
    await app.main();
    await t.pumpAndSettle();
    dynamic workspace() => t.state(find.byType(ETWorkspace));
    Future<void> open(String id) async {
      router.go('/lab/$id');
      await t.pumpAndSettle();
      await chooseSection(t, 'Experiment');
      await t.pumpAndSettle();
      await show(t, find.text('Restore defaults'));
      await t.tap(find.text('Restore defaults'));
      await t.pumpAndSettle();
      await top(t);
    }

    Future<void> seek(double seconds) async {
      final dynamic w = workspace();
      w.pause();
      w.run.seek(seconds);
      w.tick.value++;
      await t.pumpAndSettle();
      await top(t);
    }

    Future<void> shot(String name) async {
      FocusManager.instance.primaryFocus?.unfocus();
      for (int i = 0; i < 3; i++) {
        await top(t);
        await t.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)),
        );
        await t.pumpAndSettle();
      }
      await capture(t, binding, 'phase6-mode-$name');
    }

    final checks = <String, dynamic>{};
    await open('s12-e00');
    await etMode(t, 1);
    await edit(t, 'doping', '1e20');
    expect(etScene(t).run.state['electrons']!, greaterThan(1e19));
    await shot('doped-neutral-bulk');
    await open('s12-e01');
    await edit(t, 'supply', '0');
    expect(etScene(t).run.state['current'], 0);
    await edit(t, 'supply', '-2');
    expect(etScene(t).run.state['current']!, lessThan(0));
    await shot('reverse-diode');
    await open('s12-e02');
    for (final drive in [.2, .8, 5.0]) {
      await edit(t, 'drive', '$drive');
      checks['npn-$drive'] = Map.of(etScene(t).run.state);
    }
    expect(etScene(t).run.state['region'], 2);
    await shot('npn-saturation');
    await open('s12-e03');
    await etMode(t, 1);
    await edit(t, 'amplitude', '1');
    await seek(.125);
    expect(etScene(t).run.state['outputVoltage'], -4.8);
    await chooseSection(t, 'Visualize');
    await t.pumpAndSettle();
    await shot('inverting-clipped-traces');
    await open('s12-e04');
    workspace().play();
    await t.pump();
    await t.pump(const Duration(milliseconds: 80));
    workspace().pause();
    await t.pumpAndSettle();
    await edit(t, 'inputA', '1');
    expect(etScene(t).run.state['logicOutput'], 1);
    await chooseSection(t, 'Visualize');
    await t.pumpAndSettle();
    await show(t, find.byType(SwitchListTile));
    t.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged!(true);
    await t.pumpAndSettle();
    await shot('live-logic-timing');
    checks['logicEvents'] = List.of(etScene(t).run.events);
    await open('s12-e05');
    await etMode(t, 2);
    await edit(t, 'distance', '4.5');
    expect(etScene(t).run.invalid, contains('echo'));
    await shot('no-echo-explained');
    await edit(t, 'distance', '1');
    await open('s13-e00');
    await etMode(t, 1);
    await seek(etScene(t).run.characteristic);
    expect(
      etScene(t).run.state['sampleTemperature'],
      isNot(etScene(t).run.state['probeTemperature']),
    );
    await shot('cooling-probe-lag');
    await open('s13-e01');
    await etMode(t, 1);
    await edit(t, 'conductivity', '.1');
    expect(etScene(t).run.invalid, contains('Bi'));
    await shot('biot-invalid');
    await edit(t, 'conductivity', '205');
    await etMode(t, 2);
    await seek(etScene(t).run.characteristic);
    expect(etScene(t).run.state['energyResidual']!, closeTo(0, 1e-7));
    checks['radiation'] = Map.of(etScene(t).run.state);
    await shot('radiation-no-glow');
    await open('s13-e02');
    await etMode(t, 2);
    await seek(etScene(t).run.maxTime);
    checks['isobaric'] = Map.of(etScene(t).run.state);
    await shot('gas-derived-state');
    await open('s13-e03');
    await etMode(t, 3);
    await seek(etScene(t).run.maxTime);
    expect(etScene(t).run.state['heat'], 0);
    await show(t, find.text('Append current process state'));
    await t.tap(find.text('Append current process state'));
    await t.pumpAndSettle();
    expect(workspace().processHistory.length, greaterThan(0));
    await t.tap(find.byTooltip('Save session'));
    await t.pumpAndSettle();
    router.go('/');
    await t.pumpAndSettle();
    router.go('/lab/s13-e03');
    await t.pumpAndSettle();
    await chooseSection(t, 'Experiment');
    await t.pumpAndSettle();
    expect(workspace().processHistory.length, greaterThan(0));
    await shot('adiabatic-ledger');
    await open('s13-e04');
    await etMode(t, 1);
    expect(etScene(t).run.state['heat'], 0);
    expect(etScene(t).run.state['entropy']!, greaterThan(0));
    checks['freeExpansion'] = Map.of(etScene(t).run.state);
    await etMode(t, 2);
    await seek(etScene(t).run.maxTime);
    checks['thermalContact'] = Map.of(etScene(t).run.state);
    expect(etScene(t).run.state['energyResidual']!, closeTo(0, 1e-7));
    await shot('finite-body-entropy');
    await open('s13-e05');
    for (final phase in [1.0, 2.0, 3.0, 4.0]) {
      workspace().reset();
      await seek(4 * phase);
      checks['carnot-$phase'] = Map.of(etScene(t).run.state);
      await shot('carnot-stage-${phase.toInt()}');
    }
    expect(etScene(t).run.state['efficiency'], .5);
    await chooseSection(t, 'Visualize');
    await t.pumpAndSettle();
    await shot('carnot-closed-pv');
    binding.reportData ??= {};
    binding.reportData!['phase6Modes'] = checks;
    router.go('/');
    await t.pumpAndSettle();
  });
}
