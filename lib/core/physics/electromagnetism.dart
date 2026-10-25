import 'dart:math' as math;

import 'dynamics.dart' show standardGravity;

const emVersion = 'electromagnetism-5.0';
// CODATA 2022, adopted rounded central values; e is exact in SI.
const epsilon0 = 8.8541878188e-12,
    mu0 = 1.25663706127e-6,
    elementaryCharge = 1.602176634e-19;
final coulombK = 1 / (4 * math.pi * epsilon0);
typedef EMState = Map<String, double>;
String emNumber(num? v) => v == null
    ? 'Undefined'
    : v == 0
    ? '0'
    : v.abs() < .001 || v.abs() >= 100000
    ? v.toStringAsExponential(3)
    : v.toStringAsPrecision(6);

class V3 {
  final double x, y, z;
  const V3(this.x, this.y, [this.z = 0]);
  static const zero = V3(0, 0, 0);
  V3 operator +(V3 b) => V3(x + b.x, y + b.y, z + b.z);
  V3 operator -(V3 b) => V3(x - b.x, y - b.y, z - b.z);
  V3 operator *(double a) => V3(x * a, y * a, z * a);
  double dot(V3 b) => x * b.x + y * b.y + z * b.z;
  V3 cross(V3 b) => V3(y * b.z - z * b.y, z * b.x - x * b.z, x * b.y - y * b.x);
  double get norm => math.sqrt(dot(this));
  V3 get unit => norm > 1e-30 ? this * (1 / norm) : zero;
  List<double> get list => [x, y, z];
}

class ChargeSource {
  final V3 position;
  final double charge;
  const ChargeSource(this.position, this.charge);
}

class Electrostatic {
  final List<ChargeSource> sources;
  final double exclusion;
  Electrostatic(this.sources, {this.exclusion = .03}) {
    if (sources.isEmpty || sources.length > 3 || exclusion <= 0) {
      throw ArgumentError('1–3 sources and positive excluded radius');
    }
    for (int i = 0; i < sources.length; i++) {
      if (!sources[i].charge.isFinite) throw ArgumentError('Finite charge');
      for (int j = 0; j < i; j++) {
        if ((sources[i].position - sources[j].position).norm < 2 * exclusion) {
          throw ArgumentError('Source exclusion regions overlap');
        }
      }
    }
  }
  bool valid(V3 r) => sources.every((s) => (r - s.position).norm >= exclusion);
  V3 field(V3 r) {
    if (!valid(r)) {
      throw ArgumentError('Probe inside excluded point-source region');
    }
    var e = V3.zero;
    for (final s in sources) {
      final d = r - s.position;
      e = e + d * (coulombK * s.charge / math.pow(d.norm, 3));
    }
    return e;
  }

  double potential(V3 r) {
    if (!valid(r)) {
      throw ArgumentError('Probe inside excluded point-source region');
    }
    return sources.fold(
      0.0,
      (v, s) => v + coulombK * s.charge / (r - s.position).norm,
    );
  }
}

V3 coulombForce(ChargeSource a, ChargeSource b, {double minimum = .06}) {
  final d = b.position - a.position;
  if (d.norm < minimum) {
    throw ArgumentError('Centre separation below model range');
  }
  return d * (coulombK * a.charge * b.charge / math.pow(d.norm, 3));
}

/// RK4 of the normalized direction; holes/bounds/null fields terminate traces.
List<V3> traceField(
  V3 start,
  V3 Function(V3) field,
  bool Function(V3) valid, {
  int direction = 1,
  int maxSteps = 400,
  double step = .004,
}) {
  final points = <V3>[start];
  var p = start;
  V3 derivative(V3 r) =>
      valid(r) ? field(r).unit * direction.toDouble() : V3.zero;
  for (int i = 0; i < maxSteps; i++) {
    if (!valid(p) || field(p).norm < 1e-9) break;
    final a = derivative(p),
        b = derivative(p + a * (step / 2)),
        c = derivative(p + b * (step / 2)),
        d = derivative(p + c * step);
    final next = p + (a + b * 2 + c * 2 + d) * (step / 6);
    if ((next - p).norm < step * .2 || !valid(next)) break;
    points.add(next);
    p = next;
  }
  return direction > 0 ? points : points.reversed.toList();
}

