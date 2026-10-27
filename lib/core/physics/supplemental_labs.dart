import 'dart:math' as m;

const supplementalVersion = 'supplemental-1.0';

class LabInput {
  final String key, label, unit;
  final double min, max, initial;
  const LabInput(
    this.key,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.initial,
  );
}

class SupplementalLab {
  final String id,
      title,
      principle,
      equation,
      limits,
      task,
      quantity,
      unit,
      sweep;
  final int studio, kind;
  final List<LabInput> inputs;
  const SupplementalLab(
    this.kind,
    this.studio,
    this.id,
    this.title,
    this.principle,
    this.equation,
    this.limits,
    this.task,
    this.quantity,
    this.unit,
    this.sweep,
    this.inputs,
  );
  String get stage => switch (kind) {
    2 || 4 || 8 || 19 => 'Foundation',
    5 || 10 || 16 || 17 => 'Advanced',
    _ => 'Intermediate',
  };
  String get resultLabel => switch (kind) {
    0 => 'Moment of inertia',
    3 || 19 => 'Extension',
    9 => 'Detector voltage',
    10 => 'RMS current',
    11 => 'Secondary RMS voltage',
    12 => 'Mean output voltage',
    13 => 'Equilibrium temperature',
    15 => 'Capillary height',
    18 => 'Parallax angle',
    _ => quantity,
  };
  String unitFor(String key) => switch (key) {
    'inertia' => 'kg·m²',
    'angularAcceleration' => 'rad/s²',
    'angularSpeed' => 'rad/s',
    'angle' => kind == 5 ? 'rad' : '°',
    'energy' || 'hotHeat' || 'coldHeat' || 'calorimeterHeat' => 'J',
    'speed' => 'm/s',
    'acceleration' => 'm/s²',
    'distance' ||
    'height' ||
    'length' ||
    'closestApproach' ||
    'finalLength' => 'm',
    'force' => 'N',
    'stress' => 'Pa',
    'area' => 'm²',
    'time' || 'period' => 's',
    'torque' => 'N·m',
    'frequency' || 'resonance' || 'rippleFrequency' => 'Hz',
    'envelope' || 'pressure' => 'Pa',
    'intensity' => 'W/m²',
    'resistance' || 'balancedResistance' || 'impedance' => 'Ω',
    'voltage' ||
    'leftVoltage' ||
    'rightVoltage' ||
    'rmsVoltage' ||
    'averageVoltage' => 'V',
    'current' || 'rmsCurrent' || 'primaryCurrent' || 'secondaryCurrent' => 'A',
    'power' => 'W',
    'phase' => 'rad',
    'temperature' => 'K',
    'parallax' || 'fullShift' => 'mas',
    _ => '',
  };
  String get source => switch (studio) {
    2 || 3 || 7 || 8 || 14 => 'OpenStax University Physics Volume 1: rotation, elasticity, oscillations and waves. https://openstax.org/details/books/university-physics-volume-1',
    9 || 15 => 'OpenStax University Physics Volume 3: optics, relativity and nuclear physics. https://openstax.org/details/books/university-physics-volume-3',
    16 => 'OpenStax Astronomy 2e: Surveying the Stars. https://openstax.org/books/astronomy-2e/pages/19-2-surveying-the-stars',
    _ => 'OpenStax University Physics Volume 2: thermal physics, circuits and optics. https://openstax.org/details/books/university-physics-volume-2',
  };
  Map<String, double> get defaults => {
    for (final c in inputs) c.key: c.initial,
  };
  bool get dynamicModel => [0, 1, 4, 5, 6, 10, 11, 12, 14].contains(kind);
  String get graphKey => switch (kind) {
    0 => 'angularSpeed',
    1 => 'speed',
    4 => 'height',
    5 => 'angle',
    6 => 'envelope',
    10 => 'current',
    11 || 12 => 'voltage',
    _ => quantity,
  };
  String get graphUnit => switch (kind) {
    0 => 'rad/s',
    1 => 'm/s',
    4 => 'm',
    5 => 'rad',
    6 => 'Pa',
    _ => unit,
  };
  double duration(Map<String, double> p) => switch (kind) {
    1 => m.sqrt(
      2 * p['length']! / (9.80665 * m.sin(p['incline']! * m.pi / 180) / 1.4),
    ),
    4 => m.sqrt(2 * p['height']! / p['gravity']!),
    5 => 4 * m.pi * m.sqrt(p['inertia']! / p['torsion']!),
    6 => 2,
    10 || 11 || 12 => 4 / p['frequency']!,
    14 =>
      p['mass']! *
          (-2100 * p['initial']! + 334000 + 418600 + 2256000) /
          p['power']!,
    _ => 10,
  };
  String invalid(Map<String, double> p) {
    if (p.length != inputs.length ||
        inputs.any(
          (c) =>
              p[c.key] == null ||
              !p[c.key]!.isFinite ||
              p[c.key]! < c.min ||
              p[c.key]! > c.max,
        )) {
      return 'Inputs outside the documented model range.';
    }
    if (inputs.any(
      (c) =>
          ['primary', 'secondary', 'charge'].contains(c.key) &&
          p[c.key] != p[c.key]!.roundToDouble(),
    )) {
      return 'Turns and nuclear charge must be whole numbers.';
    }
    if (kind == 1 &&
        p['friction']! < .4 / 1.4 * m.tan(p['incline']! * m.pi / 180)) {
      return 'Insufficient static friction for pure rolling. Increase friction or reduce the incline.';
    }
    if (kind == 3 &&
        p['force']! / (m.pi * p['radius']! * p['radius']! * p['modulus']!) >
            .005) {
      return 'Strain exceeds the 0.5% small-strain teaching limit. Reduce force or increase radius.';
    }
    return '';
  }

