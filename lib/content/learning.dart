import '../core/physics/supplemental_labs.dart';

import 'dart:math' as math;

import 'catalog.dart';
import '../core/physics/measurement.dart';
import '../core/physics/dynamics.dart' show standardGravity, dynamicsVersion;
import '../core/physics/waves_optics.dart' show waveOpticsVersion;
import '../core/physics/advanced.dart';
import '../core/physics/electromagnetism.dart';
import '../core/physics/electronics_thermal.dart';
import '../core/physics/fluid_modern.dart';
import '../core/physics/astronomy.dart';

const learningVersion = 'learning-tools-8.0';
List<Entry> get labInventory => allEntries.where((e) => !e.tool).toList();
const groups = [
  'Measurement',
  'Motion and forces',
  'Energy',
  'Waves and optics',
  'Electricity and magnetism',
  'Matter and thermal physics',
  'Modern physics and astronomy',
];
int groupFor(int studio) => switch (studio) {
  1 => 0,
  2 || 3 || 4 => 1,
  5 || 6 || 7 => 2,
  8 || 9 => 3,
  10 || 11 || 12 => 4,
  13 || 14 => 5,
  _ => 6,
};
String apparatusFor(Entry e) => switch (e.studioIndex) {
  1 => 'Measuring instrument',
  2 || 3 || 4 || 5 || 7 => 'Mechanical apparatus',
  6 || 16 => 'Astronomical model',
  8 => 'Wave apparatus',
  9 => 'Optical apparatus',
  10 || 11 || 12 => 'Electrical apparatus',
  13 => 'Thermal apparatus',
  14 => 'Fluid apparatus',
  _ => 'Quantum / nuclear model',
};
String stageFor(Entry e) => e.supplemental
    ? supplementalById(e.id).stage
    : ['Foundation', 'Intermediate', 'Advanced'][e.index ~/ 2];
List<String> tagsFor(Entry e) => [
  groups[groupFor(e.studioIndex)],
  studios[e.studioIndex].title,
  apparatusFor(e),
  stageFor(e),
];
List<Entry> filterLabs({
  String query = '',
  int studio = -1,
  String apparatus = '',
  String stage = '',
  Set<String>? onlyIds,
}) => labInventory
    .where(
      (e) =>
          (studio < 0 || e.studioIndex == studio) &&
          (apparatus.isEmpty || apparatusFor(e) == apparatus) &&
          (stage.isEmpty || stageFor(e) == stage) &&
          (onlyIds == null || onlyIds.contains(e.id)) &&
          ('${e.title} ${e.principle} ${tagsFor(e).join(' ')}')
              .toLowerCase()
              .contains(query.toLowerCase()),
    )
    .toList();

class ConceptEdge {
  final String id, from, to, equation, explanation, assumptions, investigation;
  final List<String> labs;
  const ConceptEdge(
    this.id,
    this.from,
    this.to,
    this.equation,
    this.explanation,
    this.assumptions,
    this.investigation,
    this.labs,
  );
}