List<List<V3>> electricLines(Electrostatic e) {
  final result = <List<V3>>[];
  final positives = e.sources.where((s) => s.charge > 0).toList();
  final seeds = positives.isEmpty
      ? e.sources.where((s) => s.charge < 0)
      : positives;
  for (final s in seeds) {
    for (int i = 0; i < 12; i++) {
      final angle = 2 * math.pi * (i + .5) / 12;
      final p =
          s.position +
          V3(math.cos(angle), math.sin(angle)) * (e.exclusion * 1.08);
      result.add(
        traceField(
          p,
          e.field,
          (r) => r.x.abs() < .45 && r.y.abs() < .32 && e.valid(r),
          direction: s.charge > 0 ? 1 : -1,
        ),
      );
    }
  }
  return result;
}

class CircuitPart {
  final String id, type;
  double value, x, y;
  bool closed;
  CircuitPart(
    this.id,
    this.type, {
    this.value = 15,
    this.x = .5,
    this.y = .5,
    this.closed = true,
  });
  String get a => '$id:a';
  String get b => '$id:b';
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'value': value,
    'x': x,
    'y': y,
    'closed': closed,
  };
  factory CircuitPart.fromJson(Map j) => CircuitPart(
    j['id'],
    j['type'],
    value: (j['value'] as num).toDouble(),
    x: (j['x'] as num).toDouble(),
    y: (j['y'] as num).toDouble(),
    closed: j['closed'],
  );
}

class CircuitGraph {
  final List<CircuitPart> parts;
  final List<List<String>> wires;
  CircuitGraph(this.parts, this.wires);
  Map<String, dynamic> toJson() => {
    'parts': parts.map((p) => p.toJson()).toList(),
    'wires': wires.map(List.of).toList(),
  };
  factory CircuitGraph.fromJson(Map j) => CircuitGraph(
    (j['parts'] as List).map((p) => CircuitPart.fromJson(p)).toList(),
    (j['wires'] as List).map((w) => List<String>.from(w)).toList(),
  );
  CircuitGraph copy() => CircuitGraph.fromJson(toJson());
  factory CircuitGraph.example(int kind) {
    final source = CircuitPart('B1', 'source', value: 6, x: .18, y: .3),
        r1 = CircuitPart('R1', 'resistor', value: 10, x: .52, y: .24),
        r2 = CircuitPart('L1', 'lamp', value: 20, x: .75, y: .62),
        meter = CircuitPart('A1', 'ammeter', value: 0, x: .35, y: .78),
        sw = CircuitPart('S1', 'switch', value: 0, x: .78, y: .25),
        vm = CircuitPart('V1', 'voltmeter', value: 0, x: .17, y: .62);
    final parts = [source, r1, r2, meter, sw, vm];
    final wires = <List<String>>[
      [source.a, r1.a],
      [r1.b, sw.a],
      [sw.b, r2.a],
      [r2.b, meter.a],
      [meter.b, source.b],
      [vm.a, r2.a],
      [vm.b, r2.b],
    ];
    if (kind >= 1) {
      wires.removeWhere((w) => w[0] == sw.b && w[1] == r2.a);
      wires.addAll([
        [sw.b, r2.a],
        [r1.a, r2.a],
        [r1.b, r2.b],
      ]);
      // Parallel example: source→switch→parallel R/lamp→ammeter→source.
      wires.removeWhere(
        (w) =>
            (w[0] == source.a && w[1] == r1.a) ||
            (w[0] == r1.b && w[1] == sw.a),
      );
      wires.addAll([
        [source.a, sw.a],
        [sw.b, r1.a],
      ]);
    }
    if (kind == 2) {
      final r3 = CircuitPart('R2', 'resistor', value: 5, x: .52, y: .88);
      parts.add(r3);
      wires.removeWhere((w) => w[0] == meter.b && w[1] == source.b);
      wires.addAll([
        [meter.b, r3.a],
        [r3.b, source.b],
      ]);
    }
    return CircuitGraph(parts, wires);
  }
}

class CircuitSolution {
  final String message;
  final Map<String, double> nodes, currents, voltages, powers;
  final double kclResidual, powerResidual;
  bool get valid => message.isEmpty;
  CircuitSolution(
    this.message, {
    this.nodes = const {},
    this.currents = const {},
    this.voltages = const {},
    this.powers = const {},
    this.kclResidual = 0,
    this.powerResidual = 0,
  });
}

