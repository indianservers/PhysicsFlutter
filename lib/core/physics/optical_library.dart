import 'dart:math' as math;

import 'thermal_library.dart' show materialBenchVersion;

const opticalDataVersion = 'optics-2026-10';

class OVec {
  final double x, y, z;
  const OVec(this.x, this.y, [this.z = 0]);
  OVec operator +(OVec b) => OVec(x + b.x, y + b.y, z + b.z);
  OVec operator -(OVec b) => OVec(x - b.x, y - b.y, z - b.z);
  OVec operator *(double a) => OVec(x * a, y * a, z * a);
  double dot(OVec b) => x * b.x + y * b.y + z * b.z;
  double get length => math.sqrt(dot(this));
  OVec get unit => length < 1e-14 ? const OVec(1, 0, 0) : this * (1 / length);
  OVec rotate(double a) => OVec(
    x * math.cos(a) - y * math.sin(a),
    x * math.sin(a) + y * math.cos(a),
    z,
  );
  List<double> toJson() => [x, y, z];
  static OVec fromJson(dynamic j) {
    if (j is! List || j.length != 3) throw const FormatException('Vector');
    final n = j.map((v) => (v as num).toDouble()).toList();
    if (n.any((v) => !v.isFinite || v.abs() > 100)) {
      throw const FormatException('Vector bounds');
    }
    return OVec(n[0], n[1], n[2]);
  }
}

