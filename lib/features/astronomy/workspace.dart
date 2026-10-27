import '../workbench/learning_header.dart';

import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../../app/app.dart';
import '../workbench/workbench.dart';
import '../workbench/quantity_ledger.dart';
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/design_system/reference_style.dart';
import '../../core/rendering/materials.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/astronomy_run.dart';
import '../../core/physics/galaxy_observations.dart';
import '../../core/physics/dynamics.dart' show FixedClock;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../advanced/scene.dart' show LabPlot;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import '../fluid_modern/workspace.dart' show fmNumber, fmLabel;
import 'curriculum.dart';
import 'scene.dart';
import 'hr_diagram.dart';

class AstronomyWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const AstronomyWorkspace({super.key, required this.entry});
  @override
  ConsumerState<AstronomyWorkspace> createState() => AstronomyWorkspaceState();
}

class AstronomyWorkspaceState extends ConsumerState<AstronomyWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late final LocalNotebook store;
  late AstronomyRun run;
  late Map<String, double> parameters;
  late Ticker ticker;
  int mode = 0, section = 1, cursor = 0;
  bool incompatible = false;
  Map<String, dynamic>? retainedSession;
  bool ready = false, changed = false, overlays = true;
  String notice = '', feedback = '', graph = '';
  Duration previous = Duration.zero;
  final clock = FixedClock(),
      tick = ValueNotifier(0),
      notes = TextEditingController(),
      view = TransformationController(),
      sceneView = TransformationController();
  final attempts = <Map<String, dynamic>>[], textures = <int, ui.Image>{};
  Entry get entry => widget.entry;
  double? get result => run.invalid.isEmpty ? run.state[lesson.metric] : null;
  int guided = 0;
  @override
  void initState() {
    super.initState();
    kind = entry.index;
    lesson = astroLessons[kind];
    parameters = lesson.defaults;
    run = AstronomyRun(kind, parameters);
    graph = graphs.first;
    store = ref.read(notebookProvider);
    ticker = createTicker(onFrame);
    WidgetsBinding.instance.addObserver(this);
    load();
    if (kind == 0) loadTextures();
  }

  Future<void> loadTextures() async {
    for (int i = 0; i < 8; i++) {
      final name = [
        'mercury',
        'venus',
        'earth',
        'mars',
        'jupiter',
        'saturn',
        'uranus',
        'neptune',
      ][i];
      try {
        final bytes = await rootBundle.load('assets/textures/phase8-$name.jpg'),
            codec = await ui.instantiateImageCodec(
              bytes.buffer.asUint8List(),
              targetWidth: 512,
            );
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        if (!mounted) {
          image.dispose();
          return;
        }
        textures[i] = image;
      } catch (_) {
        notice = 'Texture unavailable; shaded schematic shown.';
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> load() async {
    final saved = await store.readSession(entry.id);
    if (saved != null && !restore(saved)) {
      incompatible = true;
      retainedSession = saved;
      notice = 'Saved model/dataset incompatible; original retained. Defaults shown. Save explicitly to adopt the current model and keep a backup.';
    }
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
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

  void onFrame(Duration elapsed) {
    clock.advance((elapsed - previous).inMicroseconds / 1e6, () => run.step());
    previous = elapsed;
    if (!store.reducedMotion || run.ticks % 24 == 0 || run.finished) {
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
    run = AstronomyRun(kind, parameters, mode: mode, cached: run);
    tick.value++;
    setState(() {});
  }

  void defaults() {
    pause();
    mode = 0;
    parameters = lesson.defaults;
    changed = false;
    run = AstronomyRun(kind, parameters);
    graph = graphs.first;
    tick.value++;
    setState(() {});
  }

  void update(String key, double value) {
    pause();
    final next = ['seed', 'scaleMode'].contains(key)
        ? value.roundToDouble()
        : value;
    changed = changed || (key != 'scaleMode' && parameters[key] != next);
    parameters[key] = next;
    run = AstronomyRun(kind, parameters, mode: mode, cached: run);
    tick.value++;
    setState(() {});
  }

  void chooseMode(int value) {
    pause();
    changed = changed || mode != value;
    mode = value;
    run = AstronomyRun(kind, parameters, mode: mode);
    graph = graphs.first;
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  Map<String, dynamic> configuration() => {
    'model': astroVersion,
    'dataset': astroDataset,
    'epoch': astroEpochs[kind],
    'kind': kind,
    'mode': mode,
    'parameters': Map.of(parameters),
    'parameterUnits': {for (final p in lesson.controls) p.key: p.unit},
    'observationAxis': {
      'quantity': 'playback time',
      'unit': 's',
      'modelSecondsPerPlaybackSecond': run.timeScale,
    },
    'ticks': run.ticks,
    'notes': notes.text,
    'guided': guided,
    'changed': changed,
    'attempts': List.of(attempts),
    'graph': graph,
    'speed': clock.speed,
    'seed': parameters['seed'],
    'samplingAlgorithm': 'xorshift32-box-muller-1',
    'stateUnits': {for (final key in run.state.keys) key: units(key)},
    'profileAxis': axes[kind],
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != astroVersion ||
          data['dataset'] != astroDataset ||
          data['kind'] != kind) {
        return false;
      }
      final p = <String, double>{};
      for (final control in lesson.controls) {
        final n = (data['parameters'][control.key] as num).toDouble();
        if (!n.isFinite || n < control.min || n > control.max) return false;
        if (['seed', 'scaleMode'].contains(control.key) &&
            n != n.roundToDouble()) {
          return false;
        }
        p[control.key] = n;
      }
      final m = (data['mode'] as num).toInt(),
          ticks = (data['ticks'] as num).toInt();
      if (m < 0 || m >= astroModes[kind].length || ticks < 0 || ticks > 2400) {
        return false;
      }
      final next = AstronomyRun(kind, p, mode: m);
      next.seek(ticks / 120);
      if (next.invalid.isNotEmpty) return false;
      ticker.stop();
      mode = m;
      parameters = p;
      run = next;
      notes.text = data['notes'] as String? ?? '';
      guided = data['guided'] is int ? (data['guided'] as int).clamp(0, 3) : 0;
      changed = data['changed'] == true;
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? []).map(
            (a) => Map<String, dynamic>.from(a),
          ),
        );
      graph = graphs.contains(data['graph']) ? data['graph'] : graphs.first;
      clock.speed = ((data['speed'] as num?)?.toDouble() ?? 1).clamp(.25, 2);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() async {
    if (ready && !incompatible) {
      await store.saveSession(entry.id, configuration());
    }
  }

  void message(String s) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
    }
  }

  Future<void> save() async {
    pause();
    try {
      if (incompatible && retainedSession != null) {
        await store.saveSession(
          'backup:${entry.id}:${DateTime.now().microsecondsSinceEpoch}',
          {'backupFor': entry.id, 'original': retainedSession},
        );
        incompatible = false;
      }
      await persist();
      message('Session and dataset version saved; reopens paused.');
    } catch (_) {
      message('Save failed; earlier data retained.');
    }
  }

  Future<void> record() async {
    pause();
    if (result == null) return;
    try {
      await store.addTrial(
        Trial(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          labId: entry.id,
          quantity: [
            'length',
            'power',
            'length',
            'speed',
            'length',
            'relativeIntensity',
          ][kind],
          unit: lesson.unit,
          value: result!,
          resolution: null,
          model: astroVersion,
          note: notes.text,
          configuration: configuration()
            ..['currentState'] = Map.of(run.state)
            ..['observations'] = run.samples
            ..['profile'] = run.profile
            ..['observationType'] =
                'Calculated educational model; any noise explicitly synthetic',
        ),
      );
      await persist();
      if (store.haptics) HapticFeedback.lightImpact();
      message('Calculated trial recorded.');
    } catch (_) {
      message('Record failed; previous trials retained.');
    }
  }

  Future<void> submit(double value) async {
    if (result == null) return;
    final a = {
      'answer': value,
      'target': result,
      'correct':
          (value - result!).abs() <= math.max(result!.abs() * .02, 1e-15),
      'mode': mode,
      'parameters': Map.of(parameters),
      'time': run.time,
    };
    attempts.add(a);
    if (attempts.length > 50) attempts.removeAt(0);
    await store.recordAttempt(entry.id, a);
    feedback =
        '${a['correct'] == true ? 'Correct' : 'Reconsider'} · ${fmNumber(result)} ${lesson.unit}. ${lesson.mistake}';
    await persist();
    if (mounted) setState(() {});
  }

  Future<void> predict() async {
    pause();
    if (result == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: 'Predict ${lesson.metric} (${lesson.unit})',
        initial: 0,
        min: -1e35,
        max: 1e35,
        onApply: submit,
      ),
    );
  }

  bool matches(dynamic p) =>
      p is Map &&
      parameters.entries
          .where((e) => e.key != 'scaleMode')
          .every((e) => p[e.key] == e.value);
  bool get eligible =>
      changed &&
      notes.text.trim().isNotEmpty &&
      attempts.any(
        (a) =>
            a['correct'] == true &&
            a['mode'] == mode &&
            a['time'] == run.time &&
            matches(a['parameters']),
      ) &&
      store.trials.any(
        (t) =>
            t.labId == entry.id &&
            t.configuration['mode'] == mode &&
            t.configuration['ticks'] == run.ticks &&
            matches(t.configuration['parameters']),
      );
  @override
  void dispose() {
    dynamicsRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    ticker.stop();
    persist();
    ticker.dispose();
    tick.dispose();
    notes.dispose();
    view.dispose();
    sceneView.dispose();
    for (final image in textures.values) {
      LabMaterials.releaseTexture(image);
      image.dispose();
    }
    super.dispose();
  }

  Widget panel(List<Widget> children) => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
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
        researchReadings: () => [
          for (final e in run.state.entries)
            InstrumentReading(e.key, e.value.toString(), units(e.key)),
        ],
        principle: () => lesson.principle,
        modelLimits: () => lesson.limits,
        equation: lesson.formula,
        predict: predict,
        captureConfiguration: configuration,
        finished: () => run.finished,
        data: () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (kind == 3)
              QuantityLedger(
                title: 'Galaxy rotation components',
                unit: 'm/s',
                quantities: {
                  for (final key in [
                    'bulgeSpeed',
                    'diskSpeed',
                    'haloSpeed',
                    'speed',
                  ])
                    if (run.state[key] != null) key: run.state[key]!,
                },
              ),
            if (kind == 4)
              QuantityLedger(
                title: 'Cosmological distance definitions',
                unit: 'm',
                quantities: {
                  for (final key in [
                    'comovingDistance',
                    'luminosityDistance',
                    'angularDistance',
                    'lightTravelDistance',
                  ])
                    if (run.state[key] != null) key: run.state[key]!,
                },
              ),
            if (kind == 1 && run.state.containsKey('logT'))
              HRDiagram(
                track: mode,
                logTemperature: run.state['logT']!,
                logLuminosity: run.state['logL']!,
                ageFraction: (parameters['ageFraction']! + run.time / 20).clamp(
                  0,
                  1,
                ),
                changeAge: (value) => update('ageFraction', value),
              ),
            metrics(),
          ],
        ),
        restoreConfiguration: (data) {
          final restored = restore(data);
          tick.value++;
          if (mounted) setState(() {});
          return restored;
        },
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
          InstrumentReading('Playback', run.time.toStringAsPrecision(4), 's'),
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
          run.step();
          run.refresh();
          tick.value++;
        },
        selection: () => DropdownButtonFormField<int>(
          key: ValueKey('dock-mode-$kind-$mode'),
          initialValue: mode,
          isExpanded: true,
          items: [
            for (int i = 0; i < astroModes[kind].length; i++)
              DropdownMenuItem(
                value: i,
                child: Text(
                  astroModes[kind][i],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (v) {
            if (v != null) chooseMode(v);
          },
        ),
        resetOriginalView: () => sceneView.value = Matrix4.identity(),
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
    body: !ready
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
  );
  List<Widget> learn() => [
    LabLearningHeader(
      entry: entry,
      onExplore: () => setState(() => section = 1),
    ),
    panel([
      Paragraph(
        'Objectives',
        'Explain ${lesson.metric}, make a quantitative prediction, compare calculated values with assumptions and identify a model limitation.',
      ),
      Paragraph('Apparatus / model', lesson.apparatus),
      Paragraph('Principles', lesson.principle),
      Paragraph('Procedure', lesson.procedure),
      Paragraph('Misconception', lesson.mistake),
      Paragraph('Assumptions and limits', lesson.limits),
      const Paragraph('Offline dataset version', astroDataset),
      Paragraph('Sources and visual provenance', astroSources[kind]),
    ]),
    investigation(),
    relatedLabs(entry.id),
  ];
  Widget investigation() => panel([
    const Eyebrow('Guided investigation'),
    Text(lesson.question),
    FilledButton(
      onPressed: result == null
          ? null
          : () => showDialog(
              context: context,
              builder: (_) => NumericInputDialog(
                label: 'Predict ${lesson.metric} (${lesson.unit})',
                initial: 0,
                min: -1e35,
                max: 1e35,
                onApply: submit,
              ),
            ),
      child: const Text('Check numerical prediction'),
    ),
    Text(feedback),
    FilledButton(
      onPressed: eligible
          ? () async {
              await store.complete(entry.id);
              if (mounted) setState(() {});
            }
          : null,
      child: const Text('Complete investigation'),
    ),
    if (!eligible)
      const Text(
        'Requires a scientific input change, correct prediction, matching recorded trial and explanatory notes.',
      ),
  ]);
  Widget compactScene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: ApparatusTransform(
            transformationController: sceneView,
            minScale: .5,
            maxScale: 5,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: AstronomyPainter(
                  run,
                  textures: textures,
                  overlays: overlays,
                  motion: !store.reducedMotion,
                ),
                isComplex: true,
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget apparatus() => ListenableBuilder(
    listenable: tick,
    builder: (c, _) => panel([
      Text(
        '${fmLabel(lesson.metric)}: ${fmNumber(result)} ${lesson.unit}',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (run.invalid.isNotEmpty)
        Text(run.invalid, style: const TextStyle(color: Colors.red)),
      Semantics(
        label:
            '${entry.title}. ${astroModes[kind][mode]}. Calculated ${lesson.metric} ${fmNumber(result)} ${lesson.unit}. ${lesson.limits}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: InteractiveViewer(
              transformationController: sceneView,
              minScale: .5,
              maxScale: 5,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: AstronomyPainter(
                    run,
                    textures: textures,
                    overlays: overlays,
                    motion: !store.reducedMotion,
                  ),
                  isComplex: true,
                ),
              ),
            ),
          ),
        ),
      ),
      Text(
        'Pinch / pan scene. Playback ${run.time.toStringAsFixed(2)} s; ${fmNumber(run.timeScale * clock.speed)} model seconds per playback second when evolving.',
      ),
      Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Overlays'),
            selected: overlays,
            onSelected: (v) => setState(() => overlays = v),
          ),
          TextButton(
            onPressed: () => sceneView.value = Matrix4.identity(),
            child: const Text('Reset scene view'),
          ),
        ],
      ),
      if (kind == 0)
        const Text(
          'Courtesy NASA/JPL-Caltech / USGS. Maps include processed mosaics and Davis/Seal artist impressions; selected type labeled in the viewport. Distances use the selected scale; body sizes exaggerated.',
        ),
      if (kind == 5)
        const Text(
          'Stellar disk is uniformly bright by model; no decorative limb darkening.',
        ),
    ]),
  );
  Widget control(Parameter p) => panel([
    Text('${p.label}: ${fmNumber(parameters[p.key])} ${p.unit}'),
    Slider(
      key: Key('slider-${p.key}'),
      value: parameters[p.key]!.clamp(p.min, p.max),
      min: p.min,
      max: p.max,
      divisions: ['seed', 'scaleMode'].contains(p.key)
          ? (p.key == 'scaleMode' ? 1 : 100)
          : null,
      label: '${fmNumber(parameters[p.key])} ${p.unit}',
      onChanged: (v) => update(p.key, v),
    ),
    OutlinedButton(
      key: Key('edit-${p.key}'),
      onPressed: () => showDialog(
        context: context,
        builder: (_) => NumericInputDialog(
          label: p.label,
          initial: parameters[p.key]!,
          min: p.min,
          max: p.max,
          onApply: (v) => update(p.key, v),
        ),
      ),
      child: const Text('Enter precise value'),
    ),
  ]);
  List<Widget> experiment() => [
    apparatus(),
    DropdownButtonFormField<int>(
      key: ValueKey('$mode-${entry.id}'),
      initialValue: mode,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Reference model / selection',
      ),
      items: [
        for (int i = 0; i < astroModes[kind].length; i++)
          DropdownMenuItem(
            value: i,
            child: Text(astroModes[kind][i], overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        if (v != null) chooseMode(v);
      },
    ),
    if (kind == 1)
      panel([
        const Text('Jump to a supported evolutionary stage (actual track age)'),
        Wrap(
          spacing: 8,
          children: [
            for (final phase in stellarTracks[mode].map((r) => r[3]).toSet())
              TextButton(
                onPressed: () {
                  final rows = stellarTracks[mode],
                      row = rows.firstWhere((r) => r[3] == phase);
                  update(
                    'ageFraction',
                    ((row[0] - rows.first[0]) / (rows.last[0] - rows.first[0]) +
                            1e-12)
                        .clamp(0, 1),
                  );
                },
                child: Text(stellarPhase(phase)),
              ),
          ],
        ),
        Text(
          mode < 2
              ? 'Expected isolated-star endpoint: white dwarf; track ends post-AGB, not full cooling history.'
              : 'Expected broad outcome: core collapse, compact remnant. NS/BH outcome model dependent, not computed by this track.',
        ),
      ]),
    Wrap(
      spacing: 8,
      children: [
        FilledButton(
          onPressed: run.dynamicLab && run.invalid.isEmpty
              ? (ticker.isActive ? pause : play)
              : null,
          child: Text(ticker.isActive ? 'Pause' : 'Play'),
        ),
        OutlinedButton(
          onPressed: run.dynamicLab && !run.finished
              ? () {
                  pause();
                  run.step();
                  run.refresh();
                  tick.value++;
                }
              : null,
          child: const Text('Step'),
        ),
        OutlinedButton(
          onPressed: run.dynamicLab ? reset : null,
          child: const Text('Reset time'),
        ),
        TextButton(onPressed: defaults, child: const Text('Restore defaults')),
      ],
    ),
    if (run.dynamicLab)
      Slider(
        value: clock.speed,
        min: .25,
        max: 2,
        label: 'Playback ×${clock.speed.toStringAsFixed(2)}',
        onChanged: (v) => setState(() => clock.speed = v),
      ),
    if (store.reducedMotion)
      const Text(
        'Reduced motion enabled: state snapshots at5Hz; playback can be explored with numeric time controls.',
      ),
    for (final p in lesson.controls) control(p),
    metrics(),
    FilledButton(
      key: const Key('record-trial'),
      onPressed: result == null ? null : record,
      child: const Text('Record calculated trial'),
    ),
    TextField(
      controller: notes,
      maxLines: 3,
      decoration: const InputDecoration(labelText: 'Investigation notes'),
      onChanged: (_) {
        setState(() {});
      },
    ),
    investigation(),
    if (notice.isNotEmpty) Text(notice),
    relatedLabs(entry.id),
  ];
  static const axes = [
    'Time across one orbit (s)',
    '−log10(Teff/K), hot left',
    'Vacuum wavelength (m)',
    'Radius (m)',
    'Redshift z',
    'Time from inferior conjunction (s)',
  ];
  String units(String key) => switch (key) {
    't' => 's',
    'playbackSeconds' => 's',
    'age' => 's',
    'daysFromJ2000' => 'd',
    'observed' || 'uncertainty' => 'm/s',
    'wavelength' => 'm',
    'luminosity' => 'W',
    'temperature' => 'K',
    'radius' ||
    'distance' ||
    'semiMajorAxis' ||
    'x' ||
    'y' ||
    'z' ||
    'projectedSeparation' ||
    'planetRadius' ||
    'starRadius' ||
    'peakWavelength' ||
    'lightTravelDistance' ||
    'comovingDistance' ||
    'luminosityDistance' ||
    'angularDistance' => 'm',
    'period' || 'duration' || 'lookback' || 'timeFromMidTransit' => 's',
    'speed' ||
    'meanSpeed' ||
    'bulgeSpeed' ||
    'diskSpeed' ||
    'haloSpeed' ||
    'radialVelocity' ||
    'recessionNow' => 'm/s',
    'potential' || 'energy' => 'm²/s²',
    'initialMass' || 'sphericalEquivalentMass' => 'kg',
    'hubbleAtEmission' || 'hubbleSI' => 's⁻¹',
    _ => '1',
  };
  Widget metrics() => ListenableBuilder(
    listenable: tick,
    builder: (c, _) => panel([
      const Eyebrow('Current calculated state'),
      for (final e in run.state.entries)
        Text('${fmLabel(e.key)}: ${fmNumber(e.value)} ${units(e.key)}'),
      if (kind == 1) Text(stellarPhase(run.state['phase'] ?? 0)),
      if (kind == 0) ...[
        const Text('Orbital comparison — same current model time'),
        for (int i = 0; i < 8; i++)
          Text(
            '${planets[i].name}: a=${planets[i].a}AU; r=${fmNumber(run.orbitStates[i]['distance']! / au)}AU; P=${fmNumber(planets[i].period / day)}d; v=${fmNumber(run.orbitStates[i]['speed'])}m/s; mean=${fmNumber(run.orbitStates[i]['meanSpeed'])}m/s',
          ),
      ],
      if (kind == 2) ...[
        const Text(
          'Identified illustrative absorption lines (vacuum rest → shifted)',
        ),
        for (int i = 0; i < balmerVacuum.length; i++)
          Text(
            'H${['α', 'β', 'γ', 'δ'][i]}: ${fmNumber(balmerVacuum[i] * 1e9)} → ${fmNumber(balmerVacuum[i] * dopplerFactor(parameters['velocity']!) * 1e9)} nm',
          ),
      ],
    ]),
  );
  List<String> get graphs => switch (kind) {
    0 => ['Heliocentric distance', 'Speed'],
    1 => ['H–R reference track'],
    2 => ['Synthetic and rest reference'],
    3 => ['Model components', 'SPARC observed NGC2403'],
    4 => ['Distance measures', 'Lookback time', 'Scale factor'],
    _ => ['Transit flux'],
  };
  CustomPainter referencePlot() {
    List<AstroState> data = run.profile;
    var keys = <String>[], unit = '';
    bool scatter = false;
    switch (kind) {
      case 0:
        keys = [graph == 'Speed' ? 'speed' : 'distance'];
        unit = graph == 'Speed' ? 'm/s' : 'm';
      case 1:
        keys = ['logLuminosity'];
        unit = 'log10(L/L☉)';
      case 2:
        keys = ['continuum', 'syntheticFlux', 'restReference'];
        unit = 'normalized flux';
      case 3:
        if (graph == 'SPARC observed NGC2403') {
          data = [
            for (final r in ngc2403)
              {
                't': r[0] * kpc,
                'observed': r[1] * 1000,
                'uncertainty': r[2] * 1000,
              },
          ];
          keys = ['observed'];
          scatter = true;
        } else {
          keys = ['speed', 'bulgeSpeed', 'diskSpeed', 'haloSpeed'];
        }
        unit = 'm/s';
      case 4:
        keys = graph == 'Lookback time'
            ? ['lookback']
            : graph == 'Scale factor'
            ? ['scaleFactor']
            : ['comovingDistance', 'luminosityDistance', 'angularDistance'];
        unit = graph == 'Lookback time'
            ? 's'
            : graph == 'Scale factor'
            ? '1'
            : 'm';
      case 5:
        keys = ['flux', if (parameters['noise']! > 0) 'syntheticFlux'];
        unit = 'relative flux';
    }
    return LabPlot(
      data,
      keys,
      axes[kind],
      unit,
      cursor,
      scatter: scatter,
      errorKeys: kind == 3 && scatter
          ? const {'observed': 'uncertainty'}
          : const {},
    );
  }

  List<Widget> visualize() {
    List<AstroState> data = run.profile;
    var keys = <String>[], unit = '';
    bool scatter = false;
    switch (kind) {
      case 0:
        keys = [graph == 'Speed' ? 'speed' : 'distance'];
        unit = graph == 'Speed' ? 'm/s' : 'm';
      case 1:
        keys = ['logLuminosity'];
        unit = 'log10(L/L☉)';
      case 2:
        keys = ['continuum', 'syntheticFlux', 'restReference'];
        unit = 'normalized flux';
      case 3:
        if (graph == 'SPARC observed NGC2403') {
          data = [
            for (final r in ngc2403)
              {
                't': r[0] * kpc,
                'observed': r[1] * 1000,
                'uncertainty': r[2] * 1000,
              },
          ];
          keys = ['observed'];
          scatter = true;
        } else {
          keys = ['speed', 'bulgeSpeed', 'diskSpeed', 'haloSpeed'];
        }
        unit = 'm/s';
      case 4:
        keys = graph == 'Lookback time'
            ? ['lookback']
            : graph == 'Scale factor'
            ? ['scaleFactor']
            : ['comovingDistance', 'luminosityDistance', 'angularDistance'];
        unit = graph == 'Lookback time'
            ? 's'
            : graph == 'Scale factor'
            ? '1'
            : 'm';
      case 5:
        keys = ['flux', if (parameters['noise']! > 0) 'syntheticFlux'];
        unit = 'relative flux';
    }
    cursor = cursor.clamp(0, math.max(0, data.length - 1));
    final selected = data.isEmpty ? <String, double>{} : data[cursor];
    return [
      apparatus(),
      DropdownButtonFormField<String>(
        key: ValueKey(graph),
        initialValue: graph,
        isExpanded: true,
        items: [
          for (final g in graphs) DropdownMenuItem(value: g, child: Text(g)),
        ],
        onChanged: (v) {
          if (v != null) {
            setState(() {
              graph = v;
              cursor = 0;
              view.value = Matrix4.identity();
            });
          }
        },
      ),
      if (kind == 1)
        const Text(
          'H–R convention: hot stars left (negative log temperature axis); log luminosity in solar units. Track density reflects reference sampling, not observation frequency.',
        ),
      if (kind == 3 && scatter)
        const Text(
          'Observed SPARC2016 NGC2403, assumed distance3.16Mpc. Quoted velocity uncertainties retained below; not generated points, not a fit to the adjustable model.',
        ),
      Semantics(
        label:
            'Graph of ${keys.join(', ')} in $unit versus ${axes[kind]}. ${selected.entries.map((e) => '${e.key} ${fmNumber(e.value)}').join(', ')}',
        child: SizedBox(
          height: 280,
          child: InteractiveViewer(
            transformationController: view,
            minScale: .5,
            maxScale: 5,
            child: CustomPaint(
              size: const Size(double.infinity, 280),
              painter: LabPlot(
                data,
                keys,
                axes[kind],
                unit,
                cursor,
                scatter: scatter,
                errorKeys: kind == 3 && scatter
                    ? const {'observed': 'uncertainty'}
                    : const {},
              ),
            ),
          ),
        ),
      ),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          for (int i = 0; i < keys.length; i++)
            Text.rich(
              TextSpan(
                children: [
                  WidgetSpan(
                    child: Icon(
                      Icons.show_chart,
                      size: 18,
                      color: LabPlot.colors[i % LabPlot.colors.length],
                    ),
                  ),
                  TextSpan(text: ' ${fmLabel(keys[i])} ($unit)'),
                ],
              ),
            ),
        ],
      ),
      TextButton(
        onPressed: () => view.value = Matrix4.identity(),
        child: const Text('Reset graph view'),
      ),
      if (data.isNotEmpty)
        Slider(
          key: const Key('astro-graph-cursor'),
          value: cursor.toDouble(),
          min: 0,
          max: math.max(1, data.length - 1).toDouble(),
          divisions: math.max(1, data.length - 1),
          label: 'Data cursor$cursor',
          onChanged: (v) {
            final index = v.round();
            if (kind == 5) {
              update(
                'phase',
                data[index]['t']! / (parameters['periodDays']! * day),
              );
            } else if (kind == 0) {
              update('elapsedDays', data[index]['t']! / day);
            } else if (kind == 2) {
              update('wavelength', data[index]['t']!);
            } else if (kind == 3) {
              update('radiusKpc', (data[index]['t']! / kpc).clamp(.1, 30));
            } else if (kind == 4) {
              update('redshift', data[index]['t']!);
            } else if (kind == 1) {
              final rows = stellarTracks[mode];
              update(
                'ageFraction',
                ((data[index]['age']! / julianYear - rows.first[0]) /
                        (rows.last[0] - rows.first[0]))
                    .clamp(0, 1),
              );
            }
            setState(() => cursor = index);
          },
        ),
      Text(
        'Cursor: ${selected.entries.map((e) => '${fmLabel(e.key)}=${fmNumber(e.value)} ${e.key == 't' ? axes[kind] : units(e.key)}').join('; ')}',
      ),
      if (kind == 5)
        const Text(
          'Noise, when enabled, is independent seeded Gaussian synthetic flux. It can exceed1; values are not clipped.',
        ),
      metrics(),
    ];
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
      Paragraph('Symbols / conventions', lesson.symbols),
      Paragraph('Validity', lesson.limits),
      Paragraph('Worked example', lesson.example),
      Paragraph(
        'Current-value substitution',
        '${parameters.entries.map((e) => '${e.key}=${fmNumber(e.value)}').join('; ')} → ${lesson.metric}=${fmNumber(result)} ${lesson.unit}',
      ),
    ]),
    metrics(),
  ];
  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    return [
      Text('${trials.length} recorded calculated trials'),
      if (trials.isEmpty)
        const Text(
          'No preloaded observations. Record a valid state in Experiment.',
        ),
      if (trials.isNotEmpty)
        FilledButton(
          onPressed: () => exportTrials(context, trials),
          child: const Text('Export actual trials as CSV'),
        ),
      for (final t in trials.reversed)
        panel([
          Text('${fmNumber(t.value)} ${t.unit}'),
          Text(t.note),
          Text('${t.model} · ${t.configuration['dataset']} · ${t.created}'),
          Text('${t.configuration['observationType']}'),
          TextButton(
            onPressed: () {
              if (restore(t.configuration)) {
                setState(() => section = 1);
                tick.value++;
              } else {
                message('Incompatible model/reference kept intact.');
              }
            },
            child: const Text('Reopen configuration'),
          ),
        ]),
    ];
  }
}
