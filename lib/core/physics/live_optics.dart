import 'dart:math' as math;

import 'waves_optics.dart' show ImageSolution, snell, opticalIntensity;
import 'optical_library.dart';

const liveOpticsVersion = 'optics-live-1.1';
const legacyLiveOpticsVersion = 'optics-live-1.0';

class OpticsParameter {
  final String key, label, unit;
  final double min, max, initial, multiplier;
  final int digits;
  const OpticsParameter(
    this.key,
    this.label,
    this.unit,
    this.min,
    this.max,
    this.initial, {
    this.multiplier = 1,
    this.digits = 1,
  });
  String format(double value) =>
      '${(value * multiplier).toStringAsFixed(digits)}${unit.isEmpty ? '' : ' $unit'}';
}

const laserLambda = OpticsParameter(
  'wavelength',
  'Wavelength (λ)',
  'nm',
  400e-9,
  700e-9,
  650e-9,
  multiplier: 1e9,
  digits: 0,
);
const laserPower = OpticsParameter(
  'power',
  'Laser power',
  'mW',
  .1,
  5,
  1,
  digits: 1,
);
const opticPosition = OpticsParameter(
  'optic',
  'Bench position',
  'cm',
  -.12,
  .12,
  0,
  multiplier: 100,
);
const objectU = OpticsParameter(
  'u',
  'Object distance (u)',
  'cm',
  .05,
  .8,
  .15,
  multiplier: 100,
);
const lensFocal = OpticsParameter(
  'focal',
  'Focal length (f)',
  'cm',
  .05,
  .3,
  .1,
  multiplier: 100,
);

class OpticsDefinition {
  final int kind;
  final String id, title, subtitle, equation, principle;
  final List<OpticsParameter> controls;
  final List<String> modes;
  const OpticsDefinition(
    this.kind,
    this.id,
    this.title,
    this.subtitle,
    this.equation,
    this.principle,
    this.controls, {
    this.modes = const [],
  });
  Map<String, double> get defaults => {
    for (final c in controls) c.key: c.initial,
  };
  OpticsParameter get primary => controls.first;
}

