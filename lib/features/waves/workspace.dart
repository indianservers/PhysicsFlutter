import '../workbench/learning_header.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../core/physics/waves_optics.dart';
import '../advanced/scene.dart' show LabPlot;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'curriculum.dart';
import 'scene.dart';
import 'microphone.dart';

final liveMicrophoneProvider = Provider<LiveMicrophone>((ref) {
  final value = LiveMicrophone();
  ref.onDispose(value.dispose);
  return value;
});

class WaveWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const WaveWorkspace({super.key, required this.entry});
  @override
  ConsumerState<WaveWorkspace> createState() => _WaveWorkspaceState();
}

class _WaveWorkspaceState extends ConsumerState<WaveWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final int kind;
  late final DynamicsLesson lesson;
  late WaveState parameters;
  late WaveOpticsRun run;
  late final LocalNotebook store;
  late final LiveMicrophone mic;
  late final Ticker ticker;
  final clock = FixedClock(), tick = ValueNotifier<int>(0);
  final view = TransformationController(),
      graphView = TransformationController();
  final notes = TextEditingController();
  Duration previous = Duration.zero;
  int section = 1, mode = 0, cursor = 0, guided = 0;
  bool ready = false,
      labels = true,
      overlays = true,
      comparison = true,
      intensity = false,
      micMode = false,
      changed = false,
      busy = false;
  String
  graphMode = 'profile',
  feedback = '',
  notice =
      'Parameter edits restart the analytic model; camera/overlay changes preserve physical time.';
  Map<String, dynamic>? authorizedAnalysis;
  Spectrum? lastMicSpectrum;
  final attempts = <Map<String, dynamic>>[];
  Entry get entry => widget.entry;
  bool get playing => ticker.isActive;
  double? get result => run.state[lesson.metric];
  String number(num? n) =>
      n == null ? 'No defined reading' : n.toStringAsPrecision(6);
  @override
  void initState() {
    super.initState();
    kind = (entry.studioIndex - 8) * 6 + entry.index;
    lesson = waveLessons[kind];
    parameters = lesson.defaults;
    validate(parameters);
    run = WaveOpticsRun(kind, parameters);
    store = ref.read(notebookProvider);
    mic = ref.read(liveMicrophoneProvider);
    mic.addListener(onMicrophone);
    ticker = createTicker(onFrame);
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
    unawaited(mic.stop());
    persist();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      pause();
      if (mic.active ||
          state == AppLifecycleState.paused ||
          state == AppLifecycleState.hidden ||
          state == AppLifecycleState.detached) {
        unawaited(mic.stop());
      }
      persist();
    }
  }

  void onMicrophone() {
    if (!mounted) return;
    if (micMode &&
        mic.spectrum != null &&
        !identical(lastMicSpectrum, mic.spectrum)) {
      lastMicSpectrum = mic.spectrum;
      run.time = mic.frameEndTime;
      run.acceptAnalyzedSignal(mic.frame, mic.spectrum!);
      cursor = run.samples.length - 1;
      tick.value++;
    }
    setState(() {});
  }

  void clearLive() {
    run.state = {'t': 0};
    run.signal = [];
    run.profile = [];
    run.frequencyCurve = [];
    run.spectrum = null;
    run.samples.clear();
  }

  Future<void> load() async {
    final data = await store.readSession(entry.id);
    if (data != null && !restore(data)) {
      await store.retainRejectedSession(entry.id, data);
      notice = 'Saved configuration is incompatible. Original records remain preserved.';
    }
    await store.visit(entry.id);
    if (mounted) setState(() => ready = true);
  }

  void validate(WaveState values) {
    if (kind == 2) {
      values['frequency'] = math.min(
        values['frequency']!,
        values['speed']! / (16 / 63),
      );
    }
    if (kind == 1) {
      for (final key in ['d1', 'd2']) {
        values[key] = values[key]! < 0 ? -1 : 1;
      }
    }
    if (kind == 3) {
      values['harmonic'] = values['harmonic']!.roundToDouble();
      values['probe'] = values['probe']!.clamp(0, values['length']!);
      values['amplitude'] = math.min(
        values['amplitude']!,
        .02 * values['length']! / values['harmonic']!,
      );
    }
    if (kind == 8 || kind == 9) {
      values['height'] = math.min(
        values['height']!,
        .08 * math.min(values['u']!, values['focal']!),
      );
    }
    if (kind >= 10) {
      values['aperture'] = math.min(
        values['aperture']!,
        math.sqrt(.1 * values['wavelength']! * values['screen']!),
      );
    }
  }

  void updateMany(Map<String, double> updates) {
    pause();
    final next = Map<String, double>.of(parameters);
    for (final item in updates.entries) {
      final p = lesson.controls.firstWhere((p) => p.key == item.key);
      next[item.key] = item.value.clamp(p.min, p.max);
    }
    final before = Map.of(next);
    validate(next);
    notice = before.entries.any((e) => e.value != next[e.key])
        ? 'A dependent range was limited to preserve endpoints, small-amplitude/paraxial or far-field validity. Model restarted.'
        : 'Parameter changed: analytic model restarted at t=0.';
    parameters = next;
    changed = true;
    if (kind >= 10 && updates.length == 1 && updates.containsKey('probe')) {
      run.setDetector(parameters['probe']!);
      notice = 'Detector moved; the same physical intensity profile is reused.';
    } else {
      run = WaveOpticsRun(kind, parameters, mode: mode);
    }
    if (micMode) clearLive();
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  Map<String, dynamic> captureAnalysis() => {
    'state': Map.of(run.state),
    'bins': List.of(run.spectrum!.amplitudes),
    'sampleRate': run.spectrum!.sampleRate,
    'size': run.spectrum!.size,
    'rms': run.spectrum!.rms,
    'peakFrequency': run.spectrum!.peakFrequency,
    'peakAmplitude': run.spectrum!.peakAmplitude,
    'peaks': List.of(run.spectrum!.peaks),
    'input': 'actual microphone PCM; waveform intentionally not saved',
  };
  Map<String, dynamic> configuration() => {
    'model': waveOpticsVersion,
    'kind': kind,
    'parameters': parameters,
    'units': {for (final p in lesson.controls) p.key: p.unit},
    'ticks': run.ticks,
    'mode': mode,
    'notes': notes.text,
    'guided': guided,
    'attempts': attempts,
    'changed': changed,
    'feedback': feedback,
    'labels': labels,
    'overlays': overlays,
    'comparison': comparison,
    'intensity': intensity,
    'graphMode': graphMode,
    'speed': clock.speed,
    'input': micMode ? 'microphone' : 'generated/model',
    if (micMode && authorizedAnalysis != null)
      'savedAnalysis': authorizedAnalysis,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != waveOpticsVersion || data['kind'] != kind) {
        return false;
      }
      final raw = Map<String, dynamic>.from(data['parameters']),
          next = <String, double>{};
      for (final p in lesson.controls) {
        final value = (raw[p.key] as num).toDouble();
        if (!value.isFinite || value < p.min - 1e-10 || value > p.max + 1e-10) {
          return false;
        }
        next[p.key] = value;
      }
      final candidateMode = (data['mode'] as int? ?? 0);
      if (candidateMode < 0 || candidateMode > (kind == 4 ? 2 : 1)) {
        return false;
      }
      validate(next);
      final count = data['ticks'] as int;
      if (count < 0 || count > 14400) return false;
      final candidate = WaveOpticsRun(kind, next, mode: candidateMode)
        ..seek(
          count *
              WaveOpticsRun.dt *
              WaveOpticsRun(kind, next, mode: candidateMode).timeScale,
        );
      pause();
      unawaited(mic.stop());
      parameters = next;
      run = candidate;
      mode = candidateMode;
      micMode = kind == 4 && data['input'] == 'microphone';
      authorizedAnalysis = null;
      if (micMode) {
        clearLive();
        final saved = data['savedAnalysis'];
        if (saved is Map) {
          final bins = (saved['bins'] as List)
              .map((x) => (x as num).toDouble())
              .toList();
          if (bins.length != 1025 || bins.any((v) => !v.isFinite)) return false;
          authorizedAnalysis = Map<String, dynamic>.from(saved);
          run.state = Map<String, double>.from(
            (saved['state'] as Map).map(
              (k, v) => MapEntry(k, (v as num).toDouble()),
            ),
          );
          run.spectrum = Spectrum(
            bins,
            saved['sampleRate'],
            saved['size'],
            (saved['rms'] as num).toDouble(),
            (saved['peakFrequency'] as num).toDouble(),
            (saved['peakAmplitude'] as num).toDouble(),
            (saved['peaks'] as List).map((x) => (x as num).toDouble()).toList(),
          );
          run.frequencyCurve = [
            for (int i = 0; i < bins.length; i++)
              {'t': i * run.spectrum!.binWidth, 'amplitude': bins[i]},
          ];
          run.samples.add(Map.of(run.state));
          notice = 'Explicitly saved microphone analysis restored. No raw waveform retained; microphone is stopped.';
        } else {
          notice = 'Microphone session restored stopped. Start listening for a new actual analysis.';
        }
      }
      notes.text = data['notes'] ?? '';
      guided = (data['guided'] as int? ?? 0).clamp(0, 2);
      changed = data['changed'] == true;
      feedback = data['feedback'] ?? '';
      attempts
        ..clear()
        ..addAll(
          (data['attempts'] as List? ?? []).map(
            (x) => Map<String, dynamic>.from(x),
          ),
        );
      labels = data['labels'] != false;
      overlays = data['overlays'] != false;
      comparison = data['comparison'] != false;
      intensity = data['intensity'] == true;
      graphMode = ['profile', 'time', 'spectrum'].contains(data['graphMode'])
          ? data['graphMode']
          : 'profile';
      clock.speed = (data['speed'] as num? ?? 1).toDouble().clamp(.25, 2);
      cursor = math.max(0, run.samples.length - 1);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() => store.saveSession(entry.id, configuration());
  Future<void> save() async {
    pause();
    if (micMode && run.spectrum != null) authorizedAnalysis = captureAnalysis();
    await persist();
    message(
      micMode
          ? 'Analyzed bins/metrics saved explicitly; raw audio is never saved.'
          : 'Session saved; reopens paused.',
    );
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void onFrame(Duration elapsed) {
    final delta = (elapsed - previous).inMicroseconds / 1e6;
    previous = elapsed;
    final before = run.revision;
    clock.advance(delta, run.step);
    if (run.revision != before) {
      cursor = math.max(0, run.samples.length - 1);
      tick.value++;
    }
    if (run.finished) pause();
  }

  void play() {
    if (run.staticLab || micMode) return;
    if (run.finished) reset();
    clock.pause();
    previous = Duration.zero;
    ticker.start();
    setState(() {});
  }

  void pause() {
    ticker.stop();
    clock.pause();
    if (!micMode && !run.staticLab) {
      run.refresh();
      tick.value++;
    }
    if (mounted) setState(() {});
  }

  void reset() {
    pause();
    run = WaveOpticsRun(kind, parameters, mode: mode);
    if (micMode) {
      unawaited(mic.stop());
      clearLive();
      authorizedAnalysis = null;
    }
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  void defaults() {
    pause();
    unawaited(mic.stop());
    parameters = lesson.defaults;
    validate(parameters);
    mode = 0;
    micMode = false;
    authorizedAnalysis = null;
    run = WaveOpticsRun(kind, parameters);
    cursor = 0;
    notice = 'Documented default parameters restored. Earlier trial records are unchanged.';
    tick.value++;
    setState(() {});
  }

  void chooseMode(int value) {
    pause();
    mode = value;
    changed = true;
    run = WaveOpticsRun(kind, parameters, mode: mode);
    cursor = 0;
    tick.value++;
    setState(() {});
  }

  String get quantity => switch (lesson.unit) {
    'm' => 'length',
    'm/s' => 'speed',
    'Hz' => 'frequency',
    '°' => 'angle',
    'm⁻¹' => 'vergence',
    _ => 'relativeIntensity',
  };
  Future<void> record() async {
    if (busy || result == null || !result!.isFinite) {
      message('No defined observation to record yet.');
      return;
    }
    pause();
    setState(() => busy = true);
    try {
      if (micMode && run.spectrum != null) {
        authorizedAnalysis = captureAnalysis();
      }
      final config = configuration()
        ..['observations'] = run.samples
        ..['currentState'] = run.state;
      if (!micMode) config['spatialProfile'] = run.profile;
      await store.addTrial(
        Trial(
          id: '${DateTime.now().microsecondsSinceEpoch}',
          labId: entry.id,
          quantity: quantity,
          unit: lesson.unit,
          value: result!,
          resolution: null,
          configuration: config,
          note: notes.text,
          model: waveOpticsVersion,
        ),
      );
      await persist();
      if (store.haptics) HapticFeedback.lightImpact();
      message(
        micMode
            ? 'Actual microphone analysis saved: bins/metrics only, no raw audio.'
            : 'Actual ${waveLabel(lesson.metric)} recorded.',
      );
    } catch (_) {
      message('Observation could not be saved.');
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> submit(double answer, {bool categorical = false}) async {
    final target = categorical
        ? run.state[kind == 7 ? 'tir' : 'imageType']
        : result;
    if (target == null) return;
    final tolerance = categorical ? 0.0 : math.max(1e-9, target.abs() * .02),
        correct = (answer - target).abs() <= tolerance;
    final attempt = <String, dynamic>{
      'created': DateTime.now().toUtc().toIso8601String(),
      'metric': categorical ? (kind == 7 ? 'tir' : 'imageType') : lesson.metric,
      'answer': answer,
      'target': target,
      'correct': correct,
      'tolerance': tolerance,
      'parameters': Map.of(parameters),
      'mode': mode,
      'input': micMode ? 'actual microphone' : 'generated/model',
      'time': run.time,
    };
    attempts.add(attempt);
    if (attempts.length > 50) attempts.removeAt(0);
    await store.recordAttempt(entry.id, attempt);
    if (mounted) {
      setState(
        () => feedback =
            '${correct ? 'Correct' : 'Reconsider'} · reference ${number(target)} ${categorical ? '' : lesson.unit}. ${lesson.mistake}',
      );
    }
    await persist();
  }

  Future<void> predict() async {
    pause();
    await mic.stop();
    if (!mounted) return;
    if (result == null) {
      message('A defined observation is required first.');
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: 'Predict ${waveLabel(lesson.metric)} (${lesson.unit})',
        initial: 0,
        min: -1e20,
        max: 1e20,
        onApply: (x) => submit(x),
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
    mic.removeListener(onMicrophone);
    unawaited(mic.stop());
    mic.frame = [];
    mic.spectrum = null;
    view.dispose();
    graphView.dispose();
    notes.dispose();
    tick.dispose();
    super.dispose();
  }

  List<InstrumentControl> instrumentControls() => [
    for (final p in lesson.controls.where(visible))
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
  CustomPainter referencePlot() {
    final x = graphMode == 'time'
        ? 'Physical time (s)'
        : kind == 4 && graphMode == 'spectrum'
        ? 'Frequency (Hz)'
        : kind == 4 || kind == 5
        ? 'Signal time (s)'
        : kind == 6 || kind == 7
        ? 'Incidence (°)'
        : kind == 8 || kind == 9
        ? 'Object distance (m)'
        : 'Position (m)';
    return LabPlot(
      graphData,
      graphKeys,
      x,
      kind == 4 && graphMode != 'time'
          ? 'relative FS'
          : waveUnit(graphKeys.first),
      cursor,
    );
  }

  String? highlightControl;
  @override
  Widget build(BuildContext context) {
    if (ready && (section == 1 || section == 2 || section == 4)) {
      return InstrumentShell(
        key: ValueKey('instrument-${entry.id}'),
        referenceChart: referencePlot,
        toolbarActions: [
          if (entry.studioIndex == 9 && entry.index <= 3)
            IconButton(
              tooltip: 'Optical component library',
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
            ? (!(!run.staticLab && !micMode) || run.time > 0)
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
            result?.toStringAsPrecision(5) ?? 'Undefined',
            lesson.unit,
          ),
          InstrumentReading('Model t', run.time.toStringAsPrecision(4), 's'),
        ],
        advanced: () => experiment().skip(1).toList(),
        results: results,
        notice: () => notice,
        playing: () => ticker.isActive,
        dynamicModel: () => !run.staticLab && !micMode,
        canRecord: () => result != null && result!.isFinite,
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
    LabLearningHeader(
      entry: entry,
      onExplore: () => setState(() => section = 1),
    ),
    relatedLabs(entry.id),
    const SizedBox(height: 12),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Paragraph(
            'Objectives',
            '${entry.principle} Predict ${waveLabel(lesson.metric)}; manipulate, compare, record and explain its validity limits.',
          ),
          Paragraph('Apparatus', lesson.apparatus),
          Paragraph('Physical principles', lesson.principle),
          Paragraph('Investigation procedure', lesson.procedure),
          Paragraph('Assumptions and sampling', lesson.limits),
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
    if (kind == 4) microphoneControls(),
    transport(),
    if (!micMode)
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice, style: const TextStyle(color: muted, fontSize: 12)),
            ...modeControls(),
            ...presets(),
            for (final p in lesson.controls)
              if (visible(p)) parameter(p),
          ],
        ),
      ),
    graph(),
    investigation(),
    recordPanel(),
  ];
  bool visible(Parameter p) =>
      !(kind == 4 && mode != 1 && ['frequency2', 'ratio'].contains(p.key)) &&
      !((kind == 8 || kind == 9) &&
          p.key == 'screen' &&
          (run.state['imageType'] ?? 0) <= 0);
  Widget compactScene() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final painter = WavePainter(
        run,
        labels: labels,
        overlays: overlays,
        comparison: comparison,
        intensity: intensity,
        microphone: micMode,
      );

      return LayoutBuilder(
        builder: (context, box) => Semantics(
          label: painter.accessibleSummary,
          child: ApparatusTransform(
            transformationController: view,
            minScale: 1,
            maxScale: 4,
            child: GestureDetector(
              onHorizontalDragUpdate: micMode
                  ? null
                  : (event) => updateMany(
                      painter.interaction(
                        event.localPosition / (box.maxWidth / 360),
                      ),
                    ),
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
      final painter = WavePainter(
        run,
        labels: labels,
        overlays: overlays,
        comparison: comparison,
        intensity: intensity,
        microphone: micMode,
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
                    onHorizontalDragUpdate: micMode
                        ? null
                        : (event) => updateMany(
                            painter.interaction(
                              event.localPosition / (box.maxWidth / 360),
                            ),
                          ),
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
                kind == 4
                    ? '${micMode ? 'Actual PCM microphone' : 'Generated signal'} · no automatic audio storage or playback.'
                    : kind >= 6
                    ? 'Drag source/object/detector; precise numerical alternatives below. Rays are instructional; optical carrier motion is not shown.'
                    : 'Drag probe/observer; precise coordinates below. Material displacement/field color is labeled and exaggerated.',
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
          const Eyebrow('Actual calculated / analyzed state'),
          const SizedBox(height: 8),
          Text(
            '${waveLabel(lesson.metric)}: ${number(result)} ${lesson.unit}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          for (final key in waveMetrics(kind))
            Text(
              '${waveLabel(key)}: ${number(run.state[key])} ${waveUnit(key)}',
            ),
          if (kind == 4 && run.spectrum != null)
            Text(
              'Detected peak bins: ${run.spectrum!.peaks.map((x) => number(x)).join(', ')} Hz. Hann coherent-gain amplitude; no peak interpolation.',
            ),
          if (kind == 7)
            Text(
              run.state['tir'] == 1
                  ? 'No ordinary transmitted propagating ray.'
                  : 'A transmitted path exists (grazing at the critical limit).',
            ),
          if (kind == 8 || kind == 9)
            Text(
              run.state['infinity'] == 1
                  ? 'Image at infinity; v and magnification are not finite.'
                  : run.state['imageType'] == 1
                  ? 'Real / inverted · screen permitted'
                  : 'Virtual / upright · no projected image on screen',
            ),
          Text(
            'Physical model time ${number(run.time)} s',
            key: const Key('wave-time'),
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
            'Static geometric / intensity investigation',
            'Edit or drag to recompute. There is no fake optical carrier playback.',
          )
        else if (micMode)
          const Paragraph(
            'Microphone uses real time',
            'Visualization slow motion does not change the capture clock. Stop ends the stream; last analysis is held in memory.',
          )
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('play-waves'),
                onPressed: playing ? pause : play,
                icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                label: Text(playing ? 'Pause' : 'Play'),
              ),
              OutlinedButton(
                key: const Key('step-waves'),
                onPressed: () {
                  pause();
                  run.step(capture: true);
                  cursor = math.max(0, run.samples.length - 1);
                  tick.value++;
                },
                child: const Text('Single step'),
              ),
              OutlinedButton(onPressed: reset, child: const Text('Reset time')),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<double>(
            initialValue: clock.speed,
            isExpanded: true,
            decoration: InputDecoration(
              labelText:
                  'Slow-motion multiplier (base ${run.timeScale}× physical time)',
            ),
            items: [.25, .5, 1.0, 2.0]
                .map(
                  (x) => DropdownMenuItem(
                    value: x,
                    child: Text(
                      '$x× selector · ${x * run.timeScale}× physical time',
                    ),
                  ),
                )
                .toList(),
            onChanged: (x) => clock.speed = x!,
          ),
          TextButton(
            key: const Key('replay-waves'),
            onPressed: () {
              pause();
              showDialog<void>(
                context: context,
                builder: (_) => NumericInputDialog(
                  label: 'Physical model time (s)',
                  initial: run.time,
                  min: 0,
                  max: run.maxTime,
                  onApply: (t) {
                    run = WaveOpticsRun(kind, parameters, mode: mode)..seek(t);
                    cursor = math.max(0, run.samples.length - 1);
                    tick.value++;
                    setState(() {});
                  },
                ),
              );
            },
            child: const Text('Time scrubber / deterministic replay'),
          ),
        ],
        OutlinedButton(
          onPressed: defaults,
          child: const Text('Restore documented defaults'),
        ),
        const Text(
          '120 Hz fixed clock · bounded catch-up · leaving/backgrounding stops activity.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
  List<Widget> modeControls() => [
    if ([0, 4, 8, 9].contains(kind))
      DropdownButtonFormField<int>(
        key: const Key('physical-model'),
        isExpanded: true,
        initialValue: mode,
        decoration: const InputDecoration(
          labelText: 'Supported physical model',
        ),
        items: [
          for (int i = 0; i < (kind == 4 ? 3 : 2); i++)
            DropdownMenuItem(
              value: i,
              child: Text(switch (kind) {
                0 => ['Right-traveling', 'Left-traveling'][i],
                4 => [
                  'Single sine',
                  'Two tones',
                  'Band-limited odd harmonics',
                ][i],
                8 => ['Converging thin lens', 'Diverging thin lens'][i],
                _ => ['Concave mirror', 'Convex mirror'][i],
              }),
            ),
        ],
        onChanged: (x) => chooseMode(x!),
      ),
  ];
  List<Widget> presets() => [
    if (kind == 1)
      OutlinedButton(
        onPressed: () => updateMany({
          'a1': .025,
          'a2': -.025,
          'width1': .1,
          'width2': .1,
          'x1': -.5,
          'x2': .5,
          'd1': 1,
          'd2': -1,
          'speed': .4,
        }),
        child: const Text('Equal/opposite pulse reference'),
      ),
    if (kind == 3)
      Text(
        'Fixed endpoints; probe limited to L and amplitude limited to 0.02L/n.',
      ),
    if (kind == 7)
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: () => updateMany({
              'n1': 1.5,
              'n2': 1,
              'angle': math.asin(1 / 1.5) * 180 / math.pi,
            }),
            child: const Text('Critical-angle reference'),
          ),
          OutlinedButton(
            onPressed: () => updateMany({'n1': 1.5, 'n2': 1, 'angle': 60}),
            child: const Text('Total internal reflection'),
          ),
        ],
      ),
    if (kind == 8 || kind == 9)
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final factor in [3.0, 2.0, 1.5, 1.0, .5])
            OutlinedButton(
              onPressed: () => updateMany({'u': factor * parameters['focal']!}),
              child: Text('u = ${factor}f magnitude'),
            ),
        ],
      ),
  ];
  Widget parameter(Parameter p) {
    if (kind == 1 && ['d1', 'd2'].contains(p.key)) {
      return DropdownButtonFormField<double>(
        isExpanded: true,
        initialValue: parameters[p.key],
        decoration: InputDecoration(labelText: p.label),
        items: const [
          DropdownMenuItem(value: -1.0, child: Text('Left (−1)')),
          DropdownMenuItem(value: 1.0, child: Text('Right (+1)')),
        ],
        onChanged: (x) => updateMany({p.key: x!}),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
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
            key: Key('slider-${p.key}'),
            min: p.min,
            max: p.max,
            divisions: p.key == 'harmonic' ? 5 : null,
            value: parameters[p.key]!.clamp(p.min, p.max),
            semanticFormatterCallback: (x) => '$x ${p.unit}',
            onChanged: (x) => updateMany({p.key: x}),
          ),
        ],
      ),
    );
  }

  Widget microphoneControls() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Device microphone input'),
          subtitle: const Text(
            'Generated signal works without permission. Switching input stops capture.',
          ),
          value: micMode,
          onChanged: (x) {
            pause();
            unawaited(mic.stop());
            micMode = x;
            authorizedAnalysis = null;
            lastMicSpectrum = null;
            run = WaveOpticsRun(kind, parameters, mode: mode);
            if (x) clearLive();
            tick.value++;
            setState(() {});
          },
        ),
        if (micMode) ...[
          const Paragraph(
            'Before listening',
            'Microphone permission is requested only when you tap Start listening. Capture stays on this screen. Raw samples are held in a bounded memory buffer; no files or uploads. Record Trial / Save session explicitly saves analyzed bins and metrics only. Levels are relative, not certified dB SPL.',
          ),
          Text(
            mic.status,
            key: const Key('microphone-status'),
            style: TextStyle(color: mic.active ? Colors.red : muted),
          ),
          Text(
            'Actual analyzed capture frames: ${mic.frames}',
            key: const Key('microphone-frames'),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const Key('start-microphone'),
                onPressed: mic.active || mic.requesting
                    ? null
                    : () async {
                        pause();
                        lastMicSpectrum = null;
                        await mic.start();
                      },
                icon: Icon(mic.active ? Icons.mic : Icons.mic_none),
                label: Text(
                  mic.requesting ? 'Requesting access…' : 'Start listening',
                ),
              ),
              OutlinedButton(
                key: const Key('stop-microphone'),
                onPressed: mic.active || mic.requesting ? mic.stop : null,
                child: const Text('Stop microphone'),
              ),
            ],
          ),
        ],
      ],
    ),
  );
  List<WaveState> get graphData => kind == 4 && graphMode == 'spectrum'
      ? run.frequencyCurve
      : graphMode == 'time'
      ? run.samples
      : run.profile;
  List<String> get graphKeys => kind == 4
      ? [
          graphMode == 'spectrum'
              ? 'amplitude'
              : graphMode == 'time'
              ? 'peakFrequency'
              : 'signal',
        ]
      : graphMode == 'time'
      ? [lesson.metric]
      : kind == 1 || kind == 3
      ? [if (comparison) 'first', if (comparison) 'second', 'sum']
      : kind == 2
      ? [intensity ? 'intensity' : 'sum']
      : kind == 5
      ? ['signal']
      : kind == 6
      ? ['reflection']
      : kind == 7
      ? ['refraction', 'reflection']
      : kind == 8 || kind == 9
      ? ['imageVergence']
      : kind >= 10
      ? ['intensity']
      : ['sum'];
  Widget graph() => ListenableBuilder(
    listenable: tick,
    builder: (context, _) {
      final data = graphData,
          keys = graphKeys,
          selected = data.isEmpty
              ? null
              : data[cursor.clamp(0, data.length - 1)];
      final xLabel = graphMode == 'time'
          ? 'Physical time (s)'
          : kind == 4 && graphMode == 'spectrum'
          ? 'Frequency (Hz)'
          : kind == 4 || kind == 5
          ? 'Signal time (s)'
          : kind == 6 || kind == 7
          ? 'Incidence from normal (°)'
          : kind == 8 || kind == 9
          ? 'Object distance (m)'
          : 'Position (m)';
      return Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Eyebrow('Computed samples · analysis / probe'),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: graphMode,
              decoration: const InputDecoration(
                labelText: 'Visualization quantity',
              ),
              items: [
                const DropdownMenuItem(
                  value: 'profile',
                  child: Text('Spatial / waveform / parameter profile'),
                ),
                const DropdownMenuItem(
                  value: 'time',
                  child: Text('Recorded probe / metric vs time'),
                ),
                if (kind == 4)
                  const DropdownMenuItem(
                    value: 'spectrum',
                    child: Text('Hann FFT spectrum'),
                  ),
              ],
              onChanged: (x) {
                setState(() => graphMode = x!);
                cursor = 0;
                tick.value++;
              },
            ),
            const SizedBox(height: 10),
            Text(keys.map(waveLabel).join(' / ')),
            if (data.isEmpty)
              Text(
                micMode && run.spectrum != null
                    ? 'Raw waveform was not saved. Select Hann FFT spectrum to inspect the explicitly saved analysis.'
                    : 'No waveform/analysis available. Live microphone data is never substituted with a generated trace.',
              )
            else ...[
              Semantics(
                label:
                    'Graph: ${keys.join(', ')} versus $xLabel. ${data.length} actual or explicitly analytic samples.',
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
                          keys,
                          xLabel,
                          kind == 4 && graphMode != 'time'
                              ? 'relative FS'
                              : waveUnit(keys.first),
                          cursor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (data.length > 1)
                Slider(
                  key: const Key('cursor-waves'),
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
                'Selected ${number(selected!['t'])}: ${keys.map((k) => '${waveLabel(k)} ${number(selected[k])}').join(' · ')}',
              ),
            ],
            TextButton(
              onPressed: () => graphView.value = Matrix4.identity(),
              child: const Text('Reset graph zoom'),
            ),
            Text(
              graphMode == 'time'
                  ? 'Bounded history: latest 301 observations.'
                  : kind >= 6
                  ? 'Analytic parameter/intensity curve, not a time-domain observation.'
                  : kind == 4
                  ? 'Actual sampled window; no peak interpolation.'
                  : 'Same spatial samples as the rendered displacement.',
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
          if (kind != 4)
            SwitchListTile(
              title: const Text('Educational overlays / normal / probe'),
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
          if (kind == 1 || kind == 3)
            SwitchListTile(
              title: const Text('Traveling-wave component comparison'),
              value: comparison,
              onChanged: (x) {
                setState(() => comparison = x);
                tick.value++;
              },
            ),
          if (kind == 2)
            SwitchListTile(
              title: const Text(
                'Time-averaged intensity proxy (instead of instantaneous height)',
              ),
              value: intensity,
              onChanged: (x) {
                setState(() => intensity = x);
                tick.value++;
              },
            ),
          if (store.reducedMotion)
            const Paragraph(
              'Reduced motion enabled',
              'No animation auto-starts. Single-step, numeric time replay and static profiles provide alternatives; microphone capture requires a separate explicit Start.',
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
              i == 0 ? 'I changed an input and predicted its effect.' : 'I compared the calculated/analyzed data and explained a limitation.',
            ),
            value: guided > i,
            onChanged: (x) {
              setState(() => guided = x == true ? i + 1 : i);
              persist();
            },
          ),
        Text(lesson.question),
        FilledButton(
          key: const Key('predict-waves'),
          onPressed: result == null ? null : predict,
          child: const Text('Test numerical prediction'),
        ),
        if (kind == 7)
          Wrap(
            spacing: 8,
            children: [
              for (final prediction in [0.0, 1.0])
                OutlinedButton(
                  onPressed: () async {
                    pause();
                    await submit(prediction, categorical: true);
                  },
                  child: Text(
                    prediction == 1
                        ? 'Predict TIR'
                        : 'Predict transmitted path',
                  ),
                ),
            ],
          ),
        if (kind == 8 || kind == 9)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final prediction in [1.0, -1.0, 0.0])
                OutlinedButton(
                  onPressed: () async {
                    pause();
                    await submit(prediction, categorical: true);
                  },
                  child: Text(
                    prediction == 1
                        ? 'Real / inverted'
                        : prediction == -1
                        ? 'Virtual / upright'
                        : 'At infinity',
                  ),
                ),
            ],
          ),
        if (feedback.isNotEmpty) Text(feedback),
        Text('${attempts.length} attempts in session (latest 50).'),
        OutlinedButton(
          onPressed: () async {
            if (!changed ||
                guided < 2 ||
                !attempts.any((x) => x['correct'] == true) ||
                !store.trials.any((x) => x.labId == entry.id)) {
              message(
                'Change an input, complete both investigation checks, answer correctly and record a trial first.',
              );
              return;
            }
            await store.complete(entry.id);
            message('Activity completed from your recorded investigation.');
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
              key: const Key('record-waves'),
              onPressed: busy || result == null ? null : record,
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
          Paragraph('Symbols, units and conventions', lesson.symbols),
          Paragraph('Validity, sampling and method', lesson.limits),
          Paragraph('Worked example', lesson.example),
          Paragraph(
            'Current-value substitution',
            '${parameters.entries.map((e) => '${e.key}=${number(e.value)} ${lesson.controls.firstWhere((p) => p.key == e.key).unit}').join('; ')}. At physical t=${number(run.time)} s, ${waveLabel(lesson.metric)}=${number(result)} ${lesson.unit}. ${substitution()}',
          ),
          const Paragraph(
            'Primary references',
            'OpenStax University Physics Volume 1, chapters 16–17, and Volume 3, chapters 1–4. Frequency analysis uses a Hann window with coherent-gain correction.',
          ),
        ],
      ),
    ),
  ];
  String substitution() => switch (kind) {
    0 =>
      'v = ${number(parameters['frequency'])} × ${number(parameters['wavelength'])} = ${number(result)} m/s.',
    1 =>
      'y1 ${number(run.state['first'])} + y2 ${number(run.state['second'])} = ${number(result)} m.',
    2 =>
      'Δr=${number(run.state['pathDifference'])} m and Δphase=${number(run.state['phaseDifference'])} rad give Irel=${number(result)}.',
    3 =>
      'fn = ${number(parameters['harmonic'])} × √(${number(parameters['tension'])}/${number(parameters['density'])}) / (2 × ${number(parameters['length'])}) = ${number(result)} Hz.',
    4 =>
      'Δf = ${number(run.state['sampleRate'])} / ${number(run.state['windowSize'])} = ${number(run.state['binWidth'])} Hz; peak-bin estimate=${number(result)} Hz.',
    5 =>
      'Retarded τ=${number(run.state['emissionTime'])} s; source at emission=${number(run.state['retardedSourceX'])} m, giving fo=${number(result)} Hz.',
    6 => 'θr=θi=${number(parameters['angle'])}°.',
    7 =>
      'n1 sinθ1 = ${number(parameters['n1'])} sin(${number(parameters['angle'])}°); transmitted angle ${number(run.state['transmittedAngle'])}° (undefined for TIR).',
    8 || 9 =>
      '1/v = 1/${number(run.state['focal'])} − 1/${number(parameters['u'])} = ${number(result)} m⁻¹. Image at infinity is represented by zero vergence, not a huge finite v.',
    _ =>
      'sinθ=${number(parameters['probe']! / math.sqrt(parameters['screen']! * parameters['screen']! + parameters['probe']! * parameters['probe']!))}; current normalized detector intensity=${number(run.state['intensity'])}.',
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
              ? 'No observations. Record a computed state or explicitly requested microphone analysis.'
              : '${waveLabel(lesson.metric)} mean ${number(trials.map((t) => t.value).reduce((a, b) => a + b) / trials.length)} ${lesson.unit}; compare matching protocols/input sources only.',
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
              Text(
                'Source ${trial.configuration['input']} · settings ${trial.configuration['parameters']}',
              ),
              if (trial.configuration['input'] == 'microphone')
                const Text(
                  'Saved analyzed bins/metrics only. Raw audio/waveform was not saved.',
                ),
              TextButton(
                onPressed: () {
                  if (restore(trial.configuration)) {
                    setState(() => section = 1);
                    tick.value++;
                    message(
                      'Original configuration/analysis restored; all capture and playback stopped.',
                    );
                  } else {
                    message(
                      'Incompatible saved configuration; original record remains preserved.',
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