class OpticalMaterial {
  final String id, name, source, conditions;
  final double nd, temperature, minNm, maxNm;
  final List<double>? b, c;
  const OpticalMaterial(
    this.id,
    this.name,
    this.nd,
    this.source,
    this.conditions, {
    this.temperature = 293.15,
    this.minNm = 585.5,
    this.maxNm = 591.5,
    this.b,
    this.c,
  });
  bool get dispersive => b != null;
  double index(double nm) {
    if (!nm.isFinite || nm < minNm || nm > maxNm) {
      throw ArgumentError('$name: wavelength outside $minNm–$maxNm nm.');
    }
    if (b == null) return nd;
    final l2 = nm * nm / 1e6;
    return math.sqrt(
      1 +
          List.generate(
            3,
            (i) => b![i] * l2 / (l2 - c![i]),
          ).reduce((a, b) => a + b),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'n_reference': nd,
    'reference_nm': id == 'bk7' || id == 'f2' ? 587.6 : 589.3,
    'temperature_K': temperature,
    'min_nm': minNm,
    'max_nm': maxNm,
    'model': dispersive
        ? 'Sellmeier, wavelength in µm'
        : 'Constant monochromatic teaching approximation',
    'B': b,
    'C_um2': c,
    'source': source,
    'conditions': conditions,
    'absorption': 'Unavailable; lossless bulk assumption',
    'sourceVersion': opticalDataVersion,
  };
}

const opticalMaterials = [
  OpticalMaterial(
    'air',
    'Air · ideal n=1',
    1,
    'https://emtoolbox.nist.gov/Wavelength/Documentation.asp',
    'Ideal surrounding medium, not a humidity/pressure air-index calculation.',
    minNm: 400,
    maxNm: 700,
  ),
  OpticalMaterial(
    'water',
    'Water · monochromatic',
    1.333,
    'https://openstax.org/books/university-physics-volume-3/pages/1-3-refraction',
    'Liquid water reference at sodium D line. No dispersion or temperature interpolation.',
  ),
  OpticalMaterial(
    'silica',
    'Fused Silica · Malitson',
    1.4585,
    'https://opg.optica.org/josa/abstract.cfm?uri=josa-55-10-1205',
    'Malitson 1965 fused-silica fit, 20 °C. Visible subset used.',
    minNm: 400,
    maxNm: 700,
    b: [.6961663, .4079426, .8974794],
    c: [.00467914825849, .01351206307396, 97.934002537921],
  ),
  OpticalMaterial(
    'bk7',
    'SCHOTT N-BK7 crown',
    1.51680,
    'https://media.schott.com/api/public/content/41e799d0bf874807a0bb8e702fbb75b5?v=54856406',
    'SCHOTT Sellmeier coefficients; reference glass, not every borosilicate. Visible subset used.',
    minNm: 400,
    maxNm: 700,
    b: [1.03961212, .231792344, 1.01046945],
    c: [.00600069867, .0200179144, 103.560653],
  ),
  OpticalMaterial(
    'f2',
    'SCHOTT N-F2 flint',
    1.62005,
    'https://media.schott.com/api/public/content/061f3156c83a44ed9220770b0f65a869?v=d69b35e0',
    'SCHOTT N-F2 Sellmeier coefficients. Visible subset used.',
    minNm: 400,
    maxNm: 700,
    b: [1.397570370, .159201403, 1.268654300],
    c: [.009959061, .0546931752, 119.248346],
  ),
  OpticalMaterial(
    'pmma',
    'PMMA / Acrylic · monochromatic',
    1.49,
    'https://www.edmundoptics.com/knowledge-center/application-notes/optics/understanding-optical-windows/',
    'Typical unfilled optical acrylic, sodium-D teaching value. Grade variation and dispersion not modeled.',
  ),
  OpticalMaterial(
    'pc',
    'Polycarbonate · monochromatic',
    1.585,
    'https://www.edmundoptics.com/knowledge-center/application-notes/optics/understanding-optical-windows/',
    'Typical optical polycarbonate; sodium-D teaching value. No dispersion fit.',
  ),
  OpticalMaterial(
    'glycerol',
    'Glycerol · monochromatic',
    1.474,
    'https://www.itwreagents.com/download_file/tds/131339/en/tds_131339_en.pdf',
    'ITW reagent glycerol n20/D; composition and water content matter.',
  ),
];
OpticalMaterial opticalMaterial(String id) =>
    opticalMaterials.firstWhere((m) => m.id == id);

class OpticalComponent {
  final String id, name, category, shape, status;
  final bool functional;
  const OpticalComponent(
    this.id,
    this.name,
    this.category,
    this.shape, {
    this.status = 'Functional in the labeled optical section; finite aperture, ideal surfaces, no image-rotation claim.',
    this.functional = true,
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'class': category,
    'geometry': shape,
    'functional': functional,
    'scope': status,
    'asset':
        'Original procedural geometry, same boundaries used for ray tracing',
    'version': opticalDataVersion,
  };
}

const opticalComponents = [
  OpticalComponent(
    'slab',
    'Rectangular Glass Slab',
    'Refractive block',
    'slab',
  ),
  OpticalComponent(
    'square',
    'Square Glass Block',
    'Refractive block',
    'square',
  ),
  OpticalComponent(
    'thick',
    'Thick Plane-Parallel Plate',
    'Refractive block',
    'thick',
  ),
  OpticalComponent(
    'window',
    'Thin Optical Window',
    'Refractive block',
    'window',
  ),
  OpticalComponent(
    'semicircle',
    'Semicircular Glass Block',
    'Refractive block',
    'semicircle',
  ),
  OpticalComponent('disk', 'Circular Glass Disk', 'Refractive block', 'disk'),
  OpticalComponent(
    'quarter',
    'Quarter-Circular Glass Block',
    'Refractive block',
    'quarter',
  ),
  OpticalComponent(
    'semiellipse',
    'Semi-Elliptical Glass Block',
    'Refractive block',
    'semiellipse',
  ),
  OpticalComponent(
    'equilateral',
    'Equilateral Triangular Prism — 60°',
    'Prism',
    'equilateral',
  ),
  OpticalComponent(
    'right45',
    'Right-Angle Isosceles Prism — 45°–45°–90°',
    'Prism',
    'right45',
  ),
  OpticalComponent(
    'right30',
    'Right-Angle Scalene Prism — 30°–60°–90°',
    'Prism',
    'right30',
  ),
  OpticalComponent('triangle', 'Custom Triangular Prism', 'Prism', 'triangle'),
  OpticalComponent('wedge', 'Thin Wedge Prism', 'Prism', 'wedge'),
  OpticalComponent('trapezoid', 'Trapezoidal Prism', 'Prism', 'trapezoid'),
  OpticalComponent('rhombic', 'Rhombic Prism', 'Prism', 'rhombic'),
  OpticalComponent(
    'penta',
    'Pentaprism',
    'Prism',
    'penta',
    status: 'Uncoated five-face prism section; surface reflection/TIR depends on incidence. Use Coated Pentaprism for ideal reflecting faces.',
  ),
  OpticalComponent(
    'roof',
    'Roof Prism',
    'Prism',
    'roof',
    status: 'Valid extruded right-angle roof section with two orthogonal reflecting faces. Does not demonstrate full 3D image inversion.',
  ),
  OpticalComponent(
    'porro',
    'Porro Prism',
    'Prism',
    'porro',
    status: 'One right-angle Porro prism section. No Porro pair or image rotation is claimed.',
  ),
  OpticalComponent(
    'dove',
    'Dove Prism',
    'Prism',
    'dove',
    status: 'Truncated-prism longitudinal section; refraction/TIR calculated. Does not model image rotation under axial rotation.',
  ),
  OpticalComponent(
    'corner',
    'Corner-Cube Retroreflector',
    'Prism',
    'corner',
    status: 'Actual 3D tetrahedral volume with three orthogonal ideal reflecting faces and refracting entrance. 3D direction vectors are reported; XY projection only.',
  ),
  OpticalComponent('biconvex', 'Symmetric Biconvex Lens', 'Lens', 'biconvex'),
  OpticalComponent(
    'asymconvex',
    'Asymmetric Biconvex Lens',
    'Lens',
    'asymconvex',
  ),
  OpticalComponent('planoconvex', 'Plano-Convex Lens', 'Lens', 'planoconvex'),
  OpticalComponent(
    'meniscusplus',
    'Positive Meniscus Lens',
    'Lens',
    'meniscusplus',
  ),
  OpticalComponent(
    'biconcave',
    'Symmetric Biconcave Lens',
    'Lens',
    'biconcave',
  ),
  OpticalComponent(
    'asymconcave',
    'Asymmetric Biconcave Lens',
    'Lens',
    'asymconcave',
  ),
  OpticalComponent(
    'planoconcave',
    'Plano-Concave Lens',
    'Lens',
    'planoconcave',
  ),
  OpticalComponent(
    'meniscusminus',
    'Negative Meniscus Lens',
    'Lens',
    'meniscusminus',
  ),
  OpticalComponent(
    'cylconvex',
    'Cylindrical Plano-Convex Lens',
    'Lens',
    'cylconvex',
    status: 'Powered XY meridional section of a cylindrical lens extruded along Z. No focusing along its unpowered axis.',
  ),
  OpticalComponent(
    'cylconcave',
    'Cylindrical Plano-Concave Lens',
    'Lens',
    'cylconcave',
    status: 'Powered XY meridional section of a cylindrical lens extruded along Z. No focusing along its unpowered axis.',
  ),
  OpticalComponent(
    'frontmirror',
    'Plane Front-Surface Mirror',
    'Mirror',
    'frontmirror',
  ),
  OpticalComponent(
    'backmirror',
    'Plane Back-Surface Glass Mirror',
    'Mirror',
    'backmirror',
    status: 'Fresnel front reflection and internal glass propagation to an ideal lossless rear mirror; ghost rays calculated.',
  ),
  OpticalComponent(
    'concavemirror',
    'Concave Spherical Mirror',
    'Mirror',
    'concavemirror',
  ),
  OpticalComponent(
    'convexmirror',
    'Convex Spherical Mirror',
    'Mirror',
    'convexmirror',
  ),
  OpticalComponent(
    'parabolic',
    'Concave Parabolic Mirror',
    'Mirror',
    'parabolic',
  ),
  OpticalComponent(
    'splitter',
    'Partially Reflective Glass Plate / Beam Splitter',
    'Coated component',
    'splitter',
    status: 'User-prescribed illustrative reflectance on the front face; lossless R+T=1. Remaining interfaces use unpolarized Fresnel. No commercial coating specification.',
  ),
  OpticalComponent(
    'coatedright',
    'Coated Right-Angle Prism',
    'Coated component',
    'coatedright',
    status: 'Ideal 100% lossless reflector on the hypotenuse; uncoated entrance/exit use Fresnel. Educational coating assumption.',
  ),
  OpticalComponent(
    'coatedpenta',
    'Coated Pentaprism',
    'Coated component',
    'coatedpenta',
    status: 'Ideal reflectors on the two 45°-separated long reflecting faces; Fresnel entrance/exit. Educational coating assumption.',
  ),
  OpticalComponent(
    'liquidprism',
    'Hollow Triangular Liquid Prism',
    'Liquid-containing element',
    'liquidprism',
    status: 'Nested finite-thickness N-BK7 container and full liquid fill in a sealed triangular section. No meniscus/fluid dynamics.',
  ),
  OpticalComponent(
    'liquidcell',
    'Rectangular Liquid Cell',
    'Liquid-containing element',
    'liquidcell',
    status: 'Nested finite-thickness N-BK7 container and full liquid fill in a sealed rectangular section. No meniscus/fluid dynamics.',
  ),
];
OpticalComponent opticalComponent(String id) =>
    opticalComponents.firstWhere((c) => c.id == id);

/// Quadratic implicit surface a x²+b y²+c z²+d x+e y+f z+g = 0.
class OpticalSurface {
  final double a, b, c, d, e, f, g;
  final String behavior;
  const OpticalSurface(
    this.a,
    this.b,
    this.c,
    this.d,
    this.e,
    this.f,
    this.g, {
    this.behavior = 'dielectric',
  });
  factory OpticalSurface.plane(
    OVec n,
    double offset, {
    String behavior = 'dielectric',
  }) => OpticalSurface(0, 0, 0, n.x, n.y, n.z, -offset, behavior: behavior);
  OVec normal(OVec p) =>
      OVec(2 * a * p.x + d, 2 * b * p.y + e, 2 * c * p.z + f).unit;
  List<double> intersections(OVec p, OVec v) {
    final qa = a * v.x * v.x + b * v.y * v.y + c * v.z * v.z,
        qb =
            2 * (a * p.x * v.x + b * p.y * v.y + c * p.z * v.z) +
            d * v.x +
            e * v.y +
            f * v.z,
        qc =
            a * p.x * p.x +
            b * p.y * p.y +
            c * p.z * p.z +
            d * p.x +
            e * p.y +
            f * p.z +
            g;
    if (qa.abs() < 1e-13) return qb.abs() < 1e-13 ? [] : [-qc / qb];
    final disc = qb * qb - 4 * qa * qc;
    if (disc < 0) return [];
    final root = math.sqrt(disc);
    final q = -.5 * (qb + (qb >= 0 ? root : -root));
    if (q.abs() < 1e-14) return [-qb / (2 * qa)];
    return [q / qa, qc / q];
  }
}

class OpticalSolid {
  final List<OpticalSurface> surfaces;
  final bool Function(OVec) contains;
  final String material;
  final List<OVec> outline;
  OpticalSolid(this.surfaces, this.contains, this.material, this.outline);
}

class PlacedOptic {
  String component, material;
  OVec position;
  double rotation, size, apex, reflectance;
  PlacedOptic(
    this.component, {
    this.material = 'bk7',
    this.position = const OVec(0, 0),
    this.rotation = 0,
    this.size = 1,
    this.apex = 60,
    this.reflectance = .5,
  });
  OVec local(OVec p) => (p - position).rotate(-rotation) * (1 / size);
  OVec world(OVec p) => p.rotate(rotation) * size + position;
  Map<String, dynamic> toJson() => {
    'component': component,
    'material': material,
    'position': position.toJson(),
    'rotation': rotation,
    'size': size,
    'apex': apex,
    'reflectance': reflectance,
    'definition': opticalComponent(component).toJson(),
    'materialRecord': opticalMaterial(material).toJson(),
  };
  static PlacedOptic fromJson(dynamic j) {
    final m = Map<String, dynamic>.from(j);
    opticalComponent(m['component']);
    opticalMaterial(m['material']);
    double n(String k, double lo, double hi) {
      final v = (m[k] as num).toDouble();
      if (!v.isFinite || v < lo || v > hi) throw FormatException(k);
      return v;
    }

    return PlacedOptic(
      m['component'],
      material: m['material'],
      position: OVec.fromJson(m['position']),
      rotation: n('rotation', -7, 7),
      size: n('size', .2, 2),
      apex: n('apex', 20, 100),
      reflectance: n('reflectance', 0, 1),
    );
  }
}

OpticalSolid polygonSolid(
  List<OVec> vertices,
  String material, {
  Map<int, String> behaviors = const {},
  double halfDepth = .45,
}) {
  // Vertices are counterclockwise; outward normal is (dy,-dx).
  final surfaces = <OpticalSurface>[];
  for (int i = 0; i < vertices.length; i++) {
    final p = vertices[i],
        q = vertices[(i + 1) % vertices.length],
        n = OVec(q.y - p.y, p.x - q.x).unit;
    surfaces.add(
      OpticalSurface.plane(n, n.dot(p), behavior: behaviors[i] ?? 'dielectric'),
    );
  }
  surfaces.addAll([
    OpticalSurface.plane(const OVec(0, 0, 1), halfDepth),
    OpticalSurface.plane(const OVec(0, 0, -1), halfDepth),
  ]);
  bool inside(OVec p) =>
      surfaces.every((s) => s.d * p.x + s.e * p.y + s.f * p.z + s.g <= 1e-10);
  return OpticalSolid(surfaces, inside, material, vertices);
}

List<OVec> rectangle(double x, double y) => [
  OVec(-x, -y),
  OVec(x, -y),
  OVec(x, y),
  OVec(-x, y),
];
OpticalSolid lensSolid(String shape, String material) {
  final cylindrical = shape.startsWith('cyl');
  final concave = [
    'biconcave',
    'asymconcave',
    'planoconcave',
    'cylconcave',
    'concavemirror',
    'parabolic',
  ].contains(shape);
  final plano = [
    'planoconvex',
    'planoconcave',
    'cylconvex',
    'cylconcave',
  ].contains(shape);
  final mirror = shape.endsWith('mirror') || shape == 'parabolic';
  double r1 = .9, r2 = shape.startsWith('asym') ? 1.35 : .9;
  double s1 = concave ? 1 : -1, s2 = concave ? -1 : 1;
  if (shape == 'meniscusplus') {
    r1 = .75;
    r2 = 1.4;
    s1 = -1;
    s2 = -1;
  }
  if (shape == 'meniscusminus') {
    r1 = 1.4;
    r2 = .75;
    s1 = -1;
    s2 = -1;
  }
  final thickness = mirror ? .025 : .30;
  double profile(bool left, OVec p) {
    final rr = cylindrical ? p.y * p.y : p.y * p.y + p.z * p.z;
    if (shape == 'parabolic') return -rr / 1.6 + (left ? 0 : thickness);
    if (mirror) {
      final sign = shape == 'concavemirror' ? 1.0 : -1.0;
      return -sign * r1 +
          sign * math.sqrt(math.max(0, r1 * r1 - rr)) +
          (left ? 0 : thickness);
    }
    if (left && plano) return -thickness / 2;
    final radius = left ? r1 : r2,
        sgn = left ? s1 : s2,
        vertex = left ? -thickness / 2 : thickness / 2;
    return vertex -
        sgn * radius +
        sgn * math.sqrt(math.max(0, radius * radius - rr));
  }

  final surfaces = <OpticalSurface>[];
  for (final left in [true, false]) {
    final behavior = mirror ? (left ? 'mirror' : 'absorb') : 'dielectric';
    if (left && plano) {
      surfaces.add(
        OpticalSurface.plane(
          const OVec(-1, 0),
          thickness / 2,
          behavior: behavior,
        ),
      );
    } else if (shape == 'parabolic') {
      surfaces.add(
        OpticalSurface(
          0,
          1,
          1,
          1.6,
          0,
          0,
          left ? 0 : -1.6 * thickness,
          behavior: behavior,
        ),
      );
    } else {
      final radius = mirror
              ? r1
              : left
              ? r1
              : r2,
          sgn = mirror
              ? (shape == 'concavemirror' ? 1.0 : -1.0)
              : left
              ? s1
              : s2,
          vertex = mirror
              ? (left ? 0 : thickness)
              : left
              ? -thickness / 2
              : thickness / 2,
          cx = vertex - sgn * radius;
      surfaces.add(
        OpticalSurface(
          1,
          1,
          cylindrical ? 0 : 1,
          -2 * cx,
          0,
          0,
          cx * cx - radius * radius,
          behavior: behavior,
        ),
      );
    }
  }
  surfaces.add(
    OpticalSurface(
      0,
      1,
      cylindrical ? 0 : 1,
      0,
      0,
      0,
      -.45 * .45,
      behavior: mirror ? 'absorb' : 'dielectric',
    ),
  );
  if (cylindrical) {
    surfaces.addAll([
      OpticalSurface.plane(const OVec(0, 0, 1), .45),
      OpticalSurface.plane(const OVec(0, 0, -1), .45),
    ]);
  }
  bool inside(OVec p) {
    final rr = cylindrical ? p.y * p.y : p.y * p.y + p.z * p.z;
    return rr <= .45 * .45 + 1e-10 &&
        p.z.abs() <= .45 + 1e-10 &&
        p.x >= profile(true, p) - 1e-10 &&
        p.x <= profile(false, p) + 1e-10;
  }

  final outline = [
    for (int i = 0; i <= 60; i++)
      OVec(profile(true, OVec(0, -.45 + .9 * i / 60)), -.45 + .9 * i / 60),
    for (int i = 60; i >= 0; i--)
      OVec(profile(false, OVec(0, -.45 + .9 * i / 60)), -.45 + .9 * i / 60),
  ];
  return OpticalSolid(surfaces, inside, material, outline);
}

List<OpticalSolid> opticSolids(PlacedOptic p) {
  final id = p.component, mat = p.material;
  if (opticalComponent(id).category == 'Lens' ||
      ['concavemirror', 'convexmirror', 'parabolic'].contains(id)) {
    return [lensSolid(id, mat)];
  }
  if (id == 'corner') {
    final ss = [
      OpticalSurface.plane(const OVec(-1, 0, 0), 0, behavior: 'mirror'),
      OpticalSurface.plane(const OVec(0, -1, 0), 0, behavior: 'mirror'),
      OpticalSurface.plane(const OVec(0, 0, -1), 0, behavior: 'mirror'),
      OpticalSurface.plane(const OVec(1, 1, 1).unit, 1 / math.sqrt(3)),
    ];
    return [
      OpticalSolid(
        ss,
        (v) =>
            v.x >= -1e-10 &&
            v.y >= -1e-10 &&
            v.z >= -1e-10 &&
            v.x + v.y + v.z <= 1 + 1e-10,
        mat,
        [const OVec(0, 0), const OVec(1, 0), const OVec(0, 1)],
      ),
    ];
  }
  if (['semicircle', 'disk', 'quarter', 'semiellipse'].contains(id)) {
    final rx = .65, ry = id == 'semiellipse' ? .4 : .65;
    final ss = [
      OpticalSurface(1 / (rx * rx), 1 / (ry * ry), 0, 0, 0, 0, -1),
      OpticalSurface.plane(const OVec(0, 0, 1), .45),
      OpticalSurface.plane(const OVec(0, 0, -1), .45),
      if (id != 'disk') OpticalSurface.plane(const OVec(0, -1), 0),
      if (id == 'quarter') OpticalSurface.plane(const OVec(-1, 0), 0),
    ];
    bool inside(OVec v) =>
        v.x * v.x / (rx * rx) + v.y * v.y / (ry * ry) <= 1 + 1e-10 &&
        v.z.abs() <= .45 &&
        (id == 'disk' || v.y >= -1e-10) &&
        (id != 'quarter' || v.x >= -1e-10);
    final start = 0.0,
        end = id == 'disk'
            ? 2 * math.pi
            : id == 'quarter'
            ? math.pi / 2
            : math.pi;
    final points = [
      for (int i = 0; i <= 90; i++)
        OVec(
          rx * math.cos(start + (end - start) * i / 90),
          ry * math.sin(start + (end - start) * i / 90),
        ),
      if (id == 'quarter') const OVec(0, 0),
    ];
    return [OpticalSolid(ss, inside, mat, points)];
  }
  List<OVec> v;
  switch (id) {
    case 'equilateral':
    case 'liquidprism':
      v = [
        const OVec(-.5, -.2886751346),
        const OVec(.5, -.2886751346),
        const OVec(0, .5773502692),
      ];
    case 'triangle':
      final half = .6 * math.tan(p.apex * math.pi / 360);
      v = [OVec(-half, -.3), OVec(half, -.3), const OVec(0, .3)];
    case 'right45':
    case 'coatedright':
    case 'roof':
    case 'porro':
      v = [const OVec(-.5, -.5), const OVec(.5, -.5), const OVec(-.5, .5)];
    case 'right30':
      v = [
        const OVec(-.5, -.2886751346),
        const OVec(.5, -.2886751346),
        const OVec(-.5, .2886751346),
      ];
    case 'wedge':
      v = [const OVec(-.06, -.6), const OVec(.06, -.6), const OVec(0, .6)];
    case 'trapezoid':
    case 'dove':
      v = [
        const OVec(-.7, -.3),
        const OVec(.7, -.3),
        const OVec(.4, .3),
        const OVec(-.4, .3),
      ];
    case 'rhombic':
      v = [
        const OVec(-.6, -.4),
        const OVec(.2, -.4),
        const OVec(.6, .4),
        const OVec(-.2, .4),
      ];
    case 'penta':
    case 'coatedpenta':
      // Interior angles: 90°,112.5°,112.5°,112.5°,112.5°; reflector normals 45° apart.
      v = [
        const OVec(-.5, -.5),
        const OVec(.5, -.5),
        const OVec(.792893218, .207106781),
        const OVec(.207106781, .792893218),
        const OVec(-.5, .5),
      ];
    default:
      v = rectangle(
        id == 'square'
            ? .5
            : id == 'thick'
            ? .3
            : id == 'window'
            ? .025
            : id == 'frontmirror'
            ? .025
            : id == 'backmirror'
            ? .12
            : id == 'splitter'
            ? .08
            : .2,
        .6,
      );
  }
  final behavior = <int, String>{};
  if (id == 'frontmirror') behavior[3] = 'mirror';
  if (id == 'backmirror') behavior[1] = 'mirror';
  if (id == 'splitter') behavior[3] = 'splitter';
  if (id == 'coatedright') behavior[1] = 'mirror';
  if (id == 'roof') {
    behavior[0] = 'mirror';
    behavior[2] = 'mirror';
  }
  if (id == 'coatedpenta') {
    behavior[1] = 'mirror';
    behavior[3] = 'mirror';
  }
  if (id.startsWith('liquid')) {
    return [
      polygonSolid(v, 'bk7'),
      polygonSolid(v.map((x) => x * .86).toList(), mat, halfDepth: .387),
    ];
  }
  return [polygonSolid(v, mat, behaviors: behavior)];
}

class RaySegment {
  final OVec start, end, direction, normal;
  final double power, wavelength, n1, n2;
  final int depth;
  final String event;
  const RaySegment(
    this.start,
    this.end,
    this.direction,
    this.power,
    this.wavelength,
    this.depth,
    this.event,
    this.normal,
    this.n1,
    this.n2,
  );
  Map<String, dynamic> toJson() => {
    'start': start.toJson(),
    'end': end.toJson(),
    'direction': direction.toJson(),
    'power': power,
    'nm': wavelength,
    'depth': depth,
    'event': event,
    'normal': normal.toJson(),
    'n1': n1,
    'n2': n2,
  };
}

class TraceResult {
  final segments = <RaySegment>[];
  double escaped = 0, absorbed = 0, truncated = 0;
  int processed = 0;
  double get accounted => escaped + absorbed + truncated;
  Map<String, dynamic> toJson() => {
    'escaped': escaped,
    'absorbed': absorbed,
    'boundedTermination': truncated,
    'accountedPower': accounted,
    'raysProcessed': processed,
    'segments': segments.map((s) => s.toJson()).toList(),
  };
}

class _TraceRay {
  final OVec p, d;
  final double power;
  final int depth;
  _TraceRay(this.p, this.d, this.power, this.depth);
}

class _WorldSolid {
  final PlacedOptic optic;
  final OpticalSolid solid;
  _WorldSolid(this.optic, this.solid);
  bool contains(OVec p) => solid.contains(optic.local(p));
}

class OpticalBench {
  List<PlacedOptic> components = [PlacedOptic('slab')];
  OVec source = const OVec(-2, -.2), direction = const OVec(1, .22);
  double wavelength = 587.6, minPower = .0001;
  int maxDepth = 20, maxRays = 256;
  String sourceMode = 'Single ray', note = '';
  bool normals = false,
      angles = false,
      powers = false,
      grid = true,
      snap = false;
  String get error {
    if (components.isEmpty) return 'Add an optical component.';
    if (components.length > 8) return 'Maximum eight components.';
    try {
      for (final p in components) {
        for (final s in opticSolids(p)) {
          opticalMaterial(s.material).index(wavelength);
          if (sourceMode == 'Visible spectrum' &&
              !opticalMaterial(s.material).dispersive &&
              s.material != 'air') {
            return 'Spectrum requires sourced dispersion for every medium; choose N-BK7, N-F2 or fused silica.';
          }
        }
      }
    } catch (e) {
      return e.toString();
    }
    // Conservative circular footprint separation: overlapping separate components are not supported.
    for (int i = 0; i < components.length; i++) {
      for (int j = i + 1; j < components.length; j++) {
        if ((components[i].position - components[j].position).length <
            1.65 * math.max(components[i].size, components[j].size)) {
          return 'Separate component footprints before tracing (nested liquid walls are supported).';
        }
      }
    }
    return '';
  }

