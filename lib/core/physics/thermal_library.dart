
import 'electronics_thermal.dart' show conduction;

const materialBenchVersion = 'materials-optics-1.0';
const thermalDataVersion = 'thermal-2026-10';
const motorCadSource =
    'https://ansyshelp.ansys.com/public/Views/Secured/MotorCAD/v252/en/Motor-CAD_UG/MotorCAD/topics/materialhelp.html';
const ashraeSource =
    'https://handbook.ashrae.org/Handbooks/F25/SI/F25_Ch26/F25_Ch26_si.aspx';

class ThermalMaterial {
  final String id,
      name,
      category,
      grade,
      source,
      direction,
      texture,
      conditions;
  final double? density, cp, k;
  final double referenceK;
  final int color;
  final bool fluid;
  final List<double>? kRange;
  const ThermalMaterial(
    this.id,
    this.name,
    this.category,
    this.grade,
    this.source,
    this.color,
    this.texture, {
    this.density,
    this.cp,
    this.k,
    this.referenceK = 300,
    this.direction = 'Isotropic approximation',
    this.fluid = false,
    this.kRange,
    this.conditions = 'Typical reference values; uncertainty not supplied. No measured temperature range. Constant-property teaching approximation only.',
  });
  bool get conducts => k != null && !fluid;
  bool get heats => density != null && cp != null;
  String get validity =>
      'Constant model within ±10 K of $referenceK K reference; this is an imposed teaching limit, not a measured validity range. No phase changes.';
  bool supports(double lo, double hi) =>
      lo.isFinite &&
      hi.isFinite &&
      lo > 0 &&
      hi > 0 &&
      (lo - referenceK).abs() <= 10 &&
      (hi - referenceK).abs() <= 10;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'class': category,
    'grade': grade,
    'density_kg_m3': density,
    'cp_J_kgK': cp,
    'k_W_mK': k,
    'reference_K': referenceK,
    'validity': validity,
    'conditions': conditions,
    'direction': direction,
    'source': source,
    'uncertainty': 'Not supplied unless range shown',
    'kRange': kRange,
    'asset': 'Procedural $texture',
    'colorARGB': color,
    'sourceVersion': thermalDataVersion,
  };
}