CircuitSolution solveCircuit(CircuitGraph g) {
  CircuitSolution fail(String message) => CircuitSolution(message);
  if (g.parts.isEmpty || g.parts.length > 12 || g.wires.length > 24) {
    return fail('Use 1–12 components and at most 24 wires.');
  }
  final terminals = {
        for (final p in g.parts) ...[p.a, p.b],
      },
      parent = <String, String>{};
  if (g.parts.map((p) => p.id).toSet().length != g.parts.length) {
    return fail('Component IDs must be unique.');
  }
  for (final t in terminals) {
    parent[t] = t;
  }
  String root(String t) {
    var r = t;
    while (parent[r] != r) {
      r = parent[r]!;
    }
    return r;
  }

  for (final w in g.wires) {
    if (w.length != 2 || !terminals.containsAll(w)) {
      return fail('Connection references a missing terminal.');
    }
    parent[root(w[0])] = root(w[1]);
  }
  for (final p in g.parts) {
    if (![
          'source',
          'resistor',
          'lamp',
          'switch',
          'ammeter',
          'voltmeter',
        ].contains(p.type) ||
        !p.value.isFinite) {
      return fail('Unsupported component or nonfinite value.');
    }
    if (['resistor', 'lamp'].contains(p.type) &&
        (p.value < .1 || p.value > 10000)) {
      return fail('Resistors/ohmic lamps require 0.1–10000 Ω.');
    }
    if (p.type == 'source' && p.value.abs() > 24) {
      return fail('Sources must be within ±24 V.');
    }
  }
  final sources = g.parts.where((p) => p.type == 'source').toList();
  if (sources.isEmpty) {
    return fail(
      'Add an ideal voltage source to define the supported powered circuit.',
    );
  }
  for (final p in sources) {
    if (root(p.a) == root(p.b) && p.value.abs() > 1e-12) {
      return fail(
        'Ideal source short circuit: remove the short or series ammeter bypass.',
      );
    }
  }
  final ground = root(sources.first.b), roots = terminals.map(root).toSet();
  final edges = <String, Set<String>>{for (final r in roots) r: <String>{}};
  for (final p in g.parts) {
    if (p.type == 'voltmeter' || p.type == 'switch' && !p.closed) continue;
    final a = root(p.a), b = root(p.b);
    edges[a]!.add(b);
    edges[b]!.add(a);
  }
  final reached = <String>{ground}, queue = [ground];
  while (queue.isNotEmpty) {
    for (final n in edges[queue.removeLast()]!) {
      if (reached.add(n)) queue.add(n);
    }
  }
  if (reached.length != roots.length) {
    return fail(
      'Floating/disconnected nodes: connect every component to the referenced circuit. An ideal voltmeter supplies no ground path.',
    );
  }
  final nodes = roots.where((r) => r != ground).toList(),
      constraints = g.parts
          .where(
            (p) =>
                p.type == 'source' ||
                p.type == 'ammeter' ||
                p.type == 'switch' && p.closed,
          )
          .toList();
  final size = nodes.length + constraints.length;
  final a = List.generate(size, (_) => List<double>.filled(size + 1, 0));
  int index(String t) => nodes.indexOf(root(t));
  void add(int i, int j, double v) {
    if (i >= 0 && j >= 0) a[i][j] += v;
  }

  for (final p in g.parts) {
    if (p.type == 'resistor' || p.type == 'lamp') {
      final i = index(p.a), j = index(p.b), c = 1 / p.value;
      add(i, i, c);
      add(j, j, c);
      add(i, j, -c);
      add(j, i, -c);
    }
  }
  for (int k = 0; k < constraints.length; k++) {
    final p = constraints[k],
        i = index(p.a),
        j = index(p.b),
        n = nodes.length + k;
    add(i, n, 1);
    add(j, n, -1);
    add(n, i, 1);
    add(n, j, -1);
    a[n][size] = p.type == 'source' ? p.value : 0;
  }
  final original = a.map(List<double>.of).toList();
  for (int k = 0; k < size; k++) {
    int pivot = k;
    for (int i = k + 1; i < size; i++) {
      if (a[i][k].abs() > a[pivot][k].abs()) pivot = i;
    }
    if (a[pivot][k].abs() < 1e-12) {
      return fail(
        'Singular/inconsistent ideal constraints. Check source conflicts, ideal ammeter shorts and redundant zero-resistance loops; no finite reading is assigned.',
      );
    }
    final row = a[k];
    a[k] = a[pivot];
    a[pivot] = row;
    final divisor = a[k][k];
    for (int j = k; j <= size; j++) {
      a[k][j] /= divisor;
    }
    for (int i = 0; i < size; i++) {
      if (i == k) continue;
      final scale = a[i][k];
      for (int j = k; j <= size; j++) {
        a[i][j] -= scale * a[k][j];
      }
    }
  }
  final solution = [for (int i = 0; i < size; i++) a[i][size]],
      volts = <String, double>{},
      currents = <String, double>{},
      powers = <String, double>{},
      byTerminal = <String, double>{};
  double potential(String t) {
    final i = index(t);
    return i < 0 ? 0 : solution[i];
  }

  for (final t in terminals) {
    byTerminal[t] = potential(t);
  }
  for (final p in g.parts) {
    final v = potential(p.a) - potential(p.b);
    volts[p.id] = v;
    final k = constraints.indexOf(p);
    final i = k >= 0
        ? solution[nodes.length + k]
        : ['resistor', 'lamp'].contains(p.type)
        ? v / p.value
        : 0.0;
    currents[p.id] = i;
    powers[p.id] = v * i;
  }
  double residual = 0;
  for (int i = 0; i < nodes.length; i++) {
    double sum = 0;
    for (int j = 0; j < size; j++) {
      sum += original[i][j] * solution[j];
    }
    residual = math.max(residual, (sum - original[i][size]).abs());
  }
  return CircuitSolution(
    '',
    nodes: byTerminal,
    currents: currents,
    voltages: volts,
    powers: powers,
    kclResidual: residual,
    powerResidual: powers.values.fold(0.0, (a, b) => a + b).abs(),
  );
}