const conceptEdges = [
  ConceptEdge(
    'force-acceleration',
    'Force',
    'Acceleration',
    'ΣF=ma',
    'Net force changes momentum; constant mass gives acceleration.',
    'Inertial frame, constant mass, valid contact conditions.',
    'Double force at fixed mass, then double mass.',
    ['s02-e00', 's04-e01'],
  ),
  ConceptEdge(
    'work-energy',
    'Work',
    'Kinetic energy',
    'Wnet=ΔK',
    'Net work changes kinetic energy.',
    'Classical motion; account for every force doing work.',
    'Compare positive and negative work with speed change.',
    ['s05-e00', 's05-e01', 's03-e03'],
  ),
  ConceptEdge(
    'gradient-field',
    'Potential',
    'Field',
    'E=−∇V; g=−∇Φ',
    'A potential gradient sets the corresponding conservative field.',
    'Electrostatic / Newtonian gravity, exterior source regions.',
    'Compare doubled-distance fields with their potentials.',
    ['s10-e02', 's06-e01', 's10-e01'],
  ),
  ConceptEdge(
    'oscillation-wave',
    'Oscillation',
    'Waves',
    'v=fλ',
    'Coupled disturbances can propagate; local oscillation and propagation differ.',
    'Linear medium, a defined phase speed.',
    'Compare a local oscillator period with fixed-end standing modes.',
    ['s07-e00', 's08-e03'],
  ),
  ConceptEdge(
    'interference',
    'Superposition',
    'Interference',
    'I∝|ψ1+ψ2|²',
    'Coherent amplitudes interfere before intensity/probability is calculated.',
    'Linear superposition; coherent phase; quantum detections are not classical paths.',
    'Compare phase shifts in sound, light and matter waves.',
    ['s08-e02', 's09-e05', 's15-e02'],
  ),
  ConceptEdge(
    'current-field',
    'Current',
    'Magnetic field',
    'B=μ0I/(2πr)',
    'A steady straight current produces an azimuthal magnetic field.',
    'Long straight wire, exterior region; finite solenoids use a different model.',
    'Reverse current and inspect field direction.',
    ['s11-e02', 's11-e03'],
  ),
  ConceptEdge(
    'flux-emf',
    'Magnetic flux',
    'Induced EMF',
    'ε=−dΦB/dt',
    'Time-varying linked flux produces an induced EMF with Lenz sign.',
    'Defined loop orientation; quasi-static model.',
    'Move a dipole through a loop and compare approach/recession.',
    ['s11-e04', 's11-e05'],
  ),
  ConceptEdge(
    'micro-thermal',
    'Microscopic models',
    'Thermal response',
    'ΔU=Q−W',
    'Macroscopic energy balance links heat, work and internal energy; a microscopic interpretation needs model assumptions.',
    'Equilibrium thermodynamics, not a literal molecular movie.',
    'Compare first-law energy accounting with lumped cooling.',
    ['s13-e04', 's13-e02', 's15-e00'],
  ),
  ConceptEdge(
    'gravity-orbits',
    'Gravitation',
    'Orbital motion',
    'P²=4π²a³/GM',
    'An inverse-square central force admits Keplerian bound orbits.',
    'Isolated two-body / frozen-element teaching models; not full ephemerides.',
    'Compare user-defined orbits with sourced planetary ellipses.',
    ['s06-e03', 's16-e00'],
  ),
  ConceptEdge(
    'spectra-stars',
    'Spectroscopy',
    'Stellar properties',
    'λo/λr=√((1+β)/(1−β))',
    'Identified line positions constrain radial motion; continuum shape and line physics carry different information.',
    'Vacuum wavelengths; normalized synthetic template is not an observed atmosphere or abundance fit.',
    'Compare hydrogen transitions with shifted synthetic Balmer lines.',
    ['s15-e03', 's16-e02'],
  ),
  ConceptEdge(
    'first-order',
    'Capacitor charge',
    'Thermal response',
    'y=y∞+(y0−y∞)e^(−t/τ)',
    'Two distinct first-order models share an exponential response shape.',
    'Constant RC and a valid lumped single-time-constant thermal response.',
    'Plot normalized responses against each model’s t/τ.',
    ['s10-e03', 's13-e00'],
  ),
];

class LearningPath {
  final String id, title, objective;
  final List<String> prerequisites;
  final List<int> studiosInOrder;
  const LearningPath(
    this.id,
    this.title,
    this.objective,
    this.prerequisites,
    this.studiosInOrder,
  );
  List<Entry> get activities => [
    for (final s in studiosInOrder) ...studios[s].entries,
  ];
  bool required(Entry e) => e.index < 5;
  List<Entry> get requiredActivities => activities.where(required).toList();
  double progress(Set<String> completed) =>
      requiredActivities.where((e) => completed.contains(e.id)).length /
      requiredActivities.length;
  Entry? resume(Set<String> completed) =>
      requiredActivities.where((e) => !completed.contains(e.id)).firstOrNull;
}