const opticsDefinitions = [
  OpticsDefinition(
    0,
    's09-e00',
    'Reflection',
    'Plane mirror – Law of reflection',
    'θᵢ = θᵣ',
    'Angles are measured from the mirror normal. Drag the mirror rim to rotate it; the incident laser stays fixed and the reflected ray follows the vector reflection law.',
    [
      OpticsParameter('angle', 'Incident angle (θᵢ)', '°', 0, 85, 30.6),
      laserLambda,
      laserPower,
      opticPosition,
    ],
  ),
  OpticsDefinition(
    1,
    's09-e01',
    'Refraction',
    'Glass block – Snell’s law & total internal reflection',
    'n₁ sin θᵢ = n₂ sin θᵣ',
    'The ray bends at each actual block face, with Fresnel reflection and internal reflections. Angle and power readouts refer to the entrance interface, not total slab transmission. Swap the incident medium to explore the critical angle. Entrance TIR has no propagating ray in the block. Schematic distances; incoherent slab branches.',
    [
      OpticsParameter('angle', 'Incident angle', '°', 0, 85, 60),
      OpticsParameter('n1', 'Incident index (n₁)', '', 1, 2.5, 1, digits: 2),
      OpticsParameter('n2', 'Second index (n₂)', '', 1, 2.5, 1.5, digits: 2),
      laserLambda,
      laserPower,
      opticPosition,
    ],
  ),
  OpticsDefinition(
    2,
    's09-e02',
    'Lenses',
    'Thin lens – Ray diagram & image formation',
    '1/f = 1/u + 1/v',
    'Drag the object or lens on the rail, or drag a focal marker. Solid rays physically converge for a real image; dashed backward extensions locate a virtual image. At u=f the image is at infinity. Ideal paraxial model; vertical object height is enlarged in the diagram.',
    [
      lensFocal,
      objectU,
      OpticsParameter(
        'height',
        'Object height',
        'cm',
        .003,
        .025,
        .012,
        multiplier: 100,
        digits: 2,
      ),
      laserLambda,
      laserPower,
      opticPosition,
    ],
    modes: ['Convex (converging)', 'Concave (diverging)'],
  ),
  OpticsDefinition(
    3,
    's09-e03',
    'Mirrors',
    'Spherical mirror – Concave & convex',
    '1/f = 1/u + 1/v; R = 2f',
    'Drag the object or mirror; move the focal handle to change curvature. Real image coordinates lie in front of the mirror, virtual image coordinates behind. Paraxial spherical-mirror model; image at infinity is handled explicitly.',
    [
      OpticsParameter(
        'focal',
        'Radius of curvature (R)',
        'cm',
        .025,
        .5,
        .15,
        multiplier: 200,
      ),
      OpticsParameter(
        'u',
        'Object distance (u)',
        'cm',
        .05,
        .8,
        .20,
        multiplier: 100,
      ),
      OpticsParameter(
        'height',
        'Object height',
        'cm',
        .003,
        .025,
        .012,
        multiplier: 100,
        digits: 2,
      ),
      laserLambda,
      laserPower,
      opticPosition,
    ],
    modes: ['Concave', 'Convex'],
  ),
  OpticsDefinition(
    4,
    's09-e04',
    'Interference',
    'Double slit – Bright & dark fringes',
    'I/I₀ = cos²(πd sin θ/λ)',
    'Ideal equal, narrow coherent slits; finite slit-width envelope is omitted. The intensity uses sin θ exactly; λL/d is the paraxial fringe-spacing estimate. Fraunhofer use requires d²/(λL) ≤ 0.1. Screen coordinates are physical; apparatus distances are schematic.',
    [
      OpticsParameter(
        'aperture',
        'Slit separation (d)',
        'mm',
        .01e-3,
        .25e-3,
        .10e-3,
        multiplier: 1e3,
        digits: 2,
      ),
      laserLambda,
      OpticsParameter(
        'screen',
        'Screen distance (L)',
        'm',
        .5,
        3,
        .5,
        digits: 2,
      ),
      OpticsParameter(
        'probe',
        'Detector position',
        'mm',
        -.03,
        .03,
        0,
        multiplier: 1e3,
      ),
      laserPower,
    ],
  ),
  OpticsDefinition(
    5,
    's09-e05',
    'Diffraction',
    'Single slit – Fraunhofer pattern',
    'I/I₀ = (sin β/β)²; β = πa sin θ/λ',
    'Drag the slit jaws or screen. The central and side lobes come from the same sinc-squared intensity used by the graph. Changing slit width or wavelength recalculates every screen sample.',
    [
      OpticsParameter(
        'aperture',
        'Slit width (a)',
        'mm',
        .02e-3,
        .15e-3,
        .10e-3,
        multiplier: 1e3,
        digits: 2,
      ),
      laserLambda,
      OpticsParameter(
        'screen',
        'Screen distance (L)',
        'm',
        .5,
        3,
        1,
        digits: 2,
      ),
      OpticsParameter(
        'probe',
        'Detector position',
        'mm',
        -.03,
        .03,
        0,
        multiplier: 1e3,
      ),
      laserPower,
    ],
  ),
  OpticsDefinition(
    6,
    's09-e06',
    'Polarization',
    'Malus’s law – Intensity vs angle',
    'I = ½ I₀ cos² θ',
    'Rotate the analyzer ring directly. Initially unpolarized light loses half its intensity at the first ideal polarizer; the analyzer transmits the squared projection. At 90° the transmitted beam extinguishes.',
    [
      OpticsParameter('angle', 'Analyzer angle (θ)', '°', 0, 180, 45),
      OpticsParameter(
        'intensity',
        'Incident intensity (I₀)',
        'W/m²',
        0,
        100,
        60,
        digits: 0,
      ),
      laserLambda,
      laserPower,
      opticPosition,
    ],
  ),
  OpticsDefinition(
    7,
    's09-e07',
    'Prism',
    'Dispersion of light – Refractive index',
    'n = n(λ); Snell’s law at every face',
    'Drag the prism to rotate it. Each wavelength is traced independently through the actual triangular glass surfaces with sourced Sellmeier dispersion and Fresnel reflection. A broad white incident beam produces a spectrum; total internal reflections are traced when present.',
    [
      OpticsParameter('angle', 'Incident angle', '°', 25, 75, 50),
      laserLambda,
      laserPower,
      opticPosition,
    ],
    modes: ['Crown glass (N-BK7)', 'Flint glass (N-F2)', 'Fused silica'],
  ),
  OpticsDefinition(
    8,
    's09-e08',
    'Thin Film Interference',
    'Soap film – Constructive & destructive',
    'φ (round trip) = 4πnt cos r/λ',
    'Drag the soap-film frame to vary its central thickness. Reflected and transmitted power use coherent two-interface Fresnel amplitudes, including phase reversal. White illumination reveals structural color; the laser probes the selected wavelength. The film has a small explicit thickness gradient.',
    [
      OpticsParameter(
        'thickness',
        'Film thickness (t)',
        'nm',
        0,
        2000e-9,
        500e-9,
        multiplier: 1e9,
        digits: 0,
      ),
      OpticsParameter(
        'wavelength',
        'Wavelength (λ)',
        'nm',
        400e-9,
        700e-9,
        550e-9,
        multiplier: 1e9,
        digits: 0,
      ),
      OpticsParameter(
        'filmIndex',
        'Film refractive index',
        '',
        1.05,
        2,
        1.33,
        digits: 2,
      ),
      OpticsParameter('angle', 'Incident angle', '°', 0, 70, 15),
      laserPower,
    ],
    modes: ['Reflected light', 'Transmitted light'],
  ),
  OpticsDefinition(
    9,
    's09-e09',
    'Optical Instruments',
    'Telescope / microscope – Ray diagram',
    'Mₜ = −f₁/f₂; Mₘ = −(v₁/u₁)(D/f₂)',
    'Drag either lens or the lens-separation handle. An ABCD ray-transfer calculation follows the same rays through both lenses. The astronomical telescope is afocal at separation f₁+f₂. A microscope objective forms an intermediate real image at the eyepiece focal plane.',
    [
      OpticsParameter(
        'f1',
        'f₁ (objective)',
        'cm',
        .05,
        .5,
        .2,
        multiplier: 100,
      ),
      OpticsParameter(
        'f2',
        'f₂ (eyepiece)',
        'cm',
        .02,
        .2,
        .05,
        multiplier: 100,
      ),
      OpticsParameter(
        'separation',
        'Lens separation',
        'cm',
        .07,
        .8,
        .25,
        multiplier: 100,
      ),
      laserLambda,
      laserPower,
      opticPosition,
    ],
    modes: ['Astronomical telescope', 'Compound microscope'],
  ),
];
OpticsDefinition opticsById(String id) =>
    opticsDefinitions.firstWhere((d) => d.id == id);