({double c, double q, double v, double field, double energy}) plateCapacitor(
  double area,
  double gap,
  double er,
  double voltage, {
  double? heldCharge,
}) {
  if (area <= 0 || gap <= 0 || er < 1 || gap > .05 * math.sqrt(area)) {
    throw ArgumentError(
      'Require positive geometry, εr≥1 and gap≤5% of plate width',
    );
  }
  final c = epsilon0 * er * area / gap,
      q = heldCharge ?? c * voltage,
      v = q / c;
  return (c: c, q: q, v: v, field: v / gap, energy: q * q / (2 * c));
}

({double voltage, double current, double charge, double energy}) rcState(
  double r,
  double c,
  double source,
  double initial,
  double time,
) {
  if (r <= 0 || c <= 0 || time < 0) {
    throw ArgumentError('Positive R/C and nonnegative time');
  }
  final v = source + (initial - source) * math.exp(-time / (r * c));
  return (
    voltage: v,
    current: (source - v) / r,
    charge: c * v,
    energy: .5 * c * v * v,
  );
}

V3 dipoleField(V3 r, V3 moment, {double exclusion = .08}) {
  if (r.norm < exclusion) {
    throw ArgumentError(
      'Exterior dipole model excludes source and near-field sphere',
    );
  }
  final u = r.unit;
  return (u * (3 * moment.dot(u)) - moment) *
      (mu0 / (4 * math.pi * math.pow(r.norm, 3)));
}

V3 wireField(V3 r, double current, {double radius = .005}) {
  final rho = math.sqrt(r.x * r.x + r.y * r.y);
  if (rho < radius) {
    throw ArgumentError('Long-wire exterior model excludes conductor');
  }
  return V3(-r.y, r.x) * (mu0 * current / (2 * math.pi * rho * rho));
}

double solenoidField(
  double x,
  double turns,
  double length,
  double radius,
  double current,
) {
  if (turns <= 0 || length <= 0 || radius <= 0) {
    throw ArgumentError('Positive coil geometry');
  }
  double end(double z) => z / math.sqrt(radius * radius + z * z);
  return mu0 *
      turns *
      current /
      (2 * length) *
      (end(x + length / 2) - end(x - length / 2));
}

({V3 position, V3 velocity}) borisStep(
  V3 p,
  V3 v,
  double charge,
  double mass,
  V3 b,
  double dt, {
  int? substeps,
}) {
  if (mass <= 0 || dt < 0 || v.norm >= 3e6) {
    throw ArgumentError(
      'Nonrelativistic v<3e6 m/s, positive mass and nonnegative dt',
    );
  }
  final count =
      substeps ?? math.max(1, (charge.abs() * b.norm / mass * dt / .03).ceil());
  final h = dt / count,
      t = b * (charge * h / (2 * mass)),
      s = t * (2 / (1 + t.dot(t)));
  for (int i = 0; i < count; i++) {
    final prime = v + v.cross(t), next = v + prime.cross(s);
    p = p + (v + next) * (h / 2);
    v = next;
  }
  return (position: p, velocity: v);
}

