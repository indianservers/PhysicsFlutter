import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart';
import '../../core/design_system/theme.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/comparisons.dart';
import '../../core/physics/dynamics.dart' show FixedClock;
import '../../core/rendering/materials.dart';
import '../../core/rendering/scientific_text.dart';
import '../advanced/scene.dart' show LabPlot;
import 'comparison_curriculum.dart';
export 'comparison_curriculum.dart' show comparisonControls;
import '../dynamics/workspace.dart' show dynamicsRouteObserver;
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import '../fluid_modern/workspace.dart' show fmNumber;

class CompareWorkspace extends ConsumerStatefulWidget {
  const CompareWorkspace({super.key});
  @override
  ConsumerState<CompareWorkspace> createState() => CompareWorkspaceState();
}

class CompareWorkspaceState extends ConsumerState<CompareWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late LocalNotebook store;
  late Ticker ticker;
  late ComparisonModel model;
  int pair = 0;
  double coordinate = 0;
  bool ready = false, changed = false, saved = false;
  String notice = '';
  final p = <String, double>{
        for (final list in comparisonControls)
          for (final control in list) control.key: control.initial,
      },
      notes = TextEditingController(),
      clock = FixedClock(),
      tick = ValueNotifier(0),
      explored = <int>{};
  Duration previous = Duration.zero;
  @override
  void initState() {
    super.initState();
    store = ref.read(notebookProvider);
    model = ComparisonModel(pair, p);
    ticker = createTicker(onFrame);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  Future<void> load() async {
    final data = await store.readSession('s00-e04');
    if (data != null && !restore(data)) {
      notice = 'Older comparison state retained; current defaults shown.';
    }
    await store.visit('s00-e04');
    if (mounted) setState(() => ready = true);
  }

  Map<String, dynamic> configuration() => {
    'model': comparisonVersion,
    'sourceModels': [
      'energy-gravity-oscillation-3.0',
      'waves-optics-4.0',
      'electromagnetism-5.0',
      'electronics-thermal-6.0',
      'fluid-modern-7.0',
    ],
    'pair': pair,
    'parameters': Map.of(p),
    'parameterUnits': {
      for (final list in comparisonControls)
        for (final c in list) c.key: c.unit,
    },
    'coordinate': coordinate,
    'convention': comparisonConventions[pair],
    'notes': notes.text,
    'changed': changed,
    'explored': explored.toList(),
    'leftUnit': model.units[0],
    'rightUnit': model.units[1],
    'values': Map.of(model.values),
    'valueUnits': {
      for (final key in model.values.keys) key: model.valueUnit(key),
    },
    'seed': p['seed'],
    'sampling': 'xorshift32-grid-cdf-1',
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (data['model'] != comparisonVersion) return false;
      final next = (data['pair'] as num).toInt();
      if (next < 0 || next > 4) return false;
      for (final list in comparisonControls) {
        for (final c in list) {
          final x = (data['parameters'][c.key] as num).toDouble();
          if (!x.isFinite || x < c.min || x > c.max) return false;
        }
      }
      pair = next;
      for (final key in p.keys) {
        p[key] = (data['parameters'][key] as num).toDouble();
      }
      coordinate = (data['coordinate'] as num).toDouble();
      if (coordinate < 0 || coordinate > 20) return false;
      model = ComparisonModel(pair, p)..at(coordinate);
      notes.text = data['notes'] as String? ?? '';
      changed = data['changed'] == true;
      explored
        ..clear()
        ..addAll(
          (data['explored'] as List? ?? []).cast<int>().where(
            (i) => i >= 0 && i < 5,
          ),
        );
      saved = true;
      return true;
    } catch (_) {
      return false;
    }
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
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      pause();
      persist();
    }
  }

  Future<void> persist() async {
    if (ready) await store.saveSession('s00-e04', configuration());
  }

  void pause() {
    ticker.stop();
    clock.pause();
    if (mounted) setState(() {});
  }

  void play() {
    if (coordinate >= 20) coordinate = 0;
    previous = Duration.zero;
    clock.pause();
    ticker.start();
    setState(() {});
  }

  void onFrame(Duration elapsed) {
    clock.advance((elapsed - previous).inMicroseconds / 1e6, () {
      coordinate = math.min(20, coordinate + 1 / 120);
    });
    previous = elapsed;
    model.at(coordinate);
    if (coordinate > 0) explored.add(pair);
    if (!store.reducedMotion || (coordinate * 120).round() % 24 == 0) {
      tick.value++;
    }
    if (coordinate >= 20) pause();
  }

  void update(String key, double value) {
    pause();
    p[key] = key == 'seed' ? value.roundToDouble() : value;
    changed = true;
    saved = false;
    model = ComparisonModel(pair, p)..at(coordinate);
    tick.value++;
    setState(() {});
  }

  void choose(int value) {
    pause();
    pair = value;
    coordinate = 0;
    model = ComparisonModel(pair, p);
    tick.value++;
    setState(() {});
  }

  Future<void> save() async {
    pause();
    try {
      await persist();
      saved = true;
      notice = 'Comparison configuration, source versions and notes saved.';
    } catch (_) {
      notice = 'Save failed; previous record retained.';
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    dynamicsRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    ticker.dispose();
    persist();
    notes.dispose();
    tick.dispose();
    super.dispose();
  }

  Widget pane(int side) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        side == 0
            ? comparisonNames[pair].split(' / ').first
            : comparisonNames[pair].split(' / ').last,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      AspectRatio(
        aspectRatio: 1.7,
        child: RepaintBoundary(
          child: CustomPaint(painter: ComparisonPainter(model, side)),
        ),
      ),
      Text('Units: ${model.units[side]}; ${model.xLabels[side]}'),
      Semantics(
        label:
            '${side == 0 ? 'Left' : 'Right'} calculated comparison graph, ${model.units[side]} versus ${model.xLabels[side]}',
        child: SizedBox(
          height: 230,
          child: InteractiveViewer(
            minScale: .5,
            maxScale: 4,
            child: CustomPaint(
              painter: LabPlot(
                side == 0 ? model.left : model.right,
                side == 0
                    ? model.left.first.keys.where((k) => k != 't').toList()
                    : model.right.first.keys.where((k) => k != 't').toList(),
                model.xLabels[side],
                model.units[side],
                0,
                histogramKeys: pair == 4 && side == 1 ? {'observed'} : {},
              ),
              size: const Size(double.infinity, 230),
            ),
          ),
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Compare Phenomena'),
      actions: [
        IconButton(
          onPressed: save,
          tooltip: 'Save comparison',
          icon: const Icon(Icons.bookmark_add_outlined),
        ),
      ],
    ),
    body: !ready
        ? const Center(child: CircularProgressIndicator())
        : PageBody(
            scrollId: 'overview:comparison',
            children: [
              const Eyebrow('Phase 8 · Five bounded comparisons'),
              DropdownButtonFormField<int>(
                key: ValueKey(pair),
                initialValue: pair,
                isExpanded: true,
                items: [
                  for (int i = 0; i < 5; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(
                        comparisonNames[i],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) {
                  if (v != null) choose(v);
                },
              ),
              Paragraph(
                'What is comparable / synchronization',
                comparisonConventions[pair],
              ),
              Paragraph('Where the analogy fails', comparisonLimits[pair]),
              ListenableBuilder(
                listenable: tick,
                builder: (c, _) => LayoutBuilder(
                  builder: (c, b) => b.maxWidth >= 760
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: pane(0)),
                            const SizedBox(width: 24),
                            Expanded(child: pane(1)),
                          ],
                        )
                      : Column(
                          children: [
                            pane(0),
                            const SizedBox(height: 24),
                            pane(1),
                          ],
                        ),
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    onPressed: ticker.isActive ? pause : play,
                    child: Text(ticker.isActive ? 'Pause' : 'Play'),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      pause();
                      coordinate = 0;
                      model.at(0);
                      tick.value++;
                    },
                    child: const Text('Reset coordinate'),
                  ),
                ],
              ),
              Slider(
                key: const Key('comparison-coordinate'),
                value: coordinate,
                min: 0,
                max: 20,
                label: 'Comparison coordinate $coordinate',
                onChanged: (x) {
                  pause();
                  coordinate = x;
                  model.at(x);
                  if (x > 0) explored.add(pair);
                  tick.value++;
                  setState(() {});
                },
              ),
              ListenableBuilder(
                listenable: tick,
                builder: (c, _) => Text(
                  'Actual calculated values: ${model.values.entries.map((e) => '${e.key}=${fmNumber(e.value)} ${model.valueUnit(e.key)}').join('; ')}',
                ),
              ),
              for (final control in comparisonControls[pair])
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${control.label}: ${fmNumber(p[control.key])} ${control.unit}',
                      ),
                      Slider(
                        value: p[control.key]!,
                        min: control.min,
                        max: control.max,
                        onChanged: (v) => update(control.key, v),
                      ),
                      OutlinedButton(
                        key: Key('edit-${control.key}'),
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => NumericInputDialog(
                            label: control.label,
                            initial: p[control.key]!,
                            min: control.min,
                            max: control.max,
                            onApply: (v) => update(control.key, v),
                          ),
                        ),
                        child: const Text('Enter precise value'),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: notes,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comparison notes',
                ),
                onChanged: (_) => setState(() {
                  saved = false;
                }),
              ),
              FilledButton(
                onPressed: save,
                child: const Text('Save comparison configuration'),
              ),
              Text(notice),
              Text(
                '${explored.length}/5 comparisons explored beyond initial state. Completion requires all five, a scientific edit and saved explanatory notes.',
              ),
              FilledButton(
                onPressed:
                    explored.length == 5 &&
                        changed &&
                        saved &&
                        notes.text.trim().isNotEmpty
                    ? () async {
                        await store.complete('s00-e04');
                        if (mounted) setState(() {});
                      }
                    : null,
                child: const Text('Complete comparison activity'),
              ),
              for (final id in comparisonLabs[pair])
                TextButton(
                  onPressed: () => context.push('/lab/$id'),
                  child: Text('Open source lab $id'),
                ),
            ],
          ),
  );
}