const thermalMaterials = <ThermalMaterial>[
  ThermalMaterial(
    'copper',
    'Copper',
    'Metal',
    'Pure copper, Motor-CAD reference',
    motorCadSource,
    0xffbc754c,
    'brushed',
    density: 8933,
    cp: 385,
    k: 401,
  ),
  ThermalMaterial(
    'aluminium',
    'Aluminium',
    'Metal',
    'Pure aluminium, Motor-CAD reference',
    motorCadSource,
    0xffc9d2db,
    'brushed',
    density: 2702,
    cp: 903,
    k: 237,
  ),
  ThermalMaterial(
    'silver',
    'Silver',
    'Metal',
    'Goodfellow silver foil, pure metal',
    'https://www.goodfellow.com/global/silver-foil-group',
    0xffe3e7e8,
    'polished',
    cp: 237,
    k: 429,
    referenceK: 298.15,
    conditions: 'cp at 25 °C; k typical 0–100 °C. Density not transcribed; heating disabled.',
  ),
  ThermalMaterial(
    'gold',
    'Gold',
    'Metal',
    'Grade not qualified',
    'https://tpsx.arc.nasa.gov/Material?id=575',
    0xffd6ab39,
    'polished',
    conditions: 'Available source lists assumed properties with unknown conditions. Values deliberately unavailable.',
  ),
  ThermalMaterial(
    'brass',
    'Brass',
    'Metal',
    '70% Cu / 30% Zn',
    motorCadSource,
    0xffbfa454,
    'brushed',
    density: 8522,
    cp: 385,
    k: 111,
  ),
  ThermalMaterial(
    'bronze',
    'Bronze',
    'Metal',
    'UNS C51000, 5% Sn / 0.2% P reference',
    'https://alloys.copper.org/alloy/C51000',
    0xff9b7947,
    'brushed',
    density: 8860,
    cp: 376.812,
    k: 69.2294,
    referenceK: 293.15,
    conditions: '20 °C values. Converted 0.09 Btu/lb/°F and 40 Btu/(h ft °F) to SI. Composition dependent.',
  ),
  ThermalMaterial(
    'carbon-steel',
    'Carbon Steel',
    'Metal',
    'Grade / heat treatment not qualified',
    'https://www.nist.gov/srd',
    0xff78818a,
    'brushed',
    conditions: 'No compatible grade-specific source record transcribed. Properties unavailable.',
  ),
  ThermalMaterial(
    'stainless',
    'Stainless Steel',
    'Metal',
    'AISI 304, Motor-CAD reference',
    motorCadSource,
    0xffa1b3c1,
    'brushed',
    density: 7900,
    cp: 477,
    k: 14.9,
  ),
  ThermalMaterial(
    'cast-iron',
    'Cast Iron',
    'Metal',
    'Generic cast iron reference; graphite grade unspecified',
    motorCadSource,
    0xff484b4c,
    'granular',
    density: 7272,
    cp: 420,
    k: 52,
  ),
  ThermalMaterial(
    'titanium',
    'Titanium',
    'Metal',
    'Goodfellow commercially pure foil',
    'https://www.goodfellow.com/global/titanium-foil-group',
    0xff9ca1a3,
    'brushed',
    cp: 523,
    k: 21.9,
    referenceK: 298.15,
    conditions: 'cp at 25 °C, k typical 0–100 °C. Density not transcribed; heating disabled.',
  ),
  ThermalMaterial(
    'lead',
    'Lead',
    'Metal',
    'Grade not qualified',
    'https://www.nist.gov/srd',
    0xff676d78,
    'matte',
    conditions: 'No compatible grade-specific source record transcribed. Properties unavailable.',
  ),
  ThermalMaterial(
    'zinc',
    'Zinc',
    'Metal',
    'Pure zinc, Motor-CAD reference',
    motorCadSource,
    0xffa7b7c6,
    'brushed',
    density: 7140,
    cp: 389,
    k: 116,
  ),
  ThermalMaterial(
    'soda-lime',
    'Soda-Lime Glass',
    'Glass / ceramic / mineral',
    'Architectural soda-lime float glass, ASHRAE generic',
    ashraeSource,
    0xffb9d9db,
    'glass',
    density: 2500,
    cp: 840,
    k: 1,
  ),
  ThermalMaterial(
    'borosilicate',
    'Borosilicate Glass',
    'Glass / ceramic / mineral',
    'SCHOTT BOROFLOAT 33',
    'https://www.schott.com/en-gb/products/b/borofloat/content/technical-details',
    0xffc4e0dd,
    'glass',
    density: 2230,
    cp: 830,
    k: 1.2,
    referenceK: 363.15,
    conditions: 'k at 90 °C; cp 20–100 °C; density at 25 °C. Density fixed in this small-temperature-range model.',
  ),
  ThermalMaterial(
    'silica',
    'Fused Silica',
    'Glass / ceramic / mineral',
    'Crystran optical fused silica',
    'https://www.crystran.com/optical-materials/fused-silica-sio2/',
    0xffd5e8ea,
    'glass',
    density: 2203,
    cp: 703,
    k: 1.38,
    referenceK: 293.15,
  ),
  ThermalMaterial(
    'alumina',
    'Alumina Ceramic',
    'Glass / ceramic / mineral',
    'CoorsTek AD-995, 99.5% Al2O3',
    'https://www.coorstek.com/media/4235/advanced-alumina.pdf',
    0xffeee5ca,
    'ceramic',
    density: 3900,
    k: 30,
    referenceK: 293.15,
    conditions: 'k at 20 °C; density typical. cp published at 100 °C, not combined with room-temperature record; heating disabled.',
  ),
  ThermalMaterial(
    'porcelain',
    'Porcelain',
    'Glass / ceramic / mineral',
    'Composition / firing not qualified',
    ashraeSource,
    0xffe5e1dc,
    'ceramic',
    conditions: 'No compatible grade-specific source record transcribed. Properties unavailable.',
  ),
  ThermalMaterial(
    'granite',
    'Granite',
    'Glass / ceramic / mineral',
    'Natural granite; mineralogy and moisture unspecified',
    ashraeSource,
    0xff94908c,
    'granite',
    kRange: [1.7, 4.3],
    conditions: 'ASHRAE Table 9 conductivity range only. No representative scalar chosen; calculations disabled.',
  ),
  ThermalMaterial(
    'marble',
    'Marble',
    'Glass / ceramic / mineral',
    'Natural marble; composition and moisture unspecified',
    ashraeSource,
    0xffe3ded3,
    'marble',
    kRange: [1.2, 4.3],
    conditions: 'ASHRAE limestone/dolomite/marble range only. No scalar chosen; calculations disabled.',
  ),
  ThermalMaterial(
    'concrete',
    'Concrete',
    'Glass / ceramic / mineral',
    'Aggregate / moisture / density not qualified',
    ashraeSource,
    0xff9f9c96,
    'granular',
    conditions: 'Concrete properties depend strongly on aggregate and moisture. No qualified scalar record.',
  ),
  ThermalMaterial(
    'firebrick',
    'Firebrick',
    'Glass / ceramic / mineral',
    'Insulating firebrick; grade not qualified',
    'https://www.firebirdref.com/products/insulating-firebrick/',
    0xffcbb499,
    'porous',
    conditions: 'No room-temperature qualified grade record; high-temperature conductivity not substituted.',
  ),
  ThermalMaterial(
    'hdpe',
    'HDPE',
    'Polymer / insulator',
    'Grade and crystallinity not qualified',
    'https://www.professionalplastics.com/professionalplastics/ThermalPropertiesofPlasticMaterials.pdf',
    0xffe5e6dc,
    'matte',
    conditions: 'Generic range is insufficient for a matched density/cp/k record. Properties unavailable.',
  ),
  ThermalMaterial(
    'pvc',
    'PVC',
    'Polymer / insulator',
    'Plasticizer and grade not qualified',
    'https://www.professionalplastics.com/professionalplastics/ThermalPropertiesofPlasticMaterials.pdf',
    0xffbec8cd,
    'matte',
    conditions: 'Rigid and plasticized PVC differ. No matched grade record transcribed.',
  ),
  ThermalMaterial(
    'ptfe',
    'PTFE',
    'Polymer / insulator',
    'Motor-CAD Teflon reference',
    motorCadSource,
    0xfff0efe9,
    'matte',
    density: 2200,
    cp: 1040,
    k: .22,
  ),
  ThermalMaterial(
    'pmma',
    'PMMA / Acrylic',
    'Polymer / insulator',
    'Generic unfilled acrylic range',
    'https://www.professionalplastics.com/professionalplastics/ThermalPropertiesofPlasticMaterials.pdf',
    0xffbfdde5,
    'glass',
    cp: 1400,
    kRange: [.17, .19],
    conditions: 'Generic range, no matching density or chosen conductivity. Calculations disabled.',
  ),
  ThermalMaterial(
    'silicone',
    'Silicone Rubber',
    'Polymer / insulator',
    'Formulation / fillers not qualified',
    'https://www.nist.gov/srd',
    0xffbdb8b1,
    'matte',
    conditions:
        'Filled and unfilled formulations differ. Properties unavailable.',
  ),
  ThermalMaterial(
    'cork',
    'Cork',
    'Polymer / insulator',
    'FAO expanded corkboard, 150 kg/m³',
    'https://www.fao.org/4/y5013e/y5013e08.htm',
    0xffac8558,
    'porous',
    density: 150,
    kRange: [.037, .043],
    referenceK: 295.65,
    conditions: '20–25 °C range only; no single conductivity chosen. Calculations disabled.',
  ),
  ThermalMaterial(
    'eps',
    'Expanded Polystyrene',
    'Polymer / insulator',
    'Density / aging not qualified',
    ashraeSource,
    0xffeeede7,
    'foam',
    conditions: 'Apparent conductivity depends on density and aging. No qualified scalar record.',
  ),
  ThermalMaterial(
    'wool',
    'Mineral Wool',
    'Polymer / insulator',
    'ROCKWOOL RWA45 declared conductivity',
    'https://www.rockwool.com/uk/products/rwa45/',
    0xffb5ae88,
    'fibres',
    k: .035,
    referenceK: 283.15,
    conditions: 'Declared apparent conductivity. cp/density not transcribed; heating disabled. No convection solver.',
  ),
  ThermalMaterial(
    'pine-long',
    'Pine — Along Grain',
    'Wood',
    'Species / moisture not qualified',
    ashraeSource,
    0xffc89c62,
    'wood-long',
    direction: 'Along grain',
    conditions: 'No matched longitudinal data; transverse conductivity is not substituted.',
  ),
  ThermalMaterial(
    'pine-cross',
    'Pine — Across Grain',
    'Wood',
    'Eastern white pine reference, transverse',
    ashraeSource,
    0xffc89c62,
    'wood-cross',
    density: 400,
    k: .10,
    direction: 'Across grain',
    conditions: 'ASHRAE/Kumaran reference. Moisture and temperature are source reference conditions, not a universal pine value. cp unavailable.',
  ),
  ThermalMaterial(
    'oak-long',
    'Oak — Along Grain',
    'Wood',
    'Species / moisture not qualified',
    ashraeSource,
    0xff967049,
    'wood-long',
    direction: 'Along grain',
    conditions: 'No matched longitudinal data; transverse conductivity is not substituted.',
  ),
  ThermalMaterial(
    'oak-cross',
    'Oak — Across Grain',
    'Wood',
    'Oak reference range, transverse',
    ashraeSource,
    0xff967049,
    'wood-cross',
    kRange: [.16, .18],
    direction: 'Across grain',
    conditions: 'ASHRAE density 660–750 kg/m³; conductivity range only. No scalar chosen.',
  ),
  ThermalMaterial(
    'water',
    'Water',
    'Fluid',
    'Motor-CAD liquid water reference',
    motorCadSource,
    0xff83b8d2,
    'liquid',
    density: 1000,
    cp: 4182,
    k: .597,
    fluid: true,
    conditions: 'Reference approximation only. Solid-rod conduction disabled; heater assumes a well-mixed liquid, no boiling.',
  ),
  ThermalMaterial(
    'glycerol',
    'Glycerol',
    'Fluid',
    'ITW reagent glycerol; thermal data not qualified',
    'https://www.itwreagents.com/download_file/tds/131339/en/tds_131339_en.pdf',
    0xffc7d5b7,
    'liquid',
    fluid: true,
    conditions: 'Optical index does not supply thermal properties. Thermal calculations disabled.',
  ),
  ThermalMaterial(
    'air',
    'Air',
    'Fluid',
    'Motor-CAD reference air at 27 °C',
    motorCadSource,
    0xffd6e1e4,
    'gas',
    density: 1.1774,
    cp: 1006,
    k: .0262,
    fluid: true,
    conditions: 'Heating uses a constant-pressure well-mixed ideal reservoir approximation with cp, not a sealed constant-volume vessel. No free convection simulation.',
  ),
];
ThermalMaterial thermalMaterial(String id) =>
    thermalMaterials.firstWhere((m) => m.id == id);