/// Neumann line integral for two separated coaxial finite filament loops.
/// Unequal radii exclude filament intersection even during axial passage.
({double flux, double derivative}) loopFlux(
  double z,
  double sourceRadius,
  double receiverRadius,
  double moment, {
  int samples = 256,
}) {
  if (sourceRadius <= 0 ||
      receiverRadius - sourceRadius < .01 - 1e-12 ||
      samples < 32) {
    throw ArgumentError(
      'Finite-loop radial clearance ≥1 cm; at least 32 quadrature samples',
    );
  }
  double integral = 0, gradient = 0;
  final step = 2 * math.pi / samples;
  for (int i = 0; i < samples; i++) {
    final cos = math.cos((i + .5) * step),
        d2 =
            sourceRadius * sourceRadius +
            receiverRadius * receiverRadius +
            z * z -
            2 * sourceRadius * receiverRadius * cos;
    integral += cos / math.sqrt(d2);
    gradient -= z * cos / math.pow(d2, 1.5);
  }
  final factor =
      mu0 *
      sourceRadius *
      receiverRadius /
      2 *
      moment /
      (math.pi * sourceRadius * sourceRadius) *
      step;
  return (flux: factor * integral, derivative: factor * gradient);
}

({double field, double flux, double force, double airField}) magneticCircuit(
  double turns,
  double current,
  double length,
  double gap,
  double area,
  double er,
) {
  if (turns <= 0 || length <= 0 || gap <= 0 || area <= 0 || er < 1) {
    throw ArgumentError('Positive magnetic geometry/permeability');
  }
  final b = mu0 * turns * current / (length / er + gap),
      air = mu0 * turns * current / (length + gap);
  if (b.abs() > .3) {
    throw ArgumentError(
      'Linear educational core limited to |B|≤0.3 T. Reduce NI or permeability, or enlarge the gap. No saturation curve is implemented.',
    );
  }
  return (
    field: b,
    flux: b * area,
    force: b * b * area / (2 * mu0),
    airField: air,
  );
}

