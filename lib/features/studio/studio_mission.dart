import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/catalog.dart';
import '../../core/physics/electromagnetism.dart';
import '../../core/physics/measurement.dart';
import '../../core/physics/waves_optics.dart' show ImageSolution, harmonic;

typedef MissionInput = ({
  String key,
  String label,
  String unit,
  double min,
  double max,
  double initial,
});

class StudioMission {
  final String studio, title, why, question, limits;
  final List<String> choices, labs;
  final List<MissionInput> inputs;
  const StudioMission(
    this.studio,
    this.title,
    this.why,
    this.question,
    this.choices,
    this.inputs,
    this.labs,
    this.limits,
  );
}

/// A teaching priority, not a usage/popularity score. These ten previews connect
/// concepts across a studio; they do not replace or change laboratory sessions.
const priorityStudioMissions = [
  StudioMission(
    's01',
    'Choose the right resolution',
    'Measurement makes every later observation meaningful.',
    'Is the gap at least one instrument division?',
    ['At least one division', 'Below one division'],
    [
      (
        key: 'gap',
        label: 'Gap to distinguish',
        unit: 'mm',
        min: .01,
        max: 2,
        initial: .2,
      ),
      (
        key: 'q',
        label: 'Instrument division',
        unit: 'mm',
        min: .01,
        max: 1,
        initial: .1,
      ),
    ],
    ['s01-e01', 's01-e05'],
    'Resolution-only preview. Quantization standard uncertainty q/√12 assumes uniform rounding within ±q/2. One division is not a guarantee of accuracy; calibration and uncertainty still matter.',
  ),
  StudioMission(
    's02',
    'Balance the lever',
    'Equilibrium connects forces, geometry and engineering.',
    'Which way does the unbalanced lever initially turn?',
    ['Left descends', 'Balanced', 'Right descends'],
    [
      (
        key: 'mass',
        label: 'Left mass',
        unit: 'kg',
        min: .5,
        max: 5,
        initial: 2,
      ),
      (
        key: 'arm',
        label: 'Right lever arm',
        unit: 'm',
        min: .1,
        max: .5,
        initial: .25,
      ),
    ],
    ['s02-e03', 's02-e04'],
    'Massless horizontal lever; left arm 0.25 m, right mass 2 kg, uniform gravity. Torques describe initial tendency, not an animated angular trajectory.',
  ),
  StudioMission(
    's03',
    'Scrub motion, read its direction',
    'Kinematics connects apparatus motion with graphs.',
    'At the selected time, which way is the object moving?',
    ['Forward', 'Stopped', 'Backward'],
    [
      (
        key: 'a',
        label: 'Constant acceleration',
        unit: 'm/s²',
        min: -3,
        max: 3,
        initial: -1,
      ),
      (key: 't', label: 'Timeline', unit: 's', min: 0, max: 5, initial: 1),
    ],
    ['s03-e00', 's03-e01'],
    'Straight-line constant-acceleration preview; x₀=0 m, v₀=2 m/s. Scrubbing selects model time; it does not replay a saved lab.',
  ),
  StudioMission(
    's04',
    'Combine opposing forces',
    'Net force explains acceleration across mechanics.',
    'Which direction is the acceleration?',
    ['Right', 'Zero', 'Left'],
    [
      (
        key: 'right',
        label: 'Rightward force',
        unit: 'N',
        min: 0,
        max: 10,
        initial: 6,
      ),
      (
        key: 'left',
        label: 'Leftward force',
        unit: 'N',
        min: 0,
        max: 10,
        initial: 2,
      ),
    ],
    ['s04-e01', 's04-e05'],
    'Two horizontal forces on a 2 kg body, no other horizontal forces. Balanced forces imply zero acceleration, not necessarily zero velocity.',
  ),
  StudioMission(
    's05',
    'Follow the energy budget',
    'Energy connects mechanical, electrical and thermal processes.',
    'After the drop, which energy share is larger?',
    ['Kinetic', 'Equal shares', 'Dissipated'],
    [
      (
        key: 'height',
        label: 'Drop height',
        unit: 'm',
        min: .1,
        max: 5,
        initial: 2,
      ),
      (
        key: 'retained',
        label: 'Fraction reaching kinetic energy',
        unit: '',
        min: 0,
        max: 1,
        initial: .8,
      ),
    ],
    ['s05-e01', 's05-e03'],
    'Ideal 1 kg drop budget: mgh=K+loss. Retained fraction is an explicit accounting assumption, not a fitted friction or drag law.',
  ),
  StudioMission(
    's10',
    'Compare circuit connections',
    'Electricity underpins circuits and electronics.',
    'Which resistor dissipates more power?',
    ['R1', 'Equal power', 'R2'],
    [
      (
        key: 'r1',
        label: 'Resistance R1',
        unit: 'Ω',
        min: 1,
        max: 30,
        initial: 10,
      ),
      (
        key: 'r2',
        label: 'Resistance R2',
        unit: 'Ω',
        min: 1,
        max: 30,
        initial: 20,
      ),
    ],
    ['s10-e06', 's10-e04'],
    'Ideal 6 V source and two resistors. Series/parallel networks use the existing circuit solver; this preview does not edit the lab circuit.',
  ),
  StudioMission(
    's08',
    'Connect frequency and wavelength',
    'Waves connect sound, light and signal transport.',
    'Compared with the reference, how does wave speed change?',
    ['Faster', 'Same speed', 'Slower'],
    [
      (key: 'f', label: 'Frequency', unit: 'Hz', min: .5, max: 5, initial: 2),
      (key: 'w', label: 'Wavelength', unit: 'm', min: .1, max: 1, initial: .4),
    ],
    ['s08-e00', 's08-e03'],
    'Reference f=2 Hz, λ=0.4 m, speed=0.8 m/s. Independent f and λ select different model speeds; this is not a fixed-medium dispersion model. Profile is computed at the selected preview time.',
  ),
  StudioMission(
    's13',
    'Compare two conduction rods',
    'Thermal reasoning links energy to everyday materials.',
    'Which rod transfers more heat per second?',
    ['Rod A', 'Equal rate', 'Rod B'],
    [
      (
        key: 'k',
        label: 'Rod A conductivity',
        unit: 'W/(m K)',
        min: 1,
        max: 300,
        initial: 205,
      ),
      (
        key: 'length',
        label: 'Rod A length',
        unit: 'm',
        min: .1,
        max: 1,
        initial: .2,
      ),
    ],
    ['s13-e01', 's13-e06'],
    'Steady Fourier conduction, area 0.0002 m², reservoirs 333.15/293.15 K. Rod B: k=50 W/(m K), L=0.2 m. No contact resistance or transient race timing; conductivity is an adjustable model input.',
  ),
  StudioMission(
    's09',
    'Move the object, classify the image',
    'Optics connects geometry with vision and instruments.',
    'What kind of image does this lens produce?',
    ['Real', 'At infinity', 'Virtual'],
    [
      (
        key: 'u',
        label: 'Object distance',
        unit: 'm',
        min: .05,
        max: 1,
        initial: .3,
      ),
      (
        key: 'f',
        label: 'Focal-length magnitude',
        unit: 'm',
        min: .05,
        max: .3,
        initial: .1,
      ),
    ],
    ['s09-e02', 's09-e03'],
    'Existing thin-lens/paraxial solver; real object on the left. Solid outgoing rays are physical; dashed backward extensions locate a virtual image. Remote images may lie outside the drawing.',
  ),
  StudioMission(
    's11',
    'Rotate a loop through the field',
    'Magnetic flux connects fields, motors and induction.',
    'What is the signed flux through the loop?',
    ['Positive', 'Zero', 'Negative'],
    [
      (
        key: 'angle',
        label: 'Normal-to-field angle',
        unit: '°',
        min: 0,
        max: 180,
        initial: 60,
      ),
      (
        key: 'field',
        label: 'Uniform field',
        unit: 'T',
        min: .01,
        max: 1,
        initial: .2,
      ),
    ],
    ['s11-e03', 's11-e04'],
    'Static uniform-field preview: Φ=BA cosθ, A=0.01 m², θ measured from the chosen area normal. Scrubbing angle is not a timed rotation and does not imply a measured EMF.',
  ),
];
StudioMission? missionForStudio(String id) =>
    priorityStudioMissions.where((m) => m.studio == id).firstOrNull;

