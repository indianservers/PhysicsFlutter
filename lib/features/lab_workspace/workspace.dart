import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/measurement.dart';
import '../../core/rendering/apparatus.dart';
import '../measurement/experiment.dart';
import '../measurement/lessons.dart';

class Workspace extends ConsumerStatefulWidget {
  final Entry entry;
  const Workspace({super.key, required this.entry});
  @override
  ConsumerState<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends ConsumerState<Workspace>
    with WidgetsBindingObserver {
  late final Experiment experiment;
  int section = 0;
  bool ready = false, recording = false;
  int dragTarget = 2;
  final transform = TransformationController();
  Entry get entry => widget.entry;
  late final LocalNotebook store;
  @override
  void initState() {
    super.initState();
    store = ref.read(notebookProvider);
    WidgetsBinding.instance.addObserver(this);
    experiment = Experiment(entry.index);
    _load();
  }

  Future<void> _load() async {
    final m = await store.readSession(entry.id);
    if (m != null && entry.interactive) {
      experiment.restore(m);
    }
    await store.visit(entry.id);
    if (mounted) {
      setState(() => ready = true);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      experiment.pause();
      if (entry.interactive) {
        store.saveSession(entry.id, experiment.toJson());
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (entry.interactive) {
      experiment.pause();
      store.saveSession(entry.id, experiment.toJson());
    }
    experiment.dispose();
    transform.dispose();
    super.dispose();
  }

  void message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> save() async {
    experiment.pause();
    try {
      await store.saveSession(entry.id, experiment.toJson());
      message('Session saved. Reopen here or from your notebook.');
    } catch (_) {
      message('Saving failed. Your current session remains open.');
    }
  }

  Future<void> record() async {
    if (recording) {
      return;
    }
    experiment.pause();
    final value = experiment.result;
    if (value == null || !value.isFinite) {
      message(
        entry.index == 3
            ? 'A flat surface has no finite radius to record.'
            : 'Add readings or run the timer before recording.',
      );
      return;
    }
    setState(() => recording = true);
    try {
      await store.addTrial(
        Trial(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          labId: entry.id,
          quantity: experiment.quantity,
          unit: experiment.siUnit,
          value: value,
          resolution:
              (entry.index == 4) ||
                  (entry.index == 5 && !experiment.resolutionKnown)
              ? null
              : experiment.leastCount,
          configuration: experiment.toJson(),
          note: experiment.note,
        ),
      );
      if (entry.index == 4) {
        for (final reading in [
          (
            quantity: 'mass',
            unit: 'kg',
            value: experiment.a - experiment.zero,
            resolution: .00001,
          ),
          (
            quantity: 'time',
            unit: 's',
            value: experiment.elapsed,
            resolution: .001,
          ),
        ]) {
          await store.addTrial(
            Trial(
              id: '${DateTime.now().microsecondsSinceEpoch}-${reading.quantity}',
              labId: entry.id,
              quantity: reading.quantity,
              unit: reading.unit,
              value: reading.value,
              resolution: reading.resolution,
              configuration: experiment.toJson(),
              note: experiment.note,
            ),
          );
        }
      }
      await store.saveSession(entry.id, experiment.toJson());
      if (store.haptics) {
        HapticFeedback.lightImpact();
      }
      message('Trial recorded in your notebook.');
    } catch (_) {
      message('Could not record the trial. Please try again.');
    } finally {
      if (mounted) {
        setState(() => recording = false);
      }
    }
  }

  Future<void> recordMass() async {
    try {
      await store.addTrial(
        Trial(
          id: '${DateTime.now().microsecondsSinceEpoch}-mass',
          labId: entry.id,
          quantity: 'mass',
          unit: 'kg',
          value: experiment.a - experiment.zero,
          resolution: .00001,
          configuration: experiment.toJson(),
          note: experiment.note,
        ),
      );
      message('Balance indication recorded in kg.');
    } catch (_) {
      message('Could not save this balance reading.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: experiment,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(entry.title),
          actions: [
            if (entry.interactive)
              IconButton(
                tooltip: 'Save session',
                onPressed: save,
                icon: const Icon(Icons.bookmark_add_outlined),
              ),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: section,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (v) {
            if (section == 1 && v != 1) {
              experiment.pause();
            }
            setState(() => section = v);
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
            NavigationDestination(
              icon: Icon(Icons.functions),
              label: 'Formulas',
            ),
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
                    Eyebrow(
                      '${studios[entry.studioIndex].title} / ${entry.availability}',
                    ),
                    const SizedBox(height: 14),
                    if (section == 0)
                      ...learn()
                    else if (section == 1)
                      ...experimentView()
                    else if (section == 2)
                      ...visualization()
                    else if (section == 3)
                      ...formulas()
                    else
                      ...results(),
                  ],
                ),
        ),
      ),
    );
  }

  List<Widget> learn() => [
    Text(entry.title, style: Theme.of(context).textTheme.headlineLarge),
    const SizedBox(height: 12),
    Text(entry.principle, style: const TextStyle(fontSize: 17, height: 1.6)),
    const SizedBox(height: 22),
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Paragraph(
            'Learning objectives',
            'Explain ${entry.title.toLowerCase()} in your own words.\n${entry.principle}\nIdentify the assumptions and units in the model. ${entry.interactive ? 'Take, correct and record a measurement.' : 'Interpret the relevant equation and its limits.'}',
          ),
          if (entry.interactive) ...[
            Paragraph('Apparatus', apparatusNames[entry.index]),
            Paragraph('Principles', errors[entry.index]),
            Paragraph('Step-by-step procedure', procedures[entry.index]),
            Paragraph('Common mistakes', mistakes[entry.index]),
            Paragraph('Sources of error', errors[entry.index]),
            Paragraph('Guided question', questions[entry.index]),
          ] else ...[
            Paragraph('Introductory theory', theoryFor(entry)),
            Paragraph('Model assumptions', assumptions[entry.studioIndex]),
            Paragraph(
              'Think about it',
              'Which quantity in ${entry.title.toLowerCase()} would you change first? Predict what the equation implies, hold other inputs fixed, and check the dimensions of your prediction.',
            ),
          ],
          FilledButton.icon(
            onPressed: () =>
                setState(() => section = entry.interactive ? 1 : 3),
            icon: const Icon(Icons.arrow_forward),
            label: Text(
              entry.interactive ? 'Open the experiment' : 'Explore the formula',
            ),
          ),
        ],
      ),
    ),
    if (entry.tool) ...toolContent(),
    OutlinedButton.icon(
      onPressed: () async {
        if (entry.interactive && experiment.step < 3) {
          message('Complete all four guided steps in Experiment first.');
          return;
        }
        await store.complete(entry.id);
        message('Activity marked complete.');
      },
      icon: const Icon(Icons.check_circle_outline),
      label: Text(
        store.completed.contains(entry.id)
            ? 'Activity completed'
            : 'Mark learning activity complete',
      ),
    ),
  ];
  List<Widget> experimentView() {
    if (!entry.interactive) {
      return [
        const Panel(
          child: Paragraph(
            'Interactive experiment · Later phase',
            'This destination currently provides learning content and formulas. Its physical experiment is scheduled for a later phase; no simulated observations or results are supplied.',
          ),
        ),
        if (entry.tool) ...toolContent(),
      ];
    }
    return [
      scene(),
      readout(),
      if (entry.index < 3) magnified(),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: controls(),
        ),
      ),
      guidedPanel(),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Record an observation',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: experiment.note,
              maxLines: 2,
              onChanged: (v) => experiment.note = v,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'What did you observe?',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  key: const Key('record-trial'),
                  onPressed: recording ? null : record,
                  icon: const Icon(Icons.add),
                  label: const Text('Record Trial'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    experiment.reset();
                    transform.value = Matrix4.identity();
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Reset'),
                ),
                OutlinedButton.icon(
                  onPressed: save,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('Save session'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget scene({bool enlarged = false}) => ListenableBuilder(
    listenable: experiment.clockTick,
    builder: (_, _) => sceneFrame(enlarged: enlarged),
  );
  Widget sceneFrame({bool enlarged = false}) {
    final e = experiment;
    final kind = entry.index;
    final painter = ApparatusPainter(
      kind,
      a: kind == 5 ? (e.resolutionKnown ? e.resolution : 0) : e.a,
      b: kind == 4 ? e.duration : e.b,
      zero: e.zero,
      time: store.reducedMotion
          ? 0
          : kind == 4
          ? e.elapsed
          : e.elapsed,
      guides: e.guides,
      samples: e.samples,
      progress: store.reducedMotion ? 0 : e.travelled / e.distance,
    );
    return Panel(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Eyebrow('Virtual apparatus · SI model'),
                  ),
                  IconButton(
                    tooltip: 'Reset zoom and pan',
                    onPressed: () => transform.value = Matrix4.identity(),
                    icon: const Icon(Icons.fit_screen),
                  ),
                ],
              ),
            ),
            LayoutBuilder(
              builder: (c, box) => Semantics(
                label:
                    '${entry.title}. ${painter.accessibleSummary}. ${summary()}. Pinch to zoom. Use precise controls below as an accessible alternative.',
                child: InteractiveViewer(
                  transformationController: transform,
                  minScale: 1,
                  maxScale: 5,
                  child: GestureDetector(
                    onHorizontalDragStart: kind == 0
                        ? (details) {
                            final x =
                                details.localPosition.dx / box.maxWidth * 360;
                            final xa = 22 + e.a * 3160, xb = 22 + e.b * 3160;
                            dragTarget = (x - xa).abs() < 18
                                ? 0
                                : (x - xb).abs() < 18
                                ? 1
                                : 2;
                          }
                        : null,
                    onHorizontalDragUpdate:
                        kind == 0 || kind == 1 || kind == 2 || kind == 3
                        ? (details) {
                            final dx =
                                details.delta.dx /
                                box.maxWidth /
                                transform.value.getMaxScaleOnAxis();
                            if (kind == 0) {
                              if (dragTarget == 0) {
                                e.setA(e.a + dx * .1);
                                return;
                              }
                              if (dragTarget == 1) {
                                e.setB(e.b + dx * .1);
                                return;
                              }
                              final length = e.b - e.a;
                              final newA = (e.a + dx * .1).clamp(
                                0.0,
                                .1 - length,
                              );
                              e.a = quantize(newA, .001);
                              e.b = e.a + length;
                              e.changed();
                            } else {
                              e.setA(
                                e.a +
                                    dx *
                                        (kind == 1
                                            ? 0.05
                                            : kind == 2
                                            ? 0.005
                                            : .006),
                              );
                            }
                          }
                        : null,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size(box.maxWidth, enlarged ? 340 : 210),
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
                kind == 0
                    ? 'Drag object ↔ · endpoint sliders below · pinch to zoom'
                    : kind == 2
                    ? 'Drag thimble ↔ · precise controls below'
                    : kind == 5
                    ? 'Error bars: quantization standard uncertainty q/√12'
                    : 'Simplified geometry · drag or use precise controls',
                style: const TextStyle(color: muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String display(double? value, {String? unit}) => value == null
      ? 'Unavailable'
      : '${value.toStringAsPrecision(6)} ${unit ?? experiment.siUnit}';
  String summary() {
    final e = experiment;
    return switch (entry.index) {
      0 =>
        'Length ${display(e.result)} · A ${mm(e.a).toStringAsFixed(1)} mm · B ${mm(e.b).toStringAsFixed(1)} mm',
      1 || 2 =>
        'Main ${mm(e.reading.main).toStringAsFixed(2)} mm + ${mm(e.reading.fraction).toStringAsFixed(2)} mm · division ${e.reading.division} · observed ${mm(e.reading.observed).toStringAsFixed(2)} mm · signed zero ${mm(e.zero).toStringAsFixed(2)} mm · corrected ${display(e.result)}',
      3 =>
        'h = ${mm(e.h).toStringAsFixed(3)} mm · r = ${mm(e.b).toStringAsFixed(1)} mm · ${e.h == 0
            ? 'Flat plane: |R| → ∞'
            : e.h > 0
            ? 'Convex rise'
            : 'Concave depression'} · signed R ${display(e.result)}',
      4 =>
        'Elapsed ${e.elapsed.toStringAsFixed(3)} s · travelled ${e.travelled.toStringAsFixed(4)} m · average speed ${display(e.result)}',
      _ => '${e.samples.length} readings · mean ${display(e.result)}',
    };
  }

  Widget readout() => ListenableBuilder(
    listenable: experiment.clockTick,
    builder: (_, _) => readoutFrame(),
  );
  Widget readoutFrame() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Current reading'),
        const SizedBox(height: 10),
        Text(
          experiment.reveal || entry.index > 2
              ? summary()
              : 'Read the scale, then reveal the answer.',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          entry.index < 4
              ? 'Resolution ${mm(experiment.leastCount).toStringAsFixed(2)} mm · full precision retained'
              : 'Simulation · values derive from current inputs',
          style: const TextStyle(color: muted, fontSize: 11),
        ),
        if (entry.index < 3)
          TextButton(
            onPressed: () {
              experiment.reveal = !experiment.reveal;
              experiment.changed();
            },
            child: Text(experiment.reveal ? 'Hide answer' : 'Reveal answer'),
          ),
      ],
    ),
  );
  Widget magnified() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Magnified reading window · 3×'),
        const SizedBox(height: 12),
        Semantics(
          label: 'Magnified instrument scale. ${summary()}',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 110,
              width: double.infinity,
              child: CustomPaint(
                painter: MagnifiedScalePainter(
                  ApparatusPainter(
                    entry.index,
                    a: experiment.a,
                    b: experiment.b,
                    zero: experiment.zero,
                    guides: experiment.guides,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
  List<Widget> controls() {
    final e = experiment;
    return switch (entry.index) {
      0 => [
        const Paragraph(
          'Position the endpoints',
          'A and B sit on the same millimetre grid as the ruler. Drag the object above to move both endpoints.',
        ),
        control('Endpoint A', e.a, 0, e.b - .001, .001, 'mm', 1000, e.setA),
        control('Endpoint B', e.b, e.a + .001, .1, .001, 'mm', 1000, e.setB),
      ],
      1 => [
        const Paragraph(
          'External measurement',
          'The vernier zero is the movable jaw position. Blue marks show the coincident division.',
        ),
        control('Jaw opening', e.a, 0, .05, .0001, 'mm', 1000, e.setA),
        control('Signed zero error', e.zero, -.001, .001, .0001, 'mm', 1000, (
          v,
        ) {
          e.zero = v;
          e.changed();
        }),
      ],
      2 => [
        const Paragraph(
          'Turn the thimble',
          'One turn = 0.5 mm. Contact stops at the defined wire thickness. Ratchet force is not simulated.',
        ),
        control('Wire thickness', e.b, .0001, .005, .00001, 'mm', 1000, e.setB),
        control('Spindle opening', e.a, e.b, .025, .00001, 'mm', 1000, e.setA),
        Text('Turns from zero: ${(e.a / .0005).toStringAsFixed(3)}'),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton(
              onPressed: () => e.setA(e.a + .0005),
              child: const Text('+1 turn'),
            ),
            OutlinedButton(
              onPressed: () => e.setA(e.a - .0005),
              child: const Text('−1 turn'),
            ),
            FilledButton(
              onPressed: () => e.setA(e.b),
              child: const Text('Ratchet to contact'),
            ),
          ],
        ),
        control(
          'Signed zero error',
          e.zero,
          -.0001,
          .0001,
          .00001,
          'mm',
          1000,
          (v) {
            e.zero = v;
            e.changed();
          },
        ),
      ],
      3 => [
        control('Screw reading', e.a, -.003, .003, .00001, 'mm', 1000, e.setA),
        control(
          'Centre-to-leg radius r',
          e.b,
          .01,
          .1,
          .001,
          'mm',
          1000,
          e.setB,
        ),
        Wrap(
          spacing: 10,
          children: [
            OutlinedButton(
              onPressed: () {
                e.a = 0;
                e.zero = 0;
                e.changed();
              },
              child: const Text('Plane reference'),
            ),
            FilledButton(
              onPressed: () {
                e.zero = e.a;
                e.changed();
              },
              child: const Text('Zero on plane'),
            ),
          ],
        ),
        Text(
          'Plane reference ${mm(e.zero).toStringAsFixed(3)} mm · l = ${(mm(e.b) * math.sqrt(3)).toStringAsFixed(3)} mm',
        ),
        const SizedBox(height: 8),
        const Text(
          'Only zero when on the plane reference. Negative sagitta describes a concave depression; radii are signed.',
        ),
      ],
      4 => [
        control('Defined mass', e.a, .001, .1, .00001, 'g', 1000, (v) {
          e.a = v;
          e.changed();
        }),
        Text(
          'Balance indication ${((e.a - e.zero) * 1000).toStringAsFixed(2)} g · weight ${(e.a * 9.80665).toStringAsFixed(4)} N',
        ),
        TextButton(
          onPressed: () {
            e.zero = e.a;
            e.changed();
          },
          child: const Text('Tare balance'),
        ),
        TextButton(
          onPressed: () {
            e.zero = 0;
            e.changed();
          },
          child: const Text('Clear tare'),
        ),
        OutlinedButton(
          onPressed: recordMass,
          child: const Text('Record balance mass'),
        ),
        control('Track distance', e.distance, .1, 2, .1, 'm', 1, (v) {
          e.resetTimer();
          e.distance = v;
          e.changed();
        }),
        control('Initial speed', e.v0, .1, 2, .1, 'm/s', 1, (v) {
          e.resetTimer();
          e.v0 = v;
          e.changed();
        }),
        control('Constant acceleration', e.acceleration, 0, 2, .1, 'm/s²', 1, (
          v,
        ) {
          e.resetTimer();
          e.acceleration = v;
          e.changed();
        }),
        Wrap(
          spacing: 10,
          children: [
            FilledButton.icon(
              onPressed: () {
                if (e.elapsed >= e.duration) {
                  e.resetTimer();
                }
                e.running ? e.pause() : e.start();
              },
              icon: Icon(e.running ? Icons.pause : Icons.play_arrow),
              label: Text(e.running ? 'Pause' : 'Start timing'),
            ),
            OutlinedButton(
              onPressed: () {
                e.pause();
                final config = e.toJson();
                config['elapsed'] = 0.0;
                e.restore(config);
              },
              child: const Text('Reset timer'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Backgrounding or leaving Experiment pauses the timer. Restore always opens paused. No artificial noise is added.',
        ),
      ],
      _ => uncertaintyControls(),
    };
  }

  Widget control(
    String title,
    double value,
    double min,
    double max,
    double step,
    String unit,
    double multiplier,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              TextButton(
                onPressed: () => numberDialog(
                  title,
                  value * multiplier,
                  min * multiplier,
                  max * multiplier,
                  (v) => onChanged(v / multiplier),
                ),
                child: Text(
                  '${(value * multiplier).toStringAsFixed(multiplier == 1000 ? 3 : 2)} $unit  ✎',
                ),
              ),
            ],
          ),
          Slider(
            semanticFormatterCallback: (v) =>
                '${(v * multiplier).toStringAsFixed(3)} $unit',
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: math.max(1, ((max - min) / step).round()),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Future<void> numberDialog(
    String label,
    double initial,
    double min,
    double max,
    ValueChanged<double> change,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => NumericInputDialog(
        label: label,
        initial: initial,
        min: min,
        max: max,
        onApply: change,
      ),
    );
  }

  Widget guidedPanel() => Panel(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Guided mode'),
        const SizedBox(height: 10),
        Text(
          'Step ${experiment.step + 1} of 4',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          [
            'Inspect the scale and units. Review the procedure in Learn.',
            'Adjust the apparatus using drag or a precise numeric input.',
            'Read the instrument. Use the reading challenge before checking.',
            'Record a trial, then mark the learning activity complete.',
          ][experiment.step],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            if (experiment.step > 0)
              OutlinedButton(
                onPressed: () {
                  experiment.step--;
                  experiment.changed();
                },
                child: const Text('Previous'),
              ),
            FilledButton(
              onPressed: () async {
                if (experiment.step < 3) {
                  experiment.step++;
                  experiment.changed();
                } else if (store.trials.any((t) => t.labId == entry.id)) {
                  await store.complete(entry.id);
                  message('Guided activity complete.');
                } else {
                  message('Record a trial to finish the guided activity.');
                }
              },
              child: Text(
                experiment.step == 3 ? 'Finish guided activity' : 'Next step',
              ),
            ),
            if (entry.index < 3)
              OutlinedButton(
                onPressed: challenge,
                child: const Text('Reading challenge'),
              ),
          ],
        ),
      ],
    ),
  );
  Future<void> challenge() async {
    await numberDialog('Your corrected reading (mm)', 0, -10, 100, (v) {
      final correct = experiment.result!;
      final matches = (v / 1000 - correct).abs() <= experiment.leastCount / 2;
      message(
        matches
            ? 'Correct within half a scale division. ${summary()}'
            : 'Try again: ${entry.index == 0 ? 'subtract B − A' : 'add main and fractional scales, then subtract signed zero error'}. Your answer was $v mm.',
      );
    });
  }

  List<Widget> visualization() => entry.interactive
      ? [
          scene(enlarged: true),
          if (entry.index < 3) magnified(),
          SwitchListTile(
            title: const Text('Instructional guides'),
            value: experiment.guides,
            onChanged: (v) {
              experiment.guides = v;
              experiment.changed();
            },
          ),
          readout(),
          Panel(
            child: Paragraph(
              'Scale and geometry',
              entry.index == 1
                  ? 'One main division is 1 mm; one vernier division is 0.9 mm. The vernier zero starts at the observed jaw opening. At index n, the scale coincides with the main scale because n × 0.1 mm is the fractional contribution. Zoom to inspect the blue coincidence.'
                  : entry.index == 2
                  ? 'The sleeve marks 0.5 mm intervals. The thimble has 50 divisions, each 0.01 mm. Rotation is derived from the same quantized screw displacement as the readout. Pinch and pan to magnify.'
                  : entry.index == 3
                  ? 'The blue curve is an exaggerated cross-section of a spherical surface. Outer legs lie at radius r from the central screw. Sagitta h is positive upward. The illustration is not to scale.'
                  : entry.index == 5
                  ? 'Teal error bars show each reading ±q/√12. The amber line shows the mean. All axes use the selected SI quantity. This chart describes the current data, not fabricated observations.'
                  : 'Pinch to magnify and pan to inspect. Zoom does not change any physical state or reading. All exact positions remain available through numerical controls.',
            ),
          ),
          if (entry.index == 5) statisticsPanel(),
        ]
      : [
          const Panel(
            child: Paragraph(
              'Visualization · Later phase',
              'Interactive visualization for this topic is scheduled for a later phase. The studio illustration is conceptual and does not represent computed data.',
            ),
          ),
        ];
  List<Widget> formulas() => [
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('The governing relationship'),
          const SizedBox(height: 20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Math.tex(
              entry.formula,
              textStyle: const TextStyle(fontSize: 23, color: navy),
            ),
          ),
          const SizedBox(height: 20),
          Paragraph(
            'Symbols, units and assumptions',
            entry.interactive
                ? symbols[entry.index]
                : '${entry.principle}\n${assumptions[entry.studioIndex]}\nUse SI units: distance m, time s, mass kg, force N, energy J, charge C, temperature K. Consult the referenced introductory text for this topic’s symbol conventions.',
          ),
          if (entry.interactive) ...[
            Paragraph('Current substitution', summary()),
            Paragraph('Worked example', substitutions[entry.index]),
            Paragraph('Valid range and uncertainty', errors[entry.index]),
          ],
          const Paragraph(
            'References',
            'NCERT Physics Laboratory Manual, Class XI, experiments 1–3 (calipers, screw gauge and spherometer). OpenStax University Physics, Volumes 1–3 (introductory theory). NIST Technical Note 1297 (uncertainty). Full source URLs and model assumptions are in docs/SCIENTIFIC_MODELS.md.',
          ),
        ],
      ),
    ),
  ];
  List<Widget> results() {
    final trials = store.trials.where((t) => t.labId == entry.id).toList();
    return [
      Text(
        'Your observations',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 12),
      if (trials.isEmpty)
        const Panel(
          child: Paragraph(
            'No trials recorded',
            'Record an observation in an available experiment to start your notebook. No sample results are supplied.',
          ),
        ),
      if (trials.isNotEmpty) ...[
        for (final unit in trials.map((t) => t.unit).toSet())
          Builder(
            builder: (context) {
              final group = trials.where((t) => t.unit == unit).toList();
              final stats = Statistics(
                group.map((t) => t.value).toList(),
                group.last.resolution,
              );
              return Panel(
                child: Paragraph(
                  '${group.length} ${group.first.quantity} observations · $unit',
                  'Mean ${display(stats.mean, unit: unit)}\nSample SD ${display(stats.sd, unit: unit)}\nRange ${display(stats.spread, unit: unit)}\nCompare only measurements of the same object under an appropriate protocol.',
                ),
              );
            },
          ),
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
                  display(t.value, unit: t.unit),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(t.note.isEmpty ? 'No notes' : t.note),
                Text(
                  t.created,
                  style: const TextStyle(color: muted, fontSize: 11),
                ),
                TextButton(
                  onPressed: () {
                    if (experiment.restore(t.configuration)) {
                      setState(() => section = 1);
                      message('Configuration restored, timer paused.');
                    } else {
                      message('This configuration is incompatible.');
                    }
                  },
                  child: const Text('Reopen configuration'),
                ),
              ],
            ),
          ),
      ],
      if (entry.interactive)
        OutlinedButton(
          onPressed: save,
          child: const Text('Save current configuration'),
        ),
    ];
  }

  List<Widget> toolContent() => [
    Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Paragraph('Introductory ${entry.title}', switch (entry.index) {
            0 => 'Browse every studio by its scientific domain.',
            1 => 'Measurement → Motion → Force → Energy. These relationships are a learning guide; an interactive graph is planned for a later phase.',
            2 => 'Recommended path: Measurement → Mechanics → Motion & Kinematics → Force & Newton’s Laws → Work/Energy/Power → Gravitation → Oscillations → Waves & Sound → Optics → Electricity → Magnetism → Electronics → Thermodynamics → Fluid Mechanics → Modern Physics. Complete each six-lab sequence in order.',
            3 => 'Discover all 90 currently interactive labs below. Later studios retain introductory learning content.',
            4 => 'Compare precision: ruler 1 mm; caliper 0.1 mm; micrometer 0.01 mm. A smaller division does not remove systematic error.',
            _ => 'Introductory challenge: A ruler reading starts at 12 mm and ends at 66 mm. What is the length? Advanced assessment is planned for a later phase.',
          }),
          if (entry.index == 5)
            OutlinedButton(
              onPressed: () => message(
                '66 − 12 = 54 mm. Subtract endpoint positions; the start need not be zero.',
              ),
              child: const Text('Explain the answer'),
            ),
          for (final s in (entry.index == 0 ? studios : studios.sublist(1, 5)))
            TextButton.icon(
              onPressed: () => context.push('/studio/${s.id}'),
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: Text(s.title),
            ),
          if (entry.index == 2 || entry.index == 3)
            for (final e in allEntries.where((e) => e.interactive))
              ListTile(
                title: Text(e.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/lab/${e.id}'),
              ),
        ],
      ),
    ),
  ];
  List<Widget> uncertaintyControls() {
    final e = experiment;
    return [
      const Paragraph(
        'Build a dataset',
        'Enter readings in the selected SI unit. Import only measurements of the same quantity and object. Changing units clears this dataset.',
      ),
      DropdownButtonFormField<String>(
        initialValue: e.unit,
        decoration: const InputDecoration(labelText: 'Quantity / SI unit'),
        items: const [
          DropdownMenuItem(value: 'm', child: Text('Length (m)')),
          DropdownMenuItem(value: 'kg', child: Text('Mass (kg)')),
          DropdownMenuItem(value: 's', child: Text('Time (s)')),
        ],
        onChanged: (v) {
          if (v == null) {
            return;
          }
          e.unit = v;
          e.samples = [];
          e.changed();
        },
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Instrument resolution is known'),
        value: e.resolutionKnown,
        onChanged: (v) {
          e.resolutionKnown = v ?? false;
          e.changed();
        },
      ),
      control(
        'Instrument resolution',
        e.resolution,
        .00001,
        .01,
        .00001,
        e.unit,
        1,
        (v) {
          e.resolution = v;
          e.changed();
        },
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          FilledButton(
            onPressed: () =>
                numberDialog('Add reading (${e.unit})', 0, -1e9, 1e9, (v) {
                  e.samples = [...e.samples, v];
                  e.changed();
                }),
            child: const Text('Add reading'),
          ),
          OutlinedButton(
            onPressed: importReadings,
            child: const Text('Import saved trials'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      for (int i = 0; i < e.samples.length; i++)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('${i + 1}. ${e.samples[i]} ${e.unit}'),
          trailing: IconButton(
            tooltip: 'Remove reading ${i + 1}',
            onPressed: () {
              e.samples = [...e.samples]..removeAt(i);
              e.changed();
            },
            icon: const Icon(Icons.close),
          ),
        ),
      statisticsPanel(),
      const SizedBox(height: 12),
      PropagationCalculator(unit: e.unit, model: e),
    ];
  }

  Future<void> importReadings() async {
    final compatible = store.trials
        .where(
          (t) =>
              t.unit == experiment.unit &&
              t.quantity == experiment.quantity &&
              t.labId != entry.id,
        )
        .toList();
    if (compatible.isEmpty) {
      message(
        'No compatible saved trials. Need ${experiment.quantity} in ${experiment.unit}.',
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import one compatible observation'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              const Text(
                'Select a trial of the same object. SI unit compatibility is checked automatically.',
              ),
              for (final t in compatible)
                ListTile(
                  title: Text(
                    '${entryById(t.labId).title}: ${t.value} ${t.unit}',
                  ),
                  subtitle: Text('Resolution ${t.resolution} ${t.unit}'),
                  onTap: () {
                    experiment.samples = [...experiment.samples, t.value];
                    experiment.resolution = math.max(
                      experiment.resolution,
                      t.resolution ?? 0,
                    );
                    if (t.resolution == null) {
                      experiment.resolutionKnown = false;
                    }
                    experiment.changed();
                    Navigator.pop(ctx);
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget statisticsPanel() {
    final stats = Statistics(
      experiment.samples,
      experiment.resolutionKnown ? experiment.resolution : null,
    );
    String f(double? n) => n == null ? 'Unavailable' : n.toStringAsPrecision(6);
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Current dataset'),
          const SizedBox(height: 12),
          Text(
            'Mean: ${f(stats.mean)} ${experiment.unit}\nSample SD: ${f(stats.sd)}\nStandard error: ${f(stats.sem)}\nInstrument uᵢ = q/√12: ${f(stats.instrument)}\nCombined u꜀: ${f(stats.combined)}\nPercentage uncertainty: ${stats.percent == null ? 'Undefined' : f(stats.percent)} %',
          ),
          const SizedBox(height: 12),
          Text(
            stats.mean == null
                ? 'No data. Add a reading.'
                : stats.sem == null
                ? 'One reading: no sample SD or standard error estimate. Add independent readings.'
                : stats.combined == null
                ? 'Set instrument resolution to estimate combined uncertainty.'
                : 'Report (k = 1): ${uncertaintyRounded(stats.mean!, stats.combined!)} ${experiment.unit}. Spread and uncertainty of the mean describe different properties.',
          ),
          const SizedBox(height: 8),
          const Text(
            'Two significant digits are retained in the reported uncertainty. Resolution is a rounding interval; no calibration uncertainty was supplied.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class NumericInputDialog extends StatefulWidget {
  final String label;
  final double initial, min, max;
  final ValueChanged<double> onApply;
  const NumericInputDialog({
    super.key,
    required this.label,
    required this.initial,
    required this.min,
    required this.max,
    required this.onApply,
  });
  @override
  State<NumericInputDialog> createState() => _NumericInputState();
}

class _NumericInputState extends State<NumericInputDialog> {
  late final TextEditingController controller;
  String? error;
  @override
  void initState() {
    super.initState();
    controller = TextEditingController(
      text: widget.initial.toStringAsPrecision(8),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.label),
    content: TextField(
      autofocus: true,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      decoration: InputDecoration(
        helperText: 'Range ${widget.min} to ${widget.max}',
        errorText: error,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          final v = double.tryParse(controller.text);
          if (v == null || !v.isFinite || v < widget.min || v > widget.max) {
            setState(
              () => error = 'Enter a finite number in the stated range.',
            );
            return;
          }
          FocusScope.of(context).unfocus();
          widget.onApply(v);
          Navigator.pop(context);
        },
        child: const Text('Apply'),
      ),
    ],
  );
}

class PropagationCalculator extends StatefulWidget {
  final String unit;
  final Experiment model;
  const PropagationCalculator({
    super.key,
    required this.unit,
    required this.model,
  });
  @override
  State<PropagationCalculator> createState() => _PropagationState();
}

class _PropagationState extends State<PropagationCalculator> {
  late final List<TextEditingController> inputs;
  String op = '+',
      output = 'Enter two values and their standard uncertainties.';
  @override
  void initState() {
    super.initState();
    inputs = List.generate(
      4,
      (i) => TextEditingController(text: widget.model.propagationInputs[i]),
    );
    op = widget.model.propagationOp;
    output = widget.model.propagationOutput;
  }

  @override
  void dispose() {
    for (final c in inputs) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Paragraph(
        'Independent-input propagation',
        'First-order propagation assumes independent inputs and small standard uncertainties. Sums/differences require the same unit; products and quotients have derived units.',
      ),
      for (int i = 0; i < 4; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: inputs[i],
            onChanged: (v) => widget.model.propagationInputs[i] = v,
            keyboardType: const TextInputType.numberWithOptions(
              signed: true,
              decimal: true,
            ),
            decoration: InputDecoration(
              labelText: [
                'Input a (${widget.unit})',
                'Standard uncertainty u(a)',
                'Input b (${widget.unit})',
                'Standard uncertainty u(b)',
              ][i],
            ),
          ),
        ),
      DropdownButton<String>(
        value: op,
        items: [
          '+',
          '−',
          '×',
          '÷',
        ].map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
        onChanged: (v) => setState(() {
          op = v!;
          widget.model.propagationOp = op;
        }),
      ),
      FilledButton(
        onPressed: () {
          try {
            final x = inputs.map((c) => double.parse(c.text)).toList();
            final r = propagate(x[0], x[1], x[2], x[3], op);
            setState(
              () => output =
                  '${uncertaintyRounded(r.value, r.uncertainty)} ${op == '×'
                      ? '${widget.unit}²'
                      : op == '÷'
                      ? '(dimensionless)'
                      : widget.unit} (k = 1)',
            );
          } catch (_) {
            setState(
              () => output = 'Enter finite numbers, nonnegative uncertainties and a nonzero denominator.',
            );
          }
          widget.model.propagationOutput = output;
        },
        child: const Text('Propagate uncertainty'),
      ),
      const SizedBox(height: 12),
      Text(output),
    ],
  );
}

String theoryFor(Entry e) =>
    '${e.principle} This introductory model isolates the relationship expressed in the formula. Define a system, choose a reference and identify the variables before applying it. ${assumptions[e.studioIndex]} Compare the predicted trend with limiting cases: a vanishing input, a doubled input, and the stated valid regime. The equation is a model under these assumptions, rather than a universal description of every physical situation.';
const assumptions = [
  'These are introductory navigation and learning aids; advanced mapping, comparison and assessment tools are planned for later phases.',
  'Idealized instruments use SI model coordinates and exact defined dimensions. Readout resolution is distinct from accuracy.',
  'Use an inertial frame, ideal rigid bodies and massless ropes where specified. A free-body diagram includes forces acting on the selected body only.',
  'Use classical kinematics in an inertial frame. Constant-acceleration formulas require constant acceleration; projectile models neglect air drag.',
  'Newtonian mechanics applies to constant-mass bodies at nonrelativistic speeds in inertial frames. Contact forces depend on the physical constraints.',
  'Work and energy refer to a chosen system. Mechanical energy alone is conserved only when nonconservative work is absent; efficiency is dimensionless.',
  'Point-mass or spherically symmetric Newtonian gravity is assumed outside the source. G is the gravitational constant; M is source mass and r is centre separation.',
  'Linear restoring forces and small displacements are assumed. Pendulum periods require small angles; damping and driving modify the simple harmonic solution.',
  'Linear waves superpose when the medium response is linear. Boundary conditions determine standing modes. Doppler sound formulas use speeds relative to the medium.',
  'Geometrical rays assume wavelengths small relative to apparatus; lens and mirror equations use the real-is-positive convention and paraxial rays. Interference requires coherence.',
  'Electrostatics uses stationary point charges or idealized distributions in vacuum unless stated. Ohmic circuits use constant resistance; ideal capacitors exclude leakage.',
  'Classical fields and ideal geometries are assumed. Wire and solenoid estimates require long geometries; magnetic force is perpendicular to velocity.',
  'Equations are introductory idealizations of specified operating regions. Real components require device parameters, temperature data and safe circuit limits.',
  'Use absolute temperature in kelvin. Equilibrium states, ideal gases or reversible limits are assumed where indicated. W is work done by the system.',
  'Continuity and Bernoulli assume steady incompressible flow; Bernoulli also neglects viscosity along a streamline. Newtonian viscosity is a constitutive approximation.',
  'Quantum and nuclear pictures are models. Symbols h, f and p denote Planck constant, frequency and momentum. Decay equations describe ensemble expectations.',
  'Celestial illustrations are not to scale. Orbital formulas use ideal two-body gravity; transit depth ignores limb darkening; Hubble linearity is a low-redshift approximation.',
];