class EMRun {
  final int kind, mode;
  final EMState p;
  final CircuitGraph circuit;
  static const dt = 1 / 120;
  double? heldCharge;
  EMState state = {};
  List<EMState> samples = [], profile = [], alternate = [];
  List<List<V3>> lines = [];
  List<(V3, V3)> arrows = [];
  List<(V3, V3)> contours = [];
  List<V3> trail = [];
  V3 position = V3.zero, velocity = V3.zero;
  CircuitSolution? network;
  String invalid = '';
  int ticks = 0, revision = 0;
  double time = 0;
  bool finished = false;
  double v(String k, [double fallback = 0]) => p[k] ?? fallback;
  bool get dynamicLab =>
      kind == 3 || kind == 7 || kind == 10 || kind == 5 && mode >= 2;
  double get timeScale => kind == 7
      ? 1e-6
      : kind == 5 && mode >= 2
      ? v('resistance') * v('capacitance')
      : 1;
  double get maxTime => kind == 7
      ? 20e-6
      : kind == 10
      ? 3
      : kind == 5 && mode >= 2
      ? 5 * timeScale
      : 30;
  List<ChargeSource> get sources => [
    for (int i = 1; i <= v('count', 2).round(); i++)
      ChargeSource(V3(v('x$i'), v('y$i')), v('q$i')),
  ];
  EMRun(
    this.kind,
    Map<String, double> parameters, {
    this.mode = 0,
    CircuitGraph? graph,
    this.heldCharge,
    EMRun? geometryFrom,
  }) : p = Map.of(parameters),
       circuit = graph?.copy() ?? CircuitGraph.example(0) {
    if (kind < 0 || kind > 11 || p.values.any((v) => !v.isFinite)) {
      throw ArgumentError('Finite supported model inputs required');
    }
    if (kind == 7) velocity = V3(v('vx'), v('vy'), v('vz'));
    calculate();
    buildProfile(geometryFrom: geometryFrom);
    capture();
  }
  void calculate() {
    invalid = '';
    state = {'t': time};
    try {
      switch (kind) {
        case 0:
          final f = coulombForce(
            ChargeSource(V3(-v('distance') / 2, 0), v('q1')),
            ChargeSource(V3(v('distance') / 2, 0), v('q2')),
          );
          state.addAll({
            'force': f.norm,
            'fx': f.x,
            'oppositeFx': -f.x,
            'separation': v('distance'),
          });
        case 1 || 2:
          final e = Electrostatic(sources),
              r = V3(v('probeX'), v('probeY')),
              field = e.field(r),
              potential = e.potential(r);
          state.addAll({
            'field': field.norm,
            'ex': field.x,
            'ey': field.y,
            'potential': potential,
            'energy': v('testCharge') * potential,
            'fx': v('testCharge') * field.x,
            'fy': v('testCharge') * field.y,
          });
          if (kind == 2) {
            const h = 1e-6;
            const dx = V3(h, 0), dy = V3(0, h);
            if ([r + dx, r - dx, r + dy, r - dy].every(e.valid)) {
              final numerical = V3(
                -(e.potential(r + dx) - e.potential(r - dx)) / (2 * h),
                -(e.potential(r + dy) - e.potential(r - dy)) / (2 * h),
              );
              final scale = e.sources.fold(
                0.0,
                (sum, s) =>
                    sum +
                    coulombK *
                        s.charge.abs() /
                        math.pow((r - s.position).norm, 2),
              );
              state.addAll({
                'gradientEx': numerical.x,
                'gradientEy': numerical.y,
                'gradientError': (numerical - field).norm,
                'gradientTolerance': scale * 1e-7,
              });
            }
          }
        case 3:
          if (v('resistance') <= 0 || v('area') <= 0 || v('density') <= 0) {
            throw ArgumentError(
              'Positive R, conductor area and carrier density',
            );
          }
          final i = v('closed') > 0 ? v('voltage') / v('resistance') : 0.0;
          state.addAll({
            'current': i,
            'charge': i * time,
            'power': v('voltage') * i,
            'drift': -i / (v('density') * elementaryCharge * v('area')),
            'voltage': v('closed') > 0 ? v('voltage') : 0,
          });
        case 4:
          network = solveCircuit(circuit);
          if (!network!.valid) {
            invalid = network!.message;
            break;
          }
          final source = circuit.parts.firstWhere((p) => p.type == 'source');
          state.addAll({
            'current': -network!.currents[source.id]!,
            'kclResidual': network!.kclResidual,
            'powerResidual': network!.powerResidual,
          });
        case 5:
          if (mode < 2) {
            final c = plateCapacitor(
              v('area'),
              v('gap'),
              v('epsilonR'),
              v('voltage'),
              heldCharge: mode == 1 ? heldCharge : null,
            );
            heldCharge ??= c.q;
            state.addAll({
              'capacitance': c.c,
              'charge': c.q,
              'voltage': c.v,
              'field': c.field,
              'energy': c.energy,
            });
          } else {
            final s = rcState(
              v('resistance'),
              v('capacitance'),
              mode == 2 ? v('voltage') : 0,
              v('initialV'),
              time,
            );
            state.addAll({
              'voltage': s.voltage,
              'current': s.current,
              'charge': s.charge,
              'energy': s.energy,
              'tau': timeScale,
              'capacitance': v('capacitance'),
            });
          }
        case 6:
          final b = dipoleField(
            V3(v('probeX'), v('probeY')),
            V3(v('moment'), 0),
          );
          state.addAll({'field': b.norm, 'bx': b.x, 'by': b.y});
          if (b.norm > 0) state['compass'] = math.atan2(b.y, b.x);
        case 7:
          if (velocity.norm >= 3e6) {
            throw ArgumentError(
              'Nonrelativistic teaching model requires total speed below 3e6 m/s.',
            );
          }
          final b = V3(0, 0, v('field')),
              force = velocity.cross(b) * v('charge'),
              omega = v('charge').abs() * b.norm / v('mass'),
              perp = math.sqrt(
                velocity.x * velocity.x + velocity.y * velocity.y,
              );
          state.addAll({
            'force': force.norm,
            'fx': force.x,
            'fy': force.y,
            'fz': force.z,
            'speed': velocity.norm,
            'energy': .5 * v('mass') * velocity.dot(velocity),
            'x': position.x,
            'y': position.y,
            'z': position.z,
            'vx': velocity.x,
            'vy': velocity.y,
            'vz': velocity.z,
          });
          if (omega > 0) {
            state.addAll({
              'radius': perp / omega,
              'period': 2 * math.pi / omega,
            });
          }
        case 8:
          final b = wireField(V3(v('probeX'), v('probeY')), v('current'));
          state.addAll({'field': b.norm, 'bx': b.x, 'by': b.y});
          if (b.norm > 0) state['compass'] = math.atan2(b.y, b.x);
        case 9:
          final field = solenoidField(
            v('probe'),
            v('turns'),
            v('length'),
            v('radius'),
            v('current'),
          );
          state['field'] = field;
          if (v('length') / v('radius') >= 10 &&
              v('probe').abs() <= v('length') / 4) {
            state['longField'] = mu0 * v('turns') / v('length') * v('current');
          }
        case 10:
          final z = v('initialZ') + v('velocity') * time,
              s = loopFlux(z, v('sourceRadius'), v('radius'), v('moment')),
              emf = -v('turns') * s.derivative * v('velocity');
          state.addAll({
            'position': z,
            'flux': s.flux,
            'fluxGradient': s.derivative,
            'linkage': v('turns') * s.flux,
            'emf': emf,
            'current': v('closed') > 0 ? emf / v('resistance') : 0,
          });
        case 11:
          final s = magneticCircuit(
            v('turns'),
            v('current'),
            v('length'),
            v('gap'),
            v('area'),
            mode == 1 ? 1 : v('muR'),
          );
          state.addAll({
            'field': s.field,
            'flux': s.flux,
            'force': s.force,
            'airField': s.airField,
            'weight': v('load') * standardGravity,
            'forceWeightRatio': s.force / (v('load') * standardGravity),
          });
      }
    } on ArgumentError catch (e) {
      invalid = e.message.toString();
    }
  }