const learningPaths = [
  LearningPath(
    'measurement',
    'Measurement foundations',
    'Read instruments, state units and distinguish random from systematic uncertainty.',
    [],
    [1],
  ),
  LearningPath(
    'motion',
    'Motion and forces',
    'Connect position, vectors, net force and momentum.',
    ['measurement'],
    [2, 3, 4],
  ),
  LearningPath(
    'energy',
    'Energy and oscillations',
    'Use work/energy and central forces, then compare oscillator models.',
    ['motion'],
    [5, 6, 7],
  ),
  LearningPath(
    'waves',
    'Waves and optics',
    'Explore superposition, propagation, ray geometry and interference.',
    ['measurement'],
    [8, 9],
  ),
  LearningPath(
    'electricity',
    'Electricity and magnetism',
    'Link fields, potentials, circuits, induction and electronics.',
    ['measurement'],
    [10, 11, 12],
  ),
  LearningPath(
    'thermal',
    'Thermal and fluid physics',
    'Apply energy balance, pressure, continuity and model validity.',
    ['energy'],
    [13, 14],
  ),
  LearningPath(
    'modern',
    'Modern physics',
    'Distinguish wavefunctions, detector distributions and nuclear datasets.',
    ['waves', 'electricity'],
    [15],
  ),
  LearningPath(
    'astronomy',
    'Astronomy',
    'Compare sourced orbit/stellar data, synthetic spectra and cosmic distance models.',
    ['energy', 'modern'],
    [16],
  ),
];
const relatedDestinations = {
  's03-e03': ['s05-e02', 's05-e01'],
  's05-e02': ['s03-e03'],
  's07-e00': ['s08-e03'],
  's08-e03': ['s07-e00'],
  's10-e02': ['s10-e03'],
  's10-e03': ['s13-e00', 's10-e02'],
  's11-e04': ['s11-e05'],
  's11-e05': ['s11-e04'],
  's15-e03': ['s16-e02'],
  's16-e02': ['s15-e03'],
  's06-e03': ['s16-e00'],
  's16-e00': ['s06-e03'],
  's16-e01': ['s13-e01'],
  's16-e03': ['s06-e01'],
  's16-e04': ['s08-e00'],
  's16-e05': ['s09-e02'],
};

class MasteryQuestion {
  final String id, lab, type, prompt, unit, explanation;
  final double Function() answer;
  final double tolerance;
  final List<String> options;
  const MasteryQuestion(
    this.id,
    this.lab,
    this.type,
    this.prompt,
    this.unit,
    this.answer,
    this.tolerance,
    this.explanation, {
    this.options = const [],
  });
  Map<String, dynamic> get configuration => challengeConfigurations[id]!;
  String get sourceModel {
    final e = entryById(lab);
    return e.astronomy
        ? astroVersion
        : e.fluidModern
        ? fmVersion
        : e.electronicsThermal
        ? etVersion
        : e.electromagnetism
        ? emVersion
        : e.wavesOptics
        ? waveOpticsVersion
        : e.advanced
        ? advancedVersion
        : e.dynamics
        ? dynamicsVersion
        : modelVersion;
  }

  int get studio => entryById(lab).studioIndex;
  List<String> get prerequisites => ['SI units', studios[studio].title];
  bool evaluate(double x) => x.isFinite && (x - answer()).abs() <= tolerance;
}

