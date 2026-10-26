import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../workbench/workbench.dart';
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/advanced.dart';
import '../../core/physics/dynamics.dart';
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'curriculum.dart';
import 'scene.dart';

Future<ui.Image>? _texture;
Future<ui.Image> planetTexture() => _texture ??= () async {
  final bytes = await rootBundle.load('assets/textures/earth-illustrative.png');
  final codec = await ui.instantiateImageCodec(
    bytes.buffer.asUint8List(),
    targetWidth: 512,
  );
  final frame = await codec.getNextFrame();
  codec.dispose();
  return frame.image;
}();

class AdvancedWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const AdvancedWorkspace({super.key, required this.entry});
  @override
  ConsumerState<AdvancedWorkspace> createState() => _AdvancedState();
}

class _AdvancedState extends ConsumerState<AdvancedWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late LabState parameters;
  late AdvancedRun run;
  late final Ticker ticker;
  late final LocalNotebook store;
  final clock = FixedClock();
  final tick = ValueNotifier<int>(0), graphTick = ValueNotifier<int>(0);
  final view = TransformationController(),
      graphView = TransformationController();
  final notes = TextEditingController();
  ui.Image? texture;
  Duration previous = Duration.zero;
  bool ready = false,
      labels = true,
      overlays = true,
      trails = true,
      changed = false,
      busy = false,
      curve = false;
  int section = 1, cursor = 0, guided = 0;
  String
  channel = '',
  feedback = '',
  notice =
      'Parameter edits pause and restart the model. Camera and overlays preserve time.',
  stamp = '';
  final attempts = <Map<String, dynamic>>[];
  Entry get entry => widget.entry;
  bool get playing => ticker.isActive;
  double get result => run.state[lesson.metric] ?? 0;
  String number(num? x) =>
      x == null ? 'Not yet available' : x.toStringAsPrecision(6);
  @override
  void initState() {
    super.initState();
    kind = (entry.studioIndex - 5) * 6 + entry.index;
    lesson = advancedLessons[kind];
    parameters = lesson.defaults;
    run = AdvancedRun(kind, parameters);
    channel = channelsFor(kind).first;
    curve = [1, 6, 7, 8, 16].contains(kind);
    store = ref.read(notebookProvider);
    ticker = createTicker(onFrame);
    tick.addListener(() {
      final next =
          '${identityHashCode(run)}:${run.samples.last['t']}:$cursor:$channel:$curve';
      if (next != stamp) {
        stamp = next;
        graphTick.value++;
      }
    });
    WidgetsBinding.instance.addObserver(this);
    load();
    if (kind >= 6 && kind <= 11) {
      planetTexture()
          .then((image) {
            if (mounted) setState(() => texture = image);
          })
          .catchError((Object error) {
            if (mounted) {
              setState(
                () => notice = 'Planet texture unavailable; shaded geometry is shown. Model calculations remain available.',
              );
            }
          });
    }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      pause();
      persist();
    }
  }

  Future<void> load() async {
    final data = await store.readSession(entry.id);
    if (data != null && !restore(data)) {
      await store.retainRejectedSession(entry.id, data);
      notice = 'Saved version is incompatible. Original trial records remain preserved.';
    }
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
  }

  Map<String, dynamic> configuration() => {
    'model': advancedVersion,
    'kind': kind,
    'parameters': parameters,
    'ticks': run.ticks,
    'notes': notes.text,
    'guided': guided,
    'attempts': attempts,
    'changed': changed,
    'feedback': feedback,
    'speed': clock.speed,
    'labels': labels,
    'overlays': overlays,
    'trails': trails,
    'channel': channel,
    'curve': curve,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != advancedVersion || data['kind'] != kind) {
        return false;
      }
      final raw = Map<String, dynamic>.from(data['parameters']),
          next = <String, double>{};
      for (final p in lesson.controls) {
        final n = (raw[p.key] as num).toDouble();
        if (!n.isFinite || n < p.min - 1e-9 || n > p.max + 1e-9) return false;
        next[p.key] = n;
      }
      final ticks = data['ticks'] as int;
      if (ticks < 0 || ticks > 14400) return false;
      final restored = AdvancedRun(kind, next)
        ..seek(ticks * AdvancedRun.dt * (kind >= 9 && kind <= 11 ? 480 : 1));
      pause();
      parameters = next;
      run = restored;
      notes.text = data['notes'] ?? '';
      guided = (data['guided'] as int? ?? 0).clamp(0, 2);
      changed = data['changed'] == true;
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? []).map(
            (x) => Map<String, dynamic>.from(x),
          ),
        );
      feedback = data['feedback'] ?? '';
      clock.speed = (data['speed'] as num? ?? 1).toDouble().clamp(.25, 2);
      labels = data['labels'] != false;
      overlays = data['overlays'] != false;
      trails = data['trails'] != false;
      channel = channelsFor(kind).contains(data['channel'])
          ? data['channel']
          : channelsFor(kind).first;
      curve = data['curve'] == true && [1, 6, 7, 8, 16].contains(kind);
      cursor = run.samples.length - 1;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() => store.saveSession(entry.id, configuration());
  Future<void> save() async {
    pause();
    await persist();
    message('Session saved. Reopens paused.');
  }

  void message(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  void onFrame(Duration elapsed) {
    final seconds = (elapsed - previous).inMicroseconds / 1e6;
    previous = elapsed;
    clock.advance(seconds, run.step);
    cursor = run.samples.length - 1;
    tick.value++;
    if (run.finished) pause();
  }

  void play() {
    if (run.staticLab) return;
    if (run.finished) reset();
    previous = Duration.zero;
    clock.pause();
    ticker.start();
    setState(() {});
  }

  void pause() {
    ticker.stop();
    clock.pause();
    if (mounted) setState(() {});
  }

  void reset() {
    pause();
    run = AdvancedRun(kind, parameters);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void updateMany(Map<String, double> values) {
    pause();
    final next = Map<String, double>.of(parameters);
    for (final e in values.entries) {
      final p = lesson.controls.firstWhere((p) => p.key == e.key);
      next[e.key] = e.value.clamp(p.min, p.max);
    }
    notice = 'Initial conditions changed: trajectory restarted at t=0.';
    if (kind == 0) {
      final sin = math.sin(next['angle']! * math.pi / 180),
          mg = next['m']! * standardGravity;
      if (next['force']! * sin > mg) {
        next['force'] = mg / sin;
        notice =
            'Force limited to preserve nonnegative normal contact. Restarted.';
      }
    }
    if (kind == 11) {
      final minA = 1.001 / (1 - next['e']!);
      if (next['a']! < minA) {
        next['a'] = minA;
        notice = 'Semi-major axis raised so periapsis stays outside the planet. Restarted.';
      }
    }
    if (kind == 13) {
      final energyLimit = 1 - math.cos(75 * math.pi / 180),
          potential = 1 - math.cos(next['angle']! * math.pi / 180),
          maxOmega = math.sqrt(
            math.max(
              0,
              2 * next['g']! / next['length']! * (energyLimit - potential),
            ),
          );
      if (next['v0']!.abs() > maxOmega) {
        next['v0'] = maxOmega * next['v0']!.sign;
        notice = 'Angular velocity limited to keep the string taut (turning angle ≤75°). Restarted.';
      }
    }
    parameters = next;
    changed = true;
    run = AdvancedRun(kind, parameters);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  String get quantity => switch (lesson.unit) {
    'J' => 'energy',
    'W' => 'power',
    'N' => 'force',
    'm/s²' => 'acceleration',
    'J/kg' => 'specificEnergy',
    'm/s' => 'speed',
    's' => 'time',
    'kg/s' => 'damping',
    'rad/s' => 'angularFrequency',
    _ => 'efficiency',
  };
  Future<void> record() async {
    if (busy) return;
    pause();
    setState(() => busy = true);
    try {
      final config = configuration()
        ..['observations'] = run.samples
        ..['currentState'] = run.state;
      await store.addTrial(
        Trial(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          labId: entry.id,
          quantity: quantity,
          unit: lesson.unit,
          value: result,
          resolution: null,
          configuration: config,
          note: notes.text,
          model: advancedVersion,
        ),
      );
      await persist();
      message('Actual ${lesson.metric} recorded at ${number(run.time)} s.');
    } catch (_) {
      message('Could not save this observation.');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> prediction() async {
    pause();
    final expected = result;
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: 'Prediction: ${lesson.metric} (${lesson.unit})',
        initial: 0,
        min: -1e30,
        max: 1e30,
        onApply: (answer) async {
          final tolerance = math.max(1e-7, expected.abs() * .02),
              ok = (answer - expected).abs() <= tolerance;
          final attempt = <String, dynamic>{
            'time': DateTime.now().toUtc().toIso8601String(),
            'metric': lesson.metric,
            'answer': answer,
            'expected': expected,
            'tolerance': tolerance,
            'correct': ok,
            'parameters': Map.of(parameters),
            'physicalTime': run.time,
          };
          attempts.add(attempt);
          if (attempts.length > 50) attempts.removeAt(0);
          await store.recordAttempt(entry.id, attempt);
          if (mounted) {
            setState(
              () => feedback =
                  '${ok ? 'Correct' : 'Try again'} · reference answer ${number(expected)} ${lesson.unit}; tolerance ${number(tolerance)}. ${lesson.question}',
            );
          }
          await persist();
        },
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
    tick.dispose();
    graphTick.dispose();
    view.dispose();
    graphView.dispose();
    notes.dispose();
    super.dispose();
  }

  List<InstrumentControl> instrumentControls() => [
    for (final p in lesson.controls)
      InstrumentControl(
        p.key,
        p.label,
        p.unit,
        parameters[p.key]!,
        p.min,
        p.max,
        (v) => updateMany(<String, double>{p.key: v}),
      ),
  ];
  String? highlightControl;
  @override
  Widget build(BuildContext context) {
    if (ready && (section == 1 || section == 2 || section == 4)) {
      return InstrumentShell(
        key: ValueKey('instrument-${entry.id}'),
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
            ? (!(!run.staticLab) || run.time > 0)
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
        graph: graph,
        controls: instrumentControls,
        readings: () => [
          InstrumentReading(
            lesson.metric,
            result.toStringAsPrecision(5),
            lesson.unit,
          ),
          InstrumentReading('Model t', run.time.toStringAsPrecision(4), 's'),
        ],
        advanced: () => experiment().skip(1).toList(),
        results: results,
        notice: () => notice,
        playing: () => ticker.isActive,
        dynamicModel: () => !run.staticLab,
        canRecord: () => result.isFinite,
        play: play,
        pause: pause,
        reset: reset,
        save: save,
        record: record,
        step: () {
          pause();
          run.step();
          tick.value++;
        },
        selection: null,
        resetOriginalView: () => view.value = Matrix4.identity(),
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
      title: Text(entry.title),
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
    body: SafeArea(
      child: !ready
          ? const Center(child: CircularProgressIndicator())
          : PageBody(
              scrollId: '${entry.id}:$section',
              children: [
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
    relatedLabs(entry.id),
    const SizedBox(height: 12),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Paragraph(
            'Objectives',
            '${entry.principle} Predict ${lesson.metric} in ${lesson.unit}; compare a calculated state with your prediction and explain the model limits.',
          ),
          Paragraph('Apparatus', lesson.apparatus),
          Paragraph('Physical principles', lesson.principle),
          Paragraph('Investigation procedure', lesson.procedure),
          Paragraph('Assumptions and valid range', lesson.limits),
          Paragraph('Misconceptions', lesson.mistake),
          Paragraph('Prediction question', lesson.question),
          FilledButton(
            onPressed: () => setState(() => section = 1),
            child: const Text('Open experiment'),
          ),
        ],
      ),
    ),
  ];
  List<Widget> experiment() => [
    scene(),
    metrics(),
    transport(),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notice, style: const TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 12),
          ...presets(),
          for (final p in lesson.controls) parameter(p),
        ],
      ),
    ),
    graph(),
    investigation(),
    recordPanel(),
  ];
  Widget compactScene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final painter = AdvancedPainter(
        kind: kind,
        s: run.state,
        p: parameters,
        samples: run.samples,
        labels: labels,
        overlays: overlays,
        trails: trails && !store.reducedMotion,
        texture: texture,
      );

      return LayoutBuilder(
        builder: (context, box) => Semantics(
          label: painter.accessibleSummary,
          child: ApparatusTransform(
            transformationController: view,
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: (event) {
                final scale = box.maxWidth / 360;
                updateMany(painter.interaction(event.localPosition / scale));
              },
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(box.maxWidth, box.maxWidth * .75),
                  painter: painter,
                ),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget scene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final painter = AdvancedPainter(
        kind: kind,
        s: run.state,
        p: parameters,
        samples: run.samples,
        labels: labels,
        overlays: overlays,
        trails: trails && !store.reducedMotion,
        texture: texture,
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
                    child: Eyebrow('Live apparatus · drag to edit'),
                  ),
                  IconButton(
                    tooltip: 'Reset scene zoom',
                    onPressed: () => view.value = Matrix4.identity(),
                    icon: const Icon(Icons.fit_screen),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${lesson.metric}: ${number(result)} ${lesson.unit}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: navy,
                  ),
                ),
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
                    onHorizontalDragUpdate: (event) {
                      final scale = box.maxWidth / 360;
                      updateMany(
                        painter.interaction(event.localPosition / scale),
                      );
                    },
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(box.maxWidth, box.maxWidth * .75),
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
                kind >= 6 && kind <= 11
                    ? kind == 6
                          ? 'Drag centre separation; body sizes are exaggerated. Centre distance and force magnitudes are given below.'
                          : 'Drag probe/initial radius; pinch to zoom. Source radius is scaled; satellite size is exaggerated. Exact coordinates below.'
                    : kind == 13
                    ? 'Drag bob angle; numeric length and angular velocity below. Pinch/pan for close inspection.'
                    : 'Drag to edit ${kind == 0
                          ? 'force'
                          : kind == 1
                          ? 'signed speed'
                          : kind == 3
                          ? 'initial bead position'
                          : kind >= 12
                          ? 'initial mass displacement'
                          : kind == 5
                          ? 'model efficiency'
                          : 'lift height'}. Pinch/pan to inspect; numeric alternatives below.',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
            ),
          ],
        ),
      );
    },
  );
  List<String> get metricKeys => switch (kind) {
    0 => [
      'appliedWork',
      'gravityWork',
      'normalWork',
      'frictionWork',
      'netWork',
      'deltaK',
      'normal',
      'x',
      'distance',
      'vx',
    ],
    1 => ['K', 'x', 'vx'],
    2 => ['y', 'U', 'deltaU', 'targetDeltaU', 'referenceU'],
    3 => ['K', 'U', 'loss', 'total', 'mechanical', 'x', 'y'],
    4 => ['work', 'power', 'instantPower', 'liftForce', 'y'],
    5 => ['input', 'useful', 'loss', 'efficiency', 'y'],
    6 => ['force', 'force2', 'radius', 'altitude'],
    7 => ['field', 'gx', 'gy', 'radius', 'altitude'],
    8 => ['potential', 'U', 'radius', 'altitude'],
    9 || 10 => [
      'speed',
      'radius',
      'altitude',
      'specificEnergy',
      'angularMomentum',
      'escape',
      'period',
      'periapsis',
    ],
    11 => [
      'period',
      'radius',
      'speed',
      'periapsis',
      'apoapsis',
      'area',
      'specificEnergy',
    ],
    13 => [
      'angle',
      'angularVelocity',
      'tension',
      'period',
      'smallPeriod',
      'measuredPeriod',
      'total',
    ],
    15 => ['x', 'vx', 'total', 'loss', 'critical', 'regime', 'envelope'],
    16 => [
      'x',
      'vx',
      'force',
      'naturalOmega',
      'dampedOmega',
      'peakOmega',
      'steadyAmplitude',
      'phase',
    ],
    17 => [
      'x',
      'x2',
      'energy1',
      'energy2',
      'total',
      'lowFrequency',
      'highFrequency',
    ],
    _ => ['x', 'vx', 'ax', 'period', 'frequency', 'K', 'U', 'total'],
  };
  Widget metrics() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Live calculated values'),
          const SizedBox(height: 8),
          Text(
            '${labelFor(lesson.metric)}: ${number(result)} ${lesson.unit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          for (final key in metricKeys)
            Text(
              '${labelFor(key)}: ${number(run.state[key])} ${unitFor(key)}',
              style: const TextStyle(
                fontFeatures: [ui.FontFeature.tabularFigures()],
              ),
            ),
          if (kind >= 9 && kind <= 11)
            Text(
              '${run.impacted ? 'Surface collision; propagation stopped. ' : ''}${(run.state['specificEnergy'] ?? 0).abs() < 1
                  ? 'Parabolic energy boundary'
                  : run.state['bound'] == 1
                  ? 'Bound energy'
                  : 'Unbound energy'}; period requires a bound, nonintersecting orbit. Screen edge does not define escape.',
            ),
          if (kind == 5)
            Text(
              run.state['input'] == 0
                  ? 'Output/input ratio undefined at zero input. η above is a specified parameter.'
                  : 'Useful + loss = input; η is specified, not measured.',
            ),
          if (kind == 15)
            Text(
              'Regime: ${run.state['regime'] == -1
                  ? 'underdamped'
                  : run.state['regime'] == 0
                  ? 'critical'
                  : 'overdamped'}',
            ),
          if (kind == 16 && run.state['steadyAmplitude'] == null)
            const Text(
              'No finite steady amplitude at undamped resonance. Actual displacement grows; no physics clipping.',
            ),
          if (kind == 16)
            const Text(
              'Steady amplitude/phase are analytic predictions. Actual x includes the transient. A zero peak frequency means no positive-frequency displacement peak.',
            ),
          if (run.finished)
            const Text(
              'Run paused at its modeled boundary or 120 display-second observation horizon.',
              style: TextStyle(color: teal),
            ),
          Text(
            'Physical time ${number(run.time)} s',
            key: const Key('advanced-time'),
          ),
        ],
      ),
    ),
  );
  Widget transport() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (run.staticLab)
          const Paragraph(
            'Supported static investigation',
            'Bodies/probe are held at chosen coordinates. Drag or edit to measure the field; this is not an orbital motion simulation.',
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('play-advanced'),
                onPressed: playing ? pause : play,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(playing ? 'Pause' : 'Play'),
              ),
              OutlinedButton(
                key: const Key('step-advanced'),
                onPressed: () {
                  pause();
                  run.step(capture: true);
                  cursor = run.samples.length - 1;
                  tick.value++;
                },
                child: const Text('Single step'),
              ),
              OutlinedButton(onPressed: reset, child: const Text('Reset')),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<double>(
            isExpanded: true,
            initialValue: clock.speed,
            decoration: const InputDecoration(labelText: 'Simulation speed'),
            items: [.25, .5, 1.0, 2.0]
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(
                      '$x× ${run.timeScale == 480 ? 'orbital clock (480× base)' : 'physical time'}',
                    ),
                  ),
                )
                .toList(),
            onChanged: (x) => clock.speed = x!,
          ),
          TextButton(
            key: const Key('replay-advanced'),
            onPressed: () {
              pause();
              showDialog<void>(
                context: context,
                builder: (_) => NumericInputDialog(
                  label: 'Physical time replay (s)',
                  initial: run.time,
                  min: 0,
                  max: 120 * run.timeScale,
                  onApply: (t) {
                    run = AdvancedRun(kind, parameters)..seek(t);
                    cursor = run.samples.length - 1;
                    tick.value++;
                    setState(() {});
                  },
                ),
              );
            },
            child: const Text('Time scrubber / deterministic replay'),
          ),
          const Text(
            '120 Hz clock · bounded catch-up · background and navigation pause.',
            style: TextStyle(fontSize: 11, color: muted),
          ),
        ],
      ],
    ),
  );
  Widget parameter(Parameter p) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(p.label, style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              key: Key('edit-${p.key}'),
              onPressed: () {
                pause();
                showDialog<void>(
                  context: context,
                  builder: (_) => NumericInputDialog(
                    label: '${p.label} (${p.unit})',
                    initial: parameters[p.key]!,
                    min: p.min,
                    max: p.max,
                    onApply: (x) => updateMany({p.key: x}),
                  ),
                );
              },
              child: Text('${number(parameters[p.key])} ${p.unit} ✎'),
            ),
          ],
        ),
        Slider(
          min: p.min,
          max: p.max,
          value: parameters[p.key]!.clamp(p.min, p.max),
          semanticFormatterCallback: (x) => '$x ${p.unit}',
          onChanged: (x) => updateMany({p.key: x}),
        ),
      ],
    ),
  );
  List<Widget> presets() => [
    if (kind == 9 || kind == 10)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => updateMany({
              'vr': 0,
              'vt':
                  math.sqrt(
                    earthMu *
                        parameters['source']! /
                        (parameters['r']! * earthRadius),
                  ) /
                  1000,
            }),
            child: const Text('Circular reference'),
          ),
          if (kind == 10)
            for (final factor in [.9, 1.0, 1.1])
              OutlinedButton(
                onPressed: () => updateMany({
                  'vt': 0,
                  'vr':
                      factor *
                      escapeSpeed(
                        earthMu * parameters['source']!,
                        parameters['r']! * earthRadius,
                      ) /
                      1000,
                }),
                child: Text('$factor× escape speed'),
              ),
        ],
      ),
    if (kind == 15)
      Wrap(
        spacing: 8,
        children: [
          for (final factor in [.4, 1.0, 2.0])
            OutlinedButton(
              onPressed: () => updateMany({
                'b':
                    factor * 2 * math.sqrt(parameters['m']! * parameters['k']!),
              }),
              child: Text(
                factor == 1
                    ? 'Critical'
                    : factor < 1
                    ? 'Underdamped'
                    : 'Overdamped',
              ),
            ),
        ],
      ),
    if (kind == 16)
      OutlinedButton(
        onPressed: () => updateMany({
          'omega': math.sqrt(parameters['k']! / parameters['m']!),
        }),
        child: const Text('Drive at natural frequency'),
      ),
    if (kind == 17)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final mode in ['In phase', 'Out of phase', 'One-mass release'])
            OutlinedButton(
              onPressed: () => updateMany({
                'm': 1,
                'm2': 1,
                'k': 20,
                'k2': 20,
                'kc': 2,
                'x0': .15,
                'x2': mode == 'In phase'
                    ? .15
                    : mode == 'Out of phase'
                    ? -.15
                    : 0,
                'v0': 0,
                'v2': 0,
              }),
              child: Text(mode),
            ),
        ],
      ),
  ];
  List<LabState> get curveData {
    final data = <LabState>[];
    for (int i = 0; i <= 160; i++) {
      final x = kind == 1
          ? -10 + 20 * i / 160
          : kind == 6
          ? 3 + 77 * i / 160
          : kind == 16
          ? 15 * i / 160
          : 1.01 + 10.99 * i / 160;
      final r = x * earthRadius, mu = earthMu * (parameters['source'] ?? 1);
      if (kind == 1) {
        data.add({'t': x, 'K': kinetic(parameters['m']!, x)});
      } else if (kind == 6) {
        data.add({
          't': x,
          'force': mu * parameters['second']! * moonMass / (r * r),
          'force2': -mu * parameters['second']! * moonMass / (r * r),
        });
      } else if (kind == 7) {
        data.add({'t': x, 'field': mu / (r * r)});
      } else if (kind == 8) {
        data.add({
          't': x,
          'potential': -mu / r,
          'U': -parameters['m']! * mu / r,
        });
      } else if (kind == 16) {
        final response = drivenResponse(
          parameters['m']!,
          parameters['k']!,
          parameters['b']!,
          parameters['force']!,
          x,
        );
        data.add({
          't': x,
          if (response.amplitude.isFinite) 'amplitude': response.amplitude,
          'phase': response.phase,
        });
      }
    }
    return data;
  }

  Widget graph() => ListenableBuilder(
    listenable: graphTick,
    builder: (context, _) {
      final data = curve ? curveData : run.samples;
      final keys = curve
          ? [
              kind == 1
                  ? 'K'
                  : kind == 6
                  ? 'force'
                  : kind == 7
                  ? 'field'
                  : kind == 8
                  ? 'potential'
                  : 'amplitude',
            ]
          : overlays &&
                ['K', 'total'].contains(channel) &&
                [3, 14].contains(kind)
          ? ['K', 'U', 'total']
          : overlays && channel == 'x' && kind == 17
          ? ['x', 'x2']
          : [channel];
      final currentIndex = cursor.clamp(0, data.length - 1),
          selected = data[currentIndex];
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Eyebrow(
              curve
                  ? 'Analytic parameter curve · not observed trials'
                  : 'Actual computed trajectory · bounded 301 samples',
            ),
            if ([1, 6, 7, 8, 16].contains(kind))
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Analytic parameter curve'),
                value: curve,
                onChanged: (x) {
                  setState(() => curve = x);
                  cursor = 0;
                  graphTick.value++;
                },
              ),
            if (!curve)
              DropdownButtonFormField<String>(
                key: ValueKey(channel),
                isExpanded: true,
                initialValue: channel,
                decoration: const InputDecoration(labelText: 'Graph quantity'),
                items: channelsFor(kind)
                    .map(
                      (key) => DropdownMenuItem(
                        value: key,
                        child: Text('$key (${unitFor(key)})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() => channel = value!);
                  graphTick.value++;
                },
              ),
            const SizedBox(height: 10),
            Text(keys.map(labelFor).join(' / ')),
            InteractiveViewer(
              transformationController: graphView,
              minScale: 1,
              maxScale: 4,
              child: RepaintBoundary(
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CustomPaint(
                    painter: LabPlot(
                      data,
                      keys,
                      curve
                          ? kind == 1
                                ? 'Signed speed (m/s)'
                                : kind == 16
                                ? 'Drive ω (rad/s)'
                                : 'Centre distance (Earth radii)'
                          : 'Physical time (s)',
                      curve && kind == 16 ? 'm' : unitFor(keys.first),
                      currentIndex,
                    ),
                  ),
                ),
              ),
            ),
            TextButton(
              onPressed: () => graphView.value = Matrix4.identity(),
              child: const Text('Reset graph zoom'),
            ),
            if (data.length > 1)
              Slider(
                key: const Key('cursor-advanced'),
                min: 0,
                max: (data.length - 1).toDouble(),
                divisions: data.length - 1,
                value: currentIndex.toDouble(),
                onChanged: (x) {
                  pause();
                  setState(() => cursor = x.round());
                  graphTick.value++;
                },
              ),
            Text(
              '${curve ? 'Parameter' : 'Recorded time'} ${number(selected['t'])}: ${keys.map((k) => '$k ${number(selected[k])}').join(' · ')}',
            ),
            if (kind == 11)
              Text(
                'Equal-time sector area (each T/12): ${number(.5 * math.sqrt(earthMu * parameters['source']! * parameters['a']! * earthRadius * (1 - parameters['e']! * parameters['e']!)) * (run.state['period'] ?? 0) / 12)} m². Both colored sectors use equal physical durations.',
              ),
            if (curve && kind == 16)
              const Text(
                'Finite samples of an analytic response curve, not a time sweep. At b=0, ω=ω₀ has no finite steady amplitude; the exact singular point is excluded.',
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
            title: const Text('Educational overlays'),
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
          if (kind >= 9 && kind <= 11)
            SwitchListTile(
              title: Text(
                store.reducedMotion
                    ? 'Motion trail disabled by Reduced motion'
                    : 'Computed motion trail',
              ),
              value: trails && !store.reducedMotion,
              onChanged: store.reducedMotion
                  ? null
                  : (x) {
                      setState(() => trails = x);
                      tick.value++;
                    },
            ),
        ],
      ),
    ),
    if (overlays && [3, 5, 14, 15, 17].contains(kind)) energyBars(),
    graph(),
    metrics(),
  ];
  Widget energyBars() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final keys = kind == 5
          ? ['input', 'useful', 'loss']
          : kind == 17
          ? ['energy1', 'energy2', 'total']
          : ['K', 'U', if (kind == 3 || kind == 15) 'loss', 'total'];
      final top = math.max(
        1e-10,
        keys.map((k) => run.state[k] ?? 0).reduce(math.max),
      );
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Energy accounting · J'),
            for (int i = 0; i < keys.length; i++)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${keys[i]} ${number(run.state[keys[i]])} J'),
                    LinearProgressIndicator(
                      value: ((run.state[keys[i]] ?? 0) / top).clamp(0, 1),
                      minHeight: 10,
                      color: LabPlot.colors[i % 4],
                      backgroundColor: const Color(0xffeef2f6),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    },
  );
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
                  ? 'I changed a parameter and predicted its effect.'
                  : 'I compared actual values and explained the model limits.',
            ),
            value: guided > i,
            onChanged: (checked) {
              setState(() => guided = checked == true ? i + 1 : i);
              persist();
            },
          ),
        Text(lesson.question),
        FilledButton(
          key: const Key('predict-advanced'),
          onPressed: prediction,
          child: const Text('Test numerical prediction'),
        ),
        if (feedback.isNotEmpty) Text(feedback),
        Text('${attempts.length} saved attempts in this session (latest 50).'),
        OutlinedButton(
          onPressed: () async {
            if (!changed ||
                guided < 2 ||
                !attempts.any((a) => a['correct'] == true) ||
                !store.trials.any((t) => t.labId == entry.id)) {
              message(
                'Change a parameter, finish both guided checks, answer correctly and record a trial first.',
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
          runSpacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('record-advanced'),
              onPressed: busy ? null : record,
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
          const SizedBox(height: 16),
          Paragraph('Symbols, units and sign conventions', lesson.symbols),
          Paragraph('Validity and method', lesson.limits),
          Paragraph('Worked example', lesson.example),
          Paragraph(
            'Current-value substitution',
            'Parameters: ${parameters.entries.map((e) => '${e.key}=${number(e.value)}').join(', ')}. At t=${number(run.time)} s, ${lesson.metric}=${number(result)} ${lesson.unit}. ${substitution()}',
          ),
          const Paragraph(
            'References',
            'OpenStax University Physics Vol. 1, chapters 7–8, 13, 15; NIST gravitational constant; JPL astrodynamic parameters. See docs/PHASE3_SCIENCE.md for per-model equations, reference links, methods and error tests.',
          ),
        ],
      ),
    ),
  ];
  String substitution() => switch (kind) {
    0 =>
      'WF = ${number(parameters['force'])} × ${number(run.state['x'])} × cos(${number(parameters['angle'])}°) = ${number(run.state['appliedWork'])} J; net = applied − loss = ${number(result)} J.',
    1 =>
      'K = 0.5 × ${number(parameters['m'])} × (${number(parameters['speed'])})² = ${number(result)} J (translational only).',
    2 =>
      'ΔUtarget = ${number(parameters['m'])} × ${number(parameters['g'])} × ${number(parameters['height'])} = ${number(result)} J.',
    3 =>
      'K ${number(run.state['K'])} + U ${number(run.state['U'])} + loss ${number(run.state['loss'])} = ${number(result)} J.',
    4 =>
      'Pavg = ${number(parameters['m'])} × 9.80665 × ${number(parameters['height'])} / ${number(parameters['duration'])} = ${number(result)} W.',
    5 =>
      'Useful = ${number(run.state['input'])} × ${number(parameters['eta'])} = ${number(run.state['useful'])} J.',
    >= 6 && <= 11 =>
      'μ = ${number(earthMu)} × ${number(parameters['source'])}; r = ${number(run.state['radius'])} m. V=−μ/r; ε=v²/2−μ/r. Current values are computed using these SI quantities.',
    13 =>
      'T0 = 2π√(${number(parameters['length'])}/${number(parameters['g'])}) = ${number(run.state['smallPeriod'])} s; nonlinear T=${number(result)} s.',
    17 =>
      'E = K ${number(run.state['K'])} + U ${number(run.state['U'])} = ${number(result)} J.',
    _ =>
      'ω0 = √(${number(parameters['k'])}/${number(parameters['m'])}) = ${number(run.state['naturalOmega'])} rad/s; K=${number(run.state['K'])} J, U=${number(run.state['U'])} J.',
  };
  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    return [
      Text(
        'Recorded observations',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      Panel(
        child: Paragraph(
          '${trials.length} actual records',
          trials.isEmpty
              ? 'No observations yet. Record a computed state in Experiment.'
              : '${lesson.metric}: mean ${number(trials.map((t) => t.value).reduce((a, b) => a + b) / trials.length)} ${lesson.unit}. Compare only matching protocols.',
        ),
      ),
      if (trials.isNotEmpty)
        FilledButton.icon(
          onPressed: () => exportTrials(context, trials),
          icon: const Icon(Icons.ios_share),
          label: const Text('Export actual trials as CSV'),
        ),
      const SizedBox(height: 12),
      for (final trial in trials.reversed)
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${number(trial.value)} ${trial.unit}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(trial.note.isEmpty ? 'No notes' : trial.note),
              Text(
                'Model ${trial.model} · ${trial.created}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
              Text('Settings ${trial.configuration['parameters']}'),
              TextButton(
                onPressed: () {
                  if (restore(trial.configuration)) {
                    setState(() => section = 1);
                    tick.value++;
                    message(
                      'Original configuration restored; simulation paused.',
                    );
                  } else {
                    message(
                      'Saved configuration is incompatible; original record remains preserved.',
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
}