  void buildProfile({EMRun? geometryFrom}) {
    profile = [];
    alternate = [];
    lines = [];
    arrows = [];
    contours = [];
    if (kind == 1 || kind == 2) {
      Electrostatic? e;
      try {
        e = Electrostatic(sources);
      } on ArgumentError {
        return;
      }
      final reuse =
          geometryFrom != null &&
          geometryFrom.kind == kind &&
          [
            'count',
            'q1',
            'q2',
            'q3',
            'x1',
            'x2',
            'x3',
            'y1',
            'y2',
            'y3',
          ].every((k) => geometryFrom.p[k] == p[k]);
      if (reuse) {
        lines = geometryFrom.lines;
        arrows = geometryFrom.arrows;
        contours = geometryFrom.contours;
      } else if (kind == 1) {
        lines = electricLines(e);
        for (int j = 0; j < 11; j++) {
          for (int i = 0; i < 15; i++) {
            final r = V3(-.42 + .06 * i, -.3 + .06 * j);
            if (e.valid(r)) arrows.add((r, e.field(r)));
          }
        }
      }
      for (int i = 0; i <= 160; i++) {
        final x = -.4 + .8 * i / 160, r = V3(x, v('probeY'));
        if (e.valid(r)) {
          final field = e.field(r);
          profile.add({
            't': x,
            'field': field.norm,
            'ex': field.x,
            'ey': field.y,
            'potential': e.potential(r),
          });
        } else {
          profile.add({'t': x});
        }
      }
      // Marching triangles: each cell is split deterministically; holes stay blank.
      if (reuse || kind == 1) return;
      final potentialGrid = List.generate(
        25,
        (j) => List<double?>.generate(37, (i) {
          final r = V3(-.45 + i * .025, -.3 + j * .025);
          return e!.valid(r) ? e.potential(r) : null;
        }),
      );
      for (final level in [
        -1000.0,
        -500.0,
        -200.0,
        -100.0,
        0.0,
        100.0,
        200.0,
        500.0,
        1000.0,
      ]) {
        for (int j = 0; j < 24; j++) {
          for (int i = 0; i < 36; i++) {
            final corners = [
              V3(-.45 + i * .025, -.3 + j * .025),
              V3(-.425 + i * .025, -.3 + j * .025),
              V3(-.425 + i * .025, -.275 + j * .025),
              V3(-.45 + i * .025, -.275 + j * .025),
            ];
            final raw = [
              potentialGrid[j][i],
              potentialGrid[j][i + 1],
              potentialGrid[j + 1][i + 1],
              potentialGrid[j + 1][i],
            ];
            if (raw.any((v) => v == null)) continue;
            final values = raw.cast<double>();
            for (final tri in [
              [0, 1, 2],
              [0, 2, 3],
            ]) {
              final hits = <V3>[];
              for (int k = 0; k < 3; k++) {
                final a = tri[k],
                    b = tri[(k + 1) % 3],
                    va = values[a] - level,
                    vb = values[b] - level;
                if ((va < 0) != (vb < 0)) {
                  hits.add(
                    corners[a] + (corners[b] - corners[a]) * (va / (va - vb)),
                  );
                }
              }
              if (hits.length == 2) contours.add((hits[0], hits[1]));
            }
          }
        }
      }
      return;
    }
    if (kind == 6) {
      final m = V3(v('moment'), 0);
      if (m.norm > 0) {
        for (int i = 0; i < 14; i++) {
          final angle = -1.4 + 2.8 * (i + .5) / 14;
          final start = V3(math.cos(angle) * .081, math.sin(angle) * .081);
          lines.add(
            traceField(
              start,
              (r) => dipoleField(r, m),
              (r) => r.norm >= .08 && r.x.abs() < .45 && r.y.abs() < .3,
              direction: v('moment') > 0 ? 1 : -1,
              maxSteps: 600,
            ),
          );
        }
      }
    }
    for (int i = 0; i <= 100; i++) {
      final fraction = i / 100;
      EMState? point;
      switch (kind) {
        case 0:
          final r = .08 + .72 * fraction;
          point = {'t': r, 'force': coulombK * v('q1') * v('q2') / (r * r)};
          final q = -5e-6 + 10e-6 * fraction;
          alternate.add({
            't': q,
            'force': coulombK * q * v('q2') / math.pow(v('distance'), 2),
          });
        case 3:
          final voltage = -12 + 24 * fraction,
              i = v('closed') > 0 ? voltage / v('resistance') : 0.0;
          point = {
            't': voltage,
            'current': i,
            'charge': i * time,
            'power': voltage * i,
          };
        case 4:
          if (i % 4 != 0) continue;
          final g = circuit.copy(),
              source = g.parts.where((p) => p.type == 'source').firstOrNull;
          if (source == null) continue;
          source.value = 24 * fraction;
          final s = solveCircuit(g);
          if (s.valid) {
            point = {'t': source.value, 'current': -s.currents[source.id]!};
          }
        case 5:
          if (mode >= 2) {
            final t = 5 * timeScale * fraction,
                s = rcState(
                  v('resistance'),
                  v('capacitance'),
                  mode == 2 ? v('voltage') : 0,
                  v('initialV'),
                  t,
                );
            point = {
              't': t,
              'voltage': s.voltage,
              'current': s.current,
              'charge': s.charge,
              'energy': s.energy,
            };
          } else {
            final d = .0002 + .0018 * fraction;
            if (d <= .05 * math.sqrt(v('area'))) {
              final c = plateCapacitor(
                v('area'),
                d,
                v('epsilonR'),
                v('voltage'),
                heldCharge: mode == 1 ? heldCharge : null,
              );
              point = {
                't': d,
                'capacitance': c.c,
                'voltage': c.v,
                'energy': c.energy,
              };
            }
          }
        case 6:
          final r = .081 + .319 * fraction;
          point = {
            't': r,
            'field': dipoleField(V3(r, 0), V3(v('moment'), 0)).norm,
          };
        case 8:
          final r = .01 + .19 * fraction;
          point = {'t': r, 'field': wireField(V3(r, 0), v('current')).norm};
        case 9:
          final x = -.6 + 1.2 * fraction;
          point = {
            't': x,
            'field': solenoidField(
              x,
              v('turns'),
              v('length'),
              v('radius'),
              v('current'),
            ),
          };
        case 10:
          final z = -.25 + .5 * fraction,
              s = loopFlux(z, v('sourceRadius'), v('radius'), v('moment')),
              emf = -v('turns') * s.derivative * v('velocity');
          point = {
            't': z,
            'emf': emf,
            'flux': s.flux,
            'current': v('closed') > 0 ? emf / v('resistance') : 0,
          };
        case 11:
          final gap = .001 + .019 * fraction;
          try {
            final s = magneticCircuit(
              v('turns'),
              v('current'),
              v('length'),
              gap,
              v('area'),
              mode == 1 ? 1 : v('muR'),
            );
            point = {'t': gap, 'force': s.force, 'field': s.field};
          } on ArgumentError {
            point = {'t': gap};
          }
      }
      if (point != null) profile.add(point);
    }
  }

