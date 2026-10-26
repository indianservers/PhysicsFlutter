import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/core/physics/thermal_library.dart';
import 'package:physics_atelier/core/physics/optical_library.dart';

void main() {
  const encoder = JsonEncoder.withIndent('  ');
  final native = File('screenshots/librariesAudit.json');
  final evidence = native.existsSync()
      ? jsonDecode(native.readAsStringSync()) as Map<String, dynamic>
      : <String, dynamic>{};
  File('docs/THERMAL_MATERIALS.json').writeAsStringSync(
    encoder.convert([
      for (final m in thermalMaterials)
        {
          ...m.toJson(),
          'solidConductionEnabled': m.conducts,
          'heatingEnabled': m.heats,
          'missingProperties': [
            if (m.k == null) 'scalar conductivity',
            if (m.density == null) 'density',
            if (m.cp == null) 'specific heat',
          ],
        },
    ]),
  );
  File('docs/OPTICAL_MATERIALS.json').writeAsStringSync(
    encoder.convert(opticalMaterials.map((m) => m.toJson()).toList()),
  );
  File('docs/OPTICAL_COMPONENTS.json').writeAsStringSync(
    encoder.convert([
      for (final c in opticalComponents)
        {
          ...c.toJson(),
          'nativeEvidence':
              (evidence['opticalComponents'] as Map<String, dynamic>?)?[c.id],
          'scientificTests': 'test/material_libraries_science_test.dart',
          'screenshot': 'screenshots/libraries-optic-${c.id}.png',
        },
    ]),
  );
  final report = {
    'thermalRecords': thermalMaterials.length,
    'solidConductionPresets': thermalMaterials.where((m) => m.conducts).length,
    'heatingPresets': thermalMaterials.where((m) => m.heats).length,
    'opticalMaterials': opticalMaterials.length,
    'opticalComponents': opticalComponents.length,
    'componentsWithNativeEvidence':
        (evidence['opticalComponents'] as Map?)?.length ?? 0,
    'guidedOpticalPresets': (evidence['guidedPresets'] as Map?)?.length ?? 0,
    'measurementLabs': (evidence['measurementLabs'] as Map?)?.length ?? 0,
  };
  File('docs/MATERIAL_LIBRARY_INVENTORY.json')
      .writeAsStringSync(encoder.convert(report));
  stdout.writeln(encoder.convert(report));
}