class ComparisonPainter extends CustomPainter {
  final ComparisonModel model;
  final int side;
  ComparisonPainter(this.model, this.side);
  void text(Canvas c, String s, Offset p) =>
      ScientificText.paint(c, s, p, color: const Color(0xff173652), font: 10);
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 360, size.height / 210);
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 210),
      Paint()..color = const Color(0xfff0f5f7),
    );
    LabMaterials.wood(c, const Rect.fromLTWH(0, 184, 360, 26));
    final s = model.values;
    switch (model.pair) {
      case 0:
        if (side == 0) {
          final x = 180 + s['springPosition']! * 350;
          LabMaterials.metal(c, const Rect.fromLTWH(35, 91, 8, 65));
          final spring = Path()..moveTo(43, 119);
          for (int i = 0; i < 20; i++) {
            spring.lineTo(43 + (x - 65) * i / 19, 119 + (i.isEven ? 8 : -8));
          }
          c.drawPath(
            spring,
            Paint()
              ..color = Colors.blueGrey
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          LabMaterials.metal(c, Rect.fromLTWH(x, 104, 30, 30));
          text(c, 'x ${fmNumber(s['springPosition'])} m', const Offset(12, 20));
        } else {
          const pivot = Offset(180, 35);
          final theta = s['pendulumAngle']!,
              end =
                  pivot + Offset(125 * math.sin(theta), 125 * math.cos(theta));
          c.drawLine(
            pivot,
            end,
            Paint()
              ..color = Colors.blueGrey
              ..strokeWidth = 2,
          );
          LabMaterials.metal(c, const Rect.fromLTWH(111, 25, 138, 8));
          LabMaterials.sphere(c, end, 13, Colors.amber);
          text(c, 'θ ${fmNumber(theta)} rad', const Offset(12, 20));
        }
      case 1:
        LabMaterials.sphere(
          c,
          const Offset(90, 110),
          24,
          side == 0 ? Colors.blue : Colors.amber,
        );
        final radius = s['fieldRadius']!;
        c.drawLine(
          const Offset(90, 110),
          Offset(100 + radius * 18, 110),
          Paint()
            ..color = Colors.teal
            ..strokeWidth = 2,
        );
        text(
          c,
          side == 0
              ? 'E ${fmNumber(s['electricField'])} N/C'
              : 'g ${fmNumber(s['gravityField'])} m/s²',
          const Offset(12, 20),
        );
        text(c, 'Exterior radius ${fmNumber(radius)} m', const Offset(12, 160));
      case 2:
        final amplitude = side == 0
                ? s['waveEnvelope']! / .4
                : s['opticalIntensity']!,
            path = Path();
        for (int i = 0; i <= 160; i++) {
          final x = 35 + 290 * i / 160,
              y =
                  110 -
                  amplitude *
                      55 *
                      (side == 0 ? math.sin(i / 160 * 4 * math.pi) : 1);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        c.drawPath(
          path,
          Paint()
            ..color = side == 0 ? Colors.blue : Colors.teal
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        text(
          c,
          side == 0 ? 'Amplitude envelope in m' : 'Coherent intensity fraction',
          const Offset(12, 20),
        );
        text(c, 'Phase ${fmNumber(s['phase'])} rad', const Offset(12, 160));
      case 3:
        if (side == 0) {
          LabMaterials.metal(c, const Rect.fromLTWH(137, 64, 9, 89));
          LabMaterials.metal(c, const Rect.fromLTWH(180, 64, 9, 89));
          c.drawRect(
            const Rect.fromLTWH(147, 66, 32, 85),
            Paint()
              ..color = Colors.blue.withValues(
                alpha: s['normalizedCharge']! * .35,
              ),
          );
          text(c, 'V ${fmNumber(s['voltage'])} V', const Offset(12, 20));
        } else {
          c.drawRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(120, 65, 100, 100),
              const Radius.circular(8),
            ),
            Paint()..color = Colors.lightBlue.withValues(alpha: .25),
          );
          LabMaterials.metal(c, const Rect.fromLTWH(165, 45, 5, 106));
          text(c, 'T ${fmNumber(s['temperature'])} K', const Offset(12, 20));
        }
        text(
          c,
          'Physical t ${fmNumber(s[side == 0 ? 'rcTime' : 'thermalTime'])} s',
          const Offset(12, 164),
        );
      case 4:
        if (side == 0) {
          final x = 35 + s['classicalPosition']! / 40 * 290;
          LabMaterials.metal(c, Rect.fromLTWH(x, 119, 25, 25));
          c.drawLine(
            const Offset(30, 146),
            const Offset(330, 146),
            Paint()..color = Colors.blueGrey,
          );
          text(
            c,
            'Classical x ${fmNumber(s['classicalPosition'])} m',
            const Offset(12, 20),
          );
        } else {
          for (final row in model.right) {
            final h = (row['observed'] ?? row['expected']!) / 6000 * 90,
                x = 35 + (row['t']! + .002) / .004 * 290;
            c.drawRect(
              Rect.fromLTWH(x, 145 - h, 3, h),
              Paint()..color = Colors.teal,
            );
          }
          text(
            c,
            '${s['detections']!.round()} seeded independent detections',
            const Offset(12, 20),
          );
          text(c, 'Probability density, not paths', const Offset(12, 163));
        }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant ComparisonPainter old) => true;
}
