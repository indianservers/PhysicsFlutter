import 'dart:async';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../content/catalog.dart';
import '../../core/persistence/notebook.dart';
import '../../core/physics/thermal_library.dart';
import '../../core/physics/optical_library.dart';
import '../workbench/workbench.dart';
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'scene.dart';

class MaterialBenchWorkspace extends ConsumerStatefulWidget {
  final Entry entry;
  const MaterialBenchWorkspace({super.key, required this.entry});
  @override
  ConsumerState<MaterialBenchWorkspace> createState() => MaterialBenchState();
}

class MaterialBenchState extends ConsumerState<MaterialBenchWorkspace>
    with WidgetsBindingObserver {
  late LocalNotebook store;
  ThermalBench thermal = ThermalBench();
  OpticalBench optical = OpticalBench();
  final revision = ValueNotifier(0);
  List<TraceResult> traced = [];
  int selected = 0, section = 1;
  bool ready = false, focus = false, dragging = false;
  bool get isThermal => widget.entry.id == 's13-e01';
  String get sessionKey => 'bench:${widget.entry.id}';
  PlacedOptic get chosen =>
      optical.components[selected.clamp(0, optical.components.length - 1)];
  String get error => isThermal ? thermal.error : optical.error;
  @override
  void initState() {
    super.initState();
    store = ref.read(notebookProvider);
    WidgetsBinding.instance.addObserver(this);
    if (!isThermal) {
      optical.components = [
        PlacedOptic(
          widget.entry.index == 0
              ? 'frontmirror'
              : widget.entry.index == 2
              ? 'biconvex'
              : widget.entry.index == 3
              ? 'concavemirror'
              : 'slab',
        ),
      ];
    }
    load();
  }

  Future<void> load() async {
    final saved = await store.readSession(sessionKey);
    if (saved != null && !restore(saved)) {
      await store.retainRejectedSession(sessionKey, saved);
    }
    if (mounted) {
      setState(() => ready = true);
      changed();
    }
  }

  bool restore(Map<String, dynamic> j) {
    try {
      if (j['bench'] != (isThermal ? 'thermal' : 'optical')) return false;
      if (isThermal) {
        thermal = ThermalBench.fromJson(j);
      } else {
        optical = OpticalBench.fromJson(j);
        selected = 0;
      }
      traced = isThermal ? [] : optical.traces;
      return true;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic> configuration() => {
    ...(isThermal ? thermal.toJson() : optical.toJson()),
    'bench': isThermal ? 'thermal' : 'optical',
  };
  void changed() {
    if (!isThermal) {
      traced = optical.traces;
    }
    revision.value++;
    if (mounted) setState(() {});
  }

  Future<void> save() async {
    await store.saveSession(sessionKey, configuration());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Arrangement saved.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && ready) {
      unawaited(store.saveSession(sessionKey, configuration()));
    }
  }

  @override
  void dispose() {
    if (ready) unawaited(store.saveSession(sessionKey, configuration()));
    WidgetsBinding.instance.removeObserver(this);
    revision.dispose();
    super.dispose();
  }

  Future<Uint8List> captureWorkspaceImage() async {
    final boundary =
        appCaptureKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      return bytes!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> exportImage() async {
    try {
      final bytes = await captureWorkspaceImage();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
              name: 'physics-workspace.png',
            ),
          ],
          fileNameOverrides: ['physics-workspace.png'],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image export could not open.')),
        );
      }
    }
  }

  double? get deviation {
    if (traced.isEmpty) return null;
    final exits = traced.first.segments.where((s) => s.event == 'exit').toList()
      ..sort((a, b) => b.power.compareTo(a.power));
    if (exits.isEmpty) return null;
    return math.acos(
          exits.first.direction.dot(optical.direction.unit).clamp(-1, 1),
        ) *
        180 /
        math.pi;
  }

  Future<void> record() async {
    if (error.isNotEmpty) return;
    final readings = isThermal ? thermal.readings : [];
    final quantity = isThermal
        ? (thermal.mode == ThermalBench.modes[1] ? 'temperature' : 'power')
        : deviation == null
        ? 'relativeIntensity'
        : 'angle';
    final value = isThermal
        ? readings.first[quantity]!
        : deviation ?? traced.first.escaped;
    final config = {
      ...configuration(),
      'observations': isThermal
          ? readings
          : traced.map((t) => t.toJson()).toList(),
    };
    await store.addTrial(
      Trial(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        labId: widget.entry.id,
        quantity: quantity,
        unit: isThermal
            ? (quantity == 'temperature' ? 'K' : 'W')
            : quantity == 'angle'
            ? '°'
            : '',
        value: value,
        resolution: null,
        configuration: config,
        note: isThermal ? thermal.note : optical.note,
        model: materialBenchVersion,
      ),
    );
    await store.saveSession(sessionKey, configuration());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calculated readings recorded.'),
          duration: Duration(seconds: 1),
        ),
      );
      changed();
    }
  }

  void numeric(
    String name,
    double value,
    double min,
    double max,
    ValueChanged<double> apply,
  ) => showDialog<void>(
    context: context,
    builder: (_) => NumericInputDialog(
      label: name,
      initial: value,
      min: min,
      max: max,
      onApply: (v) {
        apply(v);
        changed();
      },
    ),
  );
  Future<void> sheet(String title, List<Widget> Function() body) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) => ValueListenableBuilder<int>(
          valueListenable: revision,
          builder: (c, value, child) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
            child: SizedBox(
              height: MediaQuery.sizeOf(c).height * .8,
              child: Column(
                children: [
                  ListTile(
                    title: Text(title),
                    trailing: IconButton(
                      tooltip: 'Close panel',
                      onPressed: () => Navigator.pop(c),
                      icon: const Icon(Icons.close),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: body(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
  void componentPicker({bool add = false}) => sheet(
    'Optical components · 40 entries',
    () => [
      for (final d in opticalComponents)
        ListTile(
          title: Text(d.name),
          subtitle: Text('${d.category} · ${d.status}'),
          onTap: () {
            final p = PlacedOptic(
              d.id,
              position: add
                  ? OVec(optical.components.length * 2.0, 0)
                  : chosen.position,
            );
            if (d.category == 'Liquid-containing element') p.material = 'water';
            if (add) {
              if (optical.components.length >= 8) return;
              optical.components.add(p);
              selected = optical.components.length - 1;
            } else {
              optical.components[selected] = p;
            }
            Navigator.pop(context);
            focus = false;
            changed();
          },
        ),
    ],
  );
  void materialPicker(int index) => sheet(
    'Thermal materials · 36 entries',
    () => [
      for (final m in thermalMaterials)
        ListTile(
          title: Text(m.name),
          subtitle: Text(
            '${m.grade}\n${m.conducts ? 'k ${m.k} W/(m·K)' : 'Solid conduction unavailable'} · ${m.heats ? 'ρ ${m.density} kg/m³ · cp ${m.cp} J/(kg·K)' : 'Heating unavailable'}',
          ),
          onTap: () {
            thermal.materials[index] = m.id;
            Navigator.pop(context);
            changed();
          },
        ),
    ],
  );
  void propertyPanel() => sheet(
    isThermal
        ? 'Material properties and model'
        : 'Component and optical material',
    () => isThermal
        ? [
            for (final id in thermal.materials) ...[
              Text(
                thermalMaterial(id).name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(
                thermalMaterial(id)
                    .toJson()
                    .entries
                    .map((e) => '${e.key}: ${e.value ?? 'Unavailable'}')
                    .join('\n'),
              ),
              const Divider(),
            ],
            const Text(
              'Conduction answers how quickly energy flows for a gradient. Heat capacity answers how much energy changes temperature. Equal dimensions, boundaries and heater power are shared across comparisons. Conduction is 1D steady state, insulated sides, no transient solver; temperature profiles are not time evolution. Heating is a well-mixed constant-cp energy balance, no losses, no phase change. Contact resistance is an explicit total K/W parameter per interface. Insulation apparent k can include microscopic heat transport; this is not a free-fluid convection solver.',
            ),
          ]
        : [
            Text(opticalComponent(chosen.component).name),
            Text(opticalComponent(chosen.component).status),
            SelectableText(
              opticalMaterial(chosen.material)
                  .toJson()
                  .entries
                  .map((e) => '${e.key}: ${e.value ?? 'Unavailable'}')
                  .join('\n'),
            ),
            const Text(
              'Exact analytic surface intersections in 3D with vector Snell refraction, reflection and total internal reflection. Unpolarized Fresnel power per interface; no absorption data, so transparent bulk is lossless. Ideal mirror faces use R=1. Beam-splitter coating R is illustrative and explicitly prescribed, not manufacturer performance. Branching and low-power tails are bounded and accounted as terminated power. Separate component footprints; nested liquid walls are built in. Colored paths are educational overlays, not photographs of light in air.',
            ),
            if (widget.entry.id == 's09-e00')
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          MaterialBenchWorkspace(entry: entryById('s09-e01')),
                    ),
                  );
                },
                child: const Text(
                  'Investigate refraction and total internal reflection',
                ),
              ),
          ],
  );
  void inspector() => sheet(
    isThermal
        ? 'Geometry and boundary conditions'
        : 'Selected component and source',
    () => [
      if (isThermal) ...[
        for (final pair in [
          (
            'Length (m)',
            thermal.length,
            .001,
            1.0,
            (double v) => thermal.length = v,
          ),
          (
            'Area (m²)',
            thermal.area,
            .000001,
            .1,
            (double v) => thermal.area = v,
          ),
          (
            'Hot boundary (K)',
            thermal.hot,
            273.0,
            383.0,
            (double v) => thermal.hot = v,
          ),
          (
            'Cold / initial (K)',
            thermal.cold,
            273.0,
            383.0,
            (double v) => thermal.cold = v,
          ),
          (
            'Mass per sample (kg)',
            thermal.mass,
            .001,
            1.0,
            (double v) => thermal.mass = v,
          ),
          (
            'Volume per sample (m³)',
            thermal.volume,
            .000001,
            .001,
            (double v) => thermal.volume = v,
          ),
          (
            'Heater power per sample (W)',
            thermal.power,
            .001,
            100.0,
            (double v) => thermal.power = v,
          ),
          (
            'Heating time (s)',
            thermal.seconds,
            0.0,
            100.0,
            (double v) => thermal.seconds = v,
          ),
          (
            'Contact resistance per interface (K/W)',
            thermal.contact,
            0.0,
            10000.0,
            (double v) => thermal.contact = v,
          ),
        ])
          TextButton(
            onPressed: () =>
                numeric(pair.$1, pair.$2, pair.$3, pair.$4, pair.$5),
            child: Text('${pair.$1}: ${pair.$2}'),
          ),
        for (int i = 0; i < thermal.materials.length; i++)
          TextButton(
            onPressed: () => numeric(
              'Layer ${i + 1} thickness (m)',
              thermal.thicknesses[i],
              .001,
              .2,
              (v) => thermal.thicknesses[i] = v,
            ),
            child: Text('Layer ${i + 1}: ${thermal.thicknesses[i]} m'),
          ),
        TextButton(
          onPressed: () {
            thermal.equalVolume = !thermal.equalVolume;
            Navigator.pop(context);
            changed();
          },
          child: Text(
            'Compare ${thermal.equalVolume ? 'equal mass' : 'equal volume'} instead',
          ),
        ),
        TextButton(
          onPressed: () {
            thermal.overlay = !thermal.overlay;
            Navigator.pop(context);
            changed();
          },
          child: Text(
            thermal.overlay ? 'Natural appearance' : 'Thermal-color overlay',
          ),
        ),
        TextButton(
          onPressed: () {
            if (thermal.materials.length == 3) {
              thermal.materials.removeLast();
            } else {
              thermal.materials.add('ptfe');
            }
            Navigator.pop(context);
            changed();
          },
          child: Text(
            thermal.materials.length == 3
                ? 'Compare two samples'
                : 'Compare three samples',
          ),
        ),
      ] else ...[
        for (final pair in [
          (
            'Position X (m)',
            chosen.position.x,
            -6.0,
            6.0,
            (double v) =>
                chosen.position = OVec(v, chosen.position.y, chosen.position.z),
          ),
          (
            'Position Y (m)',
            chosen.position.y,
            -2.0,
            2.0,
            (double v) =>
                chosen.position = OVec(chosen.position.x, v, chosen.position.z),
          ),
          (
            'Rotation (degrees)',
            chosen.rotation * 180 / math.pi,
            -180.0,
            180.0,
            (double v) => chosen.rotation = v * math.pi / 180,
          ),
          ('Size scale', chosen.size, .2, 2.0, (double v) => chosen.size = v),
          if (chosen.component == 'triangle')
            (
              'Triangle apex (degrees)',
              chosen.apex,
              20.0,
              100.0,
              (double v) => chosen.apex = v,
            ),
          (
            'Wavelength (nm)',
            optical.wavelength,
            400.0,
            700.0,
            (double v) => optical.wavelength = v,
          ),
          (
            'Source X (m)',
            optical.source.x,
            -6.0,
            6.0,
            (double v) =>
                optical.source = OVec(v, optical.source.y, optical.source.z),
          ),
          (
            'Source Y (m)',
            optical.source.y,
            -2.0,
            2.0,
            (double v) =>
                optical.source = OVec(optical.source.x, v, optical.source.z),
          ),
          (
            'Source Z (m)',
            optical.source.z,
            -2.0,
            2.0,
            (double v) =>
                optical.source = OVec(optical.source.x, optical.source.y, v),
          ),
          (
            'Source azimuth (degrees)',
            math.atan2(optical.direction.y, optical.direction.x) *
                180 /
                math.pi,
            -180.0,
            180.0,
            (double v) {
              final elevation = math.asin(optical.direction.unit.z);
              optical.direction = OVec(
                math.cos(v * math.pi / 180) * math.cos(elevation),
                math.sin(v * math.pi / 180) * math.cos(elevation),
                math.sin(elevation),
              );
            },
          ),
          (
            'Source elevation (degrees)',
            math.asin(optical.direction.unit.z) * 180 / math.pi,
            -80.0,
            80.0,
            (double v) {
              final az = math.atan2(optical.direction.y, optical.direction.x);
              optical.direction = OVec(
                math.cos(az) * math.cos(v * math.pi / 180),
                math.sin(az) * math.cos(v * math.pi / 180),
                math.sin(v * math.pi / 180),
              );
            },
          ),
          if (chosen.component == 'splitter')
            (
              'Illustrative coating R',
              chosen.reflectance,
              0.0,
              1.0,
              (double v) => chosen.reflectance = v,
            ),
        ])
          TextButton(
            onPressed: () =>
                numeric(pair.$1, pair.$2, pair.$3, pair.$4, pair.$5),
            child: Text('${pair.$1}: ${pair.$2.toStringAsPrecision(4)}'),
          ),
        for (final m in opticalMaterials)
          ListTile(
            title: Text(m.name),
            subtitle: Text(
              m.dispersive
                  ? 'Sourced dispersion, visible range'
                  : 'Monochromatic teaching preset only',
            ),
            onTap: () {
              chosen.material = m.id;
              Navigator.pop(context);
              changed();
            },
          ),
        for (final mode in [
          'Single ray',
          'Parallel bundle',
          'Visible spectrum',
        ])
          TextButton(
            onPressed: () {
              optical.sourceMode = mode;
              Navigator.pop(context);
              changed();
            },
            child: Text(mode),
          ),
        Wrap(
          children: [
            for (final name in [
              'Normals',
              'Angles',
              'Ray power',
              'Grid',
              'Snap',
            ])
              TextButton(
                onPressed: () {
                  switch (name) {
                    case 'Normals':
                      optical.normals = !optical.normals;
                    case 'Angles':
                      optical.angles = !optical.angles;
                    case 'Ray power':
                      optical.powers = !optical.powers;
                    case 'Grid':
                      optical.grid = !optical.grid;
                    case 'Snap':
                      optical.snap = !optical.snap;
                  }
                  Navigator.pop(context);
                  changed();
                },
                child: Text('Toggle $name'),
              ),
          ],
        ),
        TextButton(
          onPressed: () {
            if (optical.components.length < 8) {
              final p = PlacedOptic.fromJson(chosen.toJson());
              p.position = p.position + const OVec(2, 0);
              optical.components.add(p);
              selected = optical.components.length - 1;
            }
            Navigator.pop(context);
            focus = false;
            changed();
          },
          child: const Text('Duplicate selected'),
        ),
        TextButton(
          onPressed: optical.components.length == 1
              ? null
              : () {
                  optical.components.removeAt(selected);
                  selected = 0;
                  Navigator.pop(context);
                  changed();
                },
          child: const Text('Delete selected'),
        ),
        for (final ray
            in traced
                .expand((t) => t.segments)
                .where((s) => s.event == 'exit' && s.power > .01)
                .take(6))
          Text(
            'Exit direction xyz: ${ray.direction.toJson().map((v) => v.toStringAsFixed(3)).join(', ')} · power ${ray.power.toStringAsPrecision(4)}',
          ),
      ],
      TextFormField(
        initialValue: isThermal ? thermal.note : optical.note,
        maxLines: 3,
        decoration: const InputDecoration(labelText: 'Notes'),
        onChanged: (v) {
          if (isThermal) {
            thermal.note = v;
          } else {
            optical.note = v;
          }
        },
      ),
    ],
  );
  static const investigations = [
    'Parallel slab / displacement',
    'Semicircle / radial entry',
    'Semicircle / critical angle',
    'Prism / deviation versus incidence',
    'Prism / minimum deviation',
    'Thin wedge / deviation',
    'Right-angle prism / TIR',
    'Back mirror / ghost ray',
    'Beam splitter / power',
    'Liquid prism / index',
    'Lens / convergence',
    'Corner cube / return direction',
  ];
  void investigation(int index) {
    optical = OpticalBench();
    selected = 0;
    final ids = [
      'slab',
      'semicircle',
      'semicircle',
      'equilateral',
      'equilateral',
      'wedge',
      'right45',
      'backmirror',
      'splitter',
      'liquidprism',
      'biconvex',
      'corner',
    ];
    optical.components = [PlacedOptic(ids[index])];
    switch (index) {
      case 1:
        optical.source = const OVec(-1.3, .75);
        optical.direction = const OVec(1.3, -.75);
      case 2:
        optical.source = const OVec(0, .3);
        optical.direction = const OVec(.75, -.66);
        optical.normals = true;
      case 3:
      case 4:
        final n = opticalMaterial('bk7').index(optical.wavelength),
            angle = math.asin(n * .5) - math.pi / 6;
        optical.direction = OVec(math.cos(angle), math.sin(angle));
        optical.source = const OVec(-.25, .1443375673) - optical.direction * 2;
      case 6:
        optical.source = const OVec(-2, 0);
        optical.direction = const OVec(1, 0);
      case 7:
      case 8:
        optical.powers = true;
      case 9:
        chosen.material = 'water';
        optical.wavelength = 589.3;
      case 10:
        optical.sourceMode = 'Parallel bundle';
        optical.source = const OVec(-2, 0);
        optical.direction = const OVec(1, 0);
      case 11:
        optical.source = const OVec(1.5, 1.4, 1.3);
        optical.direction = const OVec(-1, -1, -1);
    }
    focus = false;
    changed();
  }

  void guided() => sheet(
    'Guided investigations',
    () => isThermal
        ? [
            for (final mode in ThermalBench.modes)
              ListTile(
                title: Text(mode),
                subtitle: Text(
                  mode == ThermalBench.modes[1]
                      ? 'Equal mass or volume; fixed heater power. Q = mcΔT.'
                      : 'Same area and boundary temperatures; no free-fluid convection.',
                ),
                onTap: () {
                  thermal = ThermalBench()..mode = mode;
                  if (mode == ThermalBench.modes[2]) {
                    thermal.materials = ['ptfe', 'soda-lime'];
                  }
                  Navigator.pop(context);
                  changed();
                },
              ),
          ]
        : [
            for (int i = 0; i < investigations.length; i++)
              ListTile(
                title: Text(investigations[i]),
                subtitle: Text(
                  i == 4
                      ? 'Set symmetric internal passage; compare δmin = 2 asin(n sin(A/2)) − A for a prism in air. Adjust source angle for a sweep.'
                      : i == 5
                      ? 'Small-angle formula is approximate; traced boundaries give the exact section path.'
                      : i == 11
                      ? '3D corner path; inspect exit xyz. No image-orientation claim.'
                      : 'Use geometry/source controls; record and compare actual traced paths.',
                ),
                onTap: () {
                  Navigator.pop(context);
                  investigation(i);
                },
              ),
          ],
  );
  List<InstrumentControl> controls() => isThermal
      ? [
          InstrumentControl('length', 'Length', 'm', thermal.length, .01, .5, (
            v,
          ) {
            thermal.length = v;
            changed();
          }),
          InstrumentControl('hot', 'Hot boundary', 'K', thermal.hot, 273, 383, (
            v,
          ) {
            thermal.hot = v;
            changed();
          }),
          InstrumentControl(
            'cold',
            'Cold / start',
            'K',
            thermal.cold,
            273,
            383,
            (v) {
              thermal.cold = v;
              changed();
            },
          ),
        ]
      : [
          InstrumentControl(
            'rotation',
            'Rotation',
            '°',
            chosen.rotation * 180 / math.pi,
            -180,
            180,
            (v) {
              chosen.rotation = v * math.pi / 180;
              changed();
            },
          ),
          InstrumentControl(
            'wavelength',
            'Wavelength',
            'nm',
            optical.wavelength,
            400,
            700,
            (v) {
              optical.wavelength = v;
              changed();
            },
          ),
        ];
  Widget scene() => isThermal
      ? CustomPaint(size: Size.infinite, painter: ThermalBenchPainter(thermal))
      : LayoutBuilder(
          builder: (c, limits) => Column(
            children: [
              if (limits.maxHeight > 80)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      for (int i = 0; i < optical.components.length; i++)
                        TextButton(
                          onPressed: () {
                            selected = i;
                            changed();
                          },
                          child: Text(
                            '${i + 1}: ${opticalComponent(optical.components[i].component).name}',
                          ),
                        ),
                      IconButton(
                        tooltip: 'Add component',
                        onPressed: () => componentPicker(add: true),
                        icon: const Icon(Icons.add),
                      ),
                      IconButton(
                        tooltip: 'Focus selected',
                        onPressed: () {
                          focus = true;
                          changed();
                        },
                        icon: const Icon(Icons.center_focus_strong),
                      ),
                      IconButton(
                        tooltip: 'Fit all components',
                        onPressed: () {
                          focus = false;
                          changed();
                        },
                        icon: const Icon(Icons.fit_screen),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (c, b) {
                    final painter = OpticalBenchPainter(
                      optical,
                      traced,
                      selected,
                      focus: focus,
                    );
                    return GestureDetector(
                      key: const Key('optical-canvas'),
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (d) {
                        dragging = false;
                        final p = painter.unproject(d.localPosition, b.biggest);
                        for (
                          int i = optical.components.length - 1;
                          i >= 0;
                          i--
                        ) {
                          if (opticSolids(optical.components[i]).any(
                            (s) => s.contains(optical.components[i].local(p)),
                          )) {
                            selected = i;
                            dragging = true;
                            changed();
                            break;
                          }
                        }
                      },
                      onPanUpdate: (d) {
                        if (!dragging) {
                          return;
                        }
                        final delta = OVec(
                          d.delta.dx / painter.scale(b.biggest),
                          -d.delta.dy / painter.scale(b.biggest),
                        );
                        final next = chosen.position + delta;
                        chosen.position = OVec(
                          next.x.clamp(-6, 6),
                          next.y.clamp(-2, 2),
                          next.z,
                        );
                        if (optical.snap) {
                          chosen.position = OVec(
                            (chosen.position.x * 10).round() / 10,
                            (chosen.position.y * 10).round() / 10,
                            chosen.position.z,
                          );
                        }
                        changed();
                      },
                      child: ClipRect(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: painter,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
  List<InstrumentReading> readings() => isThermal
      ? [
          InstrumentReading('Samples', '${thermal.materials.length}'),
          if (thermal.readings.isNotEmpty)
            InstrumentReading(
              thermal.mode == ThermalBench.modes[1] ? 'T first' : 'Q̇ first',
              (thermal.readings.first[thermal.mode == ThermalBench.modes[1]
                      ? 'temperature'
                      : 'power']!)
                  .toStringAsPrecision(5),
              thermal.mode == ThermalBench.modes[1] ? 'K' : 'W',
            ),
          InstrumentReading(
            'Model',
            thermal.mode == ThermalBench.modes[1]
                ? 'No-loss heating'
                : 'Steady 1D',
          ),
        ]
      : [
          InstrumentReading('λ', optical.wavelength.toStringAsFixed(1), 'nm'),
          InstrumentReading(
            'n',
            (() => optical.error.isEmpty
                ? opticalMaterial(chosen.material)
                      .index(optical.wavelength)
                      .toStringAsFixed(5)
                : '—')(),
          ),
          InstrumentReading(
            'Deviation',
            deviation?.toStringAsFixed(2) ?? '—',
            '°',
          ),
        ];
  Widget dock() => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: TextButton(
              key: const Key('bench-picker'),
              onPressed: isThermal ? guided : () => componentPicker(),
              child: Text(
                isThermal
                    ? thermal.mode
                    : opticalComponent(chosen.component).name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Selected geometry and source',
            onPressed: inspector,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            tooltip: 'Guided investigations',
            onPressed: guided,
            icon: const Icon(Icons.explore_outlined),
          ),
          IconButton(
            tooltip: 'Properties and assumptions',
            onPressed: propertyPanel,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      if (isThermal)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (int i = 0; i < thermal.materials.length; i++)
                TextButton(
                  onPressed: () => materialPicker(i),
                  child: Text(
                    '${i + 1}: ${thermalMaterial(thermal.materials[i]).name}',
                  ),
                ),
            ],
          ),
        )
      else
        Row(
          children: [
            const Text('Rotate'),
            Expanded(
              child: Slider(
                value: chosen.rotation * 180 / math.pi,
                min: -180,
                max: 180,
                onChanged: (v) {
                  chosen.rotation = v * math.pi / 180;
                  changed();
                },
              ),
            ),
            TextButton(
              onPressed: () => numeric(
                'Rotation (degrees)',
                chosen.rotation * 180 / math.pi,
                -180,
                180,
                (v) => chosen.rotation = v * math.pi / 180,
              ),
              child: Text(
                '${(chosen.rotation * 180 / math.pi).toStringAsFixed(0)}°',
              ),
            ),
          ],
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (!ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return InstrumentShell(
      toolbarActions: [
        IconButton(
          tooltip: 'Export labeled workspace image',
          onPressed: exportImage,
          icon: const Icon(Icons.image_outlined),
        ),
      ],
      id: widget.entry.id,
      title: isThermal
          ? 'Heat Transfer · Materials'
          : '${widget.entry.title} · Optical bench',
      store: store,
      changes: revision,
      scene: scene,
      fitScene: false,
      graph: () => isThermal
          ? SizedBox(
              height: 320,
              width: double.infinity,
              child: CustomPaint(
                size: Size.infinite,
                painter: ThermalBenchPainter(thermal, graph: true),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final trace in traced) ...[
                  Text(
                    'Power: escaped ${trace.escaped.toStringAsPrecision(5)}, absorbed ${trace.absorbed}, bounded tails ${trace.truncated.toStringAsPrecision(4)}',
                  ),
                  for (final ray
                      in trace.segments
                          .where((s) => s.event != 'exit')
                          .take(30))
                    Text(
                      '${ray.event}: n ${ray.n1.toStringAsFixed(4)} → ${ray.n2.toStringAsFixed(4)}, P ${ray.power.toStringAsPrecision(4)}',
                    ),
                ],
              ],
            ),
      parameterDock: dock,
      dockExtent: 110,
      controls: controls,
      readings: readings,
      advanced: () => [
        TextButton(
          onPressed: inspector,
          child: const Text('Geometry, source and notes'),
        ),
        TextButton(
          onPressed: propertyPanel,
          child: const Text('Properties, sources and assumptions'),
        ),
        TextButton(
          onPressed: guided,
          child: const Text('Guided investigations'),
        ),
        if (error.isNotEmpty) Text(error),
      ],
      results: () => [],
      notice: () => error,
      playing: () => false,
      dynamicModel: () => false,
      canRecord: () =>
          error.isEmpty &&
          (isThermal ? thermal.readings.isNotEmpty : traced.isNotEmpty),
      play: () {},
      pause: () {},
      reset: () {
        if (isThermal) {
          final note = thermal.note;
          thermal = ThermalBench()..note = note;
        } else {
          final note = optical.note;
          optical = OpticalBench()..note = note;
          selected = 0;
        }
        changed();
      },
      save: save,
      record: record,
      section: section,
      selectSection: (v) {
        if (v == 0 || v == 3) {
          propertyPanel();
        } else {
          setState(() => section = v);
        }
      },
      exportRecorded: (ts) => exportTrials(context, ts),
      reopenTrial: (t) {
        final ok = restore(t.configuration);
        if (ok) changed();
        return ok;
      },
    );
  }
}