  Map<String, double> evaluate(Map<String, double> p, double time) {
    if (invalid(p).isNotEmpty || !time.isFinite || time < 0) return {};
    double v(String k) => p[k]!;
    final t = time.clamp(0, duration(p)), pi = m.pi;
    switch (kind) {
      case 0:
        final i = .5 * v('mass') * v('radius') * v('radius'),
            a = v('torque') / i;
        return {
          'inertia': i,
          'angularAcceleration': a,
          'angularSpeed': a * t,
          'angle': .5 * a * t * t,
          'energy': .5 * i * a * a * t * t,
        };
      case 1:
        final a = 9.80665 * m.sin(v('incline') * pi / 180) / 1.4,
            end = m.sqrt(2 * v('length') / a),
            u = m.min(t, end),
            speed = a * u;
        return {
          'acceleration': a,
          'distance': .5 * a * u * u,
          'speed': speed,
          'angularSpeed': speed / v('radius'),
          'energy': .7 * v('mass') * speed * speed,
          'requiredFriction': .4 / 1.4 * m.tan(v('incline') * pi / 180),
        };
      case 2:
        return {
          'force': v('stiffness') * v('extension'),
          'energy': .5 * v('stiffness') * v('extension') * v('extension'),
        };
      case 3:
        final area = pi * v('radius') * v('radius'),
            stress = v('force') / area,
            strain = stress / v('modulus');
        return {
          'length': strain * v('length'),
          'stress': stress,
          'strain': strain,
          'area': area,
        };
      case 4:
        return {
          'height': m.max(0, v('height') - .5 * v('gravity') * t * t),
          'speed': v('gravity') * t,
          'time': duration(p),
        };
      case 5:
        final w = m.sqrt(v('torsion') / v('inertia')),
            a = v('amplitude') * pi / 180,
            angle = a * m.cos(w * t),
            speed = -a * w * m.sin(w * t);
        return {
          'angle': angle,
          'angularSpeed': speed,
          'period': 2 * pi / w,
          'energy': .5 * v('torsion') * a * a,
          'torque': -v('torsion') * angle,
        };
      case 6:
        return {
          'frequency': v('difference'),
          'envelope':
              2 * v('amplitude') * m.cos(pi * v('difference') * t).abs(),
          'pressure':
              v('amplitude') *
              (m.sin(2 * pi * v('frequency') * t) +
                  m.sin(2 * pi * (v('frequency') + v('difference')) * t)),
        };
      case 7:
        final transmission = m.pow(m.cos(v('angle') * pi / 180), 2).toDouble();
        return {
          'intensity': .5 * v('intensity') * transmission,
          'transmission': transmission / 2,
        };
      case 8:
        final r =
            v('resistivity') * v('length') / (pi * v('radius') * v('radius'));
        return {
          'resistance': r,
          'voltage': v('current') * r,
          'power': v('current') * v('current') * r,
        };
      case 9:
        final left = v('supply') * v('r2') / (v('r1') + v('r2')),
            right = v('supply') * v('unknown') / (v('r3') + v('unknown'));
        return {
          'voltage': left - right,
          'leftVoltage': left,
          'rightVoltage': right,
          'balancedResistance': v('r2') * v('r3') / v('r1'),
        };
      case 10:
        final w = 2 * pi * v('frequency'),
            x = w * v('inductance') - 1 / (w * v('capacitance')),
            z = m.sqrt(v('resistance') * v('resistance') + x * x),
            i = v('supply') / z,
            phase = m.atan2(x, v('resistance'));
        return {
          'rmsCurrent': i,
          'current': m.sqrt2 * i * m.sin(w * t - phase),
          'impedance': z,
          'phase': phase,
          'power': i * i * v('resistance'),
          'resonance':
              1 / (2 * pi * m.sqrt(v('inductance') * v('capacitance'))),
        };
      case 11:
        final ratio = v('secondary') / v('primary'),
            rms = v('supply') * ratio,
            i = rms / v('load');
        return {
          'rmsVoltage': rms,
          'voltage': m.sqrt2 * rms * m.sin(2 * pi * v('frequency') * t),
          'secondaryCurrent': i,
          'primaryCurrent': i * ratio,
          'power': rms * i,
        };
      case 12:
        final peak = m.sqrt2 * v('supply'),
            voltage = (peak * m.sin(2 * pi * v('frequency') * t)).abs();
        return {
          'averageVoltage': 2 * peak / pi,
          'voltage': voltage,
          'current': voltage / v('load'),
          'rippleFrequency': 2 * v('frequency'),
          'rippleFactor': m.sqrt(pi * pi / 8 - 1),
        };
      case 13:
        final ch = v('hotMass') * v('hotSpecificHeat'),
            cc = v('coldMass') * 4186,
            cal = v('calorimeter'),
            f = (ch * v('hot') + (cc + cal) * v('cold')) / (ch + cc + cal);
        return {
          'temperature': f + 273.15,
          'hotHeat': ch * (f - v('hot')),
          'coldHeat': cc * (f - v('cold')),
          'calorimeterHeat': cal * (f - v('cold')),
        };
      case 14:
        final q = v('power') * t,
            mass = v('mass'),
            q1 = -mass * 2100 * v('initial'),
            q2 = q1 + mass * 334000,
            q3 = q2 + mass * 418600;
        final c = q < q1
            ? v('initial') + q / (mass * 2100)
            : q < q2
            ? 0.0
            : q < q3
            ? (q - q2) / (mass * 4186)
            : 100.0;
        return {
          'temperature': c + 273.15,
          'energy': q,
          'meltFraction': ((q - q1) / (mass * 334000)).clamp(0, 1),
          'vapourFraction': ((q - q3) / (mass * 2256000)).clamp(0, 1),
        };
      case 15:
        return {
          'length':
              2 *
              v('tension') *
              m.cos(v('angle') * pi / 180) /
              (v('density') * 9.80665 * v('radius')),
        };
      case 16:
        final a =
                8.9875517923e9 *
                v('charge') *
                2 *
                1.602176634e-19 *
                1.602176634e-19 /
                (2 * v('energy') * 1.602176634e-13),
            b = v('impact') * 1e-15;
        return {
          'angle': 2 * m.atan2(a, b) * 180 / pi,
          'closestApproach': a + m.sqrt(a * a + b * b),
        };
      case 17:
        final gamma = 1 / m.sqrt(1 - v('beta') * v('beta'));
        return {
          'time': gamma * v('properTime'),
          'length': v('properLength') / gamma,
          'gamma': gamma,
        };
      case 18:
        final parallax =
            m.atan(v('baseline') / (v('distance') * 206264.80624709636)) *
            180 /
            pi *
            3600000;
        return {'parallax': parallax, 'fullShift': 2 * parallax};
      case 19:
        final strain = v('coefficient') * v('temperatureChange');
        return {
          'length': v('length') * strain,
          'finalLength': v('length') * (1 + strain),
          'strain': strain,
        };
      default:
        return {};
    }
  }