/// Coherent intensity reflectance of a lossless air/film/air stack.
double filmReflectance(
  double lambda,
  double thickness,
  double index,
  double angle,
) {
  final i = angle * math.pi / 180,
      r = math.asin(math.sin(i) / index),
      ci = math.cos(i),
      cr = math.cos(r);
  final rs = (ci - index * cr) / (ci + index * cr),
      rp = (index * ci - cr) / (index * ci + cr);
  final phase = 4 * math.pi * index * thickness * cr / lambda;
  double coherent(double a) {
    final b = -a, ab = a * b;
    return ((a * a + b * b + 2 * ab * math.cos(phase)) /
            (1 + ab * ab + 2 * ab * math.cos(phase)))
        .clamp(0, 1);
  }

  return .5 * (coherent(rs) + coherent(rp));
}

/// Incoherent ray branches at the actual four faces of a rectangular block.
/// Coordinates may be metres or drawing units; angles and powers are invariant.
({
  List<({OVec start, OVec end, double power, bool inside})> segments,
  double escaped,
  double remaining,
})
traceRectangularSlab({
  required double width,
  required double height,
  required OVec entry,
  required OVec direction,
  required double insideIndex,
  required double outsideIndex,
  double power = 1,
}) {
  final segments = <({OVec start, OVec end, double power, bool inside})>[];
  var position = entry, d = direction.unit, carried = power;
  double escaped = 0;
  for (int bounce = 0; bounce < 32 && carried > 1e-6; bounce++) {
    var distance = double.infinity;
    var normal = const OVec(0, 1);
    for (final face in [
      (
        coordinate: 0.0,
        origin: position.x,
        speed: d.x,
        normal: const OVec(-1, 0),
      ),
      (
        coordinate: width,
        origin: position.x,
        speed: d.x,
        normal: const OVec(1, 0),
      ),
      (
        coordinate: 0.0,
        origin: position.y,
        speed: d.y,
        normal: const OVec(0, -1),
      ),
      (
        coordinate: height,
        origin: position.y,
        speed: d.y,
        normal: const OVec(0, 1),
      ),
    ]) {
      if (face.speed.abs() < 1e-12) continue;
      final t = (face.coordinate - face.origin) / face.speed;
      if (t > 1e-7 && t < distance) {
        distance = t;
        normal = face.normal;
      }
    }
    if (!distance.isFinite) break;
    final hit = position + d * distance;
    segments.add((start: position, end: hit, power: carried, inside: true));
    final ci = d.dot(normal).clamp(0.0, 1.0), eta = insideIndex / outsideIndex;
    final k = 1 - eta * eta * (1 - ci * ci);
    double reflectance = 1;
    if (k >= -1e-12) {
      final ct = math.sqrt(math.max(0, k));
      reflectance = fresnelPower(
        insideIndex,
        outsideIndex,
        math.acos(ci),
        math.acos(ct),
      );
      final transmitted = (d * eta + normal * (ct - eta * ci)).unit;
      final transmittedPower = carried * (1 - reflectance);
      segments.add((
        start: hit,
        end: hit + transmitted * 450,
        power: transmittedPower,
        inside: false,
      ));
      escaped += transmittedPower;
    }
    carried *= reflectance;
    d = d - normal * (2 * ci);
    position = hit;
  }
  return (segments: segments, escaped: escaped, remaining: carried);
}

