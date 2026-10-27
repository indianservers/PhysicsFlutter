import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/physics/electromagnetism.dart';
import '../../core/physics/waves_optics.dart' show harmonic;
import 'instrument_types.dart';

const focusLabs = <String, String>{
  's04-e01': 'Predict the acceleration',
  's05-e03': 'Energy replay',
  's10-e04': 'Circuit path debugger',
  's08-e00': 'Two wave probes',
  's09-e02': 'Build the principal rays',
  's13-e01': 'Temperature explorer',
  's11-e04': 'Move the magnetic source',
  's14-e02': 'Predict the waterline',
  's01-e01': 'Find the matching graduation',
  's15-e01': 'Six-trial threshold hunt',
};

/// Ephemeral learning evidence only. The owning workspace remains the sole
/// simulation engine. No trial, mastery, notebook or preferences are modified.
class FocusLabSession extends ChangeNotifier {
  final String id;
  final List<InstrumentControl> Function() controls;
  final List<InstrumentReading> Function() readings;
  final Map<String, dynamic> Function() configuration;
  final bool Function(Map<String, dynamic>) restore;
  final bool Function() valid;
  final VoidCallback pause, play;
  final Listenable source;
  bool recording = false, revealed = false;
  final frames = <Map<String, double>>[];
  final trials = <Map<String, double>>[];
  int frame = 0, graduation = 0;
  double prediction = 0, predictionY = 0, probeA = .3, probeB = .9;
  double rayParallel = 0, rayCentral = 0;
  bool parallelSelected = true;
  double replayRadius = 2;
  double? crestStart, crestOrigin;
  String? signature;
  String feedback = '';
  String? terminal;
  List<String> tracedPath = [];
  Map<String, dynamic>? circuitUndo;
  FocusLabSession({
    required this.id,
    required this.controls,
    required this.readings,
    required this.configuration,
    required this.restore,
    required this.valid,
    required this.pause,
    required this.play,
    required this.source,
  }) {
    source.addListener(sample);
  }
  InstrumentControl? control(String key) =>
      controls().where((c) => c.keyName == key).firstOrNull;
  double? value(String key) {
    final v = readings().where((r) => r.label == key).firstOrNull;
    final n = v == null ? null : double.tryParse(v.value);
    return n != null && n.isFinite ? n : null;
  }

  double input(String key) => control(key)?.value ?? double.nan;
  Map<String, double> get values => {
    for (final r in readings())
      if (double.tryParse(r.value) case final double n when n.isFinite)
        r.label: n,
  };
  String get setupSignature =>
      '${configuration()['mode']}|${controls().map((c) => '${c.keyName}:${c.value}').join('|')}';
  bool get stale => signature != null && signature != setupSignature;
  void update(VoidCallback action) {
    action();
    notifyListeners();
  }

  bool change(String key, double value) {
    final c = control(key);
    if (c == null || !value.isFinite || value < c.min || value > c.max) {
      return false;
    }
    pause();
    c.change(value);
    notifyListeners();
    return true;
  }

  void sample() {
    if (!recording || id != 's05-e03') return;
    if (stale || !valid()) {
      recording = false;
      feedback = 'Recording stopped: setup changed or model is unavailable.';
      return;
    }
    final v = values;
    if (!['t', 'x', 'y', 'K', 'U', 'loss'].every(v.containsKey)) return;
    if (frames.isNotEmpty && v['t']! <= frames.last['t']!) return;
    frames.add(Map.unmodifiable(v));
    frame = frames.length - 1;
    if (frames.length >= 600) {
      recording = false;
      feedback =
          '600 source frames captured. Pause the apparatus to inspect them.';
    }
  }

  void startReplay() {
    pause();
    if (!valid()) {
      feedback = 'Complete the apparatus setup before recording.';
      notifyListeners();
      return;
    }
    frames.clear();
    replayRadius = input('radius');
    signature = setupSignature;
    recording = true;
    feedback = '';
    sample();
    play();
    notifyListeners();
  }

  void stopReplay() {
    pause();
    recording = false;
    notifyListeners();
  }

