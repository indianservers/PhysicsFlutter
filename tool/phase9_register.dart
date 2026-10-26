import 'dart:convert';
import 'dart:io';

import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/features/dynamics/curriculum.dart' as d;
import 'package:physics_atelier/features/advanced/curriculum.dart' as a;
import 'package:physics_atelier/features/waves/curriculum.dart' as w;
import 'package:physics_atelier/features/electromagnetism/curriculum.dart' as e;
import 'package:physics_atelier/features/electronics_thermal/curriculum.dart'
    as t;
import 'package:physics_atelier/features/fluid_modern/curriculum.dart' as f;
import 'package:physics_atelier/features/astronomy/curriculum.dart' as s;
import 'package:physics_atelier/features/measurement/lessons.dart' as m;

void main() {
  final rows = <Map<String, dynamic>>[];
  for (final entry in allEntries) {
    final k = entry.index, studio = entry.studioIndex;
    final family = entry.tool
        ? 'overview'
        : entry.astronomy
        ? 'astronomy'
        : entry.fluidModern
        ? 'fluid_modern'
        : entry.electronicsThermal
        ? 'electronics_thermal'
        : entry.electromagnetism
        ? 'electromagnetism'
        : entry.wavesOptics
        ? 'waves'
        : entry.advanced
        ? 'advanced'
        : entry.dynamics
        ? 'dynamics'
        : 'measurement';
    d.DynamicsLesson? lesson;
    if (entry.astronomy) {
      lesson = s.astroLessons[k];
    } else if (entry.fluidModern) {
      lesson = f.fmLessons[(studio - 14) * 6 + k];
    } else if (entry.electronicsThermal) {
      lesson = t.etLessons[(studio - 12) * 6 + k];
    } else if (entry.electromagnetism) {
      lesson = e.emLessons[(studio - 10) * 6 + k];
    } else if (entry.wavesOptics) {
      lesson = w.waveLessons[(studio - 8) * 6 + k];
    } else if (entry.advanced) {
      lesson = a.advancedLessons[(studio - 5) * 6 + k];
    } else if (entry.dynamics) {
      lesson = d.lessons[(studio - 2) * 6 + k];
    }
    final phase = entry.tool || entry.astronomy
        ? 8
        : entry.fluidModern
        ? 7
        : entry.electronicsThermal
        ? 6
        : entry.electromagnetism
        ? 5
        : entry.wavesOptics
        ? 4
        : entry.advanced
        ? 3
        : entry.dynamics
        ? 2
        : 1;
    final models = [
      '',
      'measurement-1.0',
      'dynamics-2.0',
      'energy-gravity-oscillation-3.0',
      'waves-optics-4.0',
      'electromagnetism-5.0',
      'electronics-thermal-6.0',
      'fluid-modern-7.0',
      'astronomy-8.0',
    ];
    rows.add({
      'studio': studios[studio].title,
      'studioId': studios[studio].id,
      'id': entry.id,
      'name': entry.title,
      'route': '/lab/${entry.id}',
      'family': family,
      'model': entry.tool
          ? (k == 4 ? 'comparisons-8.0' : 'learning-tools-8.0')
          : models[phase],
      'equations': lesson?.formula ?? entry.formula,
      'symbolsAndUnits':
          lesson?.symbols ??
          (entry.tool ? 'Tool criteria: docs/PHASE8_TOOLS.md' : m.symbols[k]),
      'assumptionsAndLimits':
          lesson?.limits ??
          (entry.tool
              ? 'Curated guidance and bounded analogies; no validated ability score.'
              : m.errors[k]),
      'apparatus':
          lesson?.apparatus ??
          (entry.tool
              ? 'Catalog-derived navigation / assessment widgets'
              : m.apparatusNames[k]),
      'procedure':
          lesson?.procedure ??
          (entry.tool ? 'docs/PHASE8_TOOLS.md' : m.procedures[k]),
      'referenceExample':
          lesson?.example ??
          (entry.tool
              ? 'Source question configurations in PHASE8_TOOLS.md'
              : m.substitutions[k]),
      'controls': lesson == null
          ? []
          : [
              for (final p in lesson.controls)
                {
                  'key': p.key,
                  'label': p.label,
                  'unit': p.unit,
                  'min': p.min,
                  'max': p.max,
                  'default': p.initial,
                },
            ],
      'dataset': entry.astronomy
          ? 'jpl-j2000-frozen-mist1.2-sparc2016-2026-10'
          : entry.fluidModern && studio == 15
          ? 'Documented nuclear/isotope constants where applicable; seeded synthetic sampling'
          : 'Analytic or bounded numerical model; no observational dataset implied',
      'scienceDocumentation': phase == 1
          ? 'docs/SCIENTIFIC_MODELS.md'
          : 'docs/PHASE${phase}_SCIENCE.md',
      'testMapping': entry.tool || entry.astronomy
          ? [
              'test/astronomy_learning_test.dart',
              'test/astronomy_overview_app_test.dart',
            ]
          : phase == 1
          ? ['test/science_test.dart', 'test/app_test.dart']
          : phase == 2
          ? ['test/dynamics_test.dart', 'test/dynamics_app_test.dart']
          : phase == 3
          ? ['test/advanced_science_test.dart', 'test/advanced_app_test.dart']
          : phase == 4
          ? ['test/waves_science_test.dart', 'test/waves_app_test.dart']
          : phase == 5
          ? ['test/em_science_test.dart', 'test/em_app_test.dart']
          : phase == 6
          ? ['test/electronics_thermal_test.dart', 'test/et_app_test.dart']
          : ['test/fluid_modern_test.dart', 'test/fm_app_test.dart'],
      'visualAssets': entry.astronomy
          ? 'AstronomyPainter; eight credited processed/artist planet maps for orbit mode; original schematic other scenes'
          : entry.tool
          ? 'Original catalog icons and source-model comparison apparatus'
          : entry.advanced && studio == 6
          ? 'AdvancedPainter; generated illustrative Earth texture'
          : 'Original shaded procedural apparatus and studio vignette',
      'validationQualification': 'Reference, conservation, boundary and consistency checks of a bounded educational model; not independent experimental validation',
    });
  }
  File('docs/PHASE9_MODEL_REGISTER.json')
      .writeAsStringSync(const JsonEncoder.withIndent('  ').convert(rows));
  stdout.writeln(
    '${rows.length} entries, ${rows.where((r) => r['studioId'] != 's00').length} models/labs',
  );
}