class StudioMissionSession extends ChangeNotifier {
  final StudioMission mission;
  late final Map<String, double> values = {
    for (final p in mission.inputs) p.key: p.initial,
  };
  int mode = 0;
  double waveTime = .25;
  bool scrubWaveTime(double t) {
    if (!t.isFinite || t < 0 || t > 2) return false;
    waveTime = t;
    notifyListeners();
    return true;
  }

  String? prediction;
  bool revealed = false;
  StudioMissionSession(this.mission);
  double v(String key) => values[key]!;
  bool change(String key, double value) {
    final p = mission.inputs.where((p) => p.key == key).firstOrNull;
    if (p == null || !value.isFinite || value < p.min || value > p.max) {
      return false;
    }
    if (values[key] == value) return true;
    values[key] = value;
    prediction = null;
    revealed = false;
    notifyListeners();
    return true;
  }

  void selectMode(int next) {
    if (next < 0 || next > 1 || next == mode) return;
    mode = next;
    prediction = null;
    revealed = false;
    notifyListeners();
  }

  void predict(String choice) {
    if (!mission.choices.contains(choice)) return;
    prediction = choice;
    revealed = false;
    notifyListeners();
  }

  void reveal() {
    if (prediction == null) return;
    revealed = true;
    notifyListeners();
  }