  void capture() {
    if (samples.isNotEmpty && samples.last['t'] == time) samples.removeLast();
    samples.add(Map.of(state));
    if (samples.length > 301) samples.removeAt(0);
  }

  void refresh() {
    calculate();
    capture();
    revision++;
  }

  void step({bool captureNow = false}) {
    if (!dynamicLab || finished || invalid.isNotEmpty) return;
    ticks++;
    time = ticks * dt * timeScale;
    if (kind == 7) {
      final s = borisStep(
        position,
        velocity,
        v('charge'),
        v('mass'),
        V3(0, 0, v('field')),
        dt * timeScale,
      );
      position = s.position;
      velocity = s.velocity;
    }
    if (ticks % 4 == 0 || captureNow) {
      calculate();
      if (ticks % 8 == 0 || captureNow) capture();
      if (kind == 7) {
        trail.add(position);
        if (trail.length > 601) trail.removeAt(0);
      }
      revision++;
    }
    if (time >= maxTime ||
        kind == 10 && (v('initialZ') + v('velocity') * time).abs() > .35) {
      finished = true;
      refresh();
    }
  }

  void seek(double seconds) {
    if (!dynamicLab) {
      refresh();
      return;
    }
    final target = (seconds / (dt * timeScale)).round().clamp(
      0,
      (maxTime / (dt * timeScale)).round(),
    );
    while (ticks < target && !finished && invalid.isEmpty) {
      step();
    }
    refresh();
  }
}