  void reveal() {
    pause();
    if (!valid()) {
      feedback = 'Complete the apparatus setup first.';
      notifyListeners();
      return;
    }
    signature = setupSignature;
    revealed = true;
    if (id == 's04-e01') {
      final ax = value('ax'), ay = value('ay');
      feedback = ax == null || ay == null
          ? 'Acceleration unavailable.'
          : 'Vector discrepancy ${number(math.sqrt(math.pow(prediction - ax, 2) + math.pow(predictionY - ay, 2)))} m/s². Net force sets acceleration; velocity can point elsewhere.';
    } else if (id == 's14-e02') {
      final f = value('equilibriumFraction');
      feedback = f == null
          ? 'Equilibrium fraction unavailable.'
          : 'Prediction ${(prediction * 100).toStringAsFixed(0)}%; equilibrium ${(f * 100).toStringAsFixed(1)}%; discrepancy ${((prediction - f).abs() * 100).toStringAsFixed(1)} percentage points. ${input('objectDensity') > input('density')
                ? 'The object sinks; the tank bottom supplies support.'
                : input('objectDensity') == input('density')
                ? 'Neutral when fully immersed; depth is not uniquely determined.'
                : 'Displaced liquid weight balances object weight.'}';
    } else if (id == 's01-e01') {
      final fraction = value('fraction');
      if (fraction == null) {
        feedback = 'Reading unavailable.';
      } else {
        final correct = (fraction / .0001).round();
        feedback =
            'Selected $graduation; coincident division $correct. Main ${number(value('main'))} m + $correct × 0.0001 m − zero ${number(value('zero'))} m = ${number(value('length'))} m.';
      }
    } else if (id == 's09-e02') {
      final h = input('height'), u = input('u');
      final f = value('focal');
      feedback = f == null
          ? 'Signed focal length unavailable.'
          : 'Outgoing angle discrepancies: parallel ${(math.atan(-h / f) - rayParallel).abs().toStringAsFixed(4)} rad; central ${(math.atan(-h / u) - rayCentral).abs().toStringAsFixed(4)} rad. ${value('infinity') == 1
                ? 'Parallel outgoing rays: image at infinity.'
                : value('imageDistance') != null && value('imageDistance')! < 0
                ? 'Backward extensions meet at a virtual image.'
                : 'Outgoing rays meet at a real image.'}';
    }
    notifyListeners();
  }

  bool capturePhoto() {
    pause();
    if (trials.length >= 6 || !valid()) return false;
    final row = values;
    if (![
      'wavelength',
      'emitting',
      'photonEnergy',
      'maximumKineticEnergy',
      'current',
    ].every(row.containsKey)) {
      return false;
    }
    final phi = input('workFunction');
    if (trials.isNotEmpty && trials.first['workFunction'] != phi) {
      feedback = 'Work function changed. Start a new hunt so trials describe one surface.';
      notifyListeners();
      return false;
    }
    trials.add({
      ...row,
      'energeticallyAllowed': row['photonEnergy']! >= phi ? 1 : 0,
      'intensity': input('intensity'),
      'workFunction': phi,
    });
    final emit = trials
        .where((r) => r['energeticallyAllowed'] == 1)
        .map((r) => r['wavelength']!)
        .toList();
    final dark = trials
        .where((r) => r['energeticallyAllowed'] == 0)
        .map((r) => r['wavelength']!)
        .toList();
    feedback = emit.isEmpty || dark.isEmpty
        ? 'Try a wavelength on the other side of onset. Intensity changes flux, not the energy threshold. Zero irradiance can give zero current even above threshold.'
        : 'Threshold wavelength bracket: ${number(emit.reduce(math.max) * 1e9)}–${number(dark.reduce(math.min) * 1e9)} nm. Narrow it with another trial. Allowed describes photon energy; actual emission and collected current also depend on irradiance, efficiency and bias.';
    notifyListeners();
    return true;
  }

  CircuitGraph get circuit =>
      CircuitGraph.fromJson(configuration()['circuit'] as Map);
  void trace(String target) {
    final graph = circuit;
    if (terminal == null) {
      terminal = target;
      tracedPath = [target];
      notifyListeners();
      return;
    }
    final start = terminal!;
    terminal = null;
    tracedPath = circuitPath(graph, start, target);
    feedback = tracedPath.isEmpty
        ? 'No conducting path between $start and $target. Open switches and ideal voltmeters do not conduct.'
        : 'Conducting path: ${tracedPath.join(' → ')}. A path alone does not prove a powered loop; check the solver diagnosis.';
    notifyListeners();
  }

  void toggleSwitch(String id) {
    pause();
    final config = configuration();
    final graph = circuit;
    final part = graph.parts.firstWhere((p) => p.id == id);
    circuitUndo = {...config, 'circuit': graph.toJson()};
    part.closed = !part.closed;
    if (!restore({...config, 'circuit': graph.toJson()})) {
      feedback = 'Source rejected this circuit edit.';
    }
    tracedPath = [];
    terminal = null;
    notifyListeners();
  }

  @override
  void dispose() {
    source.removeListener(sample);
    super.dispose();
  }
}

String number(double? n) => n == null || !n.isFinite
    ? 'Unavailable'
    : n == 0
    ? '0'
    : n.abs() < .001 || n.abs() >= 1e5
    ? n.toStringAsExponential(3)
    : n.toStringAsPrecision(4);

/// Terminal connectivity, including sources, excludes ideal voltmeters and open
/// switches. Electrical consistency still comes from the existing MNA solver.
List<String> circuitPath(CircuitGraph graph, String start, String end) {
  final edges = <String, List<String>>{};
  void link(String a, String b) {
    (edges[a] ??= []).add(b);
    (edges[b] ??= []).add(a);
  }

  for (final w in graph.wires) {
    if (w.length == 2) link(w[0], w[1]);
  }
  for (final p in graph.parts) {
    if (p.type != 'voltmeter' && !(p.type == 'switch' && !p.closed)) {
      link(p.a, p.b);
    }
  }
  final queue = <List<String>>[
        [start],
      ],
      seen = <String>{start};
  for (int i = 0; i < queue.length; i++) {
    final path = queue[i];
    if (path.last == end) return path;
    for (final next in edges[path.last] ?? <String>[]) {
      if (seen.add(next)) queue.add([...path, next]);
    }
  }
  return [];
}