  void reset() {
    for (final p in mission.inputs) {
      values[p.key] = p.initial;
    }
    mode = 0;
    waveTime = .25;
    prediction = null;
    revealed = false;
    notifyListeners();
  }

  CircuitGraph get circuit {
    final parts = [
      CircuitPart('B', 'source', value: 6),
      CircuitPart('R1', 'resistor', value: v('r1')),
      CircuitPart('R2', 'resistor', value: v('r2')),
    ];
    return CircuitGraph(
      parts,
      mode == 0
          ? [
              ['B:a', 'R1:a'],
              ['R1:b', 'R2:a'],
              ['R2:b', 'B:b'],
            ]
          : [
              ['B:a', 'R1:a'],
              ['B:a', 'R2:a'],
              ['B:b', 'R1:b'],
              ['B:b', 'R2:b'],
            ],
    );
  }

  ImageSolution get lens =>
      ImageSolution(v('f') * (mode == 0 ? 1 : -1), v('u'), .004);
  Map<String, double> get readings => switch (mission.studio) {
    's01' => {
      'Gap / divisions': v('gap') / v('q'),
      'Quantization standard uncertainty (mm)': v('q') / math.sqrt(12),
    },
    's02' => {
      'Left torque magnitude (N·m)': v('mass') * 9.80665 * .25,
      'Right torque magnitude (N·m)': 2 * 9.80665 * v('arm'),
    },
    's03' => {
      'Position (m)': trackPosition(v('t'), 2, v('a')),
      'Velocity (m/s)': 2 + v('a') * v('t'),
    },
    's04' => {
      'Net force (N)': v('right') - v('left'),
      'Acceleration (m/s²)': (v('right') - v('left')) / 2,
    },
    's05' => {
      'Input gravitational energy (J)': 9.80665 * v('height'),
      'Kinetic energy (J)': 9.80665 * v('height') * v('retained'),
      'Dissipated energy (J)': 9.80665 * v('height') * (1 - v('retained')),
      'Speed (m/s)': math.sqrt(2 * 9.80665 * v('height') * v('retained')),
    },
    's10' => {
      'R1 power (W)': solveCircuit(circuit).powers['R1']!,
      'R2 power (W)': solveCircuit(circuit).powers['R2']!,
      'Source current magnitude (A)': solveCircuit(circuit).currents['B']!
          .abs(),
    },
    's08' => {'Wave speed (m/s)': v('f') * v('w'), 'Period (s)': 1 / v('f')},
    's13' => {
      'Rod A heat rate (W)': v('k') * .0002 * 40 / v('length'),
      'Rod B heat rate (W)': 2,
    },
    's09' => {
      'Image vergence (1/m)': lens.atInfinity ? 0 : lens.vergence,
      if (lens.distance != null) 'Signed image distance (m)': lens.distance!,
      if (lens.magnification != null) 'Magnification': lens.magnification!,
    },
    's11' => {
      'Signed flux (Wb)': v('angle') == 90
          ? 0.0
          : v('field') * .01 * math.cos(v('angle') * math.pi / 180),
    },
    _ => throw StateError('Unknown studio'),
  };
  String compare(
    double difference,
    String positive,
    String zero,
    String negative,
  ) => difference.abs() < 1e-10
      ? zero
      : difference > 0
      ? positive
      : negative;
  String get answer => switch (mission.studio) {
    's01' =>
      v('gap') + 1e-12 >= v('q')
          ? 'At least one division'
          : 'Below one division',
    's02' => compare(
      v('mass') * .25 - 2 * v('arm'),
      'Left descends',
      'Balanced',
      'Right descends',
    ),
    's03' => compare(2 + v('a') * v('t'), 'Forward', 'Stopped', 'Backward'),
    's04' => compare(v('right') - v('left'), 'Right', 'Zero', 'Left'),
    's05' => compare(
      v('retained') - .5,
      'Kinetic',
      'Equal shares',
      'Dissipated',
    ),
    's10' => compare(
      readings['R1 power (W)']! - readings['R2 power (W)']!,
      'R1',
      'Equal power',
      'R2',
    ),
    's08' => compare(v('f') * v('w') - .8, 'Faster', 'Same speed', 'Slower'),
    's13' => compare(
      readings['Rod A heat rate (W)']! - 2,
      'Rod A',
      'Equal rate',
      'Rod B',
    ),
    's09' =>
      lens.atInfinity
          ? 'At infinity'
          : lens.classification == 1
          ? 'Real'
          : 'Virtual',
    's11' => compare(readings.values.first, 'Positive', 'Zero', 'Negative'),
    _ => throw StateError('Unknown studio'),
  };
  String get explanation => switch (mission.studio) {
    's01' => 'Compare gap with division size. Smaller divisions improve resolution; they do not remove systematic error.',
    's02' => 'Compare m g × arm on both sides. Equal torques give rotational equilibrium.',
    's03' => 'Direction follows the sign of velocity, not position or acceleration. The position-curve tangent has that velocity.',
    's04' => 'Subtract opposing forces, then divide by 2 kg. Zero net force means constant velocity.',
    's05' => 'K+loss=mgh. The retained fraction determines the split; speed follows K=½mv².',
    's10' => 'Series resistors share current, so P=I²R. Parallel resistors share voltage, so P=V²/R.',
    's08' => 'Multiply f by λ and compare with 0.8 m/s. Increasing frequency alone need not increase speed in a fixed real medium.',
    's13' => 'Compare kAΔT/L. The common reservoir temperatures and areas isolate conductivity and length.',
    's09' => 'Use 1/v=1/f−1/u. Positive v is real, negative v virtual; zero vergence means an image at infinity.',
    's11' => 'Flux is the signed dot product of field and area normal. A 90° normal gives zero flux even though the magnetic field is not zero.',
    _ => '',
  };
}