class ThermalBench {
  String mode = 'Conduction comparison';
  List<String> materials = ['copper', 'aluminium', 'stainless'];
  double length = .1,
      area = .0001,
      hot = 305,
      cold = 295,
      mass = .1,
      volume = .00001,
      power = 5,
      seconds = 10,
      contact = 0;
  bool equalVolume = false, overlay = false;
  List<double> thicknesses = [.02, .02, .02];
  String note = '';
  static const modes = [
    'Conduction comparison',
    'Heating / heat capacity',
    'Insulation / composite',
  ];
  String get error {
    if (!modes.contains(mode) || materials.length < 2 || materials.length > 3) {
      return 'Select two or three samples.';
    }
    if ([length, area, mass, volume, power].any((v) => !v.isFinite || v <= 0) ||
        [hot, cold, seconds, contact, ...thicknesses].any((v) => !v.isFinite) ||
        seconds < 0 ||
        contact < 0 ||
        thicknesses.any((v) => v <= 0)) {
      return 'Use finite positive dimensions and nonnegative time/contact resistance.';
    }
    for (final id in materials) {
      final m = thermalMaterial(id);
      if (mode == modes[1]) {
        if (!m.heats) {
          return '${m.name}: matched density and specific heat unavailable.';
        }
        final end =
            cold +
            power *
                seconds /
                ((equalVolume ? m.density! * volume : mass) * m.cp!);
        if (!m.supports(cold, end)) {
          return '${m.name}: keep start/end within ±10 K of ${m.referenceK} K. No phase-change model.';
        }
      } else {
        if (!m.conducts) {
          return '${m.name}: solid conductivity unavailable${m.fluid ? ' (fluid convection not modeled)' : ''}.';
        }
        if (!m.supports(hot, cold)) {
          return '${m.name}: boundaries outside the constant-property teaching window (${m.referenceK} ±10 K).';
        }
      }
    }
    return '';
  }

