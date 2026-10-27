import '../workbench/learning_header.dart';

import 'package:flutter_math_fork/flutter_math.dart';

import 'dart:convert';

import '../../core/design_system/reference_style.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../content/catalog.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/supplemental_labs.dart';
import '../advanced/scene.dart' show LabPlot;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import '../workbench/workbench.dart';
import 'scene.dart';

class SupplementalWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const SupplementalWorkspace({super.key, required this.entry});
  @override
  ConsumerState<SupplementalWorkspace> createState() =>
      SupplementalWorkspaceState();
}

class SupplementalWorkspaceState extends ConsumerState<SupplementalWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final SupplementalLab lab;
  late final LocalNotebook store;
  late Map<String, double> parameters;
  final tick = ValueNotifier(0), notes = TextEditingController();
  late final Ticker ticker;
  Duration? previous;
  double time = 0;
  int section = 1, guide = 0;
  bool ready = false, running = false, changed = false, incompatible = false;
  bool disposing = false;
  String feedback = '';
  String correctSignature = '';
  String signature() => jsonEncode({'parameters': parameters, 'time': time});
  Future<void> checkInvestigation() async {
    final matching = store.trials.any(
      (t) =>
          t.labId == lab.id &&
          jsonEncode({
                'parameters': t.configuration['parameters'],
                'time': t.configuration['time'],
              }) ==
              signature(),
    );
    if (changed &&
        correctSignature == signature() &&
        matching &&
        notes.text.trim().isNotEmpty) {
      await store.complete(lab.id);
      feedback = 'Investigation complete: prediction, matching trial and explanation recorded.';
    } else {
      feedback = 'Change an input, make a correct prediction, record that configuration, and add your explanation first.';
    }
    await persist();
    refresh();
  }

  void refresh() {
    if (!disposing) tick.value++;
  }

  Map<String, dynamic>? retained;
  List<Map<String, double>> samples = [];
  Map<String, double> get state => lab.evaluate(parameters, time);
  @override
  void initState() {
    super.initState();
    lab = supplementalById(widget.entry.id);
    parameters = lab.defaults;
    store = ref.read(notebookProvider);
    ticker = createTicker(frame);
    WidgetsBinding.instance.addObserver(this);
    recalculate();
    load();
  }

  Future<void> load() async {
    final saved = await store.readSession(lab.id);
    if (!mounted) return;
    if (saved != null && !restore(saved)) {
      retained = saved;
      incompatible = true;
      feedback = 'Saved configuration is incompatible; original retained. Save explicitly to adopt this model.';
    }
    await store.visit(lab.id);
    if (mounted) setState(() => ready = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) dynamicsRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    pause();
    unawaited(persist());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      pause();
      unawaited(persist());
    }
  }

  @override
  void dispose() {
    disposing = true;
    pause();
    unawaited(persist());
    dynamicsRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    tick.dispose();
    notes.dispose();
    super.dispose();
  }

  void recalculate() {
    samples = lab.curve(parameters);
  }

  void frame(Duration elapsed) {
    final delta = previous == null
        ? 0.0
        : (elapsed - previous!).inMicroseconds / 1e6;
    previous = elapsed;
    if (!running) return;
    time = (time + delta.clamp(0, .1) * lab.duration(parameters) / 10).clamp(
      0,
      lab.duration(parameters),
    );
    if (time >= lab.duration(parameters)) pause();
    refresh();
  }

  void pause() {
    final wasRunning = running;
    running = false;
    if (ticker.isActive) ticker.stop();
    previous = null;
    if (wasRunning && !disposing) refresh();
  }

  void play() {
    if (lab.invalid(parameters).isNotEmpty) return;
    if (time >= lab.duration(parameters)) time = 0;
    running = true;
    previous = null;
    ticker.start();
    refresh();
  }

  void change(String key, double value) {
    pause();
    final c = lab.inputs.firstWhere((c) => c.key == key);
    final bounded = value.clamp(c.min, c.max);
    parameters = {
      ...parameters,
      key: ['primary', 'secondary', 'charge'].contains(key)
          ? bounded.roundToDouble()
          : bounded,
    };
    time = 0;
    changed = true;
    recalculate();
    refresh();
  }

  Map<String, dynamic> configuration() => {
    'model': supplementalVersion,
    'labId': lab.id,
    'parameters': Map.of(parameters),
    'time': time,
    'notes': notes.text,
    'changed': changed,
    'guide': guide,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != supplementalVersion || data['labId'] != lab.id) {
        return false;
      }
      final raw = Map<String, dynamic>.from(data['parameters']);
      final p = raw.map((k, v) => MapEntry(k, (v as num).toDouble()));
      if (p.length != lab.inputs.length ||
          lab.inputs.any(
            (c) =>
                p[c.key] == null ||
                !p[c.key]!.isFinite ||
                p[c.key]! < c.min ||
                p[c.key]! > c.max,
          )) {
        return false;
      }
      final t = (data['time'] as num).toDouble();
      if (!t.isFinite || t < 0 || t > lab.duration(p)) return false;
      final n = data['notes'];
      if (n is! String) return false;
      final rawGuide = data['guide'];
      if (rawGuide != null &&
          (rawGuide is! num ||
              !rawGuide.isFinite ||
              rawGuide < 0 ||
              rawGuide > 3 ||
              rawGuide != rawGuide.round())) {
        return false;
      }
      final restoredGuide = (rawGuide as num?)?.toInt() ?? 0;
      pause();
      parameters = p;
      time = t;
      notes.text = n;
      changed = data['changed'] == true;
      guide = restoredGuide;
      recalculate();
      refresh();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> persist() async {
    if (ready && !incompatible) {
      await store.saveSession(lab.id, configuration());
    }
  }

  Future<void> save() async {
    pause();
    try {
      if (incompatible && retained != null) {
        await store.saveSession(
          'backup:${lab.id}:${DateTime.now().microsecondsSinceEpoch}',
          {'backupFor': lab.id, 'original': retained},
        );
        incompatible = false;
      }
      await persist();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session saved; reopens paused.')),
        );
      }
    } catch (_) {
      feedback = 'Save failed; previous data retained.';
      refresh();
    }
  }

  Future<void> record() async {
    pause();
    final s = state;
    if (!ready || incompatible || s.isEmpty) return;
    await store.addTrial(
      Trial(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        labId: lab.id,
        quantity: lab.quantity,
        unit: lab.unit,
        value: s[lab.quantity]!,
        resolution: null,
        configuration: configuration()
          ..['currentState'] = s
          ..['observationType'] = 'Calculated educational model',
        note: notes.text,
        model: supplementalVersion,
      ),
    );
    await persist();
    refresh();
  }

  Future<void> predict() async {
    pause();
    final target = state[lab.quantity];
    if (target == null) return;
    await showDialog<void>(
      context: context,
      builder: (_) => NumericInputDialog(
        label: 'Predict ${lab.quantity} (${lab.unit})',
        initial: 0,
        min: -1e15,
        max: 1e15,
        onApply: (value) async {
          final correct =
              (value - target).abs() <= (target.abs() * .02 + 1e-12);
          await store.recordAttempt(lab.id, {
            'answer': value,
            'target': target,
            'correct': correct,
            'parameters': Map.of(parameters),
            'time': time,
          });
          if (correct) correctSignature = signature();
          feedback =
              '${correct ? 'Correct' : 'Reconsider'}: calculated ${lab.quantity} = ${number(target)} ${lab.unit}. ${lab.task}';
          refresh();
        },
      ),
    );
  }

  static String number(double v) => v == 0
      ? '0'
      : v.abs() < .001 || v.abs() >= 10000
      ? v.toStringAsExponential(3)
      : v.toStringAsPrecision(5);
  List<Widget> learning() => [
    ListTile(title: Text(lab.principle), subtitle: Text(lab.task)),
    ListTile(
      title: const Text('Model and assumptions'),
      subtitle: Text(lab.limits),
    ),
    ListTile(
      title: const Text('Textbook reference'),
      subtitle: SelectableText(lab.source),
    ),
    const ListTile(
      title: Text('Calculated model curves'),
      subtitle: Text(
        'Curves are analytic predictions, not recorded measurements. Only Record Trial adds an observation to your notebook.',
      ),
    ),
  ];
  Widget live(Widget Function() build) =>
      ListenableBuilder(listenable: tick, builder: (_, _) => build());
  Widget data() => SizedBox(
    height: 320,
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final v in state.entries)
          ListTile(
            title: Text(v.key),
            subtitle: Text('${number(v.value)} ${lab.unitFor(v.key)}'),
          ),
        ...learning(),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (section == 0 || section == 3) {
      return Scaffold(
        appBar: AppBar(
          leading: LabBackButton(widget.entry.id.split('-').first),
          title: Text(lab.title),
          actions: [
            LabSectionMenu(
              section: section,
              select: (v) => setState(() => section = v),
              labId: lab.id,
              notebook: store,
            ),
          ],
        ),
        bottomNavigationBar: const ReferenceNavigation(selected: 1),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (section == 0)
              LabLearningHeader(
                entry: widget.entry,
                onExplore: () => setState(() => section = 1),
              ),
            Text(
              section == 0 ? 'Learn' : 'Formulas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Math.tex(lab.equation),
            ),
            ...learning(),
            FilledButton(
              onPressed: () => setState(() => section = 1),
              child: const Text('Open experiment'),
            ),
          ],
        ),
      );
    }
    return InstrumentShell(
      researchReadings: () => [
        for (final e in state.entries)
          InstrumentReading(e.key, e.value.toString(), lab.unitFor(e.key)),
      ],
      id: lab.id,
      title: lab.title,
      store: store,
      changes: tick,
      scene: () => live(
        () => Semantics(
          image: true,
          label:
              '${lab.title}. ${state.entries.map((e) => '${e.key}: ${number(e.value)}').join('; ')}',
          child: SizedBox(
            width: 360,
            height: 270,
            child: CustomPaint(
              painter: SupplementalPainter(lab, parameters, state, time),
            ),
          ),
        ),
      ),
      graph: () => live(
        () => state.isEmpty
            ? SizedBox(
                height: 320,
                child: Center(child: Text(lab.invalid(parameters))),
              )
            : SizedBox(
                height: 320,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        lab.dynamicModel
                            ? 'Calculated ${lab.graphKey} vs time (s)'
                            : 'Calculated ${lab.quantity} vs ${lab.inputs.firstWhere((c) => c.key == lab.sweep).label} (${lab.inputs.firstWhere((c) => c.key == lab.sweep).unit})',
                      ),
                    ),
                    Expanded(
                      child: CustomPaint(
                        painter: LabPlot(
                          samples,
                          [lab.graphKey],
                          lab.dynamicModel ? 'Time (s)' : lab.sweep,
                          lab.graphUnit,
                          lab.dynamicModel
                              ? (time / lab.duration(parameters) * 240).round()
                              : samples
                                    .indexWhere(
                                      (s) => s['t']! >= parameters[lab.sweep]!,
                                    )
                                    .clamp(0, samples.length),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
      ),
      controls: () => [
        for (final c in lab.inputs)
          InstrumentControl(
            c.key,
            c.label,
            c.unit,
            parameters[c.key]!,
            c.min,
            c.max,
            (v) => change(c.key, v),
          ),
      ],
      readings: () => [
        InstrumentReading(
          lab.resultLabel,
          state.isEmpty ? '—' : number(state[lab.quantity]!),
          lab.unit,
        ),
        if (lab.dynamicModel)
          InstrumentReading('Model time', number(time), 's'),
      ],
      data: () => live(data),
      advanced: () => [
        ...learning(),
        FilledButton(
          onPressed: checkInvestigation,
          child: const Text('Check investigation'),
        ),
        TextField(
          controller: notes,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Investigation notes'),
        ),
      ],
      results: () => [
        ...learning(),
        for (final t
            in store.trials.where((t) => t.labId == lab.id).toList().reversed)
          ListTile(
            title: Text('${t.quantity}: ${number(t.value)} ${t.unit}'),
            subtitle: Text(t.note.isEmpty ? 'Calculated model trial' : t.note),
            onTap: () => restore(t.configuration),
          ),
      ],
      notice: () => lab.invalid(parameters).isNotEmpty
          ? lab.invalid(parameters)
          : feedback.isNotEmpty
          ? feedback
          : lab.dynamicModel
          ? 'Ten seconds playback = ${number(lab.duration(parameters))} model seconds.'
          : lab.task,
      principle: () => lab.principle,
      modelLimits: () => lab.limits,
      equation: lab.equation,
      predict: predict,
      playing: () => running,
      dynamicModel: () => lab.dynamicModel,
      canRecord: () => ready && !incompatible && state.isNotEmpty,
      finished: () => lab.dynamicModel && time >= lab.duration(parameters),
      play: play,
      pause: () {
        pause();
        refresh();
      },
      reset: () {
        pause();
        parameters = lab.defaults;
        time = 0;
        changed = false;
        feedback = '';
        recalculate();
        refresh();
      },
      save: save,
      record: record,
      captureConfiguration: configuration,
      restoreConfiguration: restore,
      reopenTrial: (t) =>
          t.model == supplementalVersion &&
          t.labId == lab.id &&
          restore(t.configuration),
      exportRecorded: (trials) => exportTrials(context, trials),
      guidedStep: () => guide,
      changeGuidedStep: (v) {
        guide = v;
        refresh();
      },
      guideInstructions: () => [
        'Read the principle and model assumptions.',
        lab.task,
        'Record a calculated trial and compare it with your prediction.',
        'Write your explanation in investigation notes.',
      ],
      canAdvanceGuide: (step) =>
          step == 0 ||
          step == 1 && changed ||
          step == 2 && store.trials.any((t) => t.labId == lab.id) ||
          step == 3 && notes.text.trim().isNotEmpty,
      selectSection: (v) {
        pause();
        setState(() => section = v);
      },
      section: section,
    );
  }
}