  List<Map<String, double>> curve(Map<String, double> p) {
    final c = inputs.firstWhere((c) => c.key == sweep);
    return [for (int i = 0; i <= 240; i++) _sample(p, c, i / 240)]
        .where((s) => s.length > 1)
        .toList();
  }

  Map<String, double> _sample(Map<String, double> p, LabInput c, double f) {
    var x = dynamicModel ? duration(p) * f : c.min + (c.max - c.min) * f;
    if (['primary', 'secondary', 'charge'].contains(c.key)) {
      x = x.roundToDouble();
    }
    final state = evaluate({
      ...p,
      if (!dynamicModel) c.key: x,
    }, dynamicModel ? x : 0);
    return state.isEmpty ? {} : {...state, 't': x};
  }
}

const supplementalLabs = <SupplementalLab>[
  SupplementalLab(
    0,
    2,
    's02-e06',
    'Rotational Inertia',
    'A solid disk resists angular acceleration according to its moment of inertia.',
    r'I=\frac12mR^2,\quad\alpha=\tau/I',
    'Uniform solid disk, fixed axis, constant torque, initially at rest; no drag.',
    'Double the radius. Predict how angular acceleration changes.',
    'inertia',
    'kg·m²',
    'radius',
    [
      LabInput('mass', 'Disk mass', 'kg', .1, 10, 1),
      LabInput('radius', 'Disk radius', 'm', .05, 1, .3),
      LabInput('torque', 'Applied torque', 'N·m', 0, 2, .2),
    ],
  ),
  SupplementalLab(
    1,
    2,
    's02-e07',
    'Rolling Motion',
    'A solid sphere shares gravitational energy between translation and rotation.',
    r'a=\frac{g\sin\theta}{1+2/5}',
    'Solid sphere rolling without slipping. Static friction threshold is checked; sliding is outside this model.',
    'Reduce friction until pure rolling becomes invalid; restore it and compare ramp angles.',
    'speed',
    'm/s',
    'incline',
    [
      LabInput('mass', 'Sphere mass', 'kg', .2, 5, 1),
      LabInput('radius', 'Sphere radius', 'm', .05, .25, .1),
      LabInput('incline', 'Ramp angle', '°', 5, 45, 20),
      LabInput('length', 'Ramp length', 'm', .5, 5, 2),
      LabInput('friction', 'Static friction coefficient', '', 0, 1, .5),
    ],
  ),
  SupplementalLab(
    2,
    2,
    's02-e08',
    'Hooke’s Law',
    'Restoring force magnitude is proportional to spring extension.',
    r'F=kx,\quad U=\frac12kx^2',
    'Ideal linear spring; force shown is magnitude. No material-specific yield or breaking point is modeled.',
    'Double extension and compare the force and stored energy.',
    'force',
    'N',
    'extension',
    [
      LabInput('stiffness', 'Spring stiffness', 'N/m', 10, 200, 50),
      LabInput('extension', 'Extension', 'm', 0, .2, .08),
    ],
  ),
  SupplementalLab(
    3,
    2,
    's02-e09',
    'Young’s Modulus',
    'Tensile extension depends on stress, cross section and elastic modulus.',
    r'\Delta L=\frac{FL}{AE}',
    'Uniform wire, small strain at most 0.5%; constant modulus. This limit is a teaching domain, not a real yield measurement.',
    'Double wire radius and predict the change in extension.',
    'length',
    'm',
    'force',
    [
      LabInput('force', 'Tensile force', 'N', 0, 150, 50),
      LabInput('length', 'Original length', 'm', .1, 2, 1),
      LabInput('radius', 'Wire radius', 'm', .0002, .002, .0005),
      LabInput('modulus', 'Young’s modulus', 'Pa', 1e10, 2.2e11, 2e11),
    ],
  ),
  SupplementalLab(
    4,
    3,
    's03-e06',
    'Free Fall',
    'In vacuum, objects released from rest gain speed under constant gravity.',
    r'h(t)=h_0-\frac12gt^2',
    'Constant gravity, no air resistance, released from rest. Model ends at first ground contact; no rebound.',
    'Compare two release heights and predict the impact speed.',
    'speed',
    'm/s',
    'height',
    [
      LabInput('height', 'Release height', 'm', 1, 100, 20),
      LabInput('gravity', 'Gravity', 'm/s²', 1, 20, 9.80665),
    ],
  ),
  SupplementalLab(
    5,
    7,
    's07-e06',
    'Torsional Pendulum',
    'A twisting suspension supplies restoring torque proportional to angular displacement.',
    r'T=2\pi\sqrt{I/\kappa}',
    'Linear torsion, small angles, no damping. Playback covers two periods in ten seconds.',
    'Multiply inertia by four and predict the new period.',
    'period',
    's',
    'inertia',
    [
      LabInput('inertia', 'Moment of inertia', 'kg·m²', .001, .1, .02),
      LabInput('torsion', 'Torsion constant', 'N·m/rad', .001, 1, .1),
      LabInput('amplitude', 'Initial angle', '°', 1, 20, 10),
    ],
  ),
  SupplementalLab(
    6,
    8,
    's08-e06',
    'Beats',
    'Nearby frequencies superpose to produce a slowly changing amplitude envelope.',
    r'f_b=|f_2-f_1|',
    'Equal-amplitude coherent tones; graph shows the envelope, not an undersampled carrier. Pressure is a model, not calibrated sound output.',
    'Set frequency separation to zero, then increase it and count envelope pulses.',
    'frequency',
    'Hz',
    'difference',
    [
      LabInput('frequency', 'First frequency', 'Hz', 100, 500, 220),
      LabInput('difference', 'Frequency separation', 'Hz', 0, 20, 3),
      LabInput('amplitude', 'Each pressure amplitude', 'Pa', .01, 1, .2),
    ],
  ),
  SupplementalLab(
    7,
    9,
    's09-e06',
    'Polarization',
    'An analyzer transmits the squared projection of polarized light.',
    r'I=\frac{I_0}{2}\cos^2\theta',
    'Unpolarized incident light; two ideal linear polarizers. First filter transmits half; no absorption beyond ideal projection.',
    'Rotate the analyzer from parallel to crossed axes and predict the transmitted intensity.',
    'intensity',
    'W/m²',
    'angle',
    [
      LabInput('intensity', 'Incident intensity', 'W/m²', 1, 100, 60),
      LabInput('angle', 'Analyzer angle', '°', 0, 180, 45),
    ],
  ),
  SupplementalLab(
    8,
    10,
    's10-e06',
    'Wire Resistivity',
    'Resistance increases with length and decreases with cross-sectional area.',
    r'R=\rho L/(\pi r^2)',
    'Uniform cylindrical wire, prescribed constant resistivity, ideal DC current source. Self-heating and contact resistance omitted.',
    'Double radius and compare resistance and dissipated power.',
    'resistance',
    'Ω',
    'length',
    [
      LabInput('resistivity', 'Resistivity', 'Ω·m', 1.68e-8, 1e-6, 1.68e-8),
      LabInput('length', 'Wire length', 'm', .1, 10, 2),
      LabInput('radius', 'Wire radius', 'm', .0001, .002, .0005),
      LabInput('current', 'Source current', 'A', 0, 5, 1),
    ],
  ),
  SupplementalLab(
    9,
    10,
    's10-e07',
    'Wheatstone Bridge',
    'A null detector compares two resistor-divider midpoint potentials.',
    r'R_x=R_2R_3/R_1',
    'R1 above R2 on left, R3 above Rx on right. Infinite detector impedance; no galvanometer current is inferred.',
    'Tune the unknown resistance until the detector voltage reaches zero.',
    'voltage',
    'V',
    'unknown',
    [
      LabInput('r1', 'Left upper R1', 'Ω', 10, 1000, 100),
      LabInput('r2', 'Left lower R2', 'Ω', 10, 1000, 200),
      LabInput('r3', 'Right upper R3', 'Ω', 10, 1000, 150),
      LabInput('unknown', 'Right lower Rx', 'Ω', 10, 1000, 300),
      LabInput('supply', 'Supply voltage', 'V', 1, 12, 6),
    ],
  ),
  SupplementalLab(
    10,
    10,
    's10-e08',
    'AC RLC Circuits',
    'Inductive and capacitive reactance set current amplitude and phase.',
    r'Z=\sqrt{R^2+(\omega L-1/(\omega C))^2}',
    'Series RLC sinusoidal steady state; supply is RMS. No switching transient. Four cycles shown in ten seconds of playback.',
    'Tune frequency toward the reported resonance and compare RMS current.',
    'rmsCurrent',
    'A',
    'frequency',
    [
      LabInput('supply', 'Supply RMS voltage', 'V', 1, 120, 12),
      LabInput('frequency', 'Frequency', 'Hz', 5, 500, 50),
      LabInput('resistance', 'Resistance', 'Ω', 1, 200, 30),
      LabInput('inductance', 'Inductance', 'H', .01, 1, .1),
      LabInput('capacitance', 'Capacitance', 'F', 1e-6, 100e-6, 100e-6),
    ],
  ),
  SupplementalLab(
    11,
    11,
    's11-e06',
    'Transformer',
    'AC voltage follows the turns ratio while ideal power is conserved.',
    r'V_s/V_p=N_s/N_p',
    'Ideal transformer with resistive load; no copper loss, core loss, saturation or magnetizing current. Voltages are RMS.',
    'Double secondary turns and compare voltage and primary current.',
    'rmsVoltage',
    'V',
    'secondary',
    [
      LabInput('supply', 'Primary RMS voltage', 'V', 1, 24, 12),
      LabInput('primary', 'Primary turns', '', 100, 2000, 500),
      LabInput('secondary', 'Secondary turns', '', 100, 2000, 1000),
      LabInput('frequency', 'AC frequency', 'Hz', 20, 100, 50),
      LabInput('load', 'Load resistance', 'Ω', 10, 1000, 100),
    ],
  ),
  SupplementalLab(
    12,
    12,
    's12-e06',
    'Full-wave Rectifier',
    'A diode bridge converts both AC half-cycles into a single output polarity.',
    r'v_o=|V_{pk}\sin\omega t|',
    'Ideal zero-drop bridge, resistive load, no smoothing capacitor. Pulsating DC is not a constant regulated output.',
    'Compare input frequency with ripple frequency and mean output voltage.',
    'averageVoltage',
    'V',
    'supply',
    [
      LabInput('supply', 'Input RMS voltage', 'V', 1, 24, 12),
      LabInput('frequency', 'Input frequency', 'Hz', 20, 100, 50),
      LabInput('load', 'Load resistance', 'Ω', 10, 1000, 100),
    ],
  ),
  SupplementalLab(
    13,
    13,
    's13-e06',
    'Calorimetry',
    'Heat lost by a hot body equals heat gained by water and the calorimeter.',
    r'\sum_i C_i(T_f-T_i)=0',
    'Adiabatic mixing at ordinary pressure, no phase change, constant heat capacities. Calorimeter starts at cold-water temperature.',
    'Include calorimeter heat capacity and explain why equilibrium temperature changes.',
    'temperature',
    'K',
    'hotMass',
    [
      LabInput('hotMass', 'Hot body mass', 'kg', .02, 1, .2),
      LabInput('coldMass', 'Cold water mass', 'kg', .02, 1, .2),
      LabInput(
        'hotSpecificHeat',
        'Hot body specific heat',
        'J/(kg·K)',
        400,
        4200,
        900,
      ),
      LabInput('hot', 'Hot body temperature', '°C', 50, 90, 80),
      LabInput('cold', 'Cold water temperature', '°C', 10, 40, 20),
      LabInput('calorimeter', 'Calorimeter heat capacity', 'J/K', 0, 200, 50),
    ],
  ),
  SupplementalLab(
    14,
    13,
    's13-e07',
    'Heating Curve & Latent Heat',
    'Energy can change phase while temperature remains constant.',
    r'Q=mc\Delta T,\quad Q=mL',
    'Pure ice/water at approximately 1 atm, constant heater power, no loss. c_ice=2100, c_water=4186 J/(kg K), Lf=334000, Lv=2256000 J/kg. Stops at complete vaporization.',
    'Observe the 0°C and 100°C plateaus; compare energy and duration at each transition.',
    'temperature',
    'K',
    'mass',
    [
      LabInput('mass', 'Water / ice mass', 'kg', .1, 1, .2),
      LabInput('power', 'Heater power', 'W', 50, 1000, 500),
      LabInput('initial', 'Initial ice temperature', '°C', -30, 0, -10),
    ],
  ),
  SupplementalLab(
    15,
    14,
    's14-e06',
    'Capillary Rise',
    'Surface tension and contact angle can raise or depress a narrow liquid column.',
    r'h=2\gamma\cos\theta/(\rho gr)',
    'Static narrow circular capillary; uniform surface tension, negligible meniscus-volume correction. Negative height means depression.',
    'Cross a 90° contact angle and explain the change from rise to depression.',
    'length',
    'm',
    'radius',
    [
      LabInput('tension', 'Surface tension', 'N/m', .02, .08, .072),
      LabInput('density', 'Liquid density', 'kg/m³', 700, 1400, 1000),
      LabInput('radius', 'Tube radius', 'm', .00005, .0005, .0002),
      LabInput('angle', 'Contact angle', '°', 0, 150, 20),
    ],
  ),
  SupplementalLab(
    16,
    15,
    's15-e06',
    'Rutherford Scattering',
    'Coulomb repulsion deflects an alpha particle near a positive nucleus.',
    r'\theta=2\tan^{-1}(kZze^2/(2Eb))',
    'Classical point-charge, fixed nucleus, alpha charge +2e; no recoil, electron screening or nuclear force. Drawing shows asymptotes, not a computed trajectory.',
    'Reduce impact parameter toward zero and predict the scattering angle.',
    'angle',
    '°',
    'impact',
    [
      LabInput('charge', 'Nuclear charge Z', '', 20, 79, 79),
      LabInput('energy', 'Alpha kinetic energy', 'MeV', 1, 5, 5),
      LabInput('impact', 'Impact parameter', 'fm', 0, 100, 40),
    ],
  ),
  SupplementalLab(
    17,
    15,
    's15-e07',
    'Time Dilation & Length Contraction',
    'Inertial observers relate proper intervals through the Lorentz factor.',
    r'\gamma=(1-\beta^2)^{-1/2},\quad t=\gamma\tau,\quad L=L_0/\gamma',
    'Special relativity, inertial frames, speed below c. Length is parallel to motion with endpoints measured simultaneously in the observer frame.',
    'Compare time dilation and length contraction at 0.6c and 0.8c.',
    'time',
    's',
    'beta',
    [
      LabInput('beta', 'Speed / speed of light', '', 0, .99, .6),
      LabInput('properTime', 'Proper time', 's', 1, 20, 5),
      LabInput('properLength', 'Proper length', 'm', .1, 10, 4),
    ],
  ),
  SupplementalLab(
    18,
    16,
    's16-e06',
    'Stellar Parallax',
    'Nearby stars shift against distant background stars as the observer moves.',
    r'p=\tan^{-1}(B/d)',
    'Baseline B is orbital radius in AU. Parallax is HALF the shift between opposite positions; standard d(pc)=1/p(arcsec) uses B=1 AU. Diagram angles exaggerated.',
    'Double distance and compare parallax; distinguish full shift from half angle.',
    'parallax',
    'mas',
    'distance',
    [
      LabInput('distance', 'Star distance', 'pc', 1, 1000, 10),
      LabInput('baseline', 'Orbital radius', 'AU', .5, 2, 1),
    ],
  ),
  SupplementalLab(
    19,
    13,
    's13-e08',
    'Thermal Expansion',
    'A uniform rod expands approximately in proportion to temperature change.',
    r'\Delta L=\alpha L_0\Delta T',
    'Uniform isotropic rod, constant linear expansion coefficient, freely expanding without stress. Drawing exaggerates extension.',
    'Double original length and compare extension at the same temperature change.',
    'length',
    'm',
    'temperatureChange',
    [
      LabInput('length', 'Original rod length', 'm', .1, 2, 1),
      LabInput(
        'coefficient',
        'Expansion coefficient',
        'K⁻¹',
        5e-6,
        25e-6,
        12e-6,
      ),
      LabInput('temperatureChange', 'Temperature increase', 'K', 0, 200, 100),
    ],
  ),
];
SupplementalLab supplementalById(String id) =>
    supplementalLabs.firstWhere((l) => l.id == id);
