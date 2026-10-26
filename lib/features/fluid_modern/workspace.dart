import '../workbench/learning_header.dart';

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../workbench/workbench.dart';
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/design_system/reference_style.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/dynamics.dart' show FixedClock;
import '../../core/physics/fluid_modern_run.dart';
import '../../core/physics/electromagnetism.dart' show elementaryCharge;
import '../advanced/scene.dart' show LabPlot;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../electronics_thermal/scene.dart' show ETBackdrop;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'curriculum.dart';
import 'scene.dart';

String fmNumber(num? n) => n == null || !n.isFinite
    ? '—'
    : n == 0
    ? '0'
    : n.abs() < .001 || n.abs() >= 1e6
    ? n.toStringAsExponential(5)
    : n.toStringAsPrecision(6);
String fmLabel(String key) => switch (key) {
  'expectedActivity' => 'Expected source activity',
  'bindingPerNucleon' => 'Binding energy per nucleon',
  'normalization' => 'Analytical normalization (grid check)',
  _ => key.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (m) => '${m[1]} ${m[2]!.toLowerCase()}',
  ),
};

class FMWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const FMWorkspace({super.key, required this.entry});
  @override
  ConsumerState<FMWorkspace> createState() => _FMWorkspaceState();
}

class _FMWorkspaceState extends ConsumerState<FMWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late FMState parameters;
  late FMRun run;
  late final LocalNotebook store;
  late final Ticker ticker;
  final clock = FixedClock(),
      tick = ValueNotifier(0),
      notes = TextEditingController(),
      graphView = TransformationController();
  int section = 1, mode = 0, cursor = 0;
  bool ready = false,
      changed = false,
      labels = true,
      overlays = true,
      busy = false;
  Duration previous = Duration.zero;
  String
  feedback = '',
  notice =
      'Scientific edits restart time and observations; the seed makes reset reproducible.',
  graphMode = '';
  final attempts = <Map<String, dynamic>>[];
  Entry get entry => widget.entry;
  double? get result => run.invalid.isEmpty ? run.state[lesson.metric] : null;
  String get unit => lesson.unit;
  String get quantity => [
    'pressure',
    'length',
    'force',
    'speed',
    'pressure',
    'speed',
    'energy',
    'current',
    'length',
    'length',
    'energy',
    'activity',
  ][kind];
  int guided = 0;
  @override
  void initState() {
    super.initState();
    kind = (entry.studioIndex - 14) * 6 + entry.index;
    lesson = fmLessons[kind];
    parameters = lesson.defaults;
    run = FMRun(kind, parameters);
    graphMode = graphOptions.first;
    ticker = createTicker(onFrame);
    store = ref.read(notebookProvider);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) dynamicsRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    pause();
    persist();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed) {
      pause();
      persist();
    }
  }

  Future<void> load() async {
    final saved = await store.readSession(entry.id);
    if (saved != null && !restore(saved)) {
      await store.retainRejectedSession(entry.id, saved);
      notice = 'Incompatible session kept intact; documented defaults shown.';
    }
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
  }

  void onFrame(Duration elapsed) {
    final revision = run.revision;
    clock.advance((elapsed - previous).inMicroseconds / 1e6, () => run.step());
    previous = elapsed;
    if (revision != run.revision &&
        (!store.reducedMotion || run.ticks % 24 == 0 || run.finished)) {
      tick.value++;
    }
    if (run.finished || run.invalid.isNotEmpty) pause();
  }

  void pause() {
    ticker.stop();
    clock.pause();
    run.refresh();
    if (mounted) setState(() {});
  }

  void play() {
    if (!run.dynamicLab || run.invalid.isNotEmpty) return;
    if (run.finished) reset();
    previous = Duration.zero;
    clock.pause();
    ticker.start();
    setState(() {});
  }

  void reset() {
    pause();
    run = FMRun(kind, parameters, mode: mode, geometryFrom: run);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void defaults() {
    pause();
    mode = 0;
    parameters = lesson.defaults;
    run = FMRun(kind, parameters);
    graphMode = graphOptions.first;
    changed = false;
    feedback = '';
    cursor = 0;
    notice = 'Documented defaults and original seed restored; earlier trials remain.';
    tick.value++;
    setState(() {});
  }

  void update(String key, double value) {
    if (['n', 'upper', 'seed', 'initialN'].contains(key)) {
      value = value.roundToDouble();
    }
    if (parameters[key] == value) return;
    pause();
    parameters[key] = value;
    changed = changed || key != 'azimuth';
    run = FMRun(kind, parameters, mode: mode, geometryFrom: run);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void chooseMode(int value) {
    if (value == mode) return;
    pause();
    mode = value;
    changed = true;
    run = FMRun(kind, parameters, mode: mode);
    if (!graphOptions.contains(graphMode)) graphMode = graphOptions.first;
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  Map<String, dynamic> configuration() => {
    'model': fmVersion,
    'dataset': datasetVersion,
    'samplingAlgorithm': stochasticVersion,
    'kind': kind,
    'mode': mode,
    'parameters': Map.of(parameters),
    'initial': Map.of(run.initial),
    'units': {
      for (final p in lesson.controls) p.key: p.unit,
      lesson.metric: unit,
      't': 's',
    },
    'stateUnits': {
      for (final key in run.state.keys)
        key: key == 't' ? 's' : (stateUnit(key).isEmpty ? '1' : stateUnit(key)),
    },
    'profileAxis': switch (kind) {
      0 => {'quantity': 'depth', 'unit': 'm'},
      1 => {'quantity': 'same-fluid height difference', 'unit': 'm'},
      2 => {'quantity': 'held bottom depth', 'unit': 'm'},
      3 || 4 => {'quantity': 'axial position', 'unit': 'm'},
      6 || 8 => {'quantity': 'position', 'unit': 'm'},
      7 => {'quantity': 'collector bias', 'unit': 'V'},
      9 => {'quantity': 'principal quantum number', 'unit': '1'},
      10 => {'quantity': 'mass number', 'unit': '1'},
      _ => {'quantity': 'physical time', 'unit': 's'},
    },
    'profileValueUnits': {
      for (final key
          in run.profile
              .expand((row) => row.keys)
              .toSet()
              .where((key) => key != 't'))
        key: stateUnit(key).isEmpty ? '1' : stateUnit(key),
    },
    if (run.distribution != null)
      'histogramMetadata': {
        'axisUnit': 'm',
        'densityUnit': 'm⁻¹',
        'countUnit': '1',
        'min': run.distribution!.min,
        'max': run.distribution!.max,
        'bins': run.bins,
        'binWidth': (run.distribution!.max - run.distribution!.min) / run.bins,
        'measurementCount': run.measurementCount,
      },
    'ticks': run.ticks,
    'seed': parameters['seed'],
    'notes': notes.text,
    'guided': guided,
    'changed': changed,
    'attempts': List.of(attempts),
    'labels': labels,
    'overlays': overlays,
    'speed': clock.speed,
    'graphMode': graphMode,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != fmVersion ||
          data['dataset'] != datasetVersion ||
          data['samplingAlgorithm'] != stochasticVersion ||
          data['kind'] != kind) {
        return false;
      }
      final next = <String, double>{};
      for (final p in lesson.controls) {
        final value = (data['parameters'][p.key] as num).toDouble();
        if (!value.isFinite ||
            value < p.min ||
            value > p.max ||
            ['n', 'upper', 'seed', 'initialN'].contains(p.key) &&
                value != value.roundToDouble()) {
          return false;
        }
        next[p.key] = value;
      }
      final m = data['mode'] as int, count = data['ticks'] as int;
      if (m < 0 || m >= fmModes[kind].length || count < 0 || count > 15000) {
        return false;
      }
      final candidate = FMRun(kind, next, mode: m);
      if (count > candidate.totalTicks) return false;
      candidate.seek(count * FMRun.dt * candidate.timeScale);
      ticker.stop();
      clock.pause();
      mode = m;
      parameters = next;
      run = candidate;
      notes.text = data['notes'] ?? '';
      guided = data['guided'] is int ? (data['guided'] as int).clamp(0, 3) : 0;
      changed = data['changed'] == true;
      labels = data['labels'] != false;
      overlays = data['overlays'] != false;
      clock.speed = ((data['speed'] as num?)?.toDouble() ?? 1).clamp(.25, 2);
      graphMode = graphOptions.contains(data['graphMode'])
          ? data['graphMode']
          : graphOptions.first;
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? [])
              .take(50)
              .map((e) => Map<String, dynamic>.from(e)),
        );
      notice = 'Original SI inputs, dataset and seed restored; deterministic replay paused.';
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() async {
    if (ready) await store.saveSession(entry.id, configuration());
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> save() async {
    pause();
    try {
      await persist();
      message('Session and seed saved; reopens paused.');
    } catch (_) {
      message('Save failed; existing records retained.');
    }
  }

  Future<void> record() async {
    pause();
    if (result == null || !result!.isFinite || busy) return;
    setState(() => busy = true);
    try {
      await store.addTrial(
        Trial(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          labId: entry.id,
          quantity: quantity,
          unit: unit,
          value: result!,
          resolution: null,
          configuration: configuration()
            ..['observations'] = [for (final row in run.samples) Map.of(row)]
            ..['currentState'] = Map.of(run.state)
            ..['profile'] = [for (final row in run.profile) Map.of(row)]
            ..['histogram'] = List.of(run.histogram)
            ..['recentPositions_m'] = List.of(run.positions)
            ..['observationType'] = (run.stochastic
                ? 'Analytical prediction plus explicitly simulated seeded observations'
                : 'Analytical calculation'),
          note: notes.text,
          model: fmVersion,
        ),
      );
      await persist();
      if (store.haptics) HapticFeedback.lightImpact();
      message('Actual computed state and simulated observations recorded.');
    } catch (_) {
      message('Observation could not be saved. Earlier records retained.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> predict() async {
    pause();
    if (result == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: 'Predict ${fmLabel(lesson.metric)} ($unit)',
        initial: 0,
        min: -1e30,
        max: 1e30,
        onApply: submit,
      ),
    );
  }

  Future<void> submit(double answer) async {
    if (result == null) return;
    final correct =
            (answer - result!).abs() <= math.max(result!.abs() * .02, 1e-30),
        a = <String, dynamic>{
          'answer': answer,
          'target': result,
          'correct': correct,
          'parameters': Map.of(parameters),
          'mode': mode,
          'time': run.time,
        };
    attempts.add(a);
    if (attempts.length > 50) attempts.removeAt(0);
    await store.recordAttempt(entry.id, a);
    if (mounted) {
      setState(
        () => feedback =
            '${correct ? 'Correct' : 'Reconsider'} · current reference ${fmNumber(result)} $unit. ${lesson.mistake}',
      );
    }
    await persist();
  }

  bool matching(dynamic raw) {
    if (raw is! Map) return false;
    return parameters.entries
        .where((e) => e.key != 'azimuth')
        .every((e) => raw[e.key] == e.value);
  }

  bool get eligible =>
      changed &&
      notes.text.trim().isNotEmpty &&
      attempts.any(
        (a) =>
            a['correct'] == true &&
            a['mode'] == mode &&
            matching(a['parameters']),
      ) &&
      store.trials.any(
        (t) =>
            t.labId == entry.id &&
            t.configuration['mode'] == mode &&
            matching(t.configuration['parameters']),
      );
  void sampleBatch() {
    pause();
    final target = math.min(
      run.maxTime,
      run.time + 100 / parameters['eventRate']!,
    );
    run.seek(target);
    tick.value++;
    setState(() {});
  }

  @override
  void dispose() {
    dynamicsRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    ticker.stop();
    persist();
    ticker.dispose();
    notes.dispose();
    graphView.dispose();
    tick.dispose();
    super.dispose();
  }

  Widget panel(List<Widget> children) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
  List<InstrumentControl> instrumentControls() => [
    for (final p in fmControls(kind, mode))
      InstrumentControl(
        p.key,
        p.label,
        p.unit,
        parameters[p.key]!,
        p.min,
        p.max,
        (v) => update(p.key, v),
      ),
  ];
  CustomPainter referencePlot() {
    final p = plot;
    return LabPlot(
      p.data,
      p.keys,
      p.x,
      p.unit,
      cursor,
      scatter: p.scatter,
      histogramKeys: p.bars,
    );
  }

  String? highlightControl;
  @override
  Widget build(BuildContext context) {
    if (ready && (section == 1 || section == 2 || section == 4)) {
      return InstrumentShell(
        key: ValueKey('instrument-${entry.id}'),
        referenceChart: referencePlot,
        exportRecorded: (trials) => exportTrials(context, trials),
        reopenTrial: (trial) {
          pause();
          final before = Map<String, dynamic>.from(
            jsonDecode(jsonEncode(configuration())),
          );
          final ok = restore(trial.configuration);
          if (!ok) restore(before);
          tick.value++;
          setState(() {});
          return ok;
        },

        guidedStep: () => guided,
        changeGuidedStep: (v) {
          setState(() => guided = v);
          persist();
        },
        guideInstructions: () => [
          lesson.procedure.split('. ').first,
          'Run or step the model, or inspect a static probe.',
          'Record ${lesson.metric} for this configuration.',
          'Check the numerical prediction and add explanatory notes.',
        ],
        canAdvanceGuide: (step) => step == 0
            ? changed
            : step == 1
            ? (!(run.dynamicLab) || run.time > 0)
            : step == 2
            ? store.trials.any(
                (t) =>
                    t.labId == entry.id &&
                    t.configuration['ticks'] == run.ticks &&
                    jsonEncode(t.configuration['parameters']) ==
                        jsonEncode(parameters),
              )
            : true,

        id: entry.id,
        title: entry.title,
        highlightControl: highlightControl,
        store: store,
        changes: tick,
        scene: compactScene,
        graph: () => Column(children: visualize().skip(1).toList()),
        controls: instrumentControls,
        readings: () => [
          InstrumentReading(
            lesson.metric,
            result?.toStringAsPrecision(5) ?? 'Undefined',
            lesson.unit,
          ),
          InstrumentReading('Model t', run.time.toStringAsPrecision(4), 's'),
        ],
        advanced: () => experiment().skip(1).toList(),
        results: results,
        notice: () => run.invalid.isNotEmpty ? run.invalid : '',
        playing: () => ticker.isActive,
        dynamicModel: () => run.dynamicLab,
        canRecord: () => result != null && result!.isFinite,
        play: play,
        pause: pause,
        reset: reset,
        save: save,
        record: record,
        step: () {
          pause();
          run.step(captureNow: true);
          tick.value++;
        },
        selection: () => DropdownButtonFormField<int>(
          key: ValueKey('dock-mode-$kind-$mode'),
          initialValue: mode,
          isExpanded: true,
          items: [
            for (int i = 0; i < fmModes[kind].length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(fmModes[kind][i], overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) {
            if (v != null) chooseMode(v);
          },
        ),
        resetOriginalView: null,
        section: section,
        selectSection: (value) {
          pause();
          setState(() => section = value);
        },
      );
    }
    return legacyBuild(context);
  }

  Widget legacyBuild(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: LabBackButton(entry.id.split('-').first),
      title: ReferenceLabHeading(entry.id, entry.title),
      actions: [
        LabSectionMenu(
          labId: entry.id,
          notebook: store,
          section: section,
          save: save,
          select: (value) {
            pause();
            setState(() => section = value);
          },
        ),
      ],
    ),
    bottomNavigationBar: ReferenceNavigation(
      selected: section == 4
          ? 2
          : section == 0 || section == 3
          ? 0
          : 1,
      firstIcon: [0, 10, 11, 13].contains(entry.studioIndex)
          ? Icons.home_outlined
          : Icons.menu_book_outlined,
      onFirst: () {
        pause();
        setState(() => section = 0);
      },
      onLabs: () {
        pause();
        setState(() => section = 1);
      },
      onResults: () {
        pause();
        setState(() => section = 4);
      },
    ),
    body: SafeArea(
      child: !ready
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              scrollId: '${entry.id}:$section',
              children: [
                ...switch (section) {
                  0 => learn(),
                  1 => experiment(),
                  2 => visualize(),
                  3 => formulas(),
                  _ => results(),
                },
              ],
            ),
    ),
  );
  List<Widget> learn() => [
    LabLearningHeader(
      entry: entry,
      onExplore: () => setState(() => section = 1),
    ),
    relatedLabs(entry.id),
    panel([
      Paragraph(
        'Objectives',
        'Explain the model, predict ${fmLabel(lesson.metric)}, compare calculated results and identify its validity limits.${run.stochastic ? ' Distinguish analytical predictions from seeded simulated observations.' : ''}',
      ),
      Paragraph('Apparatus', lesson.apparatus),
      Paragraph('Principles', lesson.principle),
      Paragraph('Procedure', lesson.procedure),
      Paragraph('Assumptions and validity', lesson.limits),
      Paragraph('Common misconception', lesson.mistake),
      if (kind >= 10) const Paragraph('Reference dataset', datasetVersion),
    ]),
    investigation(),
  ];
  Widget investigation() => panel([
    const Eyebrow('Guided investigation'),
    Text(lesson.question),
    const Text(
      '1. Predict  2. Change one input  3. Record  4. Explain a limitation in notes.',
    ),
    FilledButton(
      onPressed: result == null ? null : predict,
      child: const Text('Check numerical prediction'),
    ),
    Text(feedback),
    FilledButton(
      onPressed: eligible
          ? () async {
              await store.complete(entry.id);
              message('Investigation completed from your actual activity.');
            }
          : null,
      child: const Text('Complete investigation'),
    ),
    if (!eligible)
      const Text(
        'Needs changed inputs, a correct prediction and a trial for the current configuration, plus explanation notes.',
      ),
  ]);

  void dragApparatus(DragUpdateDetails e, double width) {
    final x = e.localPosition.dx / width * 360,
        y = e.localPosition.dy / (width * .75) * 270;
    if (kind == 0) {
      update(
        'depth',
        ((y - FMPainter.pressureSurface) / FMPainter.pressureScale).clamp(
          0,
          .8,
        ),
      );
    } else if (kind == 1) {
      final p = lesson.controls.firstWhere((p) => p.key == 'deltaPressure');
      update(
        p.key,
        (parameters[p.key]! + e.delta.dx / width * (p.max - p.min)).clamp(
          p.min,
          p.max,
        ),
      );
    } else if (kind == 2 && mode == 1) {
      update(
        'bottomDepth',
        ((y - FMPainter.buoyancySurface) / FMPainter.buoyancyScale).clamp(
          -.02,
          .22,
        ),
      );
    } else if (kind == 2) {
      final p = lesson.controls.firstWhere((p) => p.key == 'objectDensity');
      update(
        p.key,
        (parameters[p.key]! + e.delta.dx / width * (p.max - p.min)).clamp(
          p.min,
          p.max,
        ),
      );
    } else if (kind == 3 || kind == 4) {
      update('probeX', ((x - 180) / FMPainter.pipeScale).clamp(-.12, .12));
    } else {
      final p = fmControls(kind, mode).first;
      update(
        p.key,
        (parameters[p.key]! + e.delta.dx / width * (p.max - p.min)).clamp(
          p.min,
          p.max,
        ),
      );
    }
  }

  Widget compactScene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, b) => GestureDetector(
            onPanUpdate: (e) => dragApparatus(e, b.maxWidth),
            child: SizedBox(
              width: b.maxWidth,
              height: b.maxWidth * .75,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const RepaintBoundary(
                    child: CustomPaint(
                      painter: ETBackdrop(electronics: false),
                      isComplex: true,
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: FMPainter(
                        run,
                        labels: labels,
                        overlays: overlays,
                        motion: !store.reducedMotion,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget scene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) => Semantics(
      label:
          '${entry.title}. ${fmModes[kind][mode]}. ${fmLabel(lesson.metric)} ${fmNumber(result)} $unit. ${run.invalid}',
      child: panel([
        Text(
          '${fmLabel(lesson.metric)}: ${fmNumber(result)} $unit',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (run.invalid.isNotEmpty)
          Text(run.invalid, style: const TextStyle(color: Colors.red)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, b) => GestureDetector(
              onPanUpdate: (e) => dragApparatus(e, b.maxWidth),
              child: SizedBox(
                width: b.maxWidth,
                height: b.maxWidth * .75,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const RepaintBoundary(
                      child: CustomPaint(
                        painter: ETBackdrop(electronics: false),
                        isComplex: true,
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: FMPainter(
                          run,
                          labels: labels,
                          overlays: overlays,
                          motion: !store.reducedMotion,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(switch (kind) {
          0 =>
            'Drag the depth probe vertically; zero depth is the free surface.',
          1 => 'Drag horizontally changes applied pressure; both levels are solved together.',
          2 =>
            mode == 1
                ? 'Drag the held block vertically; displaced volume follows its geometry.'
                : 'Static equilibrium; drag changes object density. No rise/sink animation is implied.',
          3 || 4 => 'Drag the axial probe along the pipe. Markers show transported volume, not molecules.',
          10 => 'Drag rotates a schematic nucleus; positions are not observed nucleon locations.',
          _ =>
            'Drag adjusts ${fmControls(kind, mode).first.label.toLowerCase()}; precise numeric alternatives below.',
        }),
        Wrap(
          spacing: 6,
          children: [
            FilterChip(
              label: const Text('Labels'),
              selected: labels,
              onSelected: (x) => setState(() => labels = x),
            ),
            FilterChip(
              label: const Text('Overlays'),
              selected: overlays,
              onSelected: (x) => setState(() => overlays = x),
            ),
          ],
        ),
        if (store.reducedMotion)
          const Text(
            'Reduced motion: moving markers hidden; state snapshots update at reduced frequency.',
          ),
      ]),
    ),
  );
  String stateUnit(String key) {
    const units = {
      'wavefunction': 'm⁻¹/²',
      'probabilityDensity': 'm⁻¹',
      'expectedDensity': 'm⁻¹',
      'observedDensity': 'm⁻¹',
      'radius': 'm',
      'head': 'm',
      'columnTop': 'm',
      'elevation': 'm',
      'bernoulli': 'Pa',
      'absolutePressure': 'Pa',
      'gaugePressure': 'Pa',
      'fluidDensity': 'kg/m³',
      'objectDensity': 'kg/m³',
      'depth': 'm',
      'gradient': 'Pa/m',
      'leftLevel': 'm',
      'rightLevel': 'm',
      'interfaceLevel': 'm',
      'layerHeight': 'm',
      'heightDifference': 'm',
      'baseVolume': 'm³',
      'initialBaseVolume': 'm³',
      'volumeResidual': 'm³',
      'pressureBalance': 'Pa',
      'datumPressureRightGauge': 'Pa',
      'deltaPressure': 'Pa',
      'volume': 'm³',
      'mass': 'kg',
      'bottomDepth': 'm',
      'submergedHeight': 'm',
      'displacedVolume': 'm³',
      'buoyantForce': 'N',
      'weight': 'N',
      'freeNetForceUp': 'N',
      'supportForceUp': 'N',
      'speed': 'm/s',
      'inletSpeed': 'm/s',
      'throatSpeed': 'm/s',
      'area': 'm²',
      'inletArea': 'm²',
      'throatArea': 'm²',
      'flowRate': 'm³/s',
      'continuityResidual': 'm³/s',
      'probeX': 'm',
      'pressure': 'Pa',
      'inletPressure': 'Pa',
      'throatPressure': 'Pa',
      'inletHead': 'm',
      'throatHead': 'm',
      'probeHead': 'm',
      'energyPerVolume': 'Pa',
      'bernoulliResidual': 'Pa',
      'position': 'm',
      'terminalSpeed': 'm/s',
      'tau': 's',
      'drag': 'N',
      'netForceDown': 'N',
      'arrivalTime': 's',
      'energy': 'J',
      'energyEV': 'eV',
      'observedMean': 'm',
      'frequency': 'Hz',
      'wavelength': 'm',
      'photonEnergy': 'J',
      'maximumKineticEnergy': 'J',
      'thresholdFrequency': 'Hz',
      'stoppingPotential': 'V',
      'photonFlux': 's⁻¹',
      'saturationCurrent': 'A',
      'current': 'A',
      'momentum': 'kg·m/s',
      'kineticEnergy': 'J',
      'fringeSpacing': 'm',
      'lowerEnergy': 'J',
      'upperEnergy': 'J',
      'seriesLimit': 'm',
      'atomicMass': 'kg',
      'atomicMassU': 'u',
      'nuclearCharge': 'C',
      'bindingEnergy': 'J',
      'bindingPerNucleon': 'J',
      'expectedActivity': 'Bq',
      'decayConstant': 's⁻¹',
      'halfLife': 's',
      'expectedDetectorRate': 'counts/s',
      'realizationActivity': 'Bq',
    };
    return units[key] ?? '';
  }

  Widget metrics() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) => panel([
      const Eyebrow('Current scientific state'),
      Text(
        '${fmLabel(lesson.metric)}: ${fmNumber(result)} $unit',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (run.invalid.isNotEmpty)
        Text(run.invalid, style: const TextStyle(color: Colors.red)),
      if (run.invalid.isEmpty) ...[
        Text('Physical time ${fmNumber(run.time)} s'),
        for (final e in run.state.entries.where((e) => e.key != 't'))
          Text('${fmLabel(e.key)}: ${fmNumber(e.value)} ${stateUnit(e.key)}'),
        if (kind == 10)
          Text(
            'Nuclide: ᴬ_Z X = ${isotopes[mode].a}_${isotopes[mode].z} ${isotopes[mode].symbol}; binding ${fmNumber(run.state['bindingEnergy']! / elementaryCharge / 1e6)} MeV; per nucleon ${fmNumber(run.state['bindingPerNucleon']! / elementaryCharge / 1e6)} MeV.',
          ),
        if (run.stochastic)
          Text(
            'Seed ${parameters['seed']!.round()} · simulated observations only. ${kind == 11 ? 'Activity and detector counts differ by efficiency and background.' : '${run.measurementCount} detections, normalized ${run.bins}-bin histogram; recent positions capped at300.'}',
          ),
      ],
    ]),
  );
  Widget control(Parameter p) {
    final integer = ['n', 'upper', 'seed', 'initialN'].contains(p.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${p.label}: ${fmNumber(parameters[p.key])} ${p.unit}',
              ),
            ),
            IconButton(
              key: Key('edit-${p.key}'),
              tooltip: 'Edit ${p.label}',
              onPressed: () async {
                pause();
                await showDialog<void>(
                  context: context,
                  builder: (_) => NumericInputDialog(
                    label: '${p.label} (${p.unit})',
                    initial: parameters[p.key]!,
                    min: p.min,
                    max: p.max,
                    onApply: (v) => update(p.key, v),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        Slider(
          key: Key('slider-${p.key}'),
          value: parameters[p.key]!.clamp(p.min, p.max),
          min: p.min,
          max: p.max,
          divisions: integer && p.max - p.min < 100
              ? (p.max - p.min).round()
              : null,
          onChanged: (v) => update(p.key, v),
        ),
      ],
    );
  }

  List<Widget> experiment() => [
    scene(),
    DropdownButtonFormField<int>(
      key: ValueKey('$kind:$mode'),
      isExpanded: true,
      initialValue: mode,
      decoration: const InputDecoration(
        labelText: 'Model / reference selection',
      ),
      items: [
        for (int i = 0; i < fmModes[kind].length; i++)
          DropdownMenuItem(value: i, child: Text(fmModes[kind][i])),
      ],
      onChanged: (v) {
        if (v != null) chooseMode(v);
      },
    ),
    panel([
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          FilledButton.icon(
            key: const Key('play'),
            onPressed: run.dynamicLab && run.invalid.isEmpty
                ? (ticker.isActive ? pause : play)
                : null,
            icon: Icon(ticker.isActive ? Icons.pause : Icons.play_arrow),
            label: Text(ticker.isActive ? 'Pause' : 'Play'),
          ),
          OutlinedButton(
            onPressed: run.dynamicLab && !run.finished && run.invalid.isEmpty
                ? () {
                    pause();
                    run.step(captureNow: true);
                    tick.value++;
                  }
                : null,
            child: const Text('Step'),
          ),
          OutlinedButton(onPressed: reset, child: const Text('Reset time')),
          TextButton(
            onPressed: defaults,
            child: const Text('Restore defaults'),
          ),
          if (kind == 6 || kind == 8)
            OutlinedButton(
              key: const Key('sample-batch'),
              onPressed: run.invalid.isEmpty && !run.finished
                  ? sampleBatch
                  : null,
              child: const Text('Simulate up to 100 detections'),
            ),
        ],
      ),
      Text(notice),
      if (run.dynamicLab) ...[
        Text(
          'Physical seconds per playback second: ${fmNumber(run.timeScale * clock.speed)}. Speed changes playback only.',
        ),
        DropdownButton<double>(
          isExpanded: true,
          value: clock.speed,
          items: [
            for (final s in [.25, .5, 1.0, 2.0])
              DropdownMenuItem(value: s, child: Text('$s× playback')),
          ],
          onChanged: (s) {
            if (s != null) {
              pause();
              setState(() => clock.speed = s);
            }
          },
        ),
      ],
      for (final p in fmControls(kind, mode)) control(p),
    ]),
    metrics(),
    TextField(
      controller: notes,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Investigation notes'),
      onChanged: (_) => setState(() {}),
    ),
    FilledButton.icon(
      key: const Key('record-trial'),
      onPressed: result == null || busy ? null : record,
      icon: const Icon(Icons.add_chart),
      label: const Text('Record trial'),
    ),
    investigation(),
  ];
  List<String> get graphOptions => switch (kind) {
    0 => ['Gauge pressure', 'Absolute pressure'],
    1 => ['Same-fluid hydrostatic gradient'],
    2 => ['Force and immersed height'],
    3 => ['Average speed', 'Cross-sectional area'],
    4 => ['Absolute pressure', 'Average speed', 'Piezometer head'],
    5 => ['Transit speed', 'Initial response', 'Position'],
    6 => [
      'Probability density',
      'Wavefunction',
      'Detections histogram',
      'Energy ladder',
    ],
    7 => ['Current versus bias', 'Kinetic energy versus frequency'],
    8 => ['Detector probability', 'Detections histogram'],
    9 => ['Energy levels', 'Schematic spectral lines'],
    10 => ['Sourced binding energies'],
    _ => [
      'Population history',
      'Expected decay reference',
      'Detector counts',
      'Activity and expected detector rate',
    ],
  };
  ({
    List<FMState> data,
    List<String> keys,
    String x,
    String unit,
    Set<String> bars,
    bool scatter,
  })
  get plot {
    List<FMState> data = run.profile;
    List<String> keys = [lesson.metric];
    String x = '', u = unit;
    Set<String> bars = {};
    bool scatter = false;
    switch (kind) {
      case 0:
        x = 'Depth below surface (m)';
        u = 'Pa';
        keys = [
          graphMode == 'Gauge pressure' ? 'gaugePressure' : 'absolutePressure',
        ];
      case 1:
        x = 'Same-fluid level difference (m)';
        u = 'Pa';
        keys = ['pressure'];
      case 2:
        x = 'Immersed block height (m)';
        u = 'N';
        keys = ['buoyantForce', 'weight'];
      case 3 || 4:
        x = 'Axial position (m)';
        if (graphMode == 'Average speed') {
          keys = ['speed'];
          u = 'm/s';
        } else if (graphMode == 'Cross-sectional area') {
          keys = ['area'];
          u = 'm²';
        } else if (graphMode == 'Piezometer head') {
          keys = ['head'];
          u = 'm';
        } else {
          keys = ['pressure'];
          u = 'Pa';
        }
      case 5:
        x = 'Physical time (s)';
        keys = [graphMode == 'Position' ? 'position' : 'speed'];
        u = graphMode == 'Position' ? 'm' : 'm/s';
        if (graphMode == 'Initial response' && run.invalid.isEmpty) {
          final tau = run.state['tau']!;
          data = [
            for (int i = 0; i <= 160; i++)
              {
                't': 5 * tau * i / 160,
                ...stokes(
                  parameters['radius']!,
                  parameters['sphereDensity']!,
                  parameters['density']!,
                  parameters['viscosity']!,
                  parameters['travel']!,
                  5 * tau * i / 160,
                ),
              },
          ];
        }
      case 6:
        x = 'Position in well (m)';
        if (graphMode == 'Detections histogram') {
          data = run.distributionData;
          keys = ['expectedDensity', 'observedDensity'];
          bars = {'observedDensity'};
          u = 'm⁻¹';
        } else if (graphMode == 'Wavefunction') {
          keys = ['wavefunction'];
          u = 'm⁻¹ᐟ²';
        } else if (graphMode == 'Energy ladder') {
          data = [
            for (int n = 1; n <= 6; n++)
              {
                't': n.toDouble(),
                'energy': wellEnergy(
                  parameters['wellWidth']!,
                  parameters['mass']!,
                  n,
                ),
              },
          ];
          keys = ['energy'];
          x = 'Eigenstate n';
          u = 'J';
          scatter = true;
        } else {
          keys = ['probabilityDensity'];
          u = 'm⁻¹';
        }
      case 7:
        x = 'Collector bias (V)';
        keys = ['current'];
        u = 'A';
        if (graphMode == 'Kinetic energy versus frequency') {
          x = 'Frequency (Hz)';
          keys = ['maximumKineticEnergy'];
          u = 'J';
          data = [
            for (int i = 0; i <= 160; i++)
              {
                't': 3.75e14 + (1.5e15 - 3.75e14) * i / 160,
                ...photoelectric(
                  3.75e14 + (1.5e15 - 3.75e14) * i / 160,
                  parameters['intensity']!,
                  parameters['illuminatedArea']!,
                  parameters['workFunction']!,
                  parameters['quantumEfficiency']!,
                  parameters['bias']!,
                ),
              },
          ];
        }
      case 8:
        x = 'Transverse detector position (m)';
        u = 'm⁻¹';
        keys = ['expectedDensity'];
        if (graphMode == 'Detections histogram') {
          data = run.distributionData;
          keys = ['expectedDensity', 'observedDensity'];
          bars = {'observedDensity'};
        }
      case 9:
        x = 'Hydrogen level n';
        u = 'J';
        keys = ['energy'];
        scatter = true;
        if (graphMode == 'Schematic spectral lines') {
          final lower = 1 + mode % 3;
          x = 'Vacuum wavelength (m)';
          u = 'Schematic equal line heights';
          keys = ['line'];
          data = [
            for (int upper = lower + 1; upper <= 8; upper++)
              {
                't': hydrogenTransition(lower, upper)['wavelength']!,
                'line': 1.0,
              },
          ];
        }
      case 10:
        x = 'Mass number A';
        u = 'J per nucleon';
        keys = ['bindingPerNucleon'];
        scatter = true;
      case 11:
        x = 'Physical time (s)';
        data = run.samples;
        u = 'Nuclei';
        keys = ['expectedRemaining', 'remaining'];
        if (graphMode == 'Expected decay reference') {
          data = run.profile;
          keys = ['expectedRemaining'];
        } else if (graphMode == 'Detector counts') {
          keys = ['detectedSourceCounts', 'backgroundCounts', 'detectorCounts'];
          u = 'Simulated counts';
        } else if (graphMode == 'Activity and expected detector rate') {
          keys = ['expectedActivity', 'expectedDetectorRate'];
          u = 'Bq / expected counts s⁻¹';
        }
    }
    return (
      data: data,
      keys: keys,
      x: x,
      unit: u,
      bars: bars,
      scatter: scatter,
    );
  }

  List<Widget> visualize() => [
    scene(),
    panel([
      DropdownButtonFormField<String>(
        key: ValueKey(graphMode),
        isExpanded: true,
        initialValue: graphMode,
        decoration: const InputDecoration(labelText: 'Graph / distribution'),
        items: [
          for (final s in graphOptions)
            DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (s) {
          if (s != null) {
            setState(() {
              graphMode = s;
              cursor = 0;
            });
          }
        },
      ),
      ListenableBuilder(
        listenable: tick,
        builder: (context, _) {
          final p = plot;
          return Semantics(
            label:
                '${entry.title} graph. ${p.x}; ${p.unit}. ${p.keys.map(fmLabel).join(', ')}. ${run.stochastic ? 'Simulated detections ${kind == 11 ? run.detected : run.measurementCount}; seed ${parameters['seed']!.round()}.' : ''}',
            child: Column(
              children: [
                SizedBox(
                  height: 260,
                  child: InteractiveViewer(
                    transformationController: graphView,
                    minScale: 1,
                    maxScale: 5,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(double.infinity, 260),
                        painter: LabPlot(
                          p.data,
                          p.keys,
                          p.x,
                          p.unit,
                          cursor.clamp(0, math.max(0, p.data.length - 1)),
                          scatter: p.scatter,
                          histogramKeys: p.bars,
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  'Legend: ${p.keys.map(fmLabel).join('; ')}. ${p.scatter ? 'Discrete supported points only.' : 'Pinch to zoom; drag to pan.'}',
                ),
                if (run.stochastic && run.measurementCount == 0 && kind != 11)
                  const Text(
                    'No simulated detections yet. Play or simulate a batch to populate the histogram.',
                  ),
                TextButton(
                  onPressed: () => graphView.value = Matrix4.identity(),
                  child: const Text('Reset graph view'),
                ),
                if (p.data.isNotEmpty) ...[
                  Slider(
                    value: cursor.clamp(0, p.data.length - 1).toDouble(),
                    max: math.max(1, p.data.length - 1).toDouble(),
                    onChanged: (v) => setState(() => cursor = v.round()),
                  ),
                  Text(
                    'Cursor: ${p.data[cursor.clamp(0, p.data.length - 1)].entries.map((e) => '${fmLabel(e.key)}=${fmNumber(e.value)}').join('; ')}',
                  ),
                ],
              ],
            ),
          );
        },
      ),
      if (run.dynamicLab) ...[
        const Text(
          'Replay recreates the initial physical state and seeded sequence; it reopens paused.',
        ),
        Slider(
          key: const Key('replay-time'),
          value: run.time.clamp(0, run.maxTime),
          max: run.maxTime,
          onChanged: run.invalid.isEmpty
              ? (t) {
                  pause();
                  run = FMRun(kind, parameters, mode: mode, geometryFrom: run)
                    ..seek(t);
                  cursor = 0;
                  tick.value++;
                  setState(() {});
                }
              : null,
        ),
      ],
    ]),
    metrics(),
  ];
  String get substitution {
    if (run.invalid.isNotEmpty) {
      return 'No supported substitution: ${run.invalid}';
    }
    String s(String k) => fmNumber(run.state[k]);
    String p(String k) => fmNumber(parameters[k]);
    return switch (kind) {
      0 =>
        'pabs=${p('surfacePressure')}+${p('density')}×9.80665×${p('depth')}=${s('absolutePressure')} Pa; gauge=${s('absolutePressure')}−${p('referencePressure')}=${s('gaugePressure')} Pa. Object ρ=${p('objectMass')}/${p('objectVolume')}=${s('objectDensity')} kg/m³.',
      1 =>
        'zL=${s('leftLevel')} m, interface=${s('interfaceLevel')} m, zR=${s('rightLevel')} m. Base volume=${s('baseVolume')} m³, residual=${s('volumeResidual')} m³. Hydrostatic pressure residual=${s('pressureBalance')} Pa.',
      2 =>
        'Fb=ρgVsub=${p('density')}×9.80665×${s('displacedVolume')}=${s('buoyantForce')} N. Weight=${s('weight')} N; required upward support=${s('supportForceUp')} N.',
      3 =>
        'Q=A1v1=A2v2=${s('inletArea')}×${s('inletSpeed')}=${s('throatArea')}×${s('throatSpeed')}=${s('flowRate')} m³/s; continuity residual ${s('continuityResidual')} m³/s.',
      4 =>
        'Bernoulli constant p+½ρv²+ρgz=${s('energyPerVolume')} Pa; inlet–throat residual=${s('bernoulliResidual')} Pa. Throat head=(p2−101325)/(ρg)=${s('throatHead')} m.',
      5 =>
        'vt=2×(${p('radius')})²×(${p('sphereDensity')}−${p('density')})×9.80665/(9×${p('viscosity')})=${s('terminalSpeed')} m/s; Re_terminal=${s('terminalReynolds')}; arrival time=${s('arrivalTime')} s.',
      6 =>
        'En=${p('n')}²π²ħ²/(2×${p('mass')}×(${p('wellWidth')})²)=${s('energy')} J=${s('energyEV')} eV. ∫|ψ|²dx=${s('normalization')}; ${run.measurementCount} simulated positions from seed ${p('seed')}.',
      7 =>
        'hf=${s('photonEnergy')} J, φ=${p('workFunction')} J, Kmax=${s('maximumKineticEnergy')} J, Vs=${s('stoppingPotential')} V. Flux=${s('photonFlux')} s⁻¹, Isat=${s('saturationCurrent')} A, collection=${s('collectionFraction')} → I=${s('current')} A.',
      8 =>
        'λ=h/p=6.62607015e−34/${s('momentum')}=${s('wavelength')} m; fringe λD/d=${s('fringeSpacing')} m; Fresnel number=${s('fresnelNumber')}. Simulated histogram integral=${s('histogramIntegral')}.',
      9 =>
        '1/λ=RH(1/${1 + mode % 3}²−1/${p('upper')}²); λ=${s('wavelength')} m vacuum; f=${s('frequency')} Hz; photon energy=${s('photonEnergy')} J. ${mode >= 3 ? 'Absorption raises the atom.' : 'Emission lowers the atom.'}',
      10 =>
        'A=Z+N=${s('protons')}+${s('neutrons')}=${s('massNumber')}. Neutral mass=${s('atomicMassU')} u. B=[Z×$hydrogenMassU+N×$neutronMassU−${s('atomicMassU')}] u c²=${s('bindingEnergy')} J; B/A=${s('bindingPerNucleon')} J.',
      _ =>
        'λ=${s('decayConstant')} s⁻¹, N_expected=${s('expectedRemaining')}, A_expected=${s('expectedActivity')} Bq. Realization N=${s('remaining')}; source detections=${s('detectedSourceCounts')}; background=${s('backgroundCounts')}; total=${s('detectorCounts')} simulated counts.',
    };
  }

  List<Widget> formulas() => [
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in instrumentControls())
          ActionChip(
            label: Text(
              '${c.label} · ${c.value.toStringAsPrecision(4)} ${c.unit}',
            ),
            onPressed: () {
              pause();
              setState(() {
                highlightControl = c.keyName;
                section = 1;
              });
            },
          ),
      ],
    ),
    panel([
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Math.tex(
          lesson.formula,
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
      Paragraph('Symbols and units', lesson.symbols),
      Paragraph('Conventions and validity', lesson.limits),
      Paragraph('Worked example', lesson.example),
      Paragraph('Current-value substitution', substitution),
    ]),
    metrics(),
  ];
  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    return [
      Text(
        '${trials.length} actual recorded trials',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      if (trials.isEmpty)
        const Text(
          'No seeded results. Record a valid computed state or simulated dataset in Experiment.',
        ),
      if (trials.isNotEmpty)
        FilledButton.icon(
          onPressed: () => exportTrials(context, trials),
          icon: const Icon(Icons.ios_share),
          label: const Text('Export actual trials as CSV'),
        ),
      for (final t in trials.reversed)
        panel([
          Text(
            '${fmNumber(t.value)} ${t.unit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(t.note),
          Text('${t.model} · ${t.created}'),
          Text(
            'Dataset ${t.configuration['dataset']} · seed ${t.configuration['seed'] ?? 'not stochastic'}',
          ),
          Text('${t.configuration['observationType']}'),
          Text('SI inputs ${t.configuration['parameters']}'),
          TextButton(
            onPressed: () {
              if (restore(t.configuration)) {
                setState(() => section = 1);
                tick.value++;
              } else {
                message('Incompatible record; original body preserved.');
              }
            },
            child: const Text('Reopen configuration'),
          ),
        ]),
    ];
  }
}