final masteryQuestions = <MasteryQuestion>[
  MasteryQuestion(
    'read-vernier-01',
    's01-e01',
    'Instrument reading',
    'Read the displayed vernier, with no zero error. Enter length in meters.',
    'm',
    () => ScaleReading.vernier(.0236).observed,
    .00005,
    'Main23mm plus coincidence6×0.1mm =23.6mm. Instrument resolution is not zero error.',
  ),
  MasteryQuestion(
    'force-vector-01',
    's02-e00',
    'Force/vector reasoning',
    'A4N force acts at60° above +x on a2kg block. Friction0; contact maintained. Find horizontal acceleration.',
    'm/s²',
    () => 4 * math.cos(math.pi / 3) / 2,
    .02,
    'Resolve force first: ax=Fcosθ/m. Vertical normal remains positive.',
  ),
  MasteryQuestion(
    'projectile-01',
    's03-e03',
    'Numerical prediction',
    'Level-ground projectile: v0=20m/s,45°,g9.80665; no drag. Predict range.',
    'm',
    () => 400 / standardGravity,
    .1,
    'R=v0²sin(2θ)/g; same launch/landing height.',
  ),
  MasteryQuestion(
    'newton-01',
    's04-e01',
    'Numerical prediction',
    'Net force6N on3kg constant mass in an inertial frame. Predict acceleration.',
    'm/s²',
    () => 6 / 3,
    .02,
    'Newton’s second law uses net force, not one force in isolation.',
  ),
  MasteryQuestion(
    'kinetic-01',
    's05-e01',
    'Numerical prediction',
    'A2kg body moves at3m/s. Predict kinetic energy.',
    'J',
    () => kinetic(2, 3),
    .05,
    'K=mv²/2; doubling speed quadruples energy.',
  ),
  MasteryQuestion(
    'escape-01',
    's06-e04',
    'Numerical prediction',
    'Newtonian escape speed from an isolated spherical Earth at mean radius6371000m; μ=3.98600435507e14.',
    'm/s',
    () => escapeSpeed(earthMu, earthRadius),
    25,
    'vesc=√(2μ/r), neglecting atmosphere, rotation and other bodies.',
  ),
  MasteryQuestion(
    'shm-graph-01',
    's07-e00',
    'Graph interpretation',
    'The plotted undamped oscillator has m1kg,k4N/m,x0.1m,v0=0. Read x at t=π/2 seconds.',
    'm',
    () => freeOscillator(1, 4, 0, .1, 0, math.pi / 2).x,
    .002,
    'ω=2rad/s; half a period reaches x=−0.1m.',
  ),
  MasteryQuestion(
    'wave-01',
    's08-e00',
    'Numerical prediction',
    'A harmonic wave has f2Hz and λ1.5m. Find phase speed.',
    'm/s',
    () => 2 * 1.5,
    .02,
    'v=fλ. Phase speed is not material particle velocity.',
  ),
  MasteryQuestion(
    'optics-01',
    's09-e01',
    'Concept selection',
    'Light goes from n1=1.5 to n2=1 at60° incidence from the normal. What happens?',
    'choice',
    () => 2,
    0,
    '60° exceeds asin(1/1.5)≈41.8°; the Snell model gives total internal reflection.',
    options: [
      'Refracts toward normal',
      'Transmits without bending',
      'Total internal reflection',
    ],
  ),
  MasteryQuestion(
    'resistor-target-01',
    's10-e04',
    'Parameter adjustment',
    'Adjust resistance so an ideal5V source drives2mA through one resistor. Enter/adjust R.',
    'Ω',
    () => 5 / .002,
    25,
    'Ohm’s law: R=V/I=2500Ω. The live preview uses the existing circuit solver.',
  ),
  MasteryQuestion(
    'magnetic-01',
    's11-e01',
    'Numerical prediction',
    'Charge1e−6C moves at200m/s perpendicular to a uniform0.01T field. Find magnetic force magnitude.',
    'N',
    () => (const V3(200, 0).cross(const V3(0, 0, .01)) * 1e-6).norm,
    1e-8,
    '|q v×B|=|q|vB for perpendicular vectors; field does no work.',
  ),
  MasteryQuestion(
    'electronics-01',
    's12-e02',
    'Concept selection',
    'A digital input0 is inverted by an ideal NOT gate. What is its output?',
    'choice',
    () => logicGate(2, false, false) ? 1 : 0,
    0,
    'The NOT truth table maps0 to1 and1 to0.',
    options: ['0', '1', 'Undefined'],
  ),
  MasteryQuestion(
    'thermal-01',
    's13-e00',
    'Numerical prediction',
    'First-order probe: sample350K, initial300K,τ10s. Predict reading at10s.',
    'K',
    () => probeTemperature(350, 300, 10, 10),
    .2,
    'T=350+(300−350)e^(−1). This is a constant sample and single-time-constant probe.',
  ),
  MasteryQuestion(
    'fluid-01',
    's14-e00',
    'Numerical prediction',
    'Model liquidρ1000kg/m³,depth0.3m,surface/reference101325Pa. Predict gauge pressure.',
    'Pa',
    () => densityPressure(1000, .3, 101325, 101325, 1, .001)['gaugePressure']!,
    2,
    'Gauge pressure=ρgh=2941.995Pa; it differs from absolute pressure.',
  ),
  MasteryQuestion(
    'modern-01',
    's15-e03',
    'Numerical prediction',
    'Hydrogen emission n3→n2 under the reduced-mass vacuum model. Predict wavelength in nm.',
    'nm',
    () => hydrogenTransition(2, 3)['wavelength']! * 1e9,
    .1,
    'The model yields≈656.47nm vacuum, distinct from common air wavelength656.3nm.',
  ),
  MasteryQuestion(
    'astronomy-01',
    's16-e05',
    'Numerical prediction',
    'Uniform star, circular central transit, planet/star radius ratio0.1 fully overlapping. Predict relative depth.',
    '1',
    () => transit(1, 1, .1, 5, 90, 0)['midDepth']!,
    .0001,
    'Exact full overlap gives0.01. Grazing and partial overlap require lens geometry.',
  ),
];