  TraceResult trace({OVec? start, OVec? aim, double? nm}) {
    final result = TraceResult();
    if (error.isNotEmpty) return result;
    final solids = [
      for (final p in components)
        for (final s in opticSolids(p)) _WorldSolid(p, s),
    ];
    double medium(OVec p) {
      String id = 'air';
      for (final s in solids) {
        if (s.contains(p)) id = s.solid.material;
      }
      return opticalMaterial(id).index(nm ?? wavelength);
    }

    final queue = [_TraceRay(start ?? source, (aim ?? direction).unit, 1, 0)];
    const eps = 1e-7;
    while (queue.isNotEmpty) {
      final ray = queue.removeLast();
      if (ray.depth >= maxDepth ||
          ray.power < minPower ||
          result.processed >= maxRays) {
        result.truncated += ray.power;
        continue;
      }
      result.processed++;
      double distance = double.infinity;
      _WorldSolid? body;
      OpticalSurface? surface;
      OVec? at;
      for (final b in solids) {
        final o = b.optic.local(ray.p),
            d = ray.d.rotate(-b.optic.rotation) * (1 / b.optic.size);
        for (final face in b.solid.surfaces) {
          for (final t in face.intersections(o, d)) {
            if (t <= eps || t >= distance || !t.isFinite) continue;
            final hit = ray.p + ray.d * t;
            if (b.contains(hit + ray.d * eps) ==
                b.contains(hit - ray.d * eps)) {
              continue;
            }
            distance = t;
            body = b;
            surface = face;
            at = hit;
          }
        }
      }
      if (body == null) {
        result.segments.add(
          RaySegment(
            ray.p,
            ray.p + ray.d * 4,
            ray.d,
            ray.power,
            nm ?? wavelength,
            ray.depth,
            'exit',
            const OVec(0, 0),
            medium(ray.p),
            1,
          ),
        );
        result.escaped += ray.power;
        continue;
      }
      final hit = at!, face = surface!;
      var n = face.normal(body.optic.local(hit)).rotate(body.optic.rotation);
      if (n.dot(ray.d) > 0) n = n * -1;
      final n1 = medium(hit - ray.d * eps),
          n2 = medium(hit + ray.d * eps),
          cosI = (-ray.d.dot(n)).clamp(0.0, 1.0),
          eta = n1 / n2,
          k = 1 - eta * eta * (1 - cosI * cosI);
      double reflect = 0;
      OVec? transmitted;
      String event = face.behavior;
      if (face.behavior == 'absorb') {
        result.absorbed += ray.power;
      } else if (face.behavior == 'mirror') {
        reflect = 1;
      } else if (k < -1e-12) {
        reflect = 1;
        event = 'TIR';
      } else {
        final cosT = math.sqrt(math.max(0, k));
        transmitted = (ray.d * eta + n * (eta * cosI - cosT)).unit;
        if (face.behavior == 'splitter') {
          reflect = body.optic.reflectance;
        } else if ((n1 - n2).abs() < 1e-12) {
          reflect = 0;
        } else {
          final rs = (n1 * cosI - n2 * cosT) / (n1 * cosI + n2 * cosT),
              rp = (n1 * cosT - n2 * cosI) / (n1 * cosT + n2 * cosI);
          reflect = ((rs * rs + rp * rp) / 2).clamp(0.0, 1.0);
        }
      }
      result.segments.add(
        RaySegment(
          ray.p,
          hit,
          ray.d,
          ray.power,
          nm ?? wavelength,
          ray.depth,
          event,
          n,
          n1,
          n2,
        ),
      );
      if (face.behavior == 'absorb') continue;
      if (reflect > 0) {
        final d = (ray.d - n * (2 * ray.d.dot(n))).unit;
        queue.add(
          _TraceRay(hit + d * eps, d, ray.power * reflect, ray.depth + 1),
        );
      }
      if (transmitted != null && reflect < 1) {
        queue.add(
          _TraceRay(
            hit + transmitted * eps,
            transmitted,
            ray.power * (1 - reflect),
            ray.depth + 1,
          ),
        );
      }
    }
    return result;
  }

