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
import '../../core/persistence/notebook.dart';
import '../../core/physics/dynamics.dart';
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'curriculum.dart';
import 'scene.dart';

final dynamicsRouteObserver = RouteObserver<ModalRoute<void>>();

class DynamicsWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const DynamicsWorkspace({super.key, required this.entry});
  @override
  ConsumerState<DynamicsWorkspace> createState() => _DynamicsState();
}

class _DynamicsState extends ConsumerState<DynamicsWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late Map<String, double> parameters;
  late DynamicsRun run;
  late final Ticker ticker;
  late final LocalNotebook store;
  final clock = FixedClock();
  final tick = ValueNotifier<int>(0);
  final graphTick = ValueNotifier<int>(0);
  String graphStamp = '';
  final view = TransformationController();
  final notes = TextEditingController();
  int section = 1, mode = 0, frame = 0, cursor = 0, guided = 0, task = 0;
  bool ready = false,
      isolated = false,
      components = true,
      labels = true,
      trails = true,
      recording = false,
      changedByUser = false;
  Duration previous = Duration.zero;
  String channel = 'x',
      feedback = '',
      changeNotice =
          'Changes to model parameters pause and restart the trajectory.';
  final attempts = <Map<String, dynamic>>[];
  Entry get entry => widget.entry;
  bool get staticLab => kind == 3 || kind == 4;
  bool get playing => ticker.isActive;
  @override
  void initState() {
    super.initState();
    kind = (entry.studioIndex - 2) * 6 + entry.index;
    lesson = lessons[kind];
    parameters = lesson.defaults;
    run = DynamicsRun(kind, parameters);
    channel = channels.first;
    store = ref.read(notebookProvider);
    ticker = createTicker(onFrame);
    tick.addListener(() {
      final stamp =
          '${identityHashCode(run)}:${run.samples.last['t']}:$cursor:$frame:$channel';
      if (stamp != graphStamp) {
        graphStamp = stamp;
        graphTick.value++;
      }
    });
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      dynamicsRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    pause();
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
    if (data != null) {
      if (!restore(data)) {
        await store.retainRejectedSession(entry.id, data);
        changeNotice = 'Saved model is incompatible. Defaults are shown; original trial records remain in the notebook.';
      }
    }
    await store.visit(entry.id);
    if (mounted) {
      setState(() => ready = true);
    }
  }

  void onFrame(Duration elapsed) {
    final delta = (elapsed - previous).inMicroseconds / 1e6;
    previous = elapsed;
    clock.advance(delta, run.step);
    cursor = run.samples.length - 1;
    tick.value++;
    if (run.finished) {
      pause();
    }
  }

  void play() {
    if (run.finished) {
      reset();
    }
    previous = Duration.zero;
    clock.pause();
    ticker.start();
    setState(() {});
  }

  void pause() {
    ticker.stop();
    clock.pause();
    if (mounted) {
      setState(() {});
    }
  }

  void reset() {
    pause();
    run = DynamicsRun(kind, parameters, mode: mode);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void update(String key, double value) {
    pause();
    parameters[key] = value;
    if ((parameters['muk'] ?? 0) > (parameters['mus'] ?? 1)) {
      parameters['muk'] = parameters['mus']!;
      changeNotice = 'μk was limited to μs. New trajectory starts at t=0.';
    }
    if (kind == 0 || (kind == 16 && mode == 1)) {
      final fy =
              (parameters['force'] ?? 0) *
              math.sin((parameters['angle'] ?? 0) * math.pi / 180),
          mg = parameters['m']! * standardGravity;
      if (fy > mg) {
        parameters['force'] =
            mg / math.sin(parameters['angle']! * math.pi / 180);
        changeNotice = 'Upward force is limited to mg to preserve contact; lift-off is not supported. Trajectory restarted.';
      } else {
        changeNotice =
            'Initial condition changed: trajectory restarted at t=0.';
      }
    } else {
      changeNotice = 'Initial condition changed: trajectory restarted at t=0.';
    }
    changedByUser = true;
    run = DynamicsRun(kind, parameters, mode: mode);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void selectMode(int value) {
    pause();
    mode = value;
    update(parameters.keys.first, parameters.values.first);
  }

  Map<String, dynamic> configuration() => {
    'model': dynamicsVersion,
    'kind': kind,
    'parameters': parameters,
    'mode': mode,
    'frame': frame,
    'ticks': run.ticks,
    'notes': notes.text,
    'guided': guided,
    'task': task,
    'feedback': feedback,
    'attempts': attempts,
    'overlays': {
      'isolated': isolated,
      'components': components,
      'labels': labels,
      'trails': trails,
    },
    'speed': clock.speed,
    'changedByUser': changedByUser,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != dynamicsVersion || data['kind'] != kind) {
        return false;
      }
      final raw = Map<String, dynamic>.from(data['parameters']);
      final next = <String, double>{};
      for (final item in lesson.controls) {
        final value = (raw[item.key] as num).toDouble();
        if (!value.isFinite ||
            value < item.min - 1e-9 ||
            value > item.max + 1e-9) {
          return false;
        }
        next[item.key] = value;
      }
      final newMode = (data['mode'] as int).clamp(0, 1),
          newTicks = (data['ticks'] as int).clamp(0, 2400);
      if ((next['muk'] ?? 0) > (next['mus'] ?? 1)) {
        return false;
      }
      if (kind == 0 || (kind == 16 && newMode == 1)) {
        if (next['force']! * math.sin(next['angle']! * math.pi / 180) >
            next['m']! * standardGravity + 1e-8) {
          return false;
        }
      }
      ticker.stop();
      clock.pause();
      parameters = next;
      mode = newMode;
      frame = (data['frame'] as int).clamp(0, 2);
      run = DynamicsRun(kind, parameters, mode: mode)
        ..seek(newTicks * DynamicsRun.dt);
      cursor = run.samples.length - 1;
      notes.text = data['notes'] ?? '';
      guided = (data['guided'] as int? ?? 0).clamp(0, 2);
      task = (data['task'] as int? ?? 0).clamp(0, 5);
      feedback = data['feedback'] is String ? data['feedback'] : '';
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? []).map(
            (x) => Map<String, dynamic>.from(x),
          ),
        );
      final overlays = data['overlays'] as Map?;
      isolated = overlays?['isolated'] ?? false;
      components = overlays?['components'] ?? true;
      labels = overlays?['labels'] ?? true;
      trails = overlays?['trails'] ?? true;
      clock.speed = (data['speed'] as num? ?? 1).toDouble().clamp(.25, 2);
      changedByUser = data['changedByUser'] ?? false;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() async {
    await store.saveSession(entry.id, configuration());
  }

  Future<void> save() async {
    pause();
    try {
      await persist();
      message(
        'Session saved with initial conditions, time and challenge history.',
      );
    } catch (_) {
      message('Saving failed; this session remains open.');
    }
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Observation get current => run.state;
  double get result => current[lesson.metric] ?? 0;
  String number(double? n) =>
      n == null ? 'Undefined' : n.toStringAsPrecision(5);
  String get quantity => switch (lesson.unit) {
    'm' => 'length',
    'm/s' => 'velocity',
    'm/s²' => 'acceleration',
    'N' => 'force',
    'N·m' => 'torque',
    _ => 'momentum',
  };
  Future<void> record() async {
    if (recording) {
      return;
    }
    pause();
    setState(() => recording = true);
    try {
      final config = configuration()
        ..['observations'] = run.samples
        ..['impacts'] = run.impacts;
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
          model: dynamicsVersion,
        ),
      );
      await persist();
      if (store.haptics) {
        HapticFeedback.lightImpact();
      }
      message('Actual ${lesson.metric} recorded at t=${number(run.time)} s.');
    } catch (_) {
      message('The observation could not be saved.');
    }
    if (mounted) {
      setState(() => recording = false);
    }
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
    notes.dispose();
    super.dispose();
  }

  List<String> get channels => switch (kind) {
    0 || 15 => ['x', 'vx', 'fx', 'friction'],
    1 => ['x', 'vx', 'ax', 'friction'],
    2 => ['x', 'x2', 'vx', 'v2', 'tension'],
    3 => ['netTorque', 'torque1', 'torque2'],
    4 => ['x', 'y', 'netTorque'],
    5 => ['x', 'x2', 'vx', 'v2', 'momentum', 'energy', 'impulse'],
    6 || 7 || 8 => ['x', 'vx', 'ax', 'displacement', 'distance'],
    9 => ['x', 'y', 'vx', 'vy'],
    10 => ['x', 'x2', 'vx', 'v2', 'relativePosition', 'relativeVelocity'],
    11 => ['x', 'y', 'vx', 'vy', 'ax', 'ay', 'radialForce'],
    12 || 13 => ['x', 'vx', 'ax', 'fx'],
    14 => ['x', 'x2', 'vx', 'v2', 'fx', 'force2', 'momentum'],
    16 => ['supportForce', 'x', 'y', 'vx', 'vy'],
    _ => ['x', 'y', 'vx', 'vy', 'fx', 'fy'],
  };
  String units(String key) =>
      [
        'x',
        'x2',
        'y',
        'distance',
        'displacement',
        'relativePosition',
      ].contains(key)
      ? 'm'
      : ['vx', 'vy', 'v2', 'relativeVelocity'].contains(key)
      ? 'm/s'
      : ['ax', 'ay'].contains(key)
      ? 'm/s²'
      : key.toLowerCase().contains('torque')
      ? 'N·m'
      : key == 'energy'
      ? 'J'
      : key == 'momentum'
      ? 'kg·m/s'
      : key == 'impulse'
      ? 'N·s'
      : 'N';
  List<Observation> get graphSamples => kind != 10 || frame == 0
      ? run.samples
      : run.samples.map((s) {
          final observer = parameters[frame == 1 ? 'v0' : 'v2']!;
          return {
            ...s,
            'x': s['x']! - observer * s['t']!,
            'x2': s['x2']! - observer * s['t']!,
            'vx': s['vx']! - observer,
            'v2': s['v2']! - observer,
          };
        }).toList();
  List<InstrumentControl> instrumentControls() => [
    for (final p in lesson.controls)
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
            ? changedByUser
            : step == 1
            ? (!(!staticLab) || run.time > 0)
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
        notice: () => changeNotice,
        playing: () => ticker.isActive,
        dynamicModel: () => !staticLab,
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
                if (section == 0)
                  ...learn()
                else if (section == 1)
                  ...experiment()
                else if (section == 2)
                  ...visualize()
                else if (section == 3)
                  ...formulas()
                else
                  ...results(),
              ],
            ),
    ),
  );
  List<Widget> learn() => [
    relatedLabs(entry.id),
    const SizedBox(height: 14),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Paragraph(
            'Learning objectives',
            '${entry.principle}\nUse the ${lesson.apparatus.toLowerCase()}\nPredict ${lesson.metric} in ${lesson.unit}, test it and explain the result.',
          ),
          Paragraph('Apparatus', lesson.apparatus),
          Paragraph('Physical principles', lesson.principle),
          Paragraph('Investigation procedure', lesson.procedure),
          Paragraph('Assumptions & valid range', lesson.limits),
          Paragraph('Misconceptions', lesson.mistake),
          const Paragraph(
            'Sources of error',
            'The displayed data are model calculations, not sensor measurements. Rounded labels differ from full-precision saved values. Physical apparatus could add calibration error, drag, compliance or friction beyond this stated idealization. Graph samples are bounded; a cursor selects an actual sample.',
          ),
          Paragraph('Guided question', lesson.question),
          FilledButton.icon(
            onPressed: () => setState(() => section = 1),
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Open experiment'),
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
          const Eyebrow('Explore · model parameters'),
          const SizedBox(height: 10),
          Text(
            changeNotice,
            style: const TextStyle(color: muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          ...modeControls(),
          for (final item in lesson.controls)
            if (item.max > item.min &&
                !(kind == 8 &&
                    mode == 0 &&
                    ['a2', 'switch'].contains(item.key)) &&
                !(kind == 4 &&
                    ((mode == 0 && ['hangX', 'hangY'].contains(item.key)) ||
                        (mode == 1 &&
                            ['support', 'base'].contains(item.key)))) &&
                !(kind == 16 &&
                    ((mode == 0 && ['force', 'angle'].contains(item.key)) ||
                        (mode == 1 && item.key == 'a'))))
              parameterControl(item),
          if (kind == 15) ...surfacePresets(),
        ],
      ),
    ),
    graph(),
    if (kind == 13) sweeps(),
    investigation(),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Observation notes'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('record-dynamics'),
                onPressed: recording ? null : record,
                icon: const Icon(Icons.add),
                label: const Text('Record Trial'),
              ),
              OutlinedButton(
                onPressed: save,
                child: const Text('Save session'),
              ),
            ],
          ),
        ],
      ),
    ),
  ];
  Widget compactScene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final painter = DynamicsPainter(
        kind: kind,
        s: current,
        p: parameters,
        samples: store.reducedMotion ? const [] : run.samples,
        mode: mode,
        frame: frame,
        isolated: isolated,
        components: components,
        labels: labels,
        trails: trails && !store.reducedMotion,
      );

      return LayoutBuilder(
        builder: (context, box) => Semantics(
          label: painter.accessibleSummary,
          child: ApparatusTransform(
            transformationController: view,
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: (event) =>
                  drag(event.localPosition, box.maxWidth),
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(box.maxWidth, 245),
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
      final painter = DynamicsPainter(
        kind: kind,
        s: current,
        p: parameters,
        samples: store.reducedMotion ? const [] : run.samples,
        mode: mode,
        frame: frame,
        isolated: isolated,
        components: components,
        labels: labels,
        trails: trails && !store.reducedMotion,
      );
      return Panel(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
              child: Row(
                children: [
                  const Expanded(
                    child: Eyebrow('SI world · drag blue handles'),
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
                    onHorizontalDragUpdate: (event) =>
                        drag(event.localPosition, box.maxWidth),
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(box.maxWidth, 245),
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
                dragHint,
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      );
    },
  );
  String get dragHint => switch (kind) {
    0 => 'Drag force direction/magnitude; precise alternatives below.',
    1 => 'Drag ramp handle to change inclination; release restarts.',
    2 => 'Drag a hanging mass to edit load mass; topology selector below.',
    3 => 'Drag force attachment A along the static beam.',
    4 => 'Drag mass A in the original geometry; suspension is calculated equilibrium.',
    5 => 'Drag cart A starting position; velocities are signed.',
    9 => 'Drag launch-direction handle; height and speed below.',
    10 => 'Drag train A velocity; switching frame preserves time.',
    11 => 'Drag to adjust the circular-track radius.',
    16 => 'Drag to adjust body mass; select hanging or table mode below.',
    17 => 'Drag force 1 vector in the top-down plane.',
    _ => 'Drag to change initial velocity; numerical alternatives below.',
  };
  void drag(Offset point, double width) {
    final x = point.dx / width * 360, y = point.dy / 245 * 270;
    if (kind == 0 || kind == 17 || kind == 9) {
      final position = Vec2(current['x'] ?? 0, current['y'] ?? 0);
      final scale = math.min(30.0, 110 / (position.magnitude + 1));
      final anchor = kind == 0
          ? const Offset(180, 176)
          : kind == 17
          ? Offset(180 + position.x * scale, 129 - position.y * scale)
          : Offset(
              35,
              218 -
                  parameters['height']! *
                      165 /
                      math.max(2, current['maxHeight'] ?? 2),
            );
      final dx = x - anchor.dx, dy = anchor.dy - y;
      final angle = math.atan2(dy, dx) * 180 / math.pi;
      if (kind == 9) {
        update('angle', angle.clamp(-90, 90));
      } else {
        update(kind == 17 ? 'd1' : 'angle', angle.clamp(-180, 180));
        update(
          kind == 17 ? 'f1' : 'force',
          (math.sqrt(dx * dx + dy * dy) / 4).clamp(0, kind == 17 ? 20 : 60),
        );
      }
    } else if (kind == 1) {
      update(
        'angle',
        (math.atan2(y - 61, x - 38) * 180 / math.pi).clamp(0, 65),
      );
    } else if (kind == 3) {
      update('r1', ((x - 180) / 65).clamp(-2, 2));
    } else if (kind == 4) {
      if (mode == 1) {
        message(
          'Edit original coordinates numerically, or choose Supported base for direct mass dragging.',
        );
        return;
      }
      update('x0', ((x - 180) / 45).clamp(-2, 2));
      update('y1', ((222 - y) / 53).clamp(0, 2));
    } else if (kind == 5) {
      update('x0', ((x - 180) / 50).clamp(-3, 0));
    } else if (kind == 11) {
      update(
        'radius',
        (math.sqrt(math.pow(x - 180, 2) + math.pow(y - 137, 2)) / 41).clamp(
          .2,
          3,
        ),
      );
    } else if (kind == 2 || kind == 16) {
      update('m', ((240 - y) / 20).clamp(.2, 10));
    } else if (parameters.containsKey('v0')) {
      update(
        'v0',
        ((x - 180) / 30).clamp(
          lesson.controls.firstWhere((p) => p.key == 'v0').min,
          lesson.controls.firstWhere((p) => p.key == 'v0').max,
        ),
      );
    }
  }

  Widget metrics() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Live computed state'),
          const SizedBox(height: 10),
          Text(
            '${lesson.metric}: ${number(result)} ${lesson.unit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(metricSummary()),
          if (run.finished)
            const Text(
              'Run stopped at a physical limit or 20 s horizon.',
              style: TextStyle(color: teal),
            ),
          if (staticLab)
            const Text(
              'Static investigation: no rotational or suspension transient dynamics.',
            ),
        ],
      ),
    ),
  );
  String metricSummary() {
    final s = current;
    String f(String key) => number(s[key]);
    return switch (kind) {
      0 || 1 || 15 =>
        'x ${f('x')} m · v ${f('vx')} m/s · a ${f('ax')} m/s²\nN ${f('normal')} N · f ${f('friction')} N\n${s['vx']!.abs() < 1e-9 ? 'Static or stopped' : 'Sliding'} · resultant ${f('fx')} N',
      2 =>
        'A/load x ${f('x')} m · other displacement ${f('x2')} m\nv ${f('vx')} / ${f('v2')} m/s · T ${f('tension')} N\n${mode == 0 ? 'xA + xB = 0 in common-up coordinates' : '2xload − xeffort = 0 in load-up/effort-down coordinates'}',
      3 =>
        'τA ${f('torque1')} · τB ${f('torque2')} N·m\nPerpendicular arms ${f('arm1')} / ${f('arm2')} m\n${(s['netTorque'] ?? 0).abs() < .01 ? 'Torque equilibrium within 0.01 N·m' : 'A clamp would be needed to hold this orientation'}; pivot reaction balances net force.',
      4 =>
        'Original-frame COM (${f('x')}, ${f('y')}) m\nWeight and total support = ${number(s['normal'])} N\n${mode == 1
            ? 'Suspension: COM lies below eye on the plumb line.'
            : s['stable'] == 1
            ? 'COM projection inside base: supported equilibrium feasible.'
            : s['stable'] == 0
            ? 'Projection at edge: marginal, not neutral.'
            : 'Outside base: unbalanced tipping torque.'}',
      5 =>
        'p ${f('momentum')} kg·m/s; initial ${f('initialMomentum')}\nK ${f('energy')} J; initial ${f('initialEnergy')}\nJ ${f('impulse')} N·s; vA ${f('vx')}, vB ${f('v2')} m/s\n${run.impacts.length} impact(s)',
      6 || 7 || 8 =>
        'x ${f('x')} m · displacement ${f('displacement')} m\nDistance ${f('distance')} m · v ${f('vx')} m/s\nAverage v ${f('averageVelocity')} m/s · a ${f('ax')} m/s²',
      9 =>
        'Position (${f('x')},${f('y')}) m\nVelocity (${f('vx')},${f('vy')}) m/s\nFlight ${f('flight')} s · apex ${f('maxHeight')} m · landing x ${f('range')} m',
      10 =>
        'Ground xA ${f('x')},xB ${f('x2')} m\nRelative x ${f('relativePosition')} m · relative v ${f('relativeVelocity')} m/s\nFrame ${['Ground', 'A', 'B'][frame]}: vA ${number(s['vx']! - (frame == 1
                ? parameters['v0']!
                : frame == 2
                ? parameters['v2']!
                : 0))} m/s; time unchanged.',
      11 =>
        'ω ${f('omega')} rad/s · period ${(s['period'] ?? 0) == 0 ? '∞ (zero speed)' : f('period')} s\nInward a ${number(Vec2(s['ax']!, s['ay']!).magnitude)} m/s² · radial resultant ${f('radialForce')} N',
      14 =>
        'Force on A ${f('fx')} N; on B ${f('force2')} N\naA ${f('ax')}, aB ${f('a2')} m/s²\nvA ${f('vx')},vB ${f('v2')} m/s\nSystem p ${f('momentum')} kg·m/s',
      16 =>
        'Weight ${f('weight')} N · support ${f('supportForce')} N\nNet (${f('fx')}, ${f('fy')}) N\nNo negative tension or pulling normal reaction allowed.',
      17 =>
        'ΣF (${f('fx')},${f('fy')}) N\nAcceleration (${f('ax')},${f('ay')}) m/s²\nResultant ${f('resultant')} N at ${f('direction')}°',
      _ =>
        't ${f('t')} s · x ${f('x')} m\nv ${f('vx')} m/s · a ${f('ax')} m/s² · net F ${f('fx')} N',
    };
  }

  Widget transport() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              key: const Key('play-dynamics'),
              onPressed: playing ? pause : play,
              icon: Icon(playing ? Icons.pause : Icons.play_arrow),
              label: Text(playing ? 'Pause' : 'Play'),
            ),
            OutlinedButton(
              key: const Key('step-dynamics'),
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
        const SizedBox(height: 10),
        DropdownButtonFormField<double>(
          isExpanded: true,
          initialValue: clock.speed,
          decoration: const InputDecoration(labelText: 'Simulation speed'),
          items: [.25, .5, 1.0, 2.0]
              .map(
                (v) =>
                    DropdownMenuItem(value: v, child: Text('$v× physics time')),
              )
              .toList(),
          onChanged: (v) {
            clock.speed = v!;
          },
        ),
        const SizedBox(height: 10),
        const Text(
          '120 Hz fixed physics · bounded catch-up · backgrounding pauses. Model changes restart; frame/overlay changes preserve the event.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
  Widget parameterControl(Parameter item) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          children: [
            Text(item.label, style: Theme.of(context).textTheme.titleMedium),
            TextButton(
              key: Key('edit-${item.key}'),
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NumericInputDialog(
                  label: '${item.label} (${item.unit})',
                  initial: parameters[item.key]!,
                  min: item.min,
                  max: item.max,
                  onApply: (v) => update(item.key, v),
                ),
              ),
              child: Text('${number(parameters[item.key])} ${item.unit} ✎'),
            ),
          ],
        ),
        Slider(
          value: parameters[item.key]!.clamp(item.min, item.max),
          min: item.min,
          max: item.max,
          semanticFormatterCallback: (v) => '$v ${item.unit}',
          onChanged: (v) => update(item.key, v),
        ),
      ],
    ),
  );
  List<Widget> modeControls() => [
    if ([2, 4, 8, 16].contains(kind))
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<int>(
          isExpanded: true,
          initialValue: mode,
          decoration: const InputDecoration(
            labelText: 'Supported configuration',
          ),
          items: [
            for (int i = 0; i < 2; i++)
              DropdownMenuItem(
                value: i,
                child: Text(switch (kind) {
                  2 => ['Fixed Atwood', 'One movable pulley'][i],
                  4 => ['Supported base', 'Suspended equilibrium'][i],
                  8 => ['Constant acceleration', 'Two-segment schedule'][i],
                  _ => ['Hanging mass', 'Block on table'][i],
                }),
              ),
          ],
          onChanged: (v) => selectMode(v!),
        ),
      ),
    if (kind == 10)
      DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: frame,
        decoration: const InputDecoration(
          labelText: 'Observer reference frame (preserves time)',
        ),
        items: [
          for (int i = 0; i < 3; i++)
            DropdownMenuItem(
              value: i,
              child: Text(['Ground', 'Object A', 'Object B'][i]),
            ),
        ],
        onChanged: (v) {
          setState(() => frame = v!);
          tick.value++;
        },
      ),
  ];
  List<Widget> surfacePresets() => [
    const Paragraph(
      'Illustrative presets',
      'Editable model values only; these are not universal material constants.',
    ),
    Wrap(
      spacing: 8,
      children: [
        for (final preset in [
          (name: 'Wood', s: .4, k: .25),
          (name: 'Rubber', s: .8, k: .6),
          (name: 'Ice', s: .08, k: .04),
        ])
          OutlinedButton(
            onPressed: () {
              parameters['muk'] = preset.k;
              update('mus', preset.s);
            },
            child: Text(preset.name),
          ),
      ],
    ),
  ];
  Widget graph() => ListenableBuilder(
    listenable: graphTick,
    builder: (context, _) {
      final data = graphSamples;
      final selected = data[cursor.clamp(0, data.length - 1)];
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: channel,
              decoration: const InputDecoration(
                labelText: 'Computed graph channel',
              ),
              items: channels
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text('$c (${units(c)})'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => channel = v!);
              },
            ),
            const SizedBox(height: 16),
            Semantics(
              label:
                  '$channel graph, ${data.length} computed samples. Selected t ${selected['t']} s, value ${selected[channel] ?? 0} ${units(channel)}.',
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: RepaintBoundary(
                  child: SizedBox(
                    height: 205,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: DynamicsGraph(
                        data,
                        channel,
                        units(channel),
                        cursor,
                        tangent: kind == 6 && channel == 'x',
                        stepPlot: kind == 8 && channel == 'ax',
                        signedArea: kind == 7 && channel == 'vx',
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Text(
              'Sample ${cursor + 1}/${data.length}: t=${number(selected['t'])} s, $channel=${number(selected[channel] ?? 0)} ${units(channel)}',
            ),
            Slider(
              key: const Key('graph-cursor'),
              value: cursor.clamp(0, data.length - 1).toDouble(),
              min: 0,
              max: math.max(1, data.length - 1).toDouble(),
              divisions: math.max(1, data.length - 1),
              onChanged: (v) {
                pause();
                cursor = v.round().clamp(0, data.length - 1);
                tick.value++;
              },
            ),
            TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => NumericInputDialog(
                  label: 'Replay to model time (s)',
                  initial: run.time,
                  min: 0,
                  max: 20,
                  onApply: (t) {
                    pause();
                    run.seek(t);
                    cursor = run.samples.length - 1;
                    tick.value++;
                  },
                ),
              ),
              child: const Text('Time scrubber / deterministic replay'),
            ),
            const Text(
              'Cursor selects an actual recorded sample; no fabricated points. Pinch/pan graph to magnify. History is capped at 301 samples.',
              style: TextStyle(color: muted, fontSize: 11),
            ),
            if ([6, 7, 8].contains(kind))
              Text(
                kind == 6
                    ? 'Current tangent slope dx/dt = ${number(current['vx'])} m/s.'
                    : kind == 7
                    ? 'Signed v–t area = ${number(current['displacement'])} m; integral |v| = ${number(current['distance'])} m.'
                    : 'Signed a–t area = Δv = ${number(current['vx']! - parameters['v0']!)} m/s.',
              ),
          ],
        ),
      );
    },
  );
  List<Widget> visualize() => [
    scene(),
    metrics(),
    if (kind == 0)
      SwitchListTile(
        title: const Text('Isolate the selected body'),
        subtitle: const Text(
          'External forces on the crate only; components are not added again.',
        ),
        value: isolated,
        onChanged: (v) {
          setState(() => isolated = v);
          tick.value++;
        },
      ),
    if (kind == 0 || kind == 1)
      SwitchListTile(
        title: const Text('Show component explanation'),
        value: components,
        onChanged: (v) {
          setState(() => components = v);
          tick.value++;
        },
      ),
    SwitchListTile(
      title: const Text('Vector labels & time badge'),
      value: labels,
      onChanged: (v) {
        setState(() => labels = v);
        tick.value++;
      },
    ),
    if ([0, 5, 6, 7, 8, 12, 13, 14, 15].contains(kind) ||
        (kind == 16 && mode == 1))
      SwitchListTile(
        title: const Text('Motion trail (reduced motion hides trails)'),
        value: trails,
        onChanged: (v) {
          setState(() => trails = v);
          tick.value++;
        },
      ),
    graph(),
    if (kind == 5)
      Panel(
        child: Paragraph(
          'Impact history',
          run.impacts.isEmpty
              ? 'No approaching contact has occurred.'
              : run.impacts
                    .map(
                      (e) =>
                          't=${number(e['t'])} s; J=${number(e['impulse'])} N·s; vA=${number(e['v1'])}, vB=${number(e['v2'])} m/s',
                    )
                    .join('\n'),
        ),
      ),
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
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Governing equations'),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              lesson.formula,
              textStyle: const TextStyle(fontSize: 21, color: navy),
            ),
          ),
          const SizedBox(height: 18),
          Paragraph('Symbols & sign convention', lesson.symbols),
          Paragraph(
            'Current-value substitution',
            'Parameters: ${parameters.entries.map((e) => '${e.key}=${number(e.value)}').join(', ')}\nAt t=${number(run.time)} s:\n${metricSummary()}',
          ),
          Paragraph('Worked example', lesson.example),
          Paragraph('Assumptions & limits', lesson.limits),
          const Paragraph(
            'Numerical method',
            'Analytic constant-acceleration segments and exact impact/zero-speed event handling. The shared clock advances 1/120 s steps independently of display frames. All graph samples are computed states. See docs/PHASE2_SCIENCE.md for topology, conventions, references and tests.',
          ),
        ],
      ),
    ),
  ];
  Widget investigation() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Guided investigation · predict and check'),
        const SizedBox(height: 12),
        Text(
          'Step ${guided + 1}/3',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          [
            lesson.procedure,
            'Predict before reading the live result. ${lesson.question}',
            'Run/step the supported model, record a trial, then explain ${lesson.mistake.toLowerCase()}',
          ][guided],
        ),
        const SizedBox(height: 10),
        if (kind == 0)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (int i = 0; i < 4; i++)
                OutlinedButton(
                  onPressed: () => attempt(
                    i.toDouble(),
                    1,
                    i < 2,
                    i < 2 ? 'This external force acts on the selected crate.' : 'This belongs to another body, or is a kinematic quantity, so it is not a force on the crate.',
                  ),
                  child: Text(
                    [
                      'Weight on crate',
                      'Normal on crate',
                      'Crate force on table',
                      'Velocity vector',
                    ][i],
                  ),
                ),
            ],
          ),
        if (kind == 17)
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: task,
            decoration: const InputDecoration(labelText: 'Challenge'),
            items: [
              for (int i = 0; i < 6; i++)
                DropdownMenuItem(
                  value: i,
                  child: Text(
                    [
                      'Predict ax',
                      'Produce equilibrium',
                      'Reach ax=1.5, ay=0',
                      'Predict resultant direction',
                      'Predict ax if mass doubles',
                      'Cancel F1 using F2 and F3',
                    ][i],
                  ),
                ),
            ],
            onChanged: (v) => setState(() => task = v!),
          ),
        if (kind == 17)
          OutlinedButton(
            onPressed: () {
              parameters.addAll({
                'f1': 6,
                'd1': 0,
                'f2': 3,
                'd2': 120,
                'f3': 3,
                'd3': -120,
              });
              update('m', 2);
              setState(
                () => feedback = 'Reproducible start: F1=6 N at 0°, F2=3 N at 120°, F3=3 N at −120°, m=2 kg. Adjust the parameters to meet the selected task.',
              );
            },
            child: const Text('Generate reproducible challenge'),
          ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            OutlinedButton(
              onPressed: () {
                setState(() => guided = (guided + 1) % 3);
              },
              child: const Text('Next guided step'),
            ),
            FilledButton(
              key: const Key('predict-dynamics'),
              onPressed: prediction,
              child: const Text('Prediction / check'),
            ),
            OutlinedButton(
              onPressed: complete,
              child: const Text('Finish investigation'),
            ),
          ],
        ),
        if (feedback.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(feedback),
          ),
        if (attempts.isNotEmpty)
          Text(
            '${attempts.length} actual attempt(s); ${attempts.where((a) => a['correct'] == true).length} correct',
            style: const TextStyle(color: muted, fontSize: 12),
          ),
      ],
    ),
  );
  Future<void> prediction() async {
    pause();
    final target = kind == 17 && task == 3
        ? current['direction']!
        : kind == 17 && task == 4
        ? result / 2
        : result;
    if (kind == 17 && (task == 1 || task == 2 || task == 5)) {
      final correct = task == 1 || task == 5
          ? Vec2(current['fx']!, current['fy']!).magnitude <= .05 &&
                (task != 5 ||
                    (parameters['f1']! > 0 &&
                        parameters['f2']! > 0 &&
                        parameters['f3']! > 0))
          : (current['ax']! - 1.5).abs() <= .05 && current['ay']!.abs() <= .05;
      await attempt(
        0,
        task == 2 ? 1.5 : 0,
        correct,
        'Tolerance: equilibrium resultant ≤0.05 N; target acceleration components ±0.05 m/s².',
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: kind == 17 && task == 3
            ? 'Resultant direction (degrees)'
            : kind == 17 && task == 4
            ? 'ax at twice the mass (m/s²)'
            : lesson.question,
        initial: 0,
        min: -1e6,
        max: 1e6,
        onApply: (answer) {
          final tolerance = math.max(.01, target.abs() * .01);
          attempt(
            answer,
            target,
            (kind == 17 && task == 3
                    ? ((answer - target + 180) % 360 - 180).abs()
                    : (answer - target).abs()) <=
                tolerance,
            'Tolerance ±${number(tolerance)} (${kind == 17 && task == 3 ? 'degrees' : lesson.unit}).',
          );
        },
      ),
    );
  }

  Future<void> attempt(
    double answer,
    double target,
    bool correct,
    String tolerance,
  ) async {
    final item = <String, dynamic>{
      'feedback':
          '${correct ? 'Supported by the model.' : 'Reconsider the model.'} ${lesson.principle} Reference answer: ${number(target)}; current ${lesson.metric}: ${number(result)} ${lesson.unit}. $tolerance',
      'toleranceExplanation': tolerance,
      'utc': DateTime.now().toUtc().toIso8601String(),
      'task': task,
      'answer': answer,
      'target': target,
      'correct': correct,
      'modelTime': run.time,
      'parameters': Map.from(parameters),
      'mode': mode,
      'model': dynamicsVersion,
    };
    attempts.add(item);
    if (attempts.length > 50) {
      attempts.removeAt(0);
    }
    setState(
      () => feedback =
          '${correct ? 'Supported by the model.' : 'Reconsider the model.'} ${lesson.principle}\nReference answer: ${number(target)}; current ${lesson.metric}: ${number(result)} ${lesson.unit}. $tolerance',
    );
    await store.recordAttempt(entry.id, item);
    await persist();
  }

  Future<void> complete() async {
    if (guided != 2 ||
        !changedByUser ||
        !attempts.any((a) => a['correct'] == true) ||
        !store.trials.any((t) => t.labId == entry.id)) {
      message(
        'Complete the guided steps, change a parameter, answer correctly and record a trial first.',
      );
      return;
    }
    await store.complete(entry.id);
    message('Investigation completed from your recorded activity.');
  }

  Widget sweeps() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Paragraph(
          'Model sweeps',
          'Each row evaluates a=F/m. These are computed predictions, not observed trials. Record observations separately.',
        ),
        for (final force in [-10.0, -5.0, 0.0, 5.0, 10.0])
          Text(
            'F=$force N, m=${parameters['m']} kg → a=${number(force / parameters['m']!)} m/s²',
          ),
        const SizedBox(height: 10),
        for (final mass in [.5, 1.0, 2.0, 4.0, 8.0])
          Text(
            'm=$mass kg, F=${parameters['force']} N → a=${number(parameters['force']! / mass)} m/s²',
          ),
      ],
    ),
  );
  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    final mean = trials.isEmpty
        ? null
        : trials.map((t) => t.value).reduce((a, b) => a + b) / trials.length;
    final spread = trials.isEmpty
        ? null
        : trials.map((t) => t.value).reduce(math.max) -
              trials.map((t) => t.value).reduce(math.min);
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
              ? 'No observations yet. Record a real model state in Experiment.'
              : '${lesson.metric}: mean ${number(mean)} ${lesson.unit}, range ${number(spread)} ${lesson.unit}. Compare only compatible experimental protocols.',
        ),
      ),
      if (trials.isNotEmpty)
        FilledButton.icon(
          onPressed: () => exportTrials(context, trials),
          icon: const Icon(Icons.ios_share),
          label: const Text('Export actual trials as CSV'),
        ),
      const SizedBox(height: 16),
      for (final t in trials.reversed)
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${number(t.value)} ${t.unit}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(t.note.isEmpty ? 'No notes' : t.note),
              Text(
                'Model ${t.model} · ${t.created}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
              TextButton(
                onPressed: () {
                  if (restore(t.configuration)) {
                    setState(() => section = 1);
                    tick.value++;
                    message(
                      'Original configuration restored; simulation paused.',
                    );
                  } else {
                    message('This saved model version is incompatible.');
                  }
                },
                child: const Text('Reopen configuration'),
              ),
            ],
          ),
        ),
      if (attempts.isNotEmpty)
        Panel(
          child: Paragraph(
            'Challenge history',
            attempts
                .map(
                  (a) =>
                      '${a['utc']}: task ${a['task']}, answer ${a['answer']}, target ${a['target']}, ${a['correct'] == true ? 'correct' : 'retry'}',
                )
                .join('\n'),
          ),
        ),
      OutlinedButton(
        onPressed: save,
        child: const Text('Save current session'),
      ),
    ];
  }
}