  List<Map<String, double>> get readings {
    if (error.isNotEmpty) return [];
    if (mode == modes[1]) {
      return materials.map((id) {
        final m = thermalMaterial(id),
            sampleMass = equalVolume ? m.density! * volume : mass,
            energy = power * seconds;
        return {
          'mass': sampleMass,
          'temperature': cold + energy / (sampleMass * m.cp!),
          'supplied': energy,
          'stored': energy,
          'loss': 0.0,
        };
      }).toList();
    }
    if (mode == modes[0]) {
      return materials
          .map(
            (id) => {
              'power': conduction(
                thermalMaterial(id).k!,
                area,
                hot,
                cold,
                length,
              ),
              'resistance': length / (thermalMaterial(id).k! * area),
            },
          )
          .toList();
    }
    final resistances = [
      for (int i = 0; i < materials.length; i++)
        thicknesses[i] / (thermalMaterial(materials[i]).k! * area),
    ];
    final total =
            resistances.fold(0.0, (a, b) => a + b) +
            contact * (materials.length - 1),
        q = (hot - cold) / total;
    double boundary = hot;
    return [
      for (int i = 0; i < materials.length; i++)
        (() {
          final start = boundary;
          boundary -= q * resistances[i];
          final end = boundary;
          if (i < materials.length - 1) boundary -= q * contact;
          return {
            'power': q,
            'resistance': resistances[i],
            'start': start,
            'end': end,
            'contactDrop': i < materials.length - 1 ? q * contact : 0.0,
            'totalResistance': total,
          };
        })(),
    ];
  }