class LiveOpticsModel {
  final OpticsDefinition definition;
  Map<String, double> p;
  int mode;
  bool spectrum = true;
  LiveOpticsModel(
    this.definition, {
    Map<String, double>? parameters,
    this.mode = 0,
  }) : p = parameters == null ? definition.defaults : Map.of(parameters);
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  void set(String key, double value) {
    final c = definition.controls.firstWhere((c) => c.key == key);
    if (!value.isFinite) throw ArgumentError('Finite input required');
    p = {...p, key: value.clamp(c.min, c.max)};
  }

  Map<String, double> get state => solveLiveOptics(definition.kind, p, mode);
  String get invalid {
    if (definition.kind == 4 || definition.kind == 5) {
      if (v('aperture') * v('aperture') / (v('wavelength') * v('screen')) >
          .1 + 1e-12) {
        return 'Outside the Fraunhofer range (a²/λL ≤ 0.1). Reduce the aperture or increase screen distance. Near-field diffraction is not modeled.';
      }
    }
    return '';
  }

  String get responseKey => switch (definition.kind) {
    0 => 'Reflected angle (°)',
    1 => 'Transmitted angle (°)',
    2 || 3 => 'Image vergence (1/m)',
    4 || 5 => 'Detector intensity',
    6 => 'Transmitted intensity (W/m²)',
    7 => 'Deviation (°)',
    8 => mode == 0 ? 'Reflectance' : 'Transmittance',
    9 => mode == 0 ? 'Output vergence (1/m)' : 'Magnification',
    _ => throw StateError('Unknown optical response'),
  };

  ({String quantity, String unit, String label, double value})?
  get observation {
    if (invalid.isNotEmpty) return null;
    final s = state, k = definition.kind;
    final key = k == 4
        ? 'Fringe spacing (m)'
        : k == 5
        ? 'Central width (m)'
        : k == 9
        ? (mode == 0 ? 'Angular magnification' : 'Magnification')
        : responseKey;
    final value = s[key];
    if (value == null || !value.isFinite) return null;
    final quantity = k <= 1 || k == 7
        ? 'angle'
        : k == 2 || k == 3
        ? 'vergence'
        : k == 4 || k == 5
        ? 'length'
        : k == 6
        ? 'intensity'
        : k == 9
        ? 'magnification'
        : 'relativeIntensity';
    final unit = switch (quantity) {
      'angle' => '°',
      'vergence' => 'm⁻¹',
      'length' => 'm',
      'intensity' => 'W/m²',
      _ => '',
    };
    return (quantity: quantity, unit: unit, label: key, value: value);
  }

