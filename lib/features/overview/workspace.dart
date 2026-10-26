import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../content/catalog.dart';
import '../../content/learning.dart';
import '../../core/design_system/theme.dart';
import '../../core/persistence/notebook.dart';
import '../../core/rendering/apparatus.dart';
import '../../core/physics/advanced.dart' show freeOscillator;
import '../../core/physics/electromagnetism.dart';
import '../advanced/scene.dart' show LabPlot;
import '../fluid_modern/workspace.dart' show fmNumber;

class OverviewWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const OverviewWorkspace({super.key, required this.entry});
  @override
  ConsumerState<OverviewWorkspace> createState() => OverviewWorkspaceState();
}

class OverviewWorkspaceState extends ConsumerState<OverviewWorkspace>
    with WidgetsBindingObserver {
  late LocalNotebook store;
  bool ready = false,
      listView = false,
      onlyFavorites = false,
      filterUsed = false;
  String query = '',
      apparatus = '',
      stage = '',
      focus = '',
      pathId = 'measurement',
      questionId = masteryQuestions.first.id,
      challengeMode = 'Practice',
      feedback = '',
      notice = '';
  int studio = -1, topic = -1;
  final notes = TextEditingController(),
      answer = TextEditingController(),
      queryInput = TextEditingController(),
      mapView = TransformationController(),
      opened = <String>{},
      inspected = <String>{};
  List<String> savedIds = [];
  List<Map<String, dynamic>> attempts = [];
  Entry get entry => widget.entry;
  MasteryQuestion get question =>
      masteryQuestions.firstWhere((q) => q.id == questionId);
  @override
  void initState() {
    super.initState();
    store = ref.read(notebookProvider);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  Future<void> load() async {
    final data = await store.readSession(entry.id);
    if (data != null) {
      if (data['model'] == learningVersion) {
        query = data['query'] as String? ?? '';
        studio = (data['studio'] as num?)?.toInt() ?? -1;
        apparatus = data['apparatus'] as String? ?? '';
        stage = data['stage'] as String? ?? '';
        focus = data['focus'] as String? ?? '';
        pathId = learningPaths.any((p) => p.id == data['path'])
            ? data['path']
            : 'measurement';
        questionId = masteryQuestions.any((q) => q.id == data['question'])
            ? data['question']
            : masteryQuestions.first.id;
        notes.text = data['notes'] as String? ?? '';
        opened.addAll((data['opened'] as List? ?? []).cast<String>());
        inspected.addAll((data['inspected'] as List? ?? []).cast<String>());
        filterUsed = data['filterUsed'] == true;
        listView = data['listView'] == true;
        onlyFavorites = data['onlyFavorites'] == true;
        topic = ((data['topic'] as num?)?.toInt() ?? -1).clamp(-1, 16);
        challengeMode =
            [
              'Practice',
              'Topic focused',
              'Mixed review',
            ].contains(data['challengeMode'])
            ? data['challengeMode']
            : 'Practice';
        if (challengeMode == 'Topic focused' &&
            topic >= 1 &&
            question.studio != topic) {
          questionId = masteryQuestions.firstWhere((q) => q.studio == topic).id;
        }
      } else {
        notice =
            'Older tool state retained; new tools use documented defaults.';
      }
    }
    queryInput.text = query;
    savedIds = await store.savedSessionIds();
    attempts = await store.readAttempts('s00-e05');
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
  }

  Map<String, dynamic> configuration() => {
    'model': learningVersion,
    'inventory': 'catalog-17-102-stable',
    'query': query,
    'studio': studio,
    'apparatus': apparatus,
    'stage': stage,
    'focus': focus,
    'path': pathId,
    'question': questionId,
    'notes': notes.text,
    'opened': opened.toList(),
    'inspected': inspected.toList(),
    'filterUsed': filterUsed,
    'listView': listView,
    'onlyFavorites': onlyFavorites,
    'topic': topic,
    'challengeMode': challengeMode,
  };
  Future<void> persist() async {
    if (ready) await store.saveSession(entry.id, configuration());
  }

  Future<void> save() async {
    try {
      await persist();
      notice = 'Tool configuration and notes saved.';
    } catch (_) {
      notice = 'Save failed; existing saved data retained.';
    }
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) persist();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    persist();
    notes.dispose();
    answer.dispose();
    queryInput.dispose();
    mapView.dispose();
    super.dispose();
  }

  Future<void> launch(String id, {bool defaults = false}) async {
    await persist();
    if (defaults) await store.requestDocumentedDefaults(id);
    opened.add(id);
    if (!mounted) return;
    await context.push('/lab/$id');
    savedIds = await store.savedSessionIds();
    await persist();
    if (mounted) setState(() {});
  }

  Future<void> reopenSaved(String key) async {
    final data = await store.readSession(key);
    if (data == null) return;
    if (key.startsWith('backup:')) {
      final id = data['backupFor'] as String,
          original = Map<String, dynamic>.from(data['original']);
      await store.saveSession(id, original);
      await launch(id);
    } else {
      await launch(key);
    }
  }

  Future<void> submit() async {
    final value = double.tryParse(answer.text);
    if (value == null || !value.isFinite) {
      setState(
        () => feedback = 'Enter a finite numeric answer in ${question.unit}.',
      );
      return;
    }
    if (question.type == 'Parameter adjustment' &&
        (value < 250 || value > 10000)) {
      setState(
        () => feedback =
            'Resistance must be250…10000Ω; no unsupported current assigned.',
      );
      return;
    }
    final q = question,
        correct = q.evaluate(value),
        a = <String, dynamic>{
          'model': learningVersion,
          'challengeId': q.id,
          'sourceModel': q.sourceModel,
          'modelConfiguration': q.configuration,
          'labId': q.lab,
          'type': q.type,
          'answer': value,
          'target': q.answer(),
          'tolerance': q.tolerance,
          'unit': q.unit,
          'correct': correct,
          'created': DateTime.now().toUtc().toIso8601String(),
        };
    await store.recordAttempt('s00-e05', a);
    attempts.insert(0, a);
    feedback =
        '${correct ? 'Correct' : 'Try again'} · ${q.explanation} Answer ${fmNumber(q.answer())} ${q.unit}; tolerance ±${q.tolerance}.';
    await persist();
    if (mounted) setState(() {});
  }

  Set<String> get correctIds => attempts
      .where(
        (a) =>
            a['model'] == learningVersion &&
            a['correct'] == true &&
            masteryQuestions.any((q) => q.id == a['challengeId']),
      )
      .map((a) => a['challengeId'] as String)
      .toSet();
  bool get eligible => switch (entry.index) {
    0 => filterUsed && opened.length >= 3,
    1 =>
      inspected.length >= 3 &&
          opened.isNotEmpty &&
          notes.text.trim().isNotEmpty,
    2 =>
      learningPaths
              .firstWhere((p) => p.id == pathId)
              .progress(store.completed) ==
          1,
    3 =>
      store.favorites.isNotEmpty &&
          opened.isNotEmpty &&
          savedIds.any((id) => labInventory.any((e) => e.id == id)),
    5 =>
      masteryQuestions
              .where((q) => correctIds.contains(q.id))
              .map((q) => q.type)
              .toSet()
              .length >=
          6,
    _ => false,
  };
  Widget panel(List<Widget> children) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (c, _) => Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            onPressed: save,
            tooltip: 'Save tool configuration',
            icon: const Icon(Icons.bookmark_add_outlined),
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              scrollId: entry.id,
              children: [
                const Eyebrow('Phase 8 · Shared inventory and real activity'),
                ...switch (entry.index) {
                  0 => atlas(),
                  1 => relationships(),
                  2 => paths(),
                  3 => launcher(),
                  _ => mastery(),
                },
                TextField(
                  controller: notes,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Tool / investigation notes',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                FilledButton(
                  onPressed: save,
                  child: const Text('Save tool configuration'),
                ),
                Text(notice),
                Text(completionRule),
                FilledButton(
                  onPressed: eligible
                      ? () async {
                          await store.complete(entry.id);
                          if (mounted) setState(() {});
                        }
                      : null,
                  child: const Text('Complete tool activity'),
                ),
              ],
            ),
    ),
  );
  String get completionRule => switch (entry.index) {
    0 => 'Completion: use a filter and launch three distinct labs. This is navigation practice, not lab mastery.',
    1 => 'Completion: inspect three relationship explanations, open a linked lab and write notes.',
    2 => 'Completion: finish every required activity in the selected path using its source lab criteria. Optional sixth activities do not block progress.',
    3 => 'Completion: favorite a lab, open a lab and retain a real saved lab configuration.',
    _ => 'Completion: a correct actual attempt in each of the six question types. Practice accuracy is not a validated measure of ability.',
  };
  Widget search() => TextFormField(
    controller: queryInput,
    decoration: const InputDecoration(
      labelText: 'Search labs, principles and topic tags',
      prefixIcon: Icon(Icons.search),
    ),
    onChanged: (v) => setState(() {
      query = v;
      filterUsed = true;
    }),
  );
  Widget studioFilter() => DropdownButtonFormField<int>(
    key: ValueKey('studio-$studio'),
    initialValue: studio,
    isExpanded: true,
    decoration: const InputDecoration(labelText: 'Studio filter'),
    items: [
      const DropdownMenuItem(value: -1, child: Text('All sixteen lab studios')),
      for (int i = 1; i < 17; i++)
        DropdownMenuItem(value: i, child: Text(studios[i].title)),
    ],
    onChanged: (v) {
      if (v != null) {
        setState(() {
          studio = v;
          filterUsed = true;
        });
      }
    },
  );
  Widget labTile(Entry e, {bool preset = false}) => Card(
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: SizedBox(
              width: 58,
              height: 48,
              child: CustomPaint(painter: StudioIllustration(e.studioIndex)),
            ),
            title: Text(e.title),
            subtitle: Text(
              '${studios[e.studioIndex].title} · ${stageFor(e)}\n${e.principle}\n${store.completed.contains(e.id) ? 'Activity complete' : 'Not completed'} · ${e.availability}',
            ),
            trailing: IconButton(
              key: Key('favorite-${e.id}'),
              tooltip: store.favorites.contains(e.id)
                  ? 'Remove favorite'
                  : 'Add favorite',
              onPressed: () => store.toggleFavorite(e.id),
              icon: Icon(
                store.favorites.contains(e.id) ? Icons.star : Icons.star_border,
              ),
            ),
            onTap: () => launch(e.id),
          ),
          Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => launch(e.id),
                child: const Text('Open lab / current session'),
              ),
              if (preset)
                TextButton(
                  onPressed: () async {
                    final apply = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Documented default inputs'),
                        content: Text(
                          'Open ${e.title} using the source lab’s documented default parameters, model and units. These are inputs, never recorded observations. Any existing saved configuration is backed up and remains listed below. Completion is unaffected.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(c, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(c, true),
                            child: const Text('Use documented defaults'),
                          ),
                        ],
                      ),
                    );
                    if (apply == true) await launch(e.id, defaults: true);
                  },
                  child: const Text('Launch documented defaults'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
  List<Widget> atlas() {
    final filtered = filterLabs(query: query, studio: studio);
    return [
      const Paragraph(
        'Physics Atlas',
        'All96 lab identities across16 subject studios. The map groups disciplines semantically; it is not a map of physical space. Use the accessible list to discover every lab.',
      ),
      search(),
      studioFilter(),
      SwitchListTile(
        value: listView,
        title: const Text('Accessible list instead of visual atlas'),
        onChanged: (v) => setState(() => listView = v),
      ),
      if (!listView) ...[
        SizedBox(
          height: 370,
          child: InteractiveViewer(
            transformationController: mapView,
            constrained: false,
            minScale: .35,
            maxScale: 2.5,
            child: SizedBox(
              width: 850,
              height: 4 * (182 + MediaQuery.textScalerOf(context).scale(65)),
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 1; i < 17; i++)
                    SizedBox(
                      width: 195,
                      child: Card(
                        child: InkWell(
                          onTap: () => setState(() {
                            studio = i;
                            filterUsed = true;
                          }),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 88,
                                width: 150,
                                child: CustomPaint(
                                  painter: StudioIllustration(i),
                                ),
                              ),
                              Text(
                                studios[i].title,
                                textAlign: TextAlign.center,
                              ),
                              Text(
                                groups[groupFor(i)],
                                style: const TextStyle(fontSize: 11),
                              ),
                              Text(
                                '${studios[i].entries.where((e) => store.completed.contains(e.id)).length}/6 activities complete',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => mapView.value = Matrix4.identity(),
          child: const Text('Reset atlas zoom and pan'),
        ),
      ],
      Text(
        '${filtered.length}/96 labs match. All routes use the catalog identities.',
      ),
      for (final e in filtered) labTile(e),
    ];
  }

  List<Widget> relationships() {
    final edges = conceptEdges
            .where(
              (e) =>
                  (focus.isEmpty || e.from == focus || e.to == focus) &&
                  ('${e.from} ${e.to} ${e.explanation}').toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList(),
        nodes = conceptEdges.expand((e) => [e.from, e.to]).toSet().toList()
          ..sort();
    return [
      const Paragraph(
        'Curated concept graph',
        'Select a node or search relationships. Every visible connection has an explanation, assumptions, source labs and a concrete investigation below.',
      ),
      search(),
      DropdownButtonFormField<String>(
        key: ValueKey(focus),
        initialValue: focus,
        decoration: const InputDecoration(labelText: 'Focus concept node'),
        isExpanded: true,
        items: [
          const DropdownMenuItem(value: '', child: Text('All concepts')),
          for (final n in nodes) DropdownMenuItem(value: n, child: Text(n)),
        ],
        onChanged: (v) {
          if (v != null) setState(() => focus = v);
        },
      ),
      SwitchListTile(
        value: listView,
        title: const Text('Accessible relationship list only'),
        onChanged: (v) => setState(() => listView = v),
      ),
      if (!listView)
        SizedBox(
          height: 350,
          child: InteractiveViewer(
            constrained: false,
            minScale: .4,
            maxScale: 3,
            child: SizedBox(
              width: 800,
              height: 600,
              child: Stack(
                children: [
                  CustomPaint(
                    size: const Size(800, 600),
                    painter: ConceptGraphPainter(nodes, edges),
                  ),
                  for (int i = 0; i < nodes.length; i++)
                    Positioned(
                      left: 30 + (i % 4) * 195,
                      top: 20 + (i ~/ 4) * 100,
                      width: 170,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: nodes[i] == focus
                              ? const Color(0xffe0f4ef)
                              : Colors.white,
                        ),
                        onPressed: () => setState(() => focus = nodes[i]),
                        child: Text(nodes[i], textAlign: TextAlign.center),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      for (final edge in edges)
        panel([
          Text(
            '${edge.from} → ${edge.to}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(edge.equation),
          Paragraph('Relationship', edge.explanation),
          Paragraph('Assumptions', edge.assumptions),
          Paragraph('Suggested investigation', edge.investigation),
          TextButton(
            onPressed: () => setState(() => inspected.add(edge.id)),
            child: Text(
              inspected.contains(edge.id)
                  ? 'Explanation inspected'
                  : 'Inspect relationship',
            ),
          ),
          for (final id in edge.labs)
            TextButton(
              onPressed: () => launch(id),
              child: Text('Explore ${entryById(id).title}'),
            ),
        ]),
    ];
  }

  List<Widget> paths() {
    final selected = learningPaths.firstWhere((p) => p.id == pathId),
        resume = selected.resume(store.completed);
    return [
      const Paragraph(
        'Guided Path',
        'Eight curated paths cover all96 labs. Prerequisites guide learning and never lock exploration. Required progress uses actual source-lab completion; estimates are planning aids, not measured time.',
      ),
      DropdownButtonFormField<String>(
        initialValue: pathId,
        isExpanded: true,
        items: [
          for (final p in learningPaths)
            DropdownMenuItem(value: p.id, child: Text(p.title)),
        ],
        onChanged: (v) {
          if (v != null) setState(() => pathId = v);
        },
      ),
      Paragraph('Objectives', selected.objective),
      Paragraph(
        'Suggested prerequisites',
        selected.prerequisites.isEmpty
            ? 'None'
            : selected.prerequisites
                  .map(
                    (id) => learningPaths.firstWhere((p) => p.id == id).title,
                  )
                  .join(', '),
      ),
      Text(
        'Estimated effort: ${selected.activities.length * 10}–${selected.activities.length * 20} minutes, including optional work.',
      ),
      LinearProgressIndicator(value: selected.progress(store.completed)),
      Text(
        '${selected.requiredActivities.where((e) => store.completed.contains(e.id)).length}/${selected.requiredActivities.length} required activities complete. No progress is earned by visiting this page.',
      ),
      FilledButton(
        onPressed: resume == null ? null : () => launch(resume.id),
        child: Text(
          resume == null ? 'Required path complete' : 'Resume ${resume.title}',
        ),
      ),
      for (int i = 0; i < selected.activities.length; i++)
        ListTile(
          leading: CircleAvatar(child: Text('${i + 1}')),
          title: Text(selected.activities[i].title),
          subtitle: Text(
            '${selected.required(selected.activities[i]) ? 'Required' : 'Optional extension'} · ${store.completed.contains(selected.activities[i].id) ? 'Complete' : 'Not complete'}',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => launch(selected.activities[i].id),
        ),
    ];
  }

  List<Widget> launcher() {
    final filtered = filterLabs(
          query: query,
          studio: studio,
          apparatus: apparatus,
          stage: stage,
          onlyIds: onlyFavorites ? store.favorites : null,
        ),
        apparatuses = labInventory.map(apparatusFor).toSet().toList()..sort();
    return [
      const Paragraph(
        'Experiment Launcher',
        'Search all96 working lab routes. Learning-stage labels are curated teaching estimates. Presets use the source lab’s documented default inputs and never insert results.',
      ),
      search(),
      studioFilter(),
      DropdownButtonFormField<String>(
        key: ValueKey('app-$apparatus'),
        initialValue: apparatus,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Apparatus filter'),
        items: [
          const DropdownMenuItem(value: '', child: Text('All apparatus')),
          for (final a in apparatuses)
            DropdownMenuItem(value: a, child: Text(a)),
        ],
        onChanged: (v) {
          if (v != null) setState(() => apparatus = v);
        },
      ),
      DropdownButtonFormField<String>(
        initialValue: stage,
        decoration: const InputDecoration(labelText: 'Learning stage'),
        items: [
          const DropdownMenuItem(value: '', child: Text('All learning stages')),
          for (final s in ['Foundation', 'Intermediate', 'Advanced'])
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (v) {
          if (v != null) setState(() => stage = v);
        },
      ),
      FilterChip(
        selected: onlyFavorites,
        label: const Text('Favorites only'),
        onSelected: (v) => setState(() => onlyFavorites = v),
      ),
      ExpansionTile(
        key: const PageStorageKey('launcher-recents'),
        title: Text(
          'Recent labs (${store.recent.where((id) => labInventory.any((e) => e.id == id)).length})',
        ),
        children: [
          for (final id in store.recent.where(
            (id) => labInventory.any((e) => e.id == id),
          ))
            ListTile(title: Text(entryById(id).title), onTap: () => launch(id)),
        ],
      ),
      ExpansionTile(
        key: const PageStorageKey('launcher-saved'),
        title: Text(
          'Saved configurations (${savedIds.where((id) => id.startsWith('backup:') || labInventory.any((e) => e.id == id)).length})',
        ),
        children: [
          for (final id
              in savedIds
                  .where(
                    (id) =>
                        id.startsWith('backup:') ||
                        labInventory.any((e) => e.id == id),
                  )
                  .take(200))
            ListTile(
              title: Text(
                id.startsWith('backup:')
                    ? 'Preserved ${id.split(':')[1]} configuration'
                    : entryById(id).title,
              ),
              subtitle: Text(id),
              onTap: () => reopenSaved(id),
            ),
        ],
      ),
      Wrap(
        spacing: 6,
        children: [
          for (final g in groups)
            ActionChip(
              label: Text(g),
              onPressed: () => setState(() {
                query = g;
                queryInput.text = g;
              }),
            ),
        ],
      ),
      Text('${filtered.length}/96 matching labs'),
      for (final e in filtered) labTile(e, preset: true),
    ];
  }

  List<MasteryQuestion> get questions {
    final q = masteryQuestions
        .where(
          (q) =>
              challengeMode != 'Topic focused' ||
              topic < 0 ||
              q.studio == topic,
        )
        .toList();
    return q;
  }

  double adjustmentCurrent(double resistance) {
    final source = CircuitPart('source', 'source', value: 5, x: 0, y: 0),
        resistor = CircuitPart(
          'resistor',
          'resistor',
          value: resistance,
          x: 1,
          y: 0,
        ),
        graph = CircuitGraph(
          [source, resistor],
          [
            [source.a, resistor.a],
            [source.b, resistor.b],
          ],
        );
    return solveCircuit(graph).currents['resistor']!;
  }

  String adjustmentPreview() {
    final x = answer.text.trim().isEmpty
        ? 1000.0
        : double.tryParse(answer.text);
    if (x == null || !x.isFinite || x < 250 || x > 10000) {
      return 'Enter resistance250…10000Ω to calculate a supported current.';
    }
    return 'Existing MNA solver: R=$x Ω; I=${fmNumber(adjustmentCurrent(x))} A; target0.002A.';
  }

  List<Widget> mastery() {
    final q = question,
        available = questions,
        history = attempts.where((a) => a['model'] == learningVersion).toList();
    return [
      const Paragraph(
        'Mastery Challenge',
        'Six objective task types across all16 studios. Questions are curated and model-backed, with explicit units/tolerances. Practice accuracy is a heuristic summary of these attempts, not a scientifically validated ability score.',
      ),
      DropdownButtonFormField<String>(
        initialValue: challengeMode,
        isExpanded: true,
        items: [
          for (final m in ['Practice', 'Topic focused', 'Mixed review'])
            DropdownMenuItem(value: m, child: Text(m)),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() {
              challengeMode = v;
              if (questions.isNotEmpty) questionId = questions.first.id;
              feedback = '';
              answer.clear();
            });
          }
        },
      ),
      if (challengeMode == 'Topic focused')
        DropdownButtonFormField<int>(
          initialValue: topic,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: -1, child: Text('All topics')),
            for (int i = 1; i < 17; i++)
              DropdownMenuItem(value: i, child: Text(studios[i].title)),
          ],
          onChanged: (v) {
            if (v != null) {
              setState(() {
                topic = v;
                questionId = questions.first.id;
                feedback = '';
                answer.clear();
              });
            }
          },
        ),
      Text(
        '${correctIds.length}/${masteryQuestions.length} distinct questions answered correctly from actual saved attempts. ${history.length} submitted attempts.',
      ),
      DropdownButtonFormField<String>(
        key: ValueKey(questionId),
        initialValue: questionId,
        isExpanded: true,
        decoration: const InputDecoration(labelText: 'Curated challenge'),
        items: [
          for (final item in available)
            DropdownMenuItem(
              value: item.id,
              child: Text(
                '${studios[item.studio].title} · ${item.type}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() {
              questionId = v;
              feedback = '';
              answer.clear();
            });
          }
        },
      ),
      Text(
        '${q.id} · ${q.type}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      Text('Prerequisite tags: ${q.prerequisites.join(', ')}'),
      Text(q.prompt),
      if (q.type == 'Instrument reading')
        Semantics(
          label: 'Caliper main scale23mm, vernier coincidence6, least count0.1mm, zero error0',
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: CustomPaint(painter: const ApparatusPainter(1, a: .0236)),
          ),
        ),
      if (q.type == 'Graph interpretation')
        SizedBox(
          height: 240,
          child: CustomPaint(
            painter: LabPlot(
              [
                for (int i = 0; i <= 120; i++)
                  {
                    't': i / 120 * math.pi,
                    'x': freeOscillator(1, 4, 0, .1, 0, i / 120 * math.pi).x,
                  },
              ],
              const ['x'],
              'Physical time (s)',
              'm',
              60,
            ),
          ),
        ),
      if (q.type == 'Concept selection') ...[
        for (int i = 0; i < q.options.length; i++)
          ChoiceChip(
            selected: int.tryParse(answer.text) == i,
            onSelected: (_) => setState(() => answer.text = '$i'),
            label: Text(q.options[i]),
          ),
      ] else ...[
        TextField(
          key: const Key('mastery-answer'),
          controller: answer,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(labelText: 'Answer (${q.unit})'),
          onChanged: (_) => setState(() {}),
        ),
        if (q.type == 'Parameter adjustment') ...[
          Slider(
            key: const Key('target-resistance'),
            value: (double.tryParse(answer.text) ?? 1000).clamp(250, 10000),
            min: 250,
            max: 10000,
            label: 'Resistance Ω',
            onChanged: (v) =>
                setState(() => answer.text = v.toStringAsFixed(1)),
          ),
          Text(adjustmentPreview()),
        ],
      ],
      FilledButton(
        key: const Key('mastery-submit'),
        onPressed: submit,
        child: const Text('Submit answer'),
      ),
      Text(feedback),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => setState(() {
              answer.clear();
              feedback = 'Retry the same validated question.';
            }),
            child: const Text('Retry'),
          ),
          OutlinedButton(
            onPressed: () {
              final index = available.indexWhere(
                    (item) => item.id == questionId,
                  ),
                  next =
                      (index + (challengeMode == 'Mixed review' ? 7 : 1)) %
                      available.length;
              setState(() {
                questionId = available[next].id;
                answer.clear();
                feedback = '';
              });
            },
            child: const Text('Next challenge'),
          ),
          TextButton(
            onPressed: () => launch(q.lab),
            child: const Text('Explore source lab'),
          ),
        ],
      ),
      ExpansionTile(
        key: const PageStorageKey('mastery-history'),
        title: Text('Actual attempt history (${history.length})'),
        children: [
          for (final a in history.take(50))
            ListTile(
              title: Text(
                '${a['challengeId']} · ${a['correct'] == true ? 'Correct' : 'Retry'}',
              ),
              subtitle: Text('${a['answer']} ${a['unit']} · ${a['created']}'),
            ),
        ],
      ),
    ];
  }
}

class ConceptGraphPainter extends CustomPainter {
  final List<String> nodes;
  final List<ConceptEdge> edges;
  ConceptGraphPainter(this.nodes, this.edges);
  Offset at(String node) {
    final i = nodes.indexOf(node);
    return Offset(115 + (i % 4) * 195, 45 + (i ~/ 4) * 100);
  }

  @override
  void paint(Canvas c, Size size) {
    for (final e in edges) {
      final a = at(e.from),
          b = at(e.to),
          delta = b - a,
          end = b - delta / delta.distance * 30;
      c.drawLine(
        a,
        end,
        Paint()
          ..color = teal.withValues(alpha: .6)
          ..strokeWidth = 2,
      );
      final u = delta / delta.distance, n = Offset(-u.dy, u.dx);
      c.drawPath(
        Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - u.dx * 10 + n.dx * 5, end.dy - u.dy * 10 + n.dy * 5)
          ..lineTo(end.dx - u.dx * 10 - n.dx * 5, end.dy - u.dy * 10 - n.dy * 5)
          ..close(),
        Paint()..color = teal,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ConceptGraphPainter old) => true;
}