Future<void> showStudioMission(
  BuildContext context,
  StudioMissionSession session,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (sheetContext) => SizedBox(
    height: MediaQuery.sizeOf(sheetContext).height * .92,
    child: RepaintBoundary(
      key: const Key('studio-mission-surface'),
      child: Material(
        color: Theme.of(sheetContext).colorScheme.surface,
        child: StudioMissionPanel(
          session: session,
          onLab: (id) {
            Navigator.pop(sheetContext);
            context.push('/lab/$id');
          },
        ),
      ),
    ),
  ),
);

class StudioMissionPanel extends StatelessWidget {
  final StudioMissionSession session;
  final ValueChanged<String> onLab;
  const StudioMissionPanel({
    super.key,
    required this.session,
    required this.onLab,
  });
  MissionInput get dragInput => session.mission.inputs.firstWhere(
    (p) =>
        p.key ==
        (session.mission.studio == 's11'
            ? 'angle'
            : session.mission.studio == 's09'
            ? 'u'
            : session.mission.inputs.last.key),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: session,
    builder: (context, _) => SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    session.mission.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close studio activity',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              key: const Key('studio-mission-scroll'),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                const Text(
                  'Studio preview • independent of your saved lab setups',
                ),
                Text(
                  session.mission.question,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                LayoutBuilder(
                  builder: (context, box) => Semantics(
                    label:
                        '${session.mission.title}. Drag horizontally to change ${dragInput.label}; labeled controls below provide the same input.',
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (d) =>
                          drag(d.localPosition.dx / box.maxWidth),
                      onPanUpdate: (d) =>
                          drag(d.localPosition.dx / box.maxWidth),
                      child: SizedBox(
                        height: 190,
                        child: CustomPaint(painter: _MissionPainter(session)),
                      ),
                    ),
                  ),
                ),
                if (session.mission.studio == 's08') ...[
                  Text('Preview time: ${fmt(session.waveTime)} s'),
                  Slider(
                    key: const Key('mission-wave-time'),
                    value: session.waveTime,
                    min: 0,
                    max: 2,
                    label: '${fmt(session.waveTime)} s',
                    onChanged: session.scrubWaveTime,
                  ),
                ],
                if (session.mission.studio == 's10' ||
                    session.mission.studio == 's09')
                  Wrap(
                    spacing: 8,
                    children: [
                      for (int i = 0; i < 2; i++)
                        ChoiceChip(
                          label: Text(
                            session.mission.studio == 's10'
                                ? (i == 0 ? 'Series' : 'Parallel')
                                : (i == 0 ? 'Converging' : 'Diverging'),
                          ),
                          selected: session.mode == i,
                          onSelected: (_) => session.selectMode(i),
                        ),
                    ],
                  ),
                for (final p in session.mission.inputs) ...[
                  Text('${p.label}: ${fmt(session.v(p.key))} ${p.unit}'),
                  Slider(
                    key: ValueKey('mission-${p.key}'),
                    label: '${fmt(session.v(p.key))} ${p.unit}',
                    value: session.v(p.key),
                    min: p.min,
                    max: p.max,
                    onChanged: (v) => session.change(p.key, v),
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => session.change(
                          p.key,
                          (session.v(p.key) - (p.max - p.min) / 100).clamp(
                            p.min,
                            p.max,
                          ),
                        ),
                        child: Text('Decrease ${p.label}'),
                      ),
                      TextButton(
                        onPressed: () => session.change(
                          p.key,
                          (session.v(p.key) + (p.max - p.min) / 100).clamp(
                            p.min,
                            p.max,
                          ),
                        ),
                        child: Text('Increase ${p.label}'),
                      ),
                    ],
                  ),
                ],
                const Text('Make a prediction for this setup'),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final choice in session.mission.choices)
                      ChoiceChip(
                        label: Text(choice),
                        selected: session.prediction == choice,
                        onSelected: (_) => session.predict(choice),
                      ),
                  ],
                ),
                FilledButton(
                  key: const Key('mission-reveal'),
                  onPressed: session.prediction == null ? null : session.reveal,
                  child: const Text('Check prediction'),
                ),
                if (session.revealed)
                  Semantics(
                    liveRegion: true,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              session.prediction == session.answer
                                  ? 'Your prediction matches: ${session.answer}.'
                                  : 'Your prediction: ${session.prediction}. Model result: ${session.answer}.',
                              key: const Key('mission-feedback'),
                            ),
                            Text(session.explanation),
                            for (final r in session.readings.entries)
                              Text('${r.key}: ${fmt(r.value)}'),
                          ],
                        ),
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: session.reset,
                  child: const Text('Reset studio preview'),
                ),
                ExpansionTile(
                  title: const Text('Model and limits'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(session.mission.limits),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Continue in two working labs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Text(
                  'Open each lab to investigate this connection with its full apparatus. Preview inputs are not transferred and no activity is marked complete.',
                ),
                for (int i = 0; i < session.mission.labs.length; i++)
                  OutlinedButton.icon(
                    key: ValueKey('mission-lab-$i'),
                    onPressed: () => onLab(session.mission.labs[i]),
                    icon: const Icon(Icons.science_outlined),
                    label: Text(
                      '${i + 1}. ${entryById(session.mission.labs[i]).title}',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  void drag(double fraction) {
    final p = dragInput;
    if (session.mission.studio == 's09') fraction = 1 - 2 * fraction;
    session.change(p.key, p.min + (p.max - p.min) * fraction.clamp(0, 1));
  }
}

String fmt(double n) => n == 0
    ? '0'
    : n.abs() < .001 || n.abs() > 1e5
    ? n.toStringAsExponential(3)
    : n.toStringAsPrecision(4);

class _MissionPainter extends CustomPainter {
  final StudioMissionSession s;
  _MissionPainter(this.s);
  void text(Canvas c, Offset p, String t) {
    (TextPainter(
      text: TextSpan(
        text: t,
        style: const TextStyle(
          fontFamily: 'HomeManrope',
          fontSize: 11,
          color: Colors.black,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout()).paint(c, p);
  }

  Paint ink(Color color, {double width = 3}) => Paint()
    ..color = color
    ..strokeWidth = width
    ..style = PaintingStyle.stroke;
  void arrow(Canvas c, Offset a, Offset b, Color color) {
    c.drawLine(a, b, ink(color));
    if ((b - a).distance < 1) return;
    final v = (b - a) / (b - a).distance;
    c.drawLine(b, b - v * 10 + Offset(-v.dy, v.dx) * 5, ink(color));
    c.drawLine(b, b - v * 10 - Offset(-v.dy, v.dx) * 5, ink(color));
  }

  @override
  void paint(Canvas c, Size z) {
    c.save();
    c.clipRect(Offset.zero & z);
    final w = z.width;
    switch (s.mission.studio) {
      case 's01':
        final scale = (w - 40) / 3;
        for (int i = 0; i * s.v('q') <= 3; i++) {
          final x = 20 + i * s.v('q') * scale;
          c.drawLine(Offset(x, 80), Offset(x, 105), ink(Colors.blue, width: 1));
        }
        c.drawLine(
          const Offset(20, 60),
          Offset(20 + s.v('gap') * scale, 60),
          ink(Colors.orange, width: 5),
        );
        text(
          c,
          const Offset(10, 135),
          'Orange gap / blue instrument divisions · mm',
        );
        break;
      case 's02':
        final centre = Offset(w / 2, 90);
        c.drawLine(
          Offset(w * .1, 90),
          Offset(w * .9, 90),
          ink(Colors.blueGrey),
        );
        c.drawPath(
          Path()
            ..moveTo(centre.dx, 95)
            ..lineTo(centre.dx - 15, 125)
            ..lineTo(centre.dx + 15, 125)
            ..close(),
          ink(Colors.black),
        );
        final left = Offset(centre.dx - w * .25 * .7, 90),
            right = Offset(centre.dx + w * s.v('arm') * .7, 90);
        arrow(c, left, left + Offset(0, s.v('mass') * 12), Colors.orange);
        arrow(c, right, right + const Offset(0, 24), Colors.blue);
        text(
          c,
          const Offset(10, 155),
          'Left: adjustable mass / right: 2 kg · horizontal arms',
        );
        break;
      case 's03':
        final positions = [
          for (int i = 0; i <= 100; i++) trackPosition(i / 20, 2, s.v('a')),
        ];
        final low = positions.reduce(math.min),
            high = positions.reduce(math.max);
        final span = math.max(.2, high - low);
        Offset q(double t, double x) =>
            Offset(25 + t / 5 * (w - 45), 150 - (x - low) / span * 120);
        final p = Path();
        for (int i = 0; i <= 100; i++) {
          final t = i / 20, point = q(t, trackPosition(t, 2, s.v('a')));
          if (i == 0) {
            p.moveTo(point.dx, point.dy);
          } else {
            p.lineTo(point.dx, point.dy);
          }
        }
        c.drawLine(q(0, 0), q(5, 0), ink(Colors.grey, width: 1));
        text(
          c,
          const Offset(8, 5),
          'x range ${fmt(low)} to ${fmt(high)} m · t=0 to 5 s',
        );
        c.drawPath(p, ink(Colors.blue));
        final t = s.v('t'), point = q(t, trackPosition(t, 2, s.v('a')));
        c.drawCircle(point, 6, Paint()..color = Colors.orange);
        final velocity = 2 + s.v('a') * t;
        c.drawLine(
          q(t - .25, trackPosition(t, 2, s.v('a')) - .25 * velocity),
          q(t + .25, trackPosition(t, 2, s.v('a')) + .25 * velocity),
          ink(Colors.orange),
        );
        text(
          c,
          const Offset(8, 168),
          'x / m versus t / s · orange tangent at selected time',
        );
        break;
      case 's04':
        final centre = Offset(w / 2, 95);
        c.drawRect(
          Rect.fromCenter(center: centre, width: 45, height: 40),
          ink(Colors.blueGrey),
        );
        arrow(
          c,
          centre,
          centre + Offset(s.v('right') / 10 * (w / 2 - 10), 0),
          Colors.blue,
        );
        arrow(
          c,
          centre,
          centre - Offset(s.v('left') / 10 * (w / 2 - 10), 0),
          Colors.orange,
        );
        text(
          c,
          const Offset(8, 150),
          'Blue: right force / orange: left force · equal N scale',
        );
        break;
      case 's05':
        final retained = s.v('retained');
        c.drawRect(
          Rect.fromLTWH(20, 65, (w - 40) * retained, 50),
          Paint()..color = Colors.blue,
        );
        c.drawRect(
          Rect.fromLTWH(
            20 + (w - 40) * retained,
            65,
            (w - 40) * (1 - retained),
            50,
          ),
          Paint()..color = Colors.orange,
        );
        text(
          c,
          const Offset(10, 140),
          'Blue K + orange dissipated = total mgh',
        );
        break;
      case 's10':
        final a = Offset(25, 50),
            b = Offset(25, 140),
            r1 = s.mode == 0 ? Offset(w * .55, 50) : Offset(w * .5, 95),
            r2 = s.mode == 0 ? Offset(w * .55, 140) : Offset(w * .8, 95);
        c.drawLine(a, b, ink(Colors.orange, width: 5));
        if (s.mode == 0) {
          c.drawLine(a, Offset(w - 20, 50), ink(Colors.blue));
          c.drawLine(Offset(w - 20, 50), Offset(w - 20, 140), ink(Colors.blue));
          c.drawLine(Offset(w - 20, 140), b, ink(Colors.blue));
        } else {
          c.drawLine(a, Offset(w - 20, 50), ink(Colors.blue));
          c.drawLine(b, Offset(w - 20, 140), ink(Colors.blue));
          for (final x in [w * .5, w * .8]) {
            c.drawLine(Offset(x, 50), Offset(x, 140), ink(Colors.blue));
          }
        }
        c.drawCircle(r1, 12, Paint()..color = Colors.white);
        c.drawCircle(r2, 12, Paint()..color = Colors.white);
        text(c, r1 - const Offset(10, 5), 'R1');
        text(c, r2 - const Offset(10, 5), 'R2');
        text(
          c,
          const Offset(5, 5),
          '6 V ideal source · ${s.mode == 0 ? 'series' : 'parallel'} connectivity',
        );
        break;
      case 's08':
        final p = Path();
        for (int i = 0; i <= 200; i++) {
          final x = i / 100,
              y = harmonic(x, s.waveTime, .02, s.v('f'), s.v('w'), 0, 1),
              point = Offset(i / 200 * w, 85 - y * 1800);
          if (i == 0) {
            p.moveTo(point.dx, point.dy);
          } else {
            p.lineTo(point.dx, point.dy);
          }
        }
        c.drawPath(p, ink(Colors.blue));
        text(
          c,
          const Offset(10, 145),
          '2 m view · t=${fmt(s.waveTime)} s · height exaggerated',
        );
        break;
      case 's13':
        for (final row in [
          (65.0, s.v('length'), Colors.blue),
          (110.0, .2, Colors.orange),
        ]) {
          final rect = Rect.fromLTWH(15, row.$1, row.$2 * (w - 30), 25);
          c.drawRect(
            rect,
            Paint()
              ..shader = const LinearGradient(colors: [Colors.red, Colors.blue])
                  .createShader(rect),
          );
        }
        text(
          c,
          const Offset(10, 155),
          'Rod A above / B below · same temperature difference',
        );
        break;
      case 's09':
        final centre = Offset(w / 2, 95),
            sx = (w / 2 - 15) / math.max(.35, s.v('u'));
        Offset q(double x, double y) => centre + Offset(x * sx, -y * 4000);
        c.drawLine(Offset(0, 95), Offset(w, 95), ink(Colors.grey, width: 1));
        c.drawLine(q(0, .012), q(0, -.012), ink(Colors.blueGrey));
        arrow(c, q(-s.v('u'), 0), q(-s.v('u'), .004), Colors.orange);
        if (s.revealed) {
          c.drawLine(
            q(-s.v('u'), .004),
            q(0, .004),
            ink(Colors.grey, width: 1),
          );
          c.drawLine(q(-s.v('u'), .004), q(0, 0), ink(Colors.grey, width: 1));
          for (final ray in [
            (.004, -.004 / s.lens.focal),
            (0.0, -.004 / s.v('u')),
          ]) {
            c.drawLine(
              q(0, ray.$1),
              q(.35, ray.$1 + ray.$2 * .35),
              ink(Colors.blue),
            );
            if (s.lens.classification < 0) {
              for (int i = 0; i < 20; i += 2) {
                c.drawLine(
                  q(-.35 * i / 20, ray.$1 - ray.$2 * .35 * i / 20),
                  q(-.35 * (i + 1) / 20, ray.$1 - ray.$2 * .35 * (i + 1) / 20),
                  ink(Colors.blue, width: 1),
                );
              }
            }
          }
        }
        text(
          c,
          const Offset(5, 165),
          'Object left / lens centre · height exaggerated',
        );
        break;
      case 's11':
        final centre = Offset(w / 2, 90),
            a = s.v('angle') * math.pi / 180,
            normal = Offset(math.cos(a), -math.sin(a));
        for (final y in [55.0, 90.0, 125.0]) {
          arrow(
            c,
            Offset(15, y),
            Offset(w - 15, y),
            Colors.blue.withValues(alpha: .45),
          );
        }
        final tangent = Offset(-normal.dy, normal.dx);
        c.drawLine(
          centre - tangent * 50,
          centre + tangent * 50,
          ink(Colors.orange, width: 7),
        );
        arrow(c, centre, centre + normal * 60, Colors.red);
        text(
          c,
          const Offset(8, 155),
          'Blue B → / red chosen area normal / orange loop edge',
        );
        break;
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _MissionPainter oldDelegate) => true;
}