final challengeConfigurations = <String, Map<String, dynamic>>{
  'read-vernier-01': {
    'opening_m': .0236,
    'zeroError_m': 0,
    'leastCount_m': .0001,
  },
  'force-vector-01': {
    'force_N': 4,
    'angle_rad': math.pi / 3,
    'mass_kg': 2,
    'friction': 0,
    'axis': 'horizontal, positive right',
  },
  'projectile-01': {
    'speed_m_per_s': 20,
    'angle_rad': math.pi / 4,
    'g_m_per_s2': standardGravity,
    'launchHeight_m': 0,
    'landingHeight_m': 0,
    'drag': 0,
  },
  'newton-01': {'netForce_N': 6, 'mass_kg': 3},
  'kinetic-01': {'mass_kg': 2, 'speed_m_per_s': 3},
  'escape-01': {'mu_m3_per_s2': earthMu, 'radius_m': earthRadius},
  'shm-graph-01': {
    'mass_kg': 1,
    'spring_N_per_m': 4,
    'damping_kg_per_s': 0,
    'initialPosition_m': .1,
    'initialVelocity_m_per_s': 0,
    'time_s': math.pi / 2,
  },
  'wave-01': {'frequency_Hz': 2, 'wavelength_m': 1.5},
  'optics-01': {'n1': 1.5, 'n2': 1, 'incidenceFromNormal_rad': math.pi / 3},
  'resistor-target-01': {
    'sourceVoltage_V': 5,
    'targetCurrent_A': .002,
    'resistanceBounds_ohm': [250, 10000],
    'network': 'one ideal voltage source and one resistor, two common nodes',
  },
  'magnetic-01': {
    'charge_C': 1e-6,
    'velocity_m_per_s': [200, 0, 0],
    'field_T': [0, 0, .01],
  },
  'electronics-01': {'gate': 'NOT', 'inputA': false, 'inputB': false},
  'thermal-01': {
    'sample_K': 350,
    'initialProbe_K': 300,
    'tau_s': 10,
    'time_s': 10,
  },
  'fluid-01': {
    'density_kg_per_m3': 1000,
    'depth_m': .3,
    'surfacePressure_Pa': 101325,
    'referencePressure_Pa': 101325,
  },
  'modern-01': {
    'atom': 'hydrogen',
    'upper': 3,
    'lower': 2,
    'wavelengthConvention': 'vacuum reduced-mass Rydberg',
  },
  'astronomy-01': {
    'stellarMass_solar': 1,
    'stellarRadius_solar': 1,
    'radiusRatio': .1,
    'period_day': 5,
    'inclination_deg': 90,
    'timeFromMidTransit_s': 0,
    'limbDarkening': false,
  },
};
