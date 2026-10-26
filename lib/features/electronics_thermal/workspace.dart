import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../workbench/workbench.dart';
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/design_system/reference_style.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/dynamics.dart' show FixedClock;
import '../../core/physics/electronics_thermal.dart';
import '../advanced/scene.dart' show LabPlot;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'curriculum.dart';
import 'scene.dart';

String etNumber(double? n) => n == null || !n.isFinite
    ? '—'
    : n == 0
    ? '0'
    : n.abs() < .001 || n.abs() >= 1e6
    ? n.toStringAsExponential(5)
    : n.toStringAsPrecision(6);

class ETWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const ETWorkspace({super.key, required this.entry});
  @override
  ConsumerState<ETWorkspace> createState() => _ETWorkspaceState();
}

class _ETWorkspaceState extends ConsumerState<ETWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late ETState parameters;
  late ETRun run;
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
      'Scientific edits restart the run. Logic switches preserve timing history.',
  graphMetric = '';
  bool timeGraph = false;
  final attempts = <Map<String, dynamic>>[];
  final processHistory = <Map<String, dynamic>>[];
  Entry get entry => widget.entry;
  double? get result => run.invalid.isEmpty ? run.state[lesson.metric] : null;
  String get unit => kind == 5 && mode == 2 ? 's' : lesson.unit;
  String get quantity => [
    'conductivity',
    'current',
    'current',
    'gain',
    'logicState',
    mode == 2 ? 'time' : 'voltage',
    'temperature',
    'power',
    'pressure',
    'energy',
    'entropy',
    'efficiency',
  ][kind];
  int guided = 0;
  @override
  void initState() {
    super.initState();
    kind = (entry.studioIndex - 12) * 6 + entry.index;
    lesson = etLessons[kind];
    parameters = lesson.defaults;
    run = ETRun(kind, parameters);
    graphMetric = plotKeys.first;
    ticker = createTicker(onFrame);
    store = ref.read(notebookProvider);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r != null) dynamicsRouteObserver.subscribe(this, r);
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
      notice = 'Incompatible session retained; documented defaults shown.';
    }
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
  }

  void onFrame(Duration t) {
    final revision = run.revision;
    clock.advance((t - previous).inMicroseconds / 1e6, () => run.step());
    previous = t;
    if (revision != run.revision) tick.value++;
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
    clock.pause();
    previous = Duration.zero;
    ticker.start();
    setState(() {});
  }

  void reset() {
    pause();
    run = ETRun(kind, parameters, mode: mode);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void update(String key, double value) {
    if (kind == 4) {
      final next = value.roundToDouble();
      if (parameters[key] == next) return;
      try {
        run.setLogicInput(key, next);
      } on ArgumentError catch (e) {
        message(e.message.toString());
        return;
      }
      parameters[key] = next;
      changed = true;
      tick.value++;
      setState(() {});
      return;
    }
    pause();
    parameters[key] = key == 'expanded' ? value.roundToDouble() : value;
    changed = true;
    run = ETRun(kind, parameters, mode: mode);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void chooseMode(int value) {
    pause();
    mode = value;
    run = ETRun(kind, parameters, mode: mode);
    graphMetric = plotKeys.first;
    cursor = 0;
    changed = true;
    setState(() {});
  }

  Map<String, dynamic> configuration() => {
    'model': etVersion,
    'kind': kind,
    'mode': mode,
    'parameters': Map.of(parameters),
    'units': {
      for (final p in lesson.controls) p.key: p.unit,
      lesson.metric: unit,
      't': 's',
    },
    'initial': Map.of(run.initial),
    'events': List.of(run.events),
    'ticks': run.ticks,
    'notes': notes.text,
    'guided': guided,
    'changed': changed,
    'attempts': List.of(attempts),
    'processHistory': List.of(processHistory),
    'labels': labels,
    'overlays': overlays,
    'speed': clock.speed,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != etVersion || data['kind'] != kind) return false;
      final next = <String, double>{}, initial = <String, double>{};
      for (final p in lesson.controls) {
        final x = (data['parameters'][p.key] as num).toDouble(),
            a = ((data['initial'] ?? data['parameters'])[p.key] as num)
                .toDouble();
        if (!x.isFinite ||
            x < p.min ||
            x > p.max ||
            !a.isFinite ||
            a < p.min ||
            a > p.max) {
          return false;
        }
        next[p.key] = x;
        initial[p.key] = a;
      }
      final m = data['mode'] as int, count = data['ticks'] as int;
      if (m < 0 || m >= etModes[kind].length || count < 0 || count > 15000) {
        return false;
      }
      final events = (data['events'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (events.length > 200) return false;
      final candidate = ETRun(kind, initial, mode: m);
      candidate.seek(
        count * ETRun.dt * candidate.timeScale,
        inputEvents: events,
      );
      if (kind == 4 &&
          (candidate.p['inputA'] != next['inputA'] ||
              candidate.p['inputB'] != next['inputB'])) {
        return false;
      }
      ticker.stop();
      clock.pause();
      parameters = next;
      mode = m;
      run = candidate;
      notes.text = data['notes'] ?? '';
      guided = data['guided'] is int ? (data['guided'] as int).clamp(0, 3) : 0;
      changed = data['changed'] == true;
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? []).map(
            (e) => Map<String, dynamic>.from(e),
          ),
        );
      processHistory
        ..clear()
        ..addAll(
          (data['processHistory'] as List? ?? [])
              .take(20)
              .map((e) => Map<String, dynamic>.from(e)),
        );
      labels = data['labels'] != false;
      overlays = data['overlays'] != false;
      clock.speed = ((data['speed'] as num?)?.toDouble() ?? 1).clamp(.25, 2);
      graphMetric = plotKeys.first;
      notice = 'Original inputs and event history restored; playback paused.';
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() async {
    if (ready) await store.saveSession(entry.id, configuration());
  }

  void message(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  Future<void> save() async {
    pause();
    await persist();
    message('Session saved. Reopens paused.');
  }

  Future<void> record() async {
    pause();
    if (busy || result == null || !result!.isFinite) return;
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
            ..['observations'] = run.samples
            ..['currentState'] = run.state
            ..['profile'] = run.profile,
          note: notes.text,
          model: etVersion,
        ),
      );
      await persist();
      message('Actual computed observation recorded.');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit(double answer) async {
    if (result == null) return;
    final correct =
        (answer - result!).abs() <= math.max(result!.abs() * .02, 1e-30);
    final a = <String, dynamic>{
      'answer': answer,
      'target': result,
      'correct': correct,
      'time': run.time,
      'mode': mode,
      'parameters': Map.of(parameters),
    };
    attempts.add(a);
    if (attempts.length > 50) attempts.removeAt(0);
    await store.recordAttempt(entry.id, a);
    if (mounted) {
      setState(
        () => feedback =
            '${correct ? 'Correct' : 'Reconsider'}: ${etNumber(result)} $unit. ${lesson.mistake}',
      );
    }
    await persist();
  }

  Future<void> predict() async {
    pause();
    if (result == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: 'Predict ${lesson.metric} ($unit)',
        initial: 0,
        min: -1e30,
        max: 1e30,
        onApply: submit,
      ),
    );
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

  List<InstrumentControl> instrumentControls() => [
    for (final p in etControls(kind, mode))
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
    final data = timeGraph ? run.samples : run.profile;
    final keys = timeGraph
        ? (kind == 2
              ? ['collectorCurrent']
              : kind == 7
              ? ['heatRate']
              : plotKeys)
        : plotKeys;
    return LabPlot(data, keys, xLabel, plotUnit, cursor);
  }

  String? highlightControl;
  @override
  Widget build(BuildContext context) {
    if (ready && (section == 1 || section == 2 || section == 4)) {
      return InstrumentShell(
        key: ValueKey('instrument-${entry.id}'),
        referenceChart: referencePlot,
        toolbarActions: [
          if (kind == 7)
            IconButton(
              tooltip: 'Thermal material library',
              icon: const Icon(Icons.category_outlined),
              onPressed: () async {
                pause();
                await persist();
                if (context.mounted) context.push('/lab/${entry.id}/bench');
              },
            ),
        ],
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
            for (int i = 0; i < etModes[kind].length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(etModes[kind][i], overflow: TextOverflow.ellipsis),
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
  Widget panel(List<Widget> children) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
  List<Widget> learn() => [
    relatedLabs(entry.id),
    panel([
      Paragraph('Apparatus', lesson.apparatus),
      Paragraph('Principle', lesson.principle),
      Paragraph('Procedure', lesson.procedure),
      Paragraph('Validity and numerical method', lesson.limits),
      Paragraph('Common misconception', lesson.mistake),
    ]),
    investigation(),
  ];
  Widget investigation() {
    final eligible =
        changed &&
        attempts.any((a) => a['correct'] == true) &&
        store.trials.any((t) => t.labId == entry.id);
    return panel([
      const Eyebrow('Guided investigation'),
      Text(lesson.question),
      const Text(
        '1. Predict  2. Change one input  3. Record  4. Explain the limitation in notes.',
      ),
      FilledButton(onPressed: predict, child: const Text('Make a prediction')),
      Text(feedback),
      FilledButton(
        onPressed: eligible && notes.text.trim().isNotEmpty
            ? () async {
                await store.complete(entry.id);
                message('Investigation completed from your activity.');
              }
            : null,
        child: const Text('Complete investigation'),
      ),
      if (!eligible)
        const Text(
          'Requires an input change, a correct prediction and an actual recorded trial.',
        ),
    ]);
  }

  Widget compactScene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, b) => GestureDetector(
            onHorizontalDragUpdate: (e) {
              final controls = etControls(kind, mode);
              if (controls.isEmpty) return;
              final p = controls.first;
              update(
                p.key,
                (parameters[p.key]! + e.delta.dx / b.maxWidth * (p.max - p.min))
                    .clamp(p.min, p.max),
              );
            },
            child: SizedBox(
              width: b.maxWidth,
              height: b.maxWidth * .75,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: ETBackdrop(electronics: kind < 6),
                      isComplex: true,
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: ETPainter(
                        run,
                        labels: labels,
                        overlays: overlays,
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
          '${entry.title}. ${etModes[kind][mode]}. ${lesson.metric} ${etNumber(result)} $unit. ${run.invalid}',
      child: panel([
        Text(
          '${lesson.metric}: ${etNumber(result)} $unit',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (run.invalid.isNotEmpty)
          Text(run.invalid, style: const TextStyle(color: Colors.red)),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, b) => GestureDetector(
              onHorizontalDragUpdate: (e) {
                final controls = etControls(kind, mode);
                if (controls.isEmpty) return;
                final p = controls.first;
                update(
                  p.key,
                  (parameters[p.key]! +
                          e.delta.dx / b.maxWidth * (p.max - p.min))
                      .clamp(p.min, p.max),
                );
              },
              child: SizedBox(
                width: b.maxWidth,
                height: b.maxWidth * .75,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ETBackdrop(electronics: kind < 6),
                        isComplex: true,
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: ETPainter(
                          run,
                          labels: labels,
                          overlays: overlays,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Text(
          'Drag horizontally adjusts ${etControls(kind, mode).first.label.toLowerCase()}; numeric and slider alternatives below.',
        ),
        Wrap(
          children: [
            FilterChip(
              label: const Text('Labels'),
              selected: labels,
              onSelected: (v) => setState(() => labels = v),
            ),
            FilterChip(
              label: const Text('Overlays'),
              selected: overlays,
              onSelected: (v) => setState(() => overlays = v),
            ),
          ],
        ),
      ]),
    ),
  );
  Widget metrics() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) => panel([
      Text(
        '${lesson.metric}: ${etNumber(result)} $unit',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (run.invalid.isNotEmpty)
        Text(run.invalid, style: const TextStyle(color: Colors.red)),
      if (run.invalid.isEmpty) ...[
        Text('Physical time ${etNumber(run.time)} s'),
        for (final e in run.state.entries.where((e) => e.key != 't'))
          Text('${e.key}: ${etNumber(e.value)} ${stateUnit(e.key)}'),
      ],
    ]),
  );
  String stateUnit(String key) {
    const units = {
      'neutrality': 'm⁻³',
      'massAction': 'm⁻⁶',
      'mobilityN': 'm²/(V s)',
      'mobilityP': 'm²/(V s)',
      'fermiOffset': 'J',
      'bandGap': 'J',
      'kvlError': 'V',
      'diodePower': 'W',
      'collectorPower': 'W',
      'swingLimit': 'V',
      'unclippedOutput': 'V',
      'ldrResistance': 'Ω',
      'effectiveLux': 'lx',
      'roundTripTime': 's',
      'soundSpeed': 'm/s',
      'echoDistance': 'm',
      'temperatureC': '°C',
      'celsius': '°C',
      'fahrenheit': '°F',
      'gradient': 'K/m',
      'tau': 's',
      'initialPressure': 'Pa',
      'initialVolume': 'm³',
    };
    if (units.containsKey(key)) return units[key]!;
    if (['electrons', 'holes', 'ni', 'donors', 'acceptors'].contains(key)) {
      return 'm⁻³';
    }
    if (key.toLowerCase().contains('current')) return 'A';
    if (key.toLowerCase().contains('voltage') ||
        [
          'inputVoltage',
          'outputVoltage',
          'raw',
          'limit',
          'vce',
        ].contains(key)) {
      return 'V';
    }
    if (key.toLowerCase().contains('temperature') || key == 'equilibriumT') {
      return 'K';
    }
    if (key.toLowerCase().contains('entropy')) return 'J/K';
    if ([
      'heat',
      'heatOut',
      'work',
      'deltaU',
      'energyResidual',
      'stageWork',
      'stageHeat',
      'hotHeatReference',
      'coldHeatReference',
      'netWorkReference',
    ].contains(key)) {
      return 'J';
    }
    if (key == 'pressure') return 'Pa';
    if (key == 'volume' || RegExp(r'^v[1234]$').hasMatch(key)) return 'm³';
    if (key == 'heatRate') return 'W';
    if (key == 'conductivity') return 'S/m';
    if (key == 'sensorOutput') return unit;
    return '';
  }

  Widget control(Parameter p) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text('${p.label}: ${etNumber(parameters[p.key])} ${p.unit}'),
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
        divisions: ['inputA', 'inputB', 'expanded'].contains(p.key) ? 1 : null,
        onChanged: (v) => update(p.key, v),
      ),
    ],
  );
  List<Widget> experiment() => [
    scene(),
    DropdownButtonFormField<int>(
      isExpanded: true,
      key: ValueKey('$kind:$mode'),
      initialValue: mode,
      decoration: const InputDecoration(labelText: 'Model / process'),
      items: [
        for (int i = 0; i < etModes[kind].length; i++)
          DropdownMenuItem(value: i, child: Text(etModes[kind][i])),
      ],
      onChanged: (v) {
        if (v != null) chooseMode(v);
      },
    ),
    panel([
      Wrap(
        spacing: 8,
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
            onPressed: run.dynamicLab
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
            onPressed: () {
              pause();
              mode = 0;
              parameters = lesson.defaults;
              run = ETRun(kind, parameters);
              changed = false;
              graphMetric = plotKeys.first;
              setState(() {});
            },
            child: const Text('Restore defaults'),
          ),
        ],
      ),
      Text(notice),
      if (run.dynamicLab)
        Text(
          'Physical seconds per playback second: ${etNumber(run.timeScale * clock.speed)}. Speed does not alter the model.',
        ),
      if (run.dynamicLab)
        DropdownButton<double>(
          isExpanded: true,
          value: clock.speed,
          items: [
            for (final x in [.25, .5, 1.0, 2.0])
              DropdownMenuItem(value: x, child: Text('$x× playback')),
          ],
          onChanged: (x) {
            if (x != null) {
              pause();
              setState(() => clock.speed = x);
            }
          },
        ),
      for (final p in etControls(kind, mode)) control(p),
    ]),
    metrics(),
    if (kind == 9)
      panel([
        const Eyebrow('Process history · current-state ledger'),
        OutlinedButton(
          onPressed: run.invalid.isEmpty
              ? () {
                  pause();
                  processHistory.add({
                    'mode': etModes[kind][mode],
                    'parameters': Map.of(parameters),
                    'state': Map.of(run.state),
                  });
                  if (processHistory.length > 20) processHistory.removeAt(0);
                  setState(() {});
                  persist();
                }
              : null,
          child: const Text('Append current process state'),
        ),
        for (final item in processHistory)
          Text(
            '${item['mode']}: Q=${etNumber((item['state']['heat'] as num).toDouble())} J, W=${etNumber((item['state']['work'] as num).toDouble())} J, ΔU=${etNumber((item['state']['deltaU'] as num).toDouble())} J',
          ),
        const Text(
          'Latest 20 states retained with their SI inputs. Recorded trials provide full replay and CSV export.',
        ),
      ]),
    if (kind == 4) truthTable(),
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
  Widget truthTable() => panel([
    const Eyebrow('Truth table • active input row highlighted'),
    for (int i = 0; i < 4; i++)
      Builder(
        builder: (_) {
          final a = i ~/ 2,
              b = i % 2,
              y = logicGate(mode, a > 0, b > 0) ? 1 : 0,
              active =
                  parameters['inputA'] == a &&
                  (mode == 2 || parameters['inputB'] == b);
          return Container(
            color: active ? Colors.teal.withValues(alpha: .15) : null,
            padding: const EdgeInsets.all(8),
            child: Text(
              'A=$a  ${mode == 2 ? 'B ignored' : 'B=$b'}  →  Y=$y ${active ? '◀ current' : ''}',
            ),
          );
        },
      ),
  ]);
  List<String> get plotKeys => switch (kind) {
    0 => ['conductivity'],
    1 => ['current'],
    2 => ['characteristic', 'loadLine'],
    3 => ['inputVoltage', 'outputVoltage'],
    4 => ['inputA', 'inputB', 'logicOutput'],
    5 => ['sensorOutput'],
    6 => ['sampleTemperature', 'probeTemperature'],
    7 => [
      mode == 0
          ? 'probeTemperature'
          : mode == 1
          ? 'temperature'
          : 'heatRate',
    ],
    8 || 9 || 11 => ['pressure'],
    _ => [mode == 2 ? 'entropy' : 'entropy'],
  };
  String get plotUnit => switch (kind) {
    0 => 'S/m',
    1 || 2 => 'A',
    3 => 'V',
    4 => '',
    5 => unit,
    6 => 'K',
    7 => mode == 2 || timeGraph ? 'W' : 'K',
    8 || 9 || 11 => 'Pa',
    _ => 'J/K',
  };
  String get xLabel => timeGraph
      ? 'Physical time (s)'
      : switch (kind) {
          0 => 'Temperature (K)',
          1 => 'Supply (V)',
          2 => 'Vce (V)',
          3 => 'Time (s)',
          4 => 'Truth row',
          5 => ['Temperature (K)', 'Illuminance (lx)', 'Distance (m)'][mode],
          6 => 'Time (s)',
          7 =>
            mode == 0
                ? 'Position (m)'
                : mode == 1
                ? 'Time (s)'
                : 'Body temperature (K)',
          8 || 9 || 11 => 'Volume (m³)',
          _ => mode == 2 ? 'Time (s)' : 'Reference fraction / expansion ratio',
        };
  List<Widget> visualize() => [
    scene(),
    panel([
      SwitchListTile(
        title: const Text('Recorded time history'),
        value: timeGraph,
        onChanged: (v) => setState(() {
          timeGraph = v;
          cursor = 0;
        }),
      ),
      Text(xLabel),
      ListenableBuilder(
        listenable: tick,
        builder: (context, _) {
          final data = timeGraph ? run.samples : run.profile;
          final keys = timeGraph
              ? (kind == 2
                    ? ['collectorCurrent']
                    : kind == 7
                    ? ['heatRate']
                    : plotKeys)
              : plotKeys;
          return Column(
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
                        data,
                        keys,
                        xLabel,
                        plotUnit,
                        cursor.clamp(0, math.max(0, data.length - 1)),
                      ),
                    ),
                  ),
                ),
              ),
              Text('Legend: ${keys.join(', ')}. Pinch to zoom; drag to pan.'),
              TextButton(
                onPressed: () => graphView.value = Matrix4.identity(),
                child: const Text('Reset graph view'),
              ),
              if (data.isNotEmpty) ...[
                Slider(
                  value: cursor.clamp(0, data.length - 1).toDouble(),
                  max: math.max(1, data.length - 1).toDouble(),
                  onChanged: (v) => setState(() => cursor = v.round()),
                ),
                Text(
                  'Cursor: ${data[cursor.clamp(0, data.length - 1)].entries.map((e) => '${e.key}=${etNumber(e.value)}').join('; ')}',
                ),
              ],
            ],
          );
        },
      ),
      if (run.dynamicLab) ...[
        const Text(
          'Replay to selected physical time. Logic history branches here; future events are discarded.',
        ),
        Slider(
          key: const Key('replay-time'),
          value: run.time.clamp(0, run.maxTime),
          max: run.maxTime,
          onChanged: (t) {
            pause();
            final events = run.events
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            run = ETRun(kind, run.initial, mode: mode)
              ..seek(t, inputEvents: events);
            parameters = Map.of(run.p);
            cursor = 0;
            tick.value++;
            setState(() {});
          },
        ),
      ],
    ]),
    if (kind == 1)
      panel([
        const Text(
          'Intrinsic junction curve and resistor load line; their intersection is the actual operating point.',
        ),
        SizedBox(
          height: 220,
          child: CustomPaint(
            size: const Size(double.infinity, 220),
            painter: LabPlot(
              run.alternate,
              ['current', 'loadLine'],
              'Diode voltage (V)',
              'A',
              0,
            ),
          ),
        ),
      ]),
    if (kind == 4) truthTable(),
    metrics(),
  ];
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
          kind == 4
              ? [
                  r'Y=A\land B',
                  r'Y=A\lor B',
                  r'Y=\neg A',
                  r'Y=\neg(A\land B)',
                  r'Y=\neg(A\lor B)',
                  r'Y=A\oplus B',
                  r'Y=\neg(A\oplus B)',
                ][mode]
              : lesson.formula,
          textStyle: const TextStyle(fontSize: 18),
        ),
      ),
      Paragraph('Symbols and units', lesson.symbols),
      Paragraph('Worked example', lesson.example),
      Paragraph('Calculated equation at this state', substitution),
      Paragraph(
        'Current substitution',
        '${parameters.entries.map((e) => '${e.key}=${etNumber(e.value)}').join('; ')}. Model ${etModes[kind][mode]}, physical time ${etNumber(run.time)} s. Computed ${lesson.metric}=${etNumber(result)} $unit. See the actual state ledger below for intermediate values.',
      ),
      Paragraph('Assumptions and validity', lesson.limits),
    ]),
    metrics(),
  ];
  String get substitution {
    if (run.invalid.isNotEmpty) return 'No substitution: ${run.invalid}';
    String s(String key) => etNumber(run.state[key]);
    String p(String key) => etNumber(parameters[key]);
    return switch (kind) {
      0 =>
        'σ = 1.602176634e−19 × (${s('electrons')} × ${s('mobilityN')} + ${s('holes')} × ${s('mobilityP')}) = ${s('conductivity')} S/m. np=${s('massAction')} m⁻⁶.',
      1 =>
        'Vs=${p('supply')} = VD (${s('diodeVoltage')}) + I (${s('current')}) × R (${p('resistance')}) V. KVL residual ${s('kvlError')} V; ${s('iterations')} bisection iterations.',
      2 =>
        'Ie = Ib + Ic = ${s('baseCurrent')} + ${s('collectorCurrent')} = ${s('emitterCurrent')} A. Vcc = Vce + Rc Ic = ${s('vce')} + ${p('collectorResistance')} × ${s('collectorCurrent')} V.',
      3 =>
        'Gain=${s('gain')}; Vin=${s('inputVoltage')} V; requested output=${s('unclippedOutput')} V. Clip to ±${s('swingLimit')} V gives ${s('outputVoltage')} V.',
      4 =>
        '${etModes[kind][mode]}: A=${s('inputA')}, ${mode == 2 ? 'B ignored' : 'B=${s('inputB')}'} → Y=${s('logicOutput')}.',
      5 =>
        mode == 0
            ? 'V=.5+.01×${s('temperatureC')} = ${s('sensorOutput')} V.'
            : mode == 1
            ? 'V=3.3×10000/(10000+${s('ldrResistance')}) = ${s('sensorOutput')} V; saturation flag ${s('saturated')}.'
            : 't=2×${p('distance')}/${s('soundSpeed')} = ${s('roundTripTime')} s; d=ct/2=${s('echoDistance')} m.',
      6 =>
        'Probe ${s('probeTemperature')} K = ${s('celsius')} °C = ${s('fahrenheit')} °F. Sample ${s('sampleTemperature')} K; probe τ=${p('probeTau')} s. ${mode == 1 ? 'Sample ΔU=${s('deltaU')} J; heat out=${s('heatOut')} J.' : 'Fixed sample is a reservoir; probe thermal loading neglected.'}',
      7 =>
        mode == 0
            ? 'Q̇=${p('conductivity')}×${p('area')}×(${p('leftT')}−${p('rightT')})/${p('length')} = ${s('heatRate')} W.'
            : mode == 1
            ? 'Q̇=${p('h')}×${p('surface')}×(${s('temperature')}−${p('ambientT')}) = ${s('heatRate')} W. Bi=${s('biot')}; ΔU+Qout=${s('energyResidual')} J.'
            : 'Q̇=${p('emissivity')}×5.670374419e−8×${p('surface')}×(${s('temperature')}⁴−${p('ambientT')}⁴) = ${s('heatRate')} W. ΔU+Qout=${s('energyResidual')} J.',
      8 =>
        'P V = ${s('pressure')} × ${s('volume')} = n R T = ${p('amount')} × $gasConstant × ${s('temperature')} J. Work ${s('work')} J; heat ${s('heat')} J.',
      9 =>
        'ΔU = Q−W = ${s('heat')} − (${s('work')}) = ${s('deltaU')} J. Conservation residual ${s('energyResidual')} J.',
      10 =>
        mode == 2
            ? 'ΔS1+ΔS2 = ${s('entropy1')} + ${s('entropy2')} = ${s('entropy')} J/K. Tf=${s('equilibriumTemperature')} K; total energy residual ${s('energyResidual')} J.'
            : 'ΔS=${s('entropy')} J/K at T=${s('temperature')} K, V=${s('volume')} m³. ${mode == 1 ? 'Free expansion: Q=W=ΔU=0.' : 'State-function reference path.'}',
      _ =>
        'η=1−${p('coldT')}/${p('hotT')} = ${s('efficiency')}. Full-cycle Qh=${s('hotHeatReference')} J, Qc=${s('coldHeatReference')} J, Wnet=${s('netWorkReference')} J. Current Q−W−ΔU residual ${s('energyResidual')} J.',
    };
  }

  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    return [
      Text(
        '${trials.length} actual recorded observations',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      if (trials.isEmpty)
        const Text(
          'Record a valid state in Experiment. No seeded observations.',
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
            '${etNumber(t.value)} ${t.unit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(t.note),
          Text('${t.model} · ${t.created}'),
          Text('SI inputs ${t.configuration['parameters']}'),
          TextButton(
            onPressed: () {
              if (restore(t.configuration)) {
                setState(() => section = 1);
                tick.value++;
              } else {
                message(
                  'Incompatible configuration; original record retained.',
                );
              }
            },
            child: const Text('Reopen configuration'),
          ),
        ]),
    ];
  }
}
