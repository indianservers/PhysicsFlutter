import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/dynamics.dart' show FixedClock;
import '../../core/physics/electromagnetism.dart';
import '../advanced/scene.dart' show LabPlot;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'curriculum.dart';
import 'scene.dart';

class EMWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const EMWorkspace({super.key, required this.entry});
  @override
  ConsumerState<EMWorkspace> createState() => _EMWorkspaceState();
}

class _EMWorkspaceState extends ConsumerState<EMWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late EMState parameters;
  late EMRun run;
  late final LocalNotebook store;
  late final Ticker ticker;
  CircuitGraph circuit = CircuitGraph.example(0);
  final clock = FixedClock(),
      tick = ValueNotifier(0),
      notes = TextEditingController(),
      view = TransformationController(),
      graphView = TransformationController();
  int section = 0, mode = 0, cursor = 0, guided = 0;
  bool ready = false,
      labels = true,
      overlays = true,
      fieldLines = true,
      electrons = true,
      changed = false,
      busy = false;
  Duration previous = Duration.zero;
  String
  feedback = '',
  notice =
      'Input edits restart the run; camera and overlays preserve physical state.',
  graphMetric = '',
  graphMode = 'profile';
  double azimuth = .6, elevation = .4;
  double? heldCharge;
  String selected = 'R1',
      newType = 'resistor',
      terminalA = 'B1:a',
      terminalB = 'R1:a';
  final attempts = <Map<String, dynamic>>[];
  Entry get entry => widget.entry;
  double? get result => run.invalid.isEmpty ? run.state[lesson.metric] : null;
  bool get playing => ticker.isActive;
  @override
  void initState() {
    super.initState();
    kind = (entry.studioIndex - 10) * 6 + entry.index;
    lesson = emLessons[kind];
    parameters = lesson.defaults;
    store = ref.read(notebookProvider);
    run = makeRun();
    graphMetric = lesson.metric;
    if (kind == 7) graphMode = 'time';
    ticker = createTicker(onFrame);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  EMRun makeRun({EMRun? reuse}) => EMRun(
    kind,
    parameters,
    mode: mode,
    graph: circuit,
    heldCharge: heldCharge,
    geometryFrom: reuse,
  );
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
    if (saved != null && !restore(saved)) notice = 'Incompatible session: original records retained, documented defaults shown.';
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
  }

  void onFrame(Duration elapsed) {
    final delta = (elapsed - previous).inMicroseconds / 1e6;
    previous = elapsed;
    final revision = run.revision;
    clock.advance(delta, () => run.step());
    if (revision != run.revision) {
      cursor = math.max(0, graphData.length - 1);
      tick.value++;
    }
    if (run.finished || run.invalid.isNotEmpty) pause();
  }

  void pause() {
    ticker.stop();
    clock.pause();
    if (run.dynamicLab) run.refresh();
    if (mounted) setState(() {});
  }

  void play() {
    if (!run.dynamicLab || run.invalid.isNotEmpty) return;
    if (run.finished) resetTime();
    previous = Duration.zero;
    clock.pause();
    ticker.start();
    setState(() {});
  }

  void resetTime() {
    pause();
    run = makeRun();
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void defaults() {
    pause();
    mode = 0;
    heldCharge = null;
    parameters = lesson.defaults;
    circuit = CircuitGraph.example(0);
    selected = 'R1';
    run = makeRun();
    graphMetric = lesson.metric;
    graphMode = kind == 7 ? 'time' : 'profile';
    cursor = 0;
    changed = true;
    notice = 'Documented defaults restored. Earlier trial records retained.';
    tick.value++;
    setState(() {});
  }

  void restart({EMRun? reuse}) {
    pause();
    run = makeRun(reuse: reuse);
    cursor = 0;
    changed = true;
    notice = 'Scientific input/topology changed: time/history restarted; earlier records retained.';
    tick.value++;
    setState(() {});
  }

  void updateMany(Map<String, double> values) {
    pause();
    if (kind == 5 && mode == 1) heldCharge = run.state['charge'] ?? heldCharge;
    for (final e in values.entries) {
      final p = lesson.controls.firstWhere((p) => p.key == e.key);
      parameters[e.key] = e.value.clamp(p.min, p.max);
    }
    for (final key in ['turns', 'count', 'closed']) {
      if (parameters.containsKey(key)) {
        parameters[key] = parameters[key]!.roundToDouble();
      }
    }
    restart(
      reuse:
          values.keys.every(
            (k) => ['probeX', 'probeY', 'testCharge'].contains(k),
          )
          ? run
          : null,
    );
  }

  void chooseMode(int value) {
    pause();
    if (kind == 5) {
      if (value == 1 && mode < 2) {
        heldCharge = run.state['charge'] ?? heldCharge;
      }
      if (value >= 2 && mode >= 2) {
        parameters['initialV'] =
            run.state['voltage'] ?? parameters['initialV']!;
      }
    }
    mode = value;
    if (!graphOptions.contains(graphMetric)) graphMetric = graphOptions.first;
    restart();
  }

  Map<String, dynamic> configuration() => {
    'model': emVersion,
    'kind': kind,
    'mode': mode,
    'parameters': parameters,
    'units': {for (final p in lesson.controls) p.key: p.unit},
    'ticks': run.ticks,
    'heldCharge': heldCharge ?? run.heldCharge,
    'circuit': circuit.toJson(),
    'notes': notes.text,
    'guided': guided,
    'attempts': attempts,
    'changed': changed,
    'feedback': feedback,
    'labels': labels,
    'overlays': overlays,
    'fieldLines': fieldLines,
    'electrons': electrons,
    'azimuth': azimuth,
    'elevation': elevation,
    'graphMode': graphMode,
    'graphMetric': graphMetric,
    'speed': clock.speed,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != emVersion || data['kind'] != kind) return false;
      final raw = data['parameters'] as Map, next = <String, double>{};
      for (final p in lesson.controls) {
        final x = (raw[p.key] as num).toDouble();
        if (!x.isFinite || x < p.min || x > p.max) return false;
        next[p.key] = x;
      }
      final m = data['mode'] as int, count = data['ticks'] as int;
      if (m < 0 ||
          m >
              (kind == 5
                  ? 3
                  : kind == 11
                  ? 1
                  : 0) ||
          count < 0 ||
          count > 15000) {
        return false;
      }
      final graph = CircuitGraph.fromJson(data['circuit']),
          charge = (data['heldCharge'] as num?)?.toDouble();
      if (charge != null && !charge.isFinite) return false;
      final candidate =
          EMRun(kind, next, mode: m, graph: graph, heldCharge: charge)..seek(
            count *
                EMRun.dt *
                (kind == 7
                    ? 1e-6
                    : kind == 5 && m >= 2
                    ? next['resistance']! * next['capacitance']!
                    : 1),
          );
      pause();
      parameters = next;
      mode = m;
      circuit = graph;
      heldCharge = charge;
      run = candidate;
      notes.text = data['notes'] ?? '';
      guided = (data['guided'] as int? ?? 0).clamp(0, 2);
      changed = data['changed'] == true;
      feedback = data['feedback'] ?? '';
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? []).whereType<Map>().map(
            (x) => Map<String, dynamic>.from(x),
          ),
        );
      labels = data['labels'] != false;
      overlays = data['overlays'] != false;
      fieldLines = data['fieldLines'] != false;
      electrons = data['electrons'] != false;
      azimuth = ((data['azimuth'] as num?)?.toDouble() ?? .6).clamp(
        -math.pi,
        math.pi,
      );
      elevation = ((data['elevation'] as num?)?.toDouble() ?? .4).clamp(
        -1.2,
        1.2,
      );
      graphMode = kind == 7
          ? 'time'
          : data['graphMode'] == 'time'
          ? 'time'
          : data['graphMode'] == 'charge'
          ? 'charge'
          : 'profile';
      graphMetric = data['graphMetric'] ?? lesson.metric;
      clock.speed = ((data['speed'] as num?)?.toDouble() ?? 1).clamp(.25, 2);
      selected = circuit.parts.firstOrNull?.id ?? '';
      cursor = 0;
      notice = 'Original SI parameters, topology and initial conditions restored; playback paused.';
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
    message(
      'Session saved, including topology and initial conditions. Reopens paused.',
    );
  }

  String get quantity => switch (lesson.unit) {
    'N' => 'force',
    'N/C' => 'electricField',
    'V' => 'voltage',
    'A' => 'current',
    'F' => 'capacitance',
    'T' => 'magneticField',
    _ => 'energy',
  };
  Future<void> record() async {
    pause();
    if (busy || result == null || !result!.isFinite) {
      message('A valid defined scientific observation is required.');
      return;
    }
    setState(() => busy = true);
    try {
      await store.addTrial(
        Trial(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          labId: entry.id,
          quantity: quantity,
          unit: lesson.unit,
          value: result!,
          resolution: null,
          configuration: configuration()
            ..['observations'] = run.samples
            ..['currentState'] = run.state
            ..['profile'] = run.profile
            ..['branchCurrents'] = run.network?.currents
            ..['nodeVoltages'] = run.network?.nodes,
          note: notes.text,
          model: emVersion,
        ),
      );
      await persist();
      if (store.haptics) HapticFeedback.lightImpact();
      message('Actual ${lesson.metric} and full configuration recorded.');
    } catch (_) {
      message('Observation could not be saved.');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> submit(double answer) async {
    if (result == null) return;
    final target = result!,
        tolerance = math.max(target.abs() * .02, 1e-30),
        correct = (answer - target).abs() <= tolerance;
    final a = <String, dynamic>{
      'answer': answer,
      'target': target,
      'tolerance': tolerance,
      'correct': correct,
      'parameters': Map.of(parameters),
      'topology': kind == 4 ? circuit.toJson() : null,
      'mode': mode,
      'time': run.time,
    };
    attempts.add(a);
    if (attempts.length > 50) attempts.removeAt(0);
    await store.recordAttempt(entry.id, a);
    if (mounted) {
      setState(
        () => feedback =
            '${correct ? 'Correct' : 'Reconsider'} · reference ${emNumber(target)} ${lesson.unit}. ${lesson.mistake}',
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
        label: 'Predict ${lesson.metric} (${lesson.unit})',
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
    view.dispose();
    graphView.dispose();
    tick.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(entry.title),
      actions: [
        IconButton(
          tooltip: 'Save session',
          onPressed: save,
          icon: const Icon(Icons.bookmark_add_outlined),
        ),
      ],
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: section,
      onDestinationSelected: (s) {
        pause();
        setState(() => section = s);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.menu_book_outlined),
          label: 'Learn',
        ),
        NavigationDestination(
          icon: Icon(Icons.science_outlined),
          label: 'Experiment',
        ),
        NavigationDestination(
          icon: Icon(Icons.insights_outlined),
          label: 'Visualize',
        ),
        NavigationDestination(icon: Icon(Icons.functions), label: 'Formulas'),
        NavigationDestination(
          icon: Icon(Icons.assignment_outlined),
          label: 'Results',
        ),
      ],
    ),
    body: SafeArea(
      child: !ready
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              scrollId: '${entry.id}:$section',
              children: [
                Eyebrow('${studios[entry.studioIndex].title} · Phase 5 of 9'),
                const SizedBox(height: 12),
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
    Text(entry.title, style: Theme.of(context).textTheme.headlineLarge),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Paragraph(
            'Objectives',
            'Explore ${entry.title.toLowerCase()}, predict ${lesson.metric}, compare actual computed data and explain at least one model limitation.',
          ),
          Paragraph('Apparatus', lesson.apparatus),
          Paragraph('Principles', lesson.principle),
          Paragraph('Procedure', lesson.procedure),
          Paragraph('Assumptions and validity', lesson.limits),
          Paragraph('Common misconception', lesson.mistake),
        ],
      ),
    ),
    investigation(),
  ];
  Widget scene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final painter = EMPainter(
        run,
        labels: labels,
        overlays: overlays,
        fieldLines: fieldLines,
        electrons: electrons,
        azimuth: azimuth,
        elevation: elevation,
        selected: selected,
      );
      return Panel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 4, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Eyebrow('Computed apparatus · drag / pinch'),
                  ),
                  IconButton(
                    tooltip: 'Reset scene zoom',
                    onPressed: () => view.value = Matrix4.identity(),
                    icon: const Icon(Icons.fit_screen),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (context, box) => Semantics(
                label: painter.accessibleSummary,
                child: InteractiveViewer(
                  transformationController: view,
                  minScale: 1,
                  maxScale: 4,
                  child: GestureDetector(
                    onTapUp: kind == 4
                        ? (e) {
                            final point =
                                e.localPosition / (box.maxWidth / 360);
                            if (circuit.parts.isNotEmpty) {
                              final parts = List<CircuitPart>.of(circuit.parts)
                                ..sort(
                                  (a, b) =>
                                      ((painter.terminal(a, true) +
                                                      painter.terminal(
                                                        a,
                                                        false,
                                                      )) /
                                                  2 -
                                              point)
                                          .distance
                                          .compareTo(
                                            ((painter.terminal(b, true) +
                                                            painter.terminal(
                                                              b,
                                                              false,
                                                            )) /
                                                        2 -
                                                    point)
                                                .distance,
                                          ),
                                );
                              setState(() => selected = parts.first.id);
                              tick.value++;
                            }
                          }
                        : null,
                    onPanUpdate: (e) {
                      final point = e.localPosition / (box.maxWidth / 360);
                      if (kind == 4) {
                        final p = circuit.parts
                            .where((p) => p.id == selected)
                            .firstOrNull;
                        if (p != null) {
                          p.x = ((point.dx - 28) / 304).clamp(.08, .92);
                          p.y = ((point.dy - 52) / 165).clamp(.08, .92);
                          syncLayout(p);
                          changed = true;
                          tick.value++;
                        }
                      } else if (kind == 7) {
                        setState(
                          () => azimuth = (azimuth + e.delta.dx * .01).clamp(
                            -math.pi,
                            math.pi,
                          ),
                        );
                        tick.value++;
                      } else if ([1, 2, 6, 8].contains(kind)) {
                        final w = painter.inverse(point);
                        updateMany({'probeX': w.x, 'probeY': w.y});
                      } else if (kind == 0) {
                        updateMany({
                          'distance':
                              (point.dx - 180).abs() * 2 / painter.coulombScale,
                        });
                      } else if (kind == 9) {
                        updateMany({
                          'probe': (point.dx - 180) / painter.solenoidScale,
                        });
                      } else if (kind == 10) {
                        updateMany({'initialZ': (145 - point.dy) / 260});
                      } else if (kind == 5 && mode < 2) {
                        updateMany({
                          'gap': ((point.dx - 203).abs() * 2 - 12) / 12000,
                        });
                      } else if (kind == 11) {
                        updateMany({'gap': (point.dy - 197 - 8) / 1200});
                      }
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(box.maxWidth, box.maxWidth * 280 / 360),
                        painter: painter,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                kind == 4
                    ? 'Tap to select; drag selected part to move its layout. Wire terminals below to change the real graph.'
                    : kind == 7
                    ? 'Drag rotates the 3-D camera; numeric initial velocity and field control the physical trajectory.'
                    : 'Drag the distance/probe/gap/source where applicable. Numeric alternatives below; overlays show scientific representations.',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget metrics() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Actual scientific state'),
          Text(
            '${emLabel(lesson.metric)}: ${emNumber(result)} ${lesson.unit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (run.invalid.isNotEmpty)
            Text(run.invalid, style: const TextStyle(color: Colors.red)),
          for (final e in run.state.entries.where((e) => e.key != 't'))
            Text(
              '${emLabel(e.key)}: ${emNumber(e.value)} ${e.key == 'field'
                  ? kind == 1 || kind == 2
                        ? 'N/C'
                        : kind == 5
                        ? 'V/m'
                        : 'T'
                  : emUnit(e.key)}',
            ),
          if (kind == 9 && !run.state.containsKey('longField'))
            const Text(
              'Long-solenoid reference unavailable here: requires L/R≥10 and |x|≤L/4.',
            ),
          if (kind == 4 && run.network?.valid == true) ...[
            const Text('Node voltages relative to first source b'),
            for (final e in run.network!.nodes.entries)
              Text('${e.key}: ${emNumber(e.value)} V'),
            const Text('Branches: current a→b, voltage a−b, absorbed power'),
            for (final part in circuit.parts)
              Text(
                '${part.id}: ${emNumber(run.network!.currents[part.id])} A · ${emNumber(run.network!.voltages[part.id])} V · ${emNumber(run.network!.powers[part.id])} W',
              ),
          ],
          Text(
            'Physical time ${emNumber(run.time)} s',
            style: const TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    ),
  );
  Iterable<Parameter> get visibleControls => lesson.controls.where((p) {
    if ((kind == 1 || kind == 2) && RegExp(r'^[qxy][123]$').hasMatch(p.key)) {
      return int.parse(p.key.substring(1)) <= parameters['count']!.round();
    }
    if (kind == 5) {
      if (mode < 2) {
        return [
          'area',
          'gap',
          'epsilonR',
          if (mode == 0) 'voltage',
        ].contains(p.key);
      }
      return [
        'resistance',
        'capacitance',
        'initialV',
        if (mode == 2) 'voltage',
      ].contains(p.key);
    }
    if (kind == 11 && mode == 1 && p.key == 'muR') return false;
    return true;
  });
  Widget control(Parameter p) {
    final integer = ['count', 'turns', 'closed'].contains(p.key);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${p.label}: ${emNumber(parameters[p.key])} ${p.unit}',
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
                    onApply: (v) => updateMany({p.key: v}),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
        Slider(
          key: Key('slider-${p.key}'),
          min: p.min,
          max: p.max,
          divisions: integer ? (p.max - p.min).round() : null,
          value: parameters[p.key]!.clamp(p.min, p.max),
          label: '${emNumber(parameters[p.key])} ${p.unit}',
          onChanged: (v) =>
              updateMany({p.key: integer ? v.roundToDouble() : v}),
        ),
      ],
    );
  }

  Widget playback() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          run.dynamicLab
              ? 'Physical time factor ${emNumber(run.timeScale)} s per display second at 1×. No automatic playback.'
              : 'Static scientific model: change a physical input to recompute. No arbitrary playback.',
        ),
        if (run.dynamicLab) ...[
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('play-em'),
                onPressed: run.invalid.isEmpty
                    ? () {
                        if (playing) {
                          pause();
                          setState(() {});
                        } else {
                          play();
                        }
                      }
                    : null,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(playing ? 'Pause' : 'Play'),
              ),
              OutlinedButton(
                key: const Key('step-em'),
                onPressed: run.invalid.isEmpty
                    ? () {
                        pause();
                        run.step(captureNow: true);
                        tick.value++;
                        setState(() {});
                      }
                    : null,
                child: const Text('Step'),
              ),
              OutlinedButton(
                onPressed: resetTime,
                child: const Text('Reset time'),
              ),
            ],
          ),
          DropdownButtonFormField<double>(
            isExpanded: true,
            initialValue: clock.speed,
            decoration: const InputDecoration(labelText: 'Display speed'),
            items: [.25, .5, 1.0, 2.0]
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text('$x× display speed'),
                  ),
                )
                .toList(),
            onChanged: (x) {
              pause();
              setState(() => clock.speed = x!);
            },
          ),
          Slider(
            key: const Key('em-time'),
            min: 0,
            max: run.maxTime,
            value: run.time.clamp(0, run.maxTime),
            label: '${emNumber(run.time)} s',
            onChanged: (t) {
              pause();
              run = makeRun()..seek(t);
              cursor = 0;
              tick.value++;
              setState(() {});
            },
          ),
          OutlinedButton(
            key: const Key('replay-em'),
            onPressed: () async {
              pause();
              await showDialog<void>(
                context: context,
                builder: (_) => NumericInputDialog(
                  label: 'Replay physical time (s)',
                  initial: run.time,
                  min: 0,
                  max: run.maxTime,
                  onApply: (t) {
                    run = makeRun()..seek(t);
                    cursor = 0;
                    tick.value++;
                    setState(() {});
                  },
                ),
              );
            },
            child: const Text('Replay to precise time'),
          ),
        ],
        OutlinedButton(
          onPressed: defaults,
          child: const Text('Restore documented defaults'),
        ),
        Text(notice, style: const TextStyle(fontSize: 11, color: muted)),
        const Text(
          '120 Hz shared fixed clock · bounded catch-up · background/navigation pauses.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
  Widget modes() => Column(
    children: [
      if (kind == 5 || kind == 11)
        DropdownButtonFormField<int>(
          key: const Key('em-model'),
          isExpanded: true,
          initialValue: mode,
          decoration: const InputDecoration(
            labelText: 'Supported physical mode',
          ),
          items: [
            for (int i = 0; i < (kind == 5 ? 4 : 2); i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  kind == 5
                      ? [
                          'Connected geometry',
                          'Isolated geometry (hold charge)',
                          'RC charging',
                          'RC discharging',
                        ][i]
                      : ['Educational linear core', 'Air-core comparison'][i],
                ),
              ),
          ],
          onChanged: (m) => chooseMode(m!),
        ),
      if (kind == 3)
        const Text(
          'Signed supply: + terminal at left. I conventional and electron drift opposite; marker displacement ×10000.',
        ),
    ],
  );
  List<Widget> experiment() => [
    scene(),
    metrics(),
    if (kind == 4)
      builder()
    else
      Panel(
        child: Column(children: [modes(), ...visibleControls.map(control)]),
      ),
    playback(),
    graph(),
    recordPanel(),
    investigation(),
  ];
  List<EMState> get graphData => graphMode == 'time'
      ? run.samples
      : graphMode == 'charge' && kind == 0
      ? run.alternate
      : run.profile;
  String get effectiveGraphMetric =>
      graphMetric.isEmpty ? lesson.metric : graphMetric;
  List<String> get graphOptions => switch (kind) {
    0 => ['force'],
    1 => ['field', 'ex', 'ey'],
    2 => ['potential', 'field', 'ex', 'ey'],
    3 =>
      graphMode == 'time'
          ? ['current', 'charge', 'power']
          : ['current', 'power'],
    4 => ['current'],
    5 =>
      mode < 2
          ? ['capacitance', 'voltage', 'energy']
          : ['voltage', 'current', 'charge', 'energy'],
    6 || 8 || 9 => ['field'],
    7 => ['speed', 'energy', 'force', 'x', 'y', 'z'],
    10 => ['emf', 'flux', 'current'],
    _ => ['force', 'field'],
  };
  String unitFor(String key) => key == 'field'
      ? (kind == 1 || kind == 2
            ? 'N/C'
            : kind == 5
            ? 'V/m'
            : 'T')
      : emUnit(key);
  String get profileAxis => switch (kind) {
    0 => graphMode == 'charge' ? 'Charge 1 (C)' : 'Centre distance (m)',
    1 || 2 => 'Path x at probe y (m)',
    3 || 4 => 'Source voltage (V)',
    5 => mode >= 2 ? 'Physical time (s)' : 'Plate gap (m)',
    6 || 8 => 'Radial distance (m)',
    9 => 'Axial x (m)',
    10 => 'Source axial z (m)',
    11 => 'Air gap (m)',
    _ => 'Physical time (s)',
  };
  Widget graph() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final data = graphData,
          key = effectiveGraphMetric,
          selected = data.isEmpty
              ? null
              : data[cursor.clamp(0, data.length - 1)];
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Computed graph · cursor / zoom'),
            DropdownButtonFormField<String>(
              key: const Key('em-graph-mode'),
              isExpanded: true,
              initialValue: graphMode,
              decoration: const InputDecoration(labelText: 'Graph source'),
              items: [
                if (kind != 7)
                  const DropdownMenuItem(
                    value: 'profile',
                    child: Text('Analytic parameter / spatial sweep'),
                  ),
                const DropdownMenuItem(
                  value: 'time',
                  child: Text('Recorded physical-time observations'),
                ),
                if (kind == 0)
                  const DropdownMenuItem(
                    value: 'charge',
                    child: Text('Force versus charge investigation'),
                  ),
              ],
              onChanged: (s) {
                pause();
                setState(() {
                  graphMode = s!;
                  if (!graphOptions.contains(graphMetric)) {
                    graphMetric = graphOptions.first;
                  }
                });
                cursor = 0;
                tick.value++;
              },
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('metric-$kind-$mode-$graphMetric'),
              isExpanded: true,
              initialValue: graphOptions.contains(key)
                  ? key
                  : graphOptions.first,
              decoration: const InputDecoration(
                labelText: 'Displayed physical quantity',
              ),
              items: graphOptions
                  .map(
                    (s) => DropdownMenuItem(value: s, child: Text(emLabel(s))),
                  )
                  .toList(),
              onChanged: (s) {
                setState(() => graphMetric = s!);
                cursor = 0;
                tick.value++;
              },
            ),
            const SizedBox(height: 12),
            if (data.isEmpty || !data.any((p) => p.containsKey(key)))
              const Text(
                'No valid samples in this channel. Select recorded time after stepping, or a quantity available in the analytic sweep.',
              )
            else ...[
              Semantics(
                label:
                    'Actual ${data.length} samples, $key versus ${graphMode == 'time' ? 'physical time' : profileAxis}; excluded/invalid samples leave gaps.',
                child: InteractiveViewer(
                  transformationController: graphView,
                  minScale: 1,
                  maxScale: 4,
                  child: RepaintBoundary(
                    child: SizedBox(
                      height: 225,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: LabPlot(
                          data,
                          [key],
                          graphMode == 'time'
                              ? 'Physical time (s)'
                              : profileAxis,
                          unitFor(key),
                          cursor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (data.length > 1)
                Slider(
                  key: const Key('cursor-em'),
                  min: 0,
                  max: (data.length - 1).toDouble(),
                  divisions: data.length - 1,
                  value: cursor.clamp(0, data.length - 1).toDouble(),
                  onChanged: (x) {
                    pause();
                    setState(() => cursor = x.round());
                    tick.value++;
                  },
                ),
              Text(
                'Selected ${emNumber(selected!['t'])}: ${emLabel(key)} ${emNumber(selected[key])} ${unitFor(key)}',
              ),
            ],
            TextButton(
              onPressed: () => graphView.value = Matrix4.identity(),
              child: const Text('Reset graph zoom'),
            ),
            Text(
              graphMode == 'time'
                  ? 'Latest ≤301 actual observations; not a preloaded demonstration.'
                  : 'Analytic sweep at fixed remaining inputs, not an experimental time history. Invalid/excluded points remain blank.',
              style: const TextStyle(fontSize: 11, color: muted),
            ),
          ],
        ),
      );
    },
  );
  List<Widget> visualize() => [
    scene(),
    Panel(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Scientific vectors / representations'),
            value: overlays,
            onChanged: (x) {
              setState(() => overlays = x);
              tick.value++;
            },
          ),
          SwitchListTile(
            title: const Text('Labels'),
            value: labels,
            onChanged: (x) {
              setState(() => labels = x);
              tick.value++;
            },
          ),
          if ([1, 2, 6].contains(kind))
            SwitchListTile(
              title: Text(
                kind == 2 ? 'Equipotential contours' : 'Field-line traces',
              ),
              value: fieldLines,
              onChanged: (x) {
                setState(() => fieldLines = x);
                tick.value++;
              },
            ),
          if (kind == 3)
            SwitchListTile(
              title: const Text('Electron drift schematic'),
              value: electrons,
              onChanged: (x) {
                setState(() => electrons = x);
                tick.value++;
              },
            ),
          if (kind == 7) ...[
            const Text('3-D camera only: azimuth and elevation (rad)'),
            Slider(
              min: -math.pi,
              max: math.pi,
              value: azimuth,
              onChanged: (x) {
                setState(() => azimuth = x);
                tick.value++;
              },
            ),
            Slider(
              min: -1.2,
              max: 1.2,
              value: elevation,
              onChanged: (x) {
                setState(() => elevation = x);
                tick.value++;
              },
            ),
          ],
          if (store.reducedMotion)
            const Text(
              'Reduced motion: no auto-start. Step, exact replay, static curves and numeric controls remain available.',
            ),
        ],
      ),
    ),
    graph(),
    metrics(),
  ];
  Widget investigation() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Paragraph('Guided investigation', lesson.procedure),
        for (int i = 0; i < 2; i++)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              i == 0
                  ? 'I changed an input/topology and predicted its effect.'
                  : 'I compared computed data and explained an assumption.',
            ),
            value: guided > i,
            onChanged: (x) {
              setState(() => guided = x == true ? i + 1 : i);
              persist();
            },
          ),
        Text(lesson.question),
        FilledButton(
          key: const Key('predict-em'),
          onPressed: result == null ? null : predict,
          child: const Text('Test numerical prediction'),
        ),
        if (feedback.isNotEmpty) Text(feedback),
        Text('${attempts.length} attempts (latest 50).'),
        OutlinedButton(
          onPressed: () async {
            if (!changed ||
                guided < 2 ||
                !attempts.any((a) => a['correct'] == true) ||
                !store.trials.any((t) => t.labId == entry.id)) {
              message(
                'Change an input, complete both checks, answer correctly and record a valid trial first.',
              );
              return;
            }
            await store.complete(entry.id);
            message('Investigation completed from your activity.');
          },
          child: const Text('Complete investigation'),
        ),
      ],
    ),
  );
  Widget recordPanel() => Panel(
    child: Column(
      children: [
        TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Observation notes'),
          onChanged: (_) => persist(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('record-em'),
              onPressed: result == null || busy ? null : record,
              icon: const Icon(Icons.add),
              label: const Text('Record Trial'),
            ),
            OutlinedButton(onPressed: save, child: const Text('Save session')),
          ],
        ),
      ],
    ),
  );
  List<Widget> formulas() => [
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              lesson.formula,
              textStyle: const TextStyle(fontSize: 18, color: navy),
            ),
          ),
          Paragraph('Symbols, units and sign conventions', lesson.symbols),
          Paragraph('Validity and numerical method', lesson.limits),
          Paragraph('Worked example', lesson.example),
          Paragraph(
            'Current-value substitution',
            '${parameters.entries.map((e) => '${e.key}=${emNumber(e.value)} ${lesson.controls.firstWhere((p) => p.key == e.key).unit}').join('; ')}. Mode $mode, t=${emNumber(run.time)} s. ${substitution()}',
          ),
          const Paragraph(
            'Constants and primary references',
            'CODATA 2022: ε₀=8.8541878188e−12 F/m, μ₀=1.25663706127e−6 H/m, exact e=1.602176634e−19 C. OpenStax University Physics II chapters 5–13; Boris magnetic rotation and Neumann finite-loop flux. See docs/PHASE5_SCIENCE.md for source links and tolerances.',
          ),
        ],
      ),
    ),
  ];
  String substitution() {
    String p(String k) => emNumber(parameters[k]);
    String s(String k) => emNumber(run.state[k]);
    if (run.invalid.isNotEmpty) return run.invalid;
    return switch (kind) {
      0 =>
        'F₂x = k × ${p('q1')} × ${p('q2')} / ${p('distance')}² = ${s('fx')} N; F₁x = ${s('oppositeFx')} N.',
      1 =>
        'Superpose ${p('count')} sources at probe (${p('probeX')},${p('probeY')}) m: E=(${s('ex')},${s('ey')}) N/C. Fₓ=${p('testCharge')} × ${s('ex')} = ${s('fx')} N.',
      2 =>
        'V = Σ kqᵢ/rᵢ = ${s('potential')} V. U = ${p('testCharge')} × ${s('potential')} = ${s('energy')} J. E=(${s('ex')},${s('ey')}) N/C.',
      3 =>
        'I = ${p('closed')} × ${p('voltage')} / ${p('resistance')} = ${s('current')} A. Q = ${s('current')} × ${emNumber(run.time)} = ${s('charge')} C. P = ${p('voltage')} × ${s('current')} = ${s('power')} W.',
      4 =>
        'MNA stamps ${circuit.parts.length} parts / ${circuit.wires.length} wires; delivered I=${s('current')} A, KCL residual=${s('kclResidual')} A, power balance residual=${s('powerResidual')} W. Node voltages/branch currents below use a→b signs.',
      5 =>
        mode < 2
            ? 'C = ε₀ × ${p('epsilonR')} × ${p('area')} / ${p('gap')} = ${s('capacitance')} F. Q=${s('charge')} C ${mode == 1 ? '(held)' : ''}; V=Q/C=${s('voltage')} V, U=Q²/(2C)=${s('energy')} J.'
            : 'τ = ${p('resistance')} × ${p('capacitance')} = ${s('tau')} s. Vc = ${mode == 2 ? p('voltage') : '0'} + (${p('initialV')} − ${mode == 2 ? p('voltage') : '0'}) exp(−${emNumber(run.time)}/${s('tau')}) = ${s('voltage')} V. I=${s('current')} A.',
      6 =>
        'Insert m=${p('moment')} A·m² and r=(${p('probeX')},${p('probeY')},0) m into the dipole vector formula: B=(${s('bx')},${s('by')},0) T, magnitude ${s('field')} T.',
      7 =>
        'F = ${p('charge')} × (${s('vy')}×${p('field')}, −${s('vx')}×${p('field')},0) = (${s('fx')},${s('fy')},${s('fz')}) N; KE=½mv²=${s('energy')} J.',
      8 =>
        'B = μ₀ × ${p('current')} / (2π √(${p('probeX')}²+${p('probeY')}²)); vector=(${s('bx')},${s('by')},0) T, magnitude ${s('field')} T.',
      9 =>
        'Finite axial expression at x=${p('probe')} m, N=${p('turns')}, I=${p('current')} A, L=${p('length')} m, R=${p('radius')} m gives Bx=${s('field')} T; eligible long reference=${s('longField')} T.',
      10 =>
        'z=${p('initialZ')} + ${p('velocity')} × ${emNumber(run.time)} = ${s('position')} m. Φ=${s('flux')} Wb; ε=−${p('turns')} × ${s('fluxGradient')} × ${p('velocity')} = ${s('emf')} V. Iclosed=${s('current')} A.',
      _ =>
        'B = μ₀ × ${p('turns')} × ${p('current')} / (${p('length')}/${mode == 1 ? '1' : p('muR')} + ${p('gap')}) = ${s('field')} T. F=B² × ${p('area')}/(2μ₀)=${s('force')} N; load weight=${s('weight')} N.',
    };
  }

  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    return [
      Text(
        'Recorded observations',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      Panel(
        child: Paragraph(
          '${trials.length} actual records',
          trials.isEmpty
              ? 'Record a valid computed state; there are no seeded results.'
              : 'Compare matching protocols, initial states and topologies.',
        ),
      ),
      if (trials.isNotEmpty)
        FilledButton.icon(
          onPressed: () => exportTrials(context, trials),
          icon: const Icon(Icons.ios_share),
          label: const Text('Export actual trials as CSV'),
        ),
      for (final t in trials.reversed)
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${emNumber(t.value)} ${t.unit}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(t.note.isEmpty ? 'No notes' : t.note),
              Text(
                'Model ${t.model} · ${t.created}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
              Text('SI parameters ${t.configuration['parameters']}'),
              if (kind == 4)
                Text(
                  'Saved topology ${(t.configuration['circuit'] as Map)['wires']}',
                ),
              TextButton(
                onPressed: () {
                  if (restore(t.configuration)) {
                    setState(() => section = 1);
                    tick.value++;
                    message('Original configuration/topology restored paused.');
                  } else {
                    message(
                      'Incompatible record; original body remains preserved.',
                    );
                  }
                },
                child: const Text('Reopen configuration'),
              ),
            ],
          ),
        ),
    ];
  }

  void syncLayout(CircuitPart part) {
    final twin = run.circuit.parts.where((p) => p.id == part.id).firstOrNull;
    if (twin != null) {
      twin.x = part.x;
      twin.y = part.y;
    }
  }

  Widget builder() {
    final selectedPart = circuit.parts
            .where((p) => p.id == selected)
            .firstOrNull,
        terminals = [
          for (final p in circuit.parts) ...[p.a, p.b],
        ];
    if (!terminals.contains(terminalA)) terminalA = terminals.firstOrNull ?? '';
    if (!terminals.contains(terminalB)) terminalB = terminals.lastOrNull ?? '';
    void topology(void Function() edit) {
      pause();
      edit();
      restart();
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Genuine DC circuit builder'),
          const Text(
            'Bounded: 12 components, 24 wires. Gold terminals a/b; source a is positive. Wires merge nodes; meters are ideal. Component movement changes layout only.',
          ),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < 3; i++)
                OutlinedButton(
                  key: Key('example-$i'),
                  onPressed: () => topology(() {
                    circuit = CircuitGraph.example(i);
                    selected = 'R1';
                  }),
                  child: Text(
                    ['Series example', 'Parallel example', 'Mixed example'][i],
                  ),
                ),
            ],
          ),
          DropdownButtonFormField<String>(
            key: const Key('new-part-type'),
            isExpanded: true,
            initialValue: newType,
            decoration: const InputDecoration(labelText: 'Add component type'),
            items: [
              'source',
              'resistor',
              'lamp',
              'switch',
              'ammeter',
              'voltmeter',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (x) => setState(() => newType = x!),
          ),
          OutlinedButton(
            key: const Key('add-part'),
            onPressed: circuit.parts.length >= 12
                ? null
                : () => topology(() {
                    int n = 1;
                    while (circuit.parts.any((p) => p.id == 'C$n')) {
                      n++;
                    }
                    final id = 'C$n';
                    circuit.parts.add(
                      CircuitPart(
                        id,
                        newType,
                        value: newType == 'source'
                            ? 6
                            : ['resistor', 'lamp'].contains(newType)
                            ? 15
                            : 0,
                        x: .2 + .1 * (n % 6),
                        y: .4,
                      ),
                    );
                    selected = id;
                  }),
            child: const Text('Add selected component'),
          ),
          if (circuit.parts.isNotEmpty)
            DropdownButtonFormField<String>(
              key: ValueKey('selected-part-$selected'),
              isExpanded: true,
              initialValue: selectedPart?.id ?? circuit.parts.first.id,
              decoration: const InputDecoration(
                labelText: 'Selected component (or tap scene)',
              ),
              items: circuit.parts
                  .map(
                    (p) => DropdownMenuItem(
                      value: p.id,
                      child: Text('${p.id}: ${p.type}'),
                    ),
                  )
                  .toList(),
              onChanged: (x) {
                setState(() => selected = x!);
                tick.value++;
              },
            ),
          if (selectedPart != null) ...[
            Text(
              '${selectedPart.id}: ${emNumber(selectedPart.value)} ${selectedPart.type == 'source'
                  ? 'V'
                  : ['resistor', 'lamp'].contains(selectedPart.type)
                  ? 'Ω'
                  : '(ideal)'}',
            ),
            if (['source', 'resistor', 'lamp'].contains(selectedPart.type))
              OutlinedButton(
                key: const Key('edit-component'),
                onPressed: () async {
                  pause();
                  await showDialog<void>(
                    context: context,
                    builder: (_) => NumericInputDialog(
                      label:
                          '${selectedPart.id} ${selectedPart.type == 'source' ? 'V' : 'Ω'}',
                      initial: selectedPart.value,
                      min: selectedPart.type == 'source' ? -24 : .1,
                      max: selectedPart.type == 'source' ? 24 : 10000,
                      onApply: (v) => topology(() => selectedPart.value = v),
                    ),
                  );
                },
                child: const Text('Edit component value'),
              ),
            if (selectedPart.type == 'switch')
              SwitchListTile(
                key: const Key('builder-switch'),
                title: const Text('Selected switch closed'),
                value: selectedPart.closed,
                onChanged: (x) => topology(() => selectedPart.closed = x),
              ),
            for (final axis in ['x', 'y'])
              Row(
                children: [
                  Text('Layout $axis'),
                  Expanded(
                    child: Slider(
                      key: Key('layout-$axis'),
                      min: .08,
                      max: .92,
                      value: (axis == 'x' ? selectedPart.x : selectedPart.y)
                          .clamp(.08, .92),
                      onChanged: (v) {
                        setState(() {
                          if (axis == 'x') {
                            selectedPart.x = v;
                          } else {
                            selectedPart.y = v;
                          }
                          changed = true;
                          syncLayout(selectedPart);
                        });
                        tick.value++;
                      },
                    ),
                  ),
                ],
              ),
            OutlinedButton(
              key: const Key('delete-component'),
              onPressed: () => topology(() {
                final id = selectedPart.id;
                circuit.parts.remove(selectedPart);
                circuit.wires.removeWhere(
                  (w) => w.any((t) => t.startsWith('$id:')),
                );
                selected = circuit.parts.firstOrNull?.id ?? '';
              }),
              child: const Text('Delete selected component and its wires'),
            ),
          ],
          if (terminals.isNotEmpty) ...[
            DropdownButtonFormField<String>(
              key: ValueKey('wire-a-$terminalA-${terminals.length}'),
              isExpanded: true,
              initialValue: terminalA,
              decoration: const InputDecoration(
                labelText: 'Wire from terminal',
              ),
              items: terminals
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (x) => setState(() => terminalA = x!),
            ),
            DropdownButtonFormField<String>(
              key: ValueKey('wire-b-$terminalB-${terminals.length}'),
              isExpanded: true,
              initialValue: terminalB,
              decoration: const InputDecoration(labelText: 'Wire to terminal'),
              items: terminals
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (x) => setState(() => terminalB = x!),
            ),
            OutlinedButton(
              key: const Key('connect-terminals'),
              onPressed:
                  terminalA == terminalB ||
                      circuit.wires.length >= 24 ||
                      circuit.wires.any(
                        (w) => w.contains(terminalA) && w.contains(terminalB),
                      )
                  ? null
                  : () => topology(() {
                      if (!circuit.wires.any(
                        (w) => w.contains(terminalA) && w.contains(terminalB),
                      )) {
                        circuit.wires.add([terminalA, terminalB]);
                      }
                    }),
              child: const Text('Connect these terminals'),
            ),
          ],
          const Text('Connections (delete to change topology):'),
          for (final (i, w) in circuit.wires.indexed)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${w[0]} ↔ ${w[1]}'),
              trailing: IconButton(
                key: Key('delete-wire-$i'),
                tooltip: 'Delete ${w[0]} to ${w[1]}',
                onPressed: () => topology(() => circuit.wires.removeAt(i)),
                icon: const Icon(Icons.link_off),
              ),
            ),
          const Text(
            'Floating/shorted/inconsistent systems show an explanation and disable Record. No finite meter readings are invented. Lamp is an ohmic resistor; P/(P+.5 W) brightness is illustrative.',
          ),
        ],
      ),
    );
  }
}