class FocusLabPanel extends StatelessWidget {
  final FocusLabSession session;
  final bool Function() playing;
  const FocusLabPanel({
    super.key,
    required this.session,
    required this.playing,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([session, session.source]),
    builder: (context, _) => SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 12),
              const Icon(Icons.touch_app_outlined),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    focusLabs[session.id]!,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close interactive experience',
                onPressed: () {
                  session.stopReplay();
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Use your current setup. Evidence lasts for this lab visit.',
                  ),
                  if (session.stale)
                    const Text(
                      'Setup changed. Previous prediction or replay belongs to the earlier setup. Try again.',
                      style: TextStyle(color: Colors.deepOrange),
                    ),
                  ...body(context),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
  FocusLabSession get s => session;
  Widget evidence() => s.feedback.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Semantics(
            liveRegion: true,
            child: Text(s.feedback, key: const Key('focus-feedback')),
          ),
        );
  Widget button(String label, VoidCallback action) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: OutlinedButton(onPressed: action, child: Text(label)),
  );
  Widget slider(
    String label,
    double v,
    double min,
    double max,
    ValueChanged<double> change, {
    String? text,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('$label: ${text ?? number(v)}'),
      Slider(
        key: ValueKey('focus-$label'),
        label: text ?? number(v),
        value: v.clamp(min, max),
        min: min,
        max: max,
        onChanged: change,
      ),
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => change((v - (max - min) / 100).clamp(min, max)),
            child: Text('Decrease $label'),
          ),
          TextButton(
            onPressed: () => change((v + (max - min) / 100).clamp(min, max)),
            child: Text('Increase $label'),
          ),
        ],
      ),
    ],
  );
  Widget sourceControl(String key, {double scale = 1, String? unit}) {
    final c = s.control(key);
    if (c == null) {
      return const Text(
        'This control is unavailable in the selected model mode. Return to the apparatus to change mode.',
      );
    }
    return slider(
      c.label,
      c.value * scale,
      c.min * scale,
      c.max * scale,
      (v) => s.change(key, v / scale),
      text: '${number(c.value * scale)} ${unit ?? c.unit}',
    );
  }

  Widget run() => button(playing() ? 'Pause model' : 'Run model', () {
    if (playing()) {
      s.pause();
    } else {
      s.play();
    }
    s.update(() {});
  });
  Widget picture(
    void Function(Canvas, Size) paint, {
    ValueChanged<Offset>? drag,
    String label = 'Interactive model view',
  }) => LayoutBuilder(
    builder: (context, constraints) => Semantics(
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: drag == null
            ? null
            : (d) => drag(
                Offset(
                  d.localPosition.dx / constraints.maxWidth,
                  d.localPosition.dy / 200,
                ),
              ),
        onPanDown: drag == null
            ? null
            : (d) => drag(
                Offset(
                  d.localPosition.dx / constraints.maxWidth,
                  d.localPosition.dy / 200,
                ),
              ),
        onPanUpdate: drag == null
            ? null
            : (d) => drag(
                Offset(
                  d.localPosition.dx / constraints.maxWidth,
                  d.localPosition.dy / 200,
                ),
              ),
        child: SizedBox(
          height: 200,
          width: double.infinity,
          child: CustomPaint(painter: _FocusPainter(paint)),
        ),
      ),
    ),
  );
  List<Widget> body(BuildContext context) {
    switch (s.id) {
      case 's04-e01':
        final scale =
            math.max(5.0, math.max(s.prediction.abs(), s.predictionY.abs())) *
            1.2;
        final vectorScale = s.revealed && !s.stale
            ? math.max(
                scale,
                math.max(
                      (s.value('ax') ?? 0).abs(),
                      (s.value('ay') ?? 0).abs(),
                    ) *
                    1.2,
              )
            : scale;
        return [
          Text(
            'Draw your acceleration vector from the centre. +x right, +y up; visible axes ±${number(vectorScale)} m/s² (auto-scaled). Sliders provide the same input.',
          ),
          picture(
            (c, z) {
              axes(c, z);
              arrow(
                c,
                z,
                Offset(
                  s.prediction / vectorScale,
                  -s.predictionY / vectorScale,
                ),
                Colors.orange,
              );
              if (s.revealed && !s.stale) {
                arrow(
                  c,
                  z,
                  Offset(
                    (s.value('ax') ?? 0) / vectorScale,
                    -(s.value('ay') ?? 0) / vectorScale,
                  ),
                  Colors.blue,
                );
              }
            },
            drag: (p) => s.update(() {
              s.prediction = ((p.dx - .5) * 2 * vectorScale).clamp(-100, 100);
              s.predictionY = ((.5 - p.dy) * 2 * vectorScale).clamp(-100, 100);
              s.revealed = false;
            }),
            label: 'Acceleration vectors: orange prediction; blue model after reveal',
          ),
          slider(
            'Predicted ax',
            s.prediction,
            -100,
            100,
            (v) => s.update(() {
              s.prediction = v;
              s.revealed = false;
            }),
          ),
          slider(
            'Predicted ay',
            s.predictionY,
            -100,
            100,
            (v) => s.update(() {
              s.predictionY = v;
              s.revealed = false;
            }),
          ),
          button('Compare with model', s.reveal),
          evidence(),
          if (s.revealed && !s.stale)
            Text(
              'Model ax ${number(s.value('ax'))} m/s² · ay ${number(s.value('ay'))} m/s²',
            ),
          run(),
          sourceControl('force'),
          sourceControl('m'),
        ];
      case 's05-e03':
        final row = s.frames.isEmpty
            ? null
            : s.frames[s.frame.clamp(0, s.frames.length - 1)];
        return [
          const Text(
            'Record a run, pause, then scrub actual captured source frames. Replay does not rewind the apparatus. Up to 600 frames; gaps are not interpolated.',
          ),
          button(
            s.recording ? 'Stop recording' : 'Record a new run',
            s.recording ? s.stopReplay : s.startReplay,
          ),
          evidence(),
          if (row != null) ...[
            Text(
              'Frame ${s.frame + 1}/${s.frames.length} · t=${number(row['t'])} s · x=${number(row['x'])} m · y=${number(row['y'])} m',
            ),
            slider(
              'Replay frame',
              s.frame.toDouble(),
              0,
              math.max(1, s.frames.length - 1).toDouble(),
              (v) => s.update(() {
                s.pause();
                s.recording = false;
                s.frame = v.round().clamp(0, s.frames.length - 1);
              }),
            ),
            picture((c, z) {
              final r = s.replayRadius;
              final p = Path();
              for (int i = 0; i <= 100; i++) {
                final x = -2.5 + i * .05, y = x * x / (2 * r);
                final q = Offset(z.width * (.5 + x / 6), 180 - y * 30);
                if (i == 0) {
                  p.moveTo(q.dx, q.dy);
                } else {
                  p.lineTo(q.dx, q.dy);
                }
              }
              c.drawPath(
                p,
                Paint()
                  ..color = Colors.blueGrey
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              );
              c.drawCircle(
                Offset(z.width * (.5 + row['x']! / 6), 180 - row['y']! * 30),
                8,
                Paint()..color = Colors.blue,
              );
            }),
            for (final key in ['K', 'U', 'loss']) ...[
              Text(
                '${const {'K': 'Kinetic K', 'U': 'Potential U', 'loss': 'Dissipated'}[key]} = ${number(row[key])} J',
              ),
              LinearProgressIndicator(
                color: const {
                  'K': Colors.blue,
                  'U': Colors.green,
                  'loss': Colors.orange,
                }[key],
                value:
                    ((row[key] ?? 0) /
                            math.max(
                              1e-20,
                              (row['K'] ?? 0) +
                                  (row['U'] ?? 0) +
                                  (row['loss'] ?? 0),
                            ))
                        .clamp(0, 1),
              ),
            ],
            Text(
              'K + U + dissipated = ${number((row['K'] ?? 0) + (row['U'] ?? 0) + (row['loss'] ?? 0))} J',
            ),
          ],
          sourceControl('drag'),
        ];
      case 's10-e04':
        final graph = s.circuit, solution = solveCircuit(s.circuit);
        return [
          const Text(
            'Select two terminals to trace connectivity. Blue links show the traced path. Open switches and ideal voltmeters are excluded from conduction. The source solver detects floating nodes and ideal-source conflicts.',
          ),
          Text(
            solution.valid
                ? 'Solver: consistent network. KCL residual ${number(solution.kclResidual)}.'
                : 'Solver: ${solution.message}',
            key: const Key('circuit-diagnosis'),
          ),
          evidence(),
          if (s.terminal != null)
            Text(
              'Start terminal ${s.terminal}; select the destination terminal.',
            ),
          picture((c, z) {
            Offset terminal(String id) {
              final p = graph.parts.firstWhere(
                (p) => p.id == id.split(':').first,
              );
              return Offset(
                (p.x + (id.endsWith(':a') ? -.035 : .035)) * z.width,
                p.y * 170,
              );
            }

            bool traced(String a, String b) {
              for (int i = 1; i < s.tracedPath.length; i++) {
                if ((s.tracedPath[i - 1] == a && s.tracedPath[i] == b) ||
                    (s.tracedPath[i - 1] == b && s.tracedPath[i] == a)) {
                  return true;
                }
              }
              return false;
            }

            for (final w in graph.wires) {
              c.drawLine(
                terminal(w[0]),
                terminal(w[1]),
                Paint()
                  ..color = (traced(w[0], w[1]) ? Colors.blue : Colors.grey)
                  ..strokeWidth = traced(w[0], w[1]) ? 4 : 1,
              );
            }
            for (final p in graph.parts) {
              if (p.type == 'switch' && !p.closed) {
                final a = terminal(p.a), b = terminal(p.b);
                c.drawLine(
                  a,
                  b - const Offset(0, 12),
                  Paint()
                    ..color = Colors.orange
                    ..strokeWidth = 3,
                );
              } else {
                c.drawLine(
                  terminal(p.a),
                  terminal(p.b),
                  Paint()
                    ..color = traced(p.a, p.b) ? Colors.blue : Colors.black
                    ..strokeWidth = 3,
                );
              }
              label(c, Offset(p.x * z.width - 10, p.y * 170 + 8), p.id);
            }
          }),
          for (final p in graph.parts)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${p.id} · ${p.type} · ${solution.valid ? '${number(solution.currents[p.id])} A' : 'No valid current'}',
                    ),
                    Wrap(
                      children: [
                        for (final terminal in [p.a, p.b])
                          TextButton(
                            onPressed: () => s.trace(terminal),
                            child: Text(terminal),
                          ),
                      ],
                    ),
                    if (p.type == 'switch')
                      button(
                        '${p.closed ? 'Open' : 'Close'} ${p.id}',
                        () => s.toggleSwitch(p.id),
                      ),
                  ],
                ),
              ),
            ),
          if (s.circuitUndo != null)
            button('Undo switch edit', () {
              s.restore(s.circuitUndo!);
              s.update(() {
                s.circuitUndo = null;
                s.tracedPath = [];
              });
            }),
        ];
      case 's08-e00':
        final a = s.input('amplitude'),
            f = s.input('frequency'),
            w = s.input('wavelength'),
            phase = s.input('phase'),
            t = s.value('t') ?? 0,
            direction = s.configuration()['mode'] == 0 ? 1 : -1;
        double y(double x, double time) =>
            harmonic(x, time, a, f, w, phase, direction);
        final travel = direction * (s.probeB - s.probeA) / (f * w);
        return [
          const Text(
            'Drag either probe along the 2 m wave view. Orange A and blue B sample the same harmonic model. The traces below cover one period ending at the current model time.',
          ),
          picture(
            (c, z) {
              final p = Path();
              for (int i = 0; i <= 200; i++) {
                final q = Offset(z.width * i / 200, 100 - y(i / 100, t) * 1800);
                if (i == 0) {
                  p.moveTo(q.dx, q.dy);
                } else {
                  p.lineTo(q.dx, q.dy);
                }
              }
              c.drawPath(
                p,
                Paint()
                  ..color = Colors.indigo
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              );
              for (final item in [
                (s.probeA, Colors.orange),
                (s.probeB, Colors.blue),
              ]) {
                final x = item.$1 / 2 * z.width;
                c.drawLine(
                  Offset(x, 15),
                  Offset(x, 185),
                  Paint()..color = item.$2,
                );
                c.drawCircle(
                  Offset(x, 100 - y(item.$1, t) * 1800),
                  5,
                  Paint()..color = item.$2,
                );
              }
              if (s.crestStart != null && !s.stale) {
                final x = s.probeA + direction * f * w * (t - s.crestStart!);
                if (x >= 0 && x <= 2) {
                  c.drawCircle(
                    Offset(x / 2 * z.width, 100 - a * 1800),
                    8,
                    Paint()..color = Colors.green,
                  );
                  label(c, Offset(x / 2 * z.width, 15), 'marked crest');
                }
              }
            },
            drag: (p) => s.update(() {
              final x = (p.dx * 2).clamp(0, 2).toDouble();
              if ((x - s.probeA).abs() < (x - s.probeB).abs()) {
                s.probeA = x;
              } else {
                s.probeB = x;
              }
              s.crestStart = null;
            }),
          ),
          slider(
            'Probe A position / m',
            s.probeA,
            0,
            2,
            (v) => s.update(() {
              s.probeA = v;
              s.crestStart = null;
            }),
          ),
          slider(
            'Probe B position / m',
            s.probeB,
            0,
            2,
            (v) => s.update(() {
              s.probeB = v;
              s.crestStart = null;
            }),
          ),
          Text(
            'A ${number(y(s.probeA, t))} m · B ${number(y(s.probeB, t))} m · speed ${number(f * w)} m/s',
          ),
          picture((c, z) {
            for (final item in [
              (s.probeA, Colors.orange),
              (s.probeB, Colors.blue),
            ]) {
              final p = Path();
              for (int i = 0; i <= 160; i++) {
                final q = Offset(
                  i / 160 * z.width,
                  100 - y(item.$1, t - 1 / f + i / 160 / f) * 1800,
                );
                if (i == 0) {
                  p.moveTo(q.dx, q.dy);
                } else {
                  p.lineTo(q.dx, q.dy);
                }
              }
              c.drawPath(
                p,
                Paint()
                  ..color = item.$2
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 2,
              );
            }
            label(c, const Offset(4, 4), '−1 period → now · displacement / m');
          }),
          if (a == 0)
            const Text(
              'Zero amplitude: there is no visible crest. Increase amplitude before marking one.',
            ),
          if (a > 0)
            button(
              'Mark next crest at A',
              () => s.update(() {
                final raw =
                    (s.probeA / w -
                    direction * f * t +
                    phase / (2 * math.pi) -
                    .25);
                final n = direction == 1 ? raw.floor() : raw.ceil();
                s.crestStart =
                    (s.probeA / w + phase / (2 * math.pi) - .25 - n) /
                    (direction * f);
                s.crestOrigin = t;
                s.signature = s.setupSignature;
              }),
            ),
          if (s.crestStart != null)
            Text(
              s.stale
                  ? 'Wave setup changed; mark a new crest.'
                  : travel < 0
                  ? 'B is upstream. Swap probe positions to time the same crest downstream.'
                  : 'Marked crest arrives at A at ${number(s.crestStart)} s and B at ${number(s.crestStart! + travel)} s. Transit ${number(travel)} s; elapsed since marking ${number(t - s.crestOrigin!)} s.',
            ),
          run(),
          sourceControl('frequency'),
          sourceControl('wavelength'),
          sourceControl('amplitude'),
        ];
      case 's09-e02':
        final u = s.input('u'),
            h = s.input('height'),
            f = s.value('focal') ?? s.input('focal');
        return [
          const Text(
            'Construct two outgoing rays: the parallel incident ray leaves from lens height h; the central ray leaves the optical centre. Select a ray, then drag its endpoint height, or set its outgoing angle. Orange is your construction; blue is the model after reveal. Dashed lines are virtual backward extensions.',
          ),
          Wrap(
            children: [
              ChoiceChip(
                label: const Text('Parallel ray'),
                selected: s.parallelSelected,
                onSelected: (_) => s.update(() => s.parallelSelected = true),
              ),
              ChoiceChip(
                label: const Text('Central ray'),
                selected: !s.parallelSelected,
                onSelected: (_) => s.update(() => s.parallelSelected = false),
              ),
            ],
          ),
          picture(
            (c, z) {
              final sx = z.width / (2 * math.max(u, .35)),
                  sy = 2500.0,
                  origin = Offset(z.width / 2, 100);
              Offset q(double x, double y) => origin + Offset(x * sx, -y * sy);
              c.drawLine(q(-u, 0), q(.35, 0), Paint()..color = Colors.grey);
              c.drawLine(
                q(0, .025),
                q(0, -.025),
                Paint()
                  ..color = Colors.blueGrey
                  ..strokeWidth = 3,
              );
              c.drawLine(q(-u, h), q(0, h), Paint()..color = Colors.black);
              c.drawLine(q(-u, h), q(0, 0), Paint()..color = Colors.black);
              for (final item in [
                (h, s.rayParallel, math.atan(-h / f)),
                (0.0, s.rayCentral, math.atan(-h / u)),
              ]) {
                c.drawLine(
                  q(0, item.$1),
                  q(.35, item.$1 + .35 * math.tan(item.$2)),
                  Paint()
                    ..color = Colors.orange
                    ..strokeWidth = 2,
                );
                if (s.revealed && !s.stale) {
                  c.drawLine(
                    q(0, item.$1),
                    q(.35, item.$1 + .35 * math.tan(item.$3)),
                    Paint()
                      ..color = Colors.blue
                      ..strokeWidth = 1,
                  );
                  if ((s.value('imageDistance') ?? 0) < 0) {
                    dashed(
                      c,
                      q(0, item.$1),
                      q(-u, item.$1 - u * math.tan(item.$3)),
                      Colors.blue,
                    );
                  }
                }
              }
              label(
                c,
                const Offset(4, 4),
                'Optical axis / m · vertical ×${number(sy / sx)}',
              );
            },
            drag: (p) => s.update(() {
              final height = (100 - p.dy * 200) / 2500;
              final angle = math.atan(
                (height - (s.parallelSelected ? h : 0)) / .35,
              );
              if (s.parallelSelected) {
                s.rayParallel = angle;
              } else {
                s.rayCentral = angle;
              }
              s.revealed = false;
            }),
          ),
          slider(
            'Parallel ray angle / rad',
            s.rayParallel,
            -.5,
            .5,
            (v) => s.update(() {
              s.rayParallel = v;
              s.revealed = false;
            }),
          ),
          slider(
            'Central ray angle / rad',
            s.rayCentral,
            -.5,
            .5,
            (v) => s.update(() {
              s.rayCentral = v;
              s.revealed = false;
            }),
          ),
          button('Reveal model rays', s.reveal),
          evidence(),
          if (s.revealed && !s.stale)
            Text(
              'Image distance ${number(s.value('imageDistance'))} m · magnification ${number(s.value('magnification'))}. Blue backward extensions are virtual. Drawing window is limited; numeric image distance is not clipped.',
            ),
          sourceControl('u'),
          sourceControl('focal'),
        ];
      case 's13-e01':
        final probe = s.control('probe'),
            left = s.control('leftT'),
            right = s.control('rightT'),
            length = s.control('length');
        if (probe == null || left == null || right == null || length == null) {
          return [
            const Text(
              'Select steady conduction in the apparatus to explore position along the rod. Cooling and radiation have no spatial rod probe.',
            ),
          ];
        }
        return [
          const Text(
            'Drag the probe along the rod. This is the source model’s steady linear conduction profile, not a transient heating animation.',
          ),
          picture((c, z) {
            final rect = Rect.fromLTWH(0, 65, z.width, 50);
            c.drawRect(
              rect,
              Paint()
                ..shader = LinearGradient(
                  colors: left.value >= right.value
                      ? [Colors.red, Colors.blue]
                      : [Colors.blue, Colors.red],
                ).createShader(rect),
            );
            c.drawLine(
              Offset(probe.value * z.width, 40),
              Offset(probe.value * z.width, 145),
              Paint()
                ..color = Colors.black
                ..strokeWidth = 3,
            );
            label(
              c,
              const Offset(5, 160),
              '${number(left.value)} K → ${number(right.value)} K',
            );
          }, drag: (p) => s.change('probe', p.dx.clamp(0, 1))),
          sourceControl('probe'),
          Text(
            'x = ${number(probe.value * length.value)} m · T = ${number(s.value('probeTemperature'))} K',
          ),
          picture((c, z) {
            final min = math.min(left.value, right.value) - 1,
                max = math.max(left.value, right.value) + 1;
            Offset q(double x, double t) => Offset(
              20 + x * (z.width - 40),
              175 - (t - min) / (max - min) * 140,
            );
            c.drawLine(
              q(0, left.value),
              q(1, right.value),
              Paint()
                ..color = Colors.blue
                ..strokeWidth = 3,
            );
            final temp = left.value + (right.value - left.value) * probe.value;
            c.drawCircle(
              q(probe.value, temp),
              6,
              Paint()..color = Colors.orange,
            );
            label(c, const Offset(4, 4), 'Temperature / K versus position / m');
          }),
          sourceControl('leftT'),
          sourceControl('rightT'),
          Text(
            'Heat rate ${number(s.value('heatRate'))} W · gradient ${number(s.value('gradient'))} K/m',
          ),
        ];
      case 's11-e04':
        return [
          const Text(
            'Move the axial magnetic source past the receiver coil. The same finite-loop flux integral drives the apparatus. The signed velocity control determines instantaneous dΦ/dt; moving position while paused selects a new initial condition, not a measured drag speed.',
          ),
          picture(
            (c, z) {
              final position = s.value('position') ?? 0,
                  x = (position + .25) / .5 * z.width;
              c.drawOval(
                Rect.fromCenter(
                  center: Offset(z.width / 2, 100),
                  width: 30,
                  height: 110,
                ),
                Paint()
                  ..color = Colors.orange
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 5,
              );
              c.drawRect(
                Rect.fromCenter(center: Offset(x, 100), width: 40, height: 25),
                Paint()..color = Colors.red,
              );
              label(
                c,
                const Offset(5, 5),
                '−0.25 m       receiver at z=0       +0.25 m',
              );
            },
            drag: (p) =>
                s.change('initialZ', (-.25 + p.dx * .5).clamp(-.25, .25)),
          ),
          sourceControl('initialZ'),
          sourceControl('velocity'),
          sourceControl('closed'),
          Text(
            'z ${number(s.value('position'))} m · flux ${number(s.value('flux'))} Wb · linkage ${number(s.value('linkage'))} Wb',
          ),
          Text(
            'EMF ${number(s.value('emf'))} V · current ${number(s.value('current'))} A · ${s.value('emf') == null
                ? 'polarity unavailable'
                : s.value('emf')! > 0
                ? 'positive polarity'
                : s.value('emf')! < 0
                ? 'negative polarity'
                : 'zero EMF'}',
            key: const Key('induction-linked'),
          ),
          run(),
          const Text(
            'Reverse velocity to reverse EMF at the same position. An open receiver can have EMF while current remains zero.',
          ),
        ];
      case 's14-e02':
        return [
          const Text(
            'Predict the equilibrium submerged fraction for this uniform block. Drag the waterline up or down, or use the slider. Orange is your prediction; blue shows calculated equilibrium after reveal.',
          ),
          picture(
            (c, z) {
              final rect = Rect.fromLTWH(z.width * .3, 20, z.width * .4, 150);
              c.drawRect(rect, Paint()..color = Colors.brown.shade200);
              final y = 170 - s.prediction * 150;
              c.drawRect(
                Rect.fromLTRB(rect.left, y, rect.right, 170),
                Paint()..color = Colors.orange.withValues(alpha: .6),
              );
              if (s.revealed && !s.stale) {
                final actual = s.value('equilibriumFraction');
                if (actual != null) {
                  c.drawLine(
                    Offset(0, 170 - actual * 150),
                    Offset(z.width, 170 - actual * 150),
                    Paint()
                      ..color = Colors.blue
                      ..strokeWidth = 3,
                  );
                }
              }
            },
            drag: (p) => s.update(() {
              s.prediction = ((170 - p.dy * 200) / 150).clamp(0, 1);
              s.revealed = false;
            }),
          ),
          slider(
            'Predicted submerged fraction',
            s.prediction,
            0,
            1,
            (v) => s.update(() {
              s.prediction = v;
              s.revealed = false;
            }),
          ),
          button('Test waterline prediction', s.reveal),
          evidence(),
          sourceControl('objectDensity'),
          sourceControl('density'),
        ];
      case 's01-e01':
        final main = s.value('main') ?? 0, fraction = s.value('fraction') ?? 0;
        return [
          const Text(
            'Which vernier graduation coincides with a main-scale line? Tap a division before revealing the corrected reading. Scale shown in mm; vernier spacing is 0.9 mm and least count 0.1 mm.',
          ),
          picture(
            (c, z) {
              final sx = z.width * .9 / 12, start = z.width * .05;
              for (int i = 0; i <= 12; i++) {
                final x = start + i * sx;
                c.drawLine(
                  Offset(x, 45),
                  Offset(x, 75),
                  Paint()..color = Colors.black,
                );
                label(c, Offset(x - 5, 23), '${(main * 1000).round() + i}');
              }
              for (int i = 0; i <= 10; i++) {
                final x = start + (fraction * 1000 + i * .9) * sx;
                c.drawLine(
                  Offset(x, 90),
                  Offset(x, 120),
                  Paint()
                    ..color = i == s.graduation ? Colors.orange : Colors.blue
                    ..strokeWidth = i == s.graduation ? 3 : 1,
                );
                label(c, Offset(x - 3, 130), '$i');
              }
            },
            drag: (p) => s.update(() {
              s.graduation = (((p.dx - .05) / .9 * 12 - fraction * 1000) / .9)
                  .round()
                  .clamp(0, 9);
              s.revealed = false;
            }),
            label: 'Main scale above; vernier below. Tap a graduation or use the numbered buttons.',
          ),
          Wrap(
            children: [
              for (int i = 0; i < 10; i++)
                Padding(
                  padding: const EdgeInsets.all(2),
                  child: ChoiceChip(
                    label: Text('$i'),
                    selected: s.graduation == i,
                    onSelected: (_) => s.update(() {
                      s.graduation = i;
                      s.revealed = false;
                    }),
                  ),
                ),
            ],
          ),
          button('Reveal scale breakdown', s.reveal),
          evidence(),
          sourceControl('a', scale: 1000, unit: 'mm'),
          sourceControl('zero', scale: 1000, unit: 'mm'),
        ];
      case 's15-e01':
        return [
          const Text(
            'Find the threshold wavelength in six explicit trials. Keep work function fixed. Vary wavelength and irradiance independently; record both sides of emission onset. Energetic permission and measured collector current are different.',
          ),
          if (s.control('wavelength') != null)
            sourceControl('wavelength', scale: 1e9, unit: 'nm')
          else
            sourceControl('frequency'),
          sourceControl('intensity'),
          Text(
            'Trial ${s.trials.length}/6 · current ${number(s.value('current'))} A',
          ),
          if (s.trials.length < 6)
            button('Capture threshold trial', s.capturePhoto),
          evidence(),
          for (int i = 0; i < s.trials.length; i++)
            Text(
              '${i + 1}. ${number(s.trials[i]['wavelength']! * 1e9)} nm · ${number(s.trials[i]['intensity'])} W/m² · ${s.trials[i]['energeticallyAllowed'] == 1 ? 'allowed by energy' : 'below threshold'} · ${s.trials[i]['emitting'] == 1 ? 'emitting' : 'no emission'} · Kmax ${number(s.trials[i]['maximumKineticEnergy'])} J · I ${number(s.trials[i]['current'])} A',
            ),
          if (s.trials.length == 6)
            const Text(
              'Six trials complete. Review the bracket and evidence before starting again.',
            ),
          button(
            'Start a new threshold hunt',
            () => s.update(() {
              s.trials.clear();
              s.feedback = '';
            }),
          ),
        ];
      default:
        return [];
    }
  }
}