  Map<String, dynamic> toJson() => {
    'model': materialBenchVersion,
    'dataVersion': thermalDataVersion,
    'mode': mode,
    'materials': materials,
    'length': length,
    'area': area,
    'hot': hot,
    'cold': cold,
    'mass': mass,
    'volume': volume,
    'power': power,
    'seconds': seconds,
    'contact': contact,
    'thicknesses': thicknesses,
    'equalVolume': equalVolume,
    'overlay': overlay,
    'note': note,
    'materialRecords': materials
        .map((id) => thermalMaterial(id).toJson())
        .toList(),
    'readings': readings,
  };
  static ThermalBench fromJson(Map<String, dynamic> j) {
    if (j['model'] != materialBenchVersion ||
        j['dataVersion'] != thermalDataVersion) {
      throw const FormatException('Material version');
    }
    final b = ThermalBench()
      ..mode = j['mode'] as String
      ..materials = List<String>.from(j['materials'])
      ..equalVolume = j['equalVolume'] as bool
      ..overlay = j['overlay'] as bool
      ..note = j['note'] as String;
    for (final id in b.materials) {
      thermalMaterial(id);
    }
    double n(String k, double lo, double hi) {
      final v = (j[k] as num).toDouble();
      if (!v.isFinite || v < lo || v > hi) throw FormatException(k);
      return v;
    }

    b.length = n('length', .001, 2);
    b.area = n('area', 1e-8, 1);
    b.hot = n('hot', 273, 383);
    b.cold = n('cold', 273, 383);
    b.mass = n('mass', .00001, 10);
    b.volume = n('volume', 1e-9, 1);
    b.power = n('power', .001, 1000);
    b.seconds = n('seconds', 0, 3600);
    b.contact = n('contact', 0, 1e6);
    b.thicknesses = (j['thicknesses'] as List)
        .map((v) => (v as num).toDouble())
        .toList();
    if (!modes.contains(b.mode) ||
        b.materials.length < 2 ||
        b.materials.length > 3 ||
        b.thicknesses.length != 3 ||
        b.thicknesses.any((v) => !v.isFinite || v <= 0 || v > 2)) {
      throw const FormatException('Thermal arrangement');
    }
    return b;
  }

  List<List<double>> get curves => error.isNotEmpty
      ? []
      : [
          for (int i = 0; i < materials.length; i++)
            [
              for (int j = 0; j <= 40; j++)
                mode == modes[1]
                    ? cold + (readings[i]['temperature']! - cold) * j / 40
                    : mode == modes[0]
                    ? hot + (cold - hot) * j / 40
                    : readings[i]['start']! +
                          (readings[i]['end']! - readings[i]['start']!) *
                              j /
                              40,
            ],
        ];
}