  List<TraceResult> get traces => error.isNotEmpty
      ? []
      : sourceMode == 'Visible spectrum'
      ? [
          for (final nm in [450.0, 550.0, 650.0]) trace(nm: nm),
        ]
      : sourceMode == 'Parallel bundle'
      ? [
          for (final dy in [-.2, 0.0, .2]) trace(start: source + OVec(0, dy)),
        ]
      : [trace()];
  Map<String, dynamic> toJson() => {
    'model': materialBenchVersion,
    'dataVersion': opticalDataVersion,
    'components': components.map((p) => p.toJson()).toList(),
    'source': source.toJson(),
    'direction': direction.toJson(),
    'wavelength': wavelength,
    'minPower': minPower,
    'maxDepth': maxDepth,
    'maxRays': maxRays,
    'sourceMode': sourceMode,
    'note': note,
    'normals': normals,
    'angles': angles,
    'powers': powers,
    'grid': grid,
    'snap': snap,
  };
  static OpticalBench fromJson(Map<String, dynamic> j) {
    if (j['model'] != materialBenchVersion ||
        j['dataVersion'] != opticalDataVersion) {
      throw const FormatException('Optical version');
    }
    final b = OpticalBench()
      ..components = (j['components'] as List)
          .map(PlacedOptic.fromJson)
          .toList()
      ..source = OVec.fromJson(j['source'])
      ..direction = OVec.fromJson(j['direction'])
      ..note = j['note'] as String
      ..sourceMode = j['sourceMode'] as String;
    double n(String k, double lo, double hi) {
      final v = (j[k] as num).toDouble();
      if (!v.isFinite || v < lo || v > hi) throw FormatException(k);
      return v;
    }

    b.wavelength = n('wavelength', 400, 700);
    b.minPower = n('minPower', .00001, .01);
    b.maxDepth = n('maxDepth', 1, 40).toInt();
    b.maxRays = n('maxRays', 16, 512).toInt();
    if (b.components.isEmpty ||
        b.components.length > 8 ||
        b.direction.length < 1e-9 ||
        ![
          'Single ray',
          'Parallel bundle',
          'Visible spectrum',
        ].contains(b.sourceMode)) {
      throw const FormatException('Optical arrangement');
    }
    b.normals = j['normals'] as bool;
    b.angles = j['angles'] as bool;
    b.powers = j['powers'] as bool;
    b.grid = j['grid'] as bool;
    b.snap = j['snap'] as bool;
    return b;
  }
}