void dashed(Canvas c, Offset a, Offset b, Color color) {
  final d = b - a;
  final count = math.max(1, (d.distance / 8).ceil());
  for (int i = 0; i < count; i += 2) {
    c.drawLine(
      a + d * (i / count),
      a + d * (math.min(i + 1, count) / count),
      Paint()..color = color,
    );
  }
}

void label(Canvas c, Offset p, String text) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 11,
        fontFamily: 'HomeManrope',
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(c, p);
}

void axes(Canvas c, Size z) {
  final p = Paint()..color = Colors.grey;
  c.drawLine(Offset(0, z.height / 2), Offset(z.width, z.height / 2), p);
  c.drawLine(Offset(z.width / 2, 0), Offset(z.width / 2, z.height), p);
}

void arrow(Canvas c, Size z, Offset v, Color color) {
  final a = Offset(z.width / 2, z.height / 2),
      b = a + Offset(v.dx * z.width / 2, v.dy * z.height / 2);
  final p = Paint()
    ..color = color
    ..strokeWidth = 3;
  c.drawLine(a, b, p);
  if (v.distance > 0) {
    final angle = math.atan2(b.dy - a.dy, b.dx - a.dx);
    for (final sign in [-1, 1]) {
      c.drawLine(
        b,
        b -
            Offset(math.cos(angle + sign * .45), math.sin(angle + sign * .45)) *
                10,
        p,
      );
    }
  }
}

class _FocusPainter extends CustomPainter {
  final void Function(Canvas, Size) draw;
  _FocusPainter(this.draw);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    draw(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FocusPainter oldDelegate) => true;
}