  List<TraceResult> prismTraces({bool spectrum = true}) {
    final materials = ['bk7', 'f2', 'silica'];
    final optic = PlacedOptic(
      'equilateral',
      material: materials[mode.clamp(0, 2)],
      rotation: (30 - v('angle')) * math.pi / 180,
    );
    final bench = OpticalBench()
      ..components = [optic]
      // Aim through the midpoint of the intended entrance face. A fixed
      // centreline can hit the base after rotation, changing the prism angle.
      ..source = OVec(
        -2,
        const OVec(-.25, .1443375673).rotate(optic.rotation).y,
      )
      ..direction = const OVec(1, 0)
      ..maxDepth = 8
      ..maxRays = 48;
    return [
      for (final nm
          in spectrum
              ? [430.0, 460.0, 490.0, 520.0, 550.0, 580.0, 610.0, 650.0, 680.0]
              : [v('wavelength') * 1e9])
        bench.trace(nm: nm),
    ];
  }

  Map<String, dynamic> toJson() => {
    'model': liveOpticsVersion,
    'id': definition.id,
    'p': Map.of(p),
    'mode': mode,
    'spectrum': spectrum,
  };
  bool restore(Map<String, dynamic> data) {
    try {
      if (![
            liveOpticsVersion,
            legacyLiveOpticsVersion,
          ].contains(data['model']) ||
          data['id'] != definition.id) {
        return false;
      }
      final raw = Map<String, dynamic>.from(data['p']);
      if (raw.length != definition.controls.length) return false;
      final next = <String, double>{};
      for (final c in definition.controls) {
        final n = (raw[c.key] as num).toDouble();
        if (!n.isFinite || n < c.min || n > c.max) return false;
        next[c.key] = n;
      }
      final nextMode = data['mode'] as int;
      if (nextMode < 0 || nextMode >= math.max(1, definition.modes.length)) {
        return false;
      }
      final spectrumValue = data['spectrum'] ?? true;
      if (spectrumValue is! bool) return false;
      p = next;
      mode = nextMode;
      spectrum = spectrumValue;
      return true;
    } catch (_) {
      return false;
    }
  }

  double profile(double y) => opticalIntensity(
    definition.kind == 4,
    v('wavelength'),
    v('aperture'),
    v('screen'),
    y,
  );
  List<({double x, double y})> curve() {
    final kind = definition.kind;
    if (invalid.isNotEmpty) return [];
    if (kind == 4 || kind == 5) {
      return [
        for (int i = 0; i <= 400; i++)
          (x: -.03 + .06 * i / 400, y: profile(-.03 + .06 * i / 400)),
      ];
    }
    final c = definition.primary;
    return [
      for (int i = 0; i <= 160; i++)
        _sample(c, c.min + (c.max - c.min) * i / 160),
    ];
  }

  ({double x, double y}) _sample(OpticsParameter c, double value) {
    final s = solveLiveOptics(definition.kind, {...p, c.key: value}, mode);
    final key = responseKey;
    return (
      x: value,
      y: s['TIR'] == 1 || s['Exit TIR'] == 1
          ? double.nan
          : s[key] ?? double.nan,
    );
  }
}

