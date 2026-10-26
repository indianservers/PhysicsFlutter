import 'dart:io';

import 'package:physics_atelier/content/learning.dart';
import 'package:physics_atelier/content/catalog.dart';
import 'package:physics_atelier/core/physics/comparisons.dart';

void main() {
  final out = StringBuffer(
    '# Phase 8 learning-tool specifications\n\nModel learning-tools-8.0; comparisons-8.0. Generated from the same curated runtime content. Catalog is the identity/availability source. Exactly96 physical labs and six tools; tools are not extra physical labs.\n\n',
  );
  out.writeln(
    '## Physics Atlas\n\nAll16 lab studios and96 labs; semantic group map, pinch/pan/reset, searchable summaries, studio filter, actual source progress and an accessible list. Completion requires a used filter plus three distinct actual lab launches. No visit alone completes a physical lab.\n\n## Relationship Map\n\nCurated directed graph, node focus, query filter, and full text/list alternative. Every edge is listed below. Tool activity completion requires inspecting three explanations, opening a linked source and explanatory notes.\n',
  );
  for (final e in conceptEdges) {
    out.writeln(
      '### ${e.id}: ${e.from} → ${e.to}\n\n${e.explanation}\n\nEquation: ${e.equation}\n\nAssumptions: ${e.assumptions}\n\nInvestigation: ${e.investigation}\n\nSource labs: ${e.labs.join(', ')}.\n',
    );
  }
  out.writeln(
    '## Guided Path\n\nEight paths cover all96 lab IDs exactly once. Suggested prerequisite graph is acyclic, advisory and never locks exploration. Steps0…4 in each studio are required, step5 optional extension. Estimates10…20min per activity are planning estimates. Progress is derived from the existing completed-ID set; visits/recent/favorites do not count. Existing labs retain their own documented activity criteria, including inherited manual learning marks in Measurement. A path/tool completion requires every required source activity.\n',
  );
  for (final p in learningPaths) {
    out.writeln(
      '### ${p.id}: ${p.title}\n\n${p.objective}\n\nPrerequisites: ${p.prerequisites.join(', ')}.\n\nOrdered activities:',
    );
    for (final e in p.activities) {
      out.writeln(
        '- ${e.id} ${e.title} — ${p.required(e) ? 'required' : 'optional'}.',
      );
    }
    out.writeln('');
  }
  out.writeln(
    '## Experiment Launcher\n\nThe shared96-lab inventory supports text/topic-tag search, studio, apparatus and teaching-stage filters, recent32 destinations, favorites and actual saved sessions. Stage labels Foundation/Intermediate/Advanced are curated curricular estimates (entry pairs0/1,2/3,4/5), not measured ability or prerequisites. Presets open the source workspace’s documented defaults; a prior saved session is backed up under a separate visible backup key before a one-use default launch. Presets never insert trials or completion. Saved original models/datasets are not converted by a preset. Tool activity completion requires a favorite, actual lab launch and real saved lab configuration.\n\n## Compare Phenomena\n\nFive curated pairs only. Stacked on phones, side-by-side from760 logical pixels. Separate graphs and explicit units; numeric alternatives, actual values, probe coordinate, play/pause, save/reopen notes and source-model versions. Input edits rebuild only the chosen model; hidden/background tickers stop. Completion requires exploring every pair beyond coordinate0, a scientific edit and saved explanatory notes.\n',
  );
  for (int i = 0; i < 5; i++) {
    out.writeln(
      '### ${comparisonNames[i]}\n\nSources: ${comparisonLabs[i].join(', ')}.\n\nComparable / synchronization: ${comparisonConventions[i]}\n\nAnalogy limits: ${comparisonLimits[i]}\n',
    );
  }
  out.writeln(
    '## Mastery Challenge\n\nSix types,16 curated reference tasks (one per physical studio). Practice uses ordered questions, Topic focused filters the studio, Mixed review advances by coprime step7 through the16-question bank. Retry keeps the same validated question. No unchecked/random question generator, inferred attempts, scientific ability score or fake history. Every attempt stores stable question ID, source model/configuration, finite answer, target, units, tolerance, explanation rule version, correct flag and UTC time. Parameter-adjustment resistance must be250…10000Ω; unsupported input assigns no current. Progress summarizes actual saved attempts; completion requires a correct attempt in all six types. History is retained; the interface shows the most recent50.\n',
  );
  for (final q in masteryQuestions) {
    out.writeln(
      '### ${q.id} — ${q.type}\n\n${q.prompt}\n\nTopic: ${studios[q.studio].title}; prerequisites/review tags: ${q.prerequisites.join(', ')}.\n\nSource ${q.sourceModel} / ${q.lab}. Configuration: ${q.configuration}.\n\nReference answer ${q.answer()} ${q.unit}; absolute tolerance±${q.tolerance}. Rule: finite numeric input within this tolerance; categorical answers are exact option indices.\n\n${q.explanation}\n',
    );
  }
  File('docs/PHASE8_TOOLS.md')
      .writeAsStringSync('${out.toString().trimRight()}\n');
}