Map<String, double> solveLiveOptics(int kind, Map<String, double> p, int mode) {
  double v(String key, [double fallback = 0]) => p[key] ?? fallback;
  switch (kind) {
    case 0:
      return {
        'Reflected angle (°)': v('angle'),
        'Incident angle (°)': v('angle'),
      };
    case 1:
      final result = snell(v('n1'), v('n2'), v('angle') * math.pi / 180);
      final i = v('angle') * math.pi / 180, r = result.angle;
      final reflectance = r == null
          ? 1.0
          : fresnelPower(v('n1'), v('n2'), i, r);
      return {
        if (r != null) 'Transmitted angle (°)': r * 180 / math.pi,
        'TIR': result.tir ? 1 : 0,
        'Reflected power': reflectance,
        'Transmitted power': 1 - reflectance,
        if (result.critical != null)
          'Critical angle (°)': result.critical! * 180 / math.pi,
      };
    case 2:
    case 3:
      final image = ImageSolution(
        v('focal') * (mode == 0 ? 1 : -1),
        v('u'),
        v('height'),
      );
      return {
        'Image vergence (1/m)': image.vergence,
        if (image.distance != null) 'Image distance (m)': image.distance!,
        if (image.magnification != null) 'Magnification': image.magnification!,
        'At infinity': image.atInfinity ? 1 : 0,
        'Image type': image.classification.toDouble(),
        if (image.magnification != null)
          'Image height (m)': image.magnification! * v('height'),
      };
    case 4:
    case 5:
      final lambda = v('wavelength'), a = v('aperture'), length = v('screen');
      final width = kind == 4
          ? lambda * length / a
          : 2 * length * math.tan(math.asin((lambda / a).clamp(-1, 1)));
      return {
        kind == 4 ? 'Fringe spacing (m)' : 'Central width (m)': width,
        'Detector intensity': opticalIntensity(
          kind == 4,
          lambda,
          a,
          length,
          v('probe'),
        ),
        'Fresnel number': a * a / (lambda * length),
      };
    case 6:
      final transmitted =
          v('intensity') *
          .5 *
          math.pow(math.cos(v('angle') * math.pi / 180), 2);
      return {
        'Transmitted intensity (W/m²)': transmitted,
        'Transmission': .5 * math.pow(math.cos(v('angle') * math.pi / 180), 2),
        'After polarizer (W/m²)': v('intensity') * .5,
      };
    case 7:
      final material = opticalMaterial(
            ['bk7', 'f2', 'silica'][mode.clamp(0, 2)],
          ),
          index = material.index(v('wavelength') * 1e9);
      final i = v('angle') * math.pi / 180,
          r1 = math.asin(math.sin(i) / index),
          r2 = math.pi / 3 - r1,
          tir = index * math.sin(r2) > 1;
      return {
        'Index': index,
        if (!tir)
          'Deviation (°)':
              (i +
                  math.asin((index * math.sin(r2)).clamp(-1, 1)) -
                  math.pi / 3) *
              180 /
              math.pi,
        'Exit TIR': tir ? 1 : 0,
      };
    case 8:
      final r = filmReflectance(
        v('wavelength'),
        v('thickness'),
        v('filmIndex'),
        v('angle'),
      );
      return {
        'Reflectance': r,
        'Transmittance': 1 - r,
        'Optical thickness (m)': v('filmIndex') * v('thickness'),
      };
    case 9:
      final f1 = v('f1'), f2 = v('f2'), d = v('separation');
      if (mode == 0) {
        final defocus = d - f1 - f2, afocal = defocus.abs() < 1e-10;
        final object = d - f1;
        final vergence = object.abs() < 1e-12 ? null : 1 / f2 - 1 / object;
        return {
          if (afocal) 'Angular magnification': -f1 / f2,
          'Afocal': afocal ? 1 : 0,
          if (vergence != null) 'Output vergence (1/m)': afocal ? 0 : vergence,
          if (!afocal && vergence != null && vergence.abs() > 1e-12)
            'Final image distance (m)': 1 / vergence,
          'Afocal separation (m)': f1 + f2,
          'Defocus (m)': defocus,
        };
      }
      final image = d - f2,
          object = image <= f1 ? double.infinity : f1 * image / (image - f1);
      return {
        if (object.isFinite) 'Magnification': -(image / object) * (.25 / f2),
        'Intermediate image (m)': image,
        if (object.isFinite) 'Objective object distance (m)': object,
        'Valid microscope': object.isFinite ? 1 : 0,
      };
    default:
      throw ArgumentError('Optics kind');
  }
}

double fresnelPower(double n1, double n2, double i, double r) {
  if ((n1 - n2).abs() < 1e-12) return 0;
  if ((i - math.pi / 2).abs() < 1e-8) return 1;
  final ci = math.cos(i),
      cr = math.cos(r),
      s = (n1 * ci - n2 * cr) / (n1 * ci + n2 * cr),
      p = (n2 * ci - n1 * cr) / (n2 * ci + n1 * cr);
  return ((s * s + p * p) * .5).clamp(0, 1);
}
