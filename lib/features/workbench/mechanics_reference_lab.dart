import '../../core/rendering/interactive_mechanics.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'instrument_types.dart';
import 'workbench.dart' show InstrumentShell;

/// Layout specification; all apparatus is rendered from live geometry.
class MechanicsReference {
  final String title, subtitle;
  final double controlsTop;
  final List<String> keys, labels;
  const MechanicsReference(
    this.title,
    this.subtitle,
    this.controlsTop,
    this.keys,
    this.labels,
  );
}

const mechanicsReferences = <String, MechanicsReference>{
  's02-e00': MechanicsReference(
    'Free Body Diagrams',
    'Explore forces acting on a block',
    900,
    ['m', 'force', 'muk'],
    ['Mass', 'Applied Force', 'Friction Coeff.'],
  ),
  's04-e01': MechanicsReference(
    '2. Forces in Motion',
    'Newton’s second law in action',
    893,
    ['m', 'hanger', 'trackFriction'],
    ['Cart mass', 'Hanging mass', 'Track friction'],
  ),
  's02-e02': MechanicsReference(
    '3. Pulley Systems',
    'Mechanical advantage & tension',
    1095,
    ['m', 'm2', 'v0'],
    ['Load mass', 'Effort mass', 'Initial speed'],
  ),
  's02-e03': MechanicsReference(
    '4. Torque Levers',
    'Balance of moments',
    870,
    ['force', 'r1', 'force2', 'r2'],
    ['Force A', 'Distance A', 'Force B', 'Distance B'],
  ),
  's02-e04': MechanicsReference(
    'Equilibrium & Centre of Mass',
    'Find the centre of mass of a 2D body',
    935,
    ['m', 'm2', 'm3'],
    ['Mass A', 'Mass B', 'Mass C'],
  ),
  's02-e05': MechanicsReference(
    '6. Momentum & Collisions',
    'Elastic and inelastic collisions',
    880,
    ['m', 'm2', 'v0', 'v2'],
    ['Mass A', 'Mass B', 'Initial velocity A', 'Initial velocity B'],
  ),
  's02-e06': MechanicsReference(
    '7. Rotational Inertia',
    'Moment of inertia of a solid disk',
    795,
    ['mass', 'radius', 'torque'],
    ['Disk mass', 'Disk radius', 'Applied torque'],
  ),
  's02-e07': MechanicsReference(
    '8. Rolling Motion',
    'Rolling without slipping',
    880,
    ['mass', 'radius', 'incline'],
    ['Sphere mass', 'Sphere radius', 'Incline angle'],
  ),
  's02-e08': MechanicsReference(
    '9. Hooke’s Law',
    'Spring extension and force',
    860,
    ['stiffness', 'extension'],
    ['Spring constant (k)', 'Extension'],
  ),
  's02-e09': MechanicsReference(
    '10. Young’s Modulus',
    'Tensile test of a metal wire',
    935,
    ['force', 'length', 'radius'],
    ['Tensile force', 'Original length', 'Diameter'],
  ),
};

class MechanicsReferenceLab extends StatefulWidget {
  final InstrumentShell shell;
  final ValueChanged<int> openSection;
  const MechanicsReferenceLab({
    super.key,
    required this.shell,
    required this.openSection,
  });
  @override
  State<MechanicsReferenceLab> createState() => _MechanicsReferenceLabState();
}

class _MechanicsReferenceLabState extends State<MechanicsReferenceLab> {
  InstrumentShell get s => widget.shell;
  MechanicsReference get spec => mechanicsReferences[s.id]!;
  int tab = 0;
  bool plumb = true, springGraph = false;
  int shape = 0;
  static const white = Color(0xffedf5ff), blue = Color(0xff0086ff);
  static const muted = Color(0xffbad3e8);
  List<InstrumentControl> get controls => s.controls();
  InstrumentControl control(String key) =>
      controls.firstWhere((c) => c.keyName == key);
  Map<String, double> get values => {
    for (final r in s.researchReadings?.call() ?? s.readings())
      if (double.tryParse(r.value) case final double n) r.label: n,
  };
  double input(String key) => control(key).value;
  double get time =>
      values['t'] ?? values['Model t'] ?? values['Model time'] ?? 0;
  Widget label(
    String text,
    double size, {
    Color color = white,
    FontWeight weight = FontWeight.w500,
  }) => Text(
    text,
    maxLines: 1,
    style: TextStyle(
      fontFamily: 'HomeManrope',
      fontSize: size,
      color: color,
      fontWeight: weight,
    ),
  );
  BoxDecoration glass({double radius = 24}) => BoxDecoration(
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xff45677e), width: 1.8),
    gradient: const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xf0213849), Color(0xfa081c29)],
    ),
    boxShadow: const [
      BoxShadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 2)),
    ],
  );
  void change(InstrumentControl c, double value) {
    s.pause();
    c.change(value.clamp(c.min, c.max));
    setState(() {});
  }

  void play() {
    setState(() {});
    s.playing() ? s.pause() : s.play();
  }

  void sheet(String title, Widget child) {
    s.pause();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xff0a1e2b),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(
            children: [
              ListTile(
                title: Text(title, style: const TextStyle(color: white)),
                trailing: IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: white),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void options(String choice) {
    switch (choice) {
      case 'learn':
        widget.openSection(0);
      case 'experiment':
        widget.openSection(1);
      case 'visualize':
        widget.openSection(2);
      case 'formulas':
        widget.openSection(3);
      case 'results':
        widget.openSection(4);
      case 'guide':
        sheet(
          'Experiment guide',
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.principle?.call() ?? spec.subtitle),
              const SizedBox(height: 20),
              Text(s.modelLimits?.call() ?? ''),
              ...s.advanced(),
            ],
          ),
        );
      case 'controls':
        sheet(
          'Controls & investigation',
          Column(
            children: [
              for (final c in controls)
                _SheetControl(control: c, pause: s.pause),
              if (s.researchSelection != null) s.researchSelection!(),
              ...?s.investigationTools?.call(),
            ],
          ),
        );
      case 'save':
        s.save();
      case 'record':
        if (s.canRecord()) {
          s.record();
        }
      case 'reset':
        s.reset();
        setState(() {});
    }
  }

  Widget square(
    IconData icon,
    VoidCallback action, {
    bool active = false,
    String? tooltip,
  }) => IconButton(
    tooltip: tooltip,
    onPressed: action,
    style: IconButton.styleFrom(
      backgroundColor: active ? blue : const Color(0xff183142),
      foregroundColor: white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      side: BorderSide(
        color: active ? const Color(0xff59d7ff) : const Color(0xff3c576a),
        width: 2,
      ),
    ),
    icon: Icon(icon, size: 35),
    padding: const EdgeInsets.all(12),
  );
  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'HomeManrope',
      colorScheme: const ColorScheme.dark(
        primary: blue,
        surface: Color(0xff102b3d),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: Color(0xff17384c),
      ),
    ),
    child: buildLab(context),
  );
  Widget buildLab(BuildContext context) => AnimatedBuilder(
    animation: s.changes,
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xff081b28),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = math.min(box.maxWidth, 720.0);
            // Preserve the reference proportions; short displays scroll instead of
            // compressing controls or cutting off navigation.
            return Center(
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 1280 * width / 720,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: 720,
                        height: 1280,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff172d3b),
                                      Color(0xff061621),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              right: 0,
                              top: 200,
                              bottom: 110,
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: 0,
                                    height:
                                        spec.controlsTop -
                                        200 -
                                        ([
                                              's02-e00',
                                              's02-e03',
                                              's02-e07',
                                            ].contains(s.id)
                                            ? 101
                                            : 0),
                                    child: InteractiveMechanics(
                                      key: ValueKey('apparatus-${s.id}'),
                                      id: s.id,
                                      parameters: {
                                        for (final c in controls)
                                          c.keyName: c.value,
                                      },
                                      values: values,
                                      controls: controls,
                                      time: time,
                                      mode:
                                          (s.captureConfiguration
                                                  ?.call()['mode']
                                              as int?) ??
                                          0,
                                      plumb: plumb,
                                      pause: s.pause,
                                      play: s.play,
                                      inspect: numeric,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              height: 120,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xff172e3d),
                                      Color(0xff071c2c),
                                    ],
                                  ),
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Color(0xff3b5d73),
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    square(
                                      Icons.arrow_back_ios_new,
                                      () => context.go('/?tab=explore'),
                                      tooltip: 'Back',
                                    ),
                                    const SizedBox(width: 24),
                                    Icon(
                                      s.id == 's02-e03'
                                          ? Icons.architecture
                                          : Icons.timer_outlined,
                                      size: 62,
                                      color: white,
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: label(
                                              spec.title,
                                              s.id == 's02-e04' ? 31 : 38,
                                              weight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: label(
                                              spec.subtitle,
                                              23,
                                              color: muted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Help',
                                      onPressed: () => options('guide'),
                                      icon: const Icon(
                                        Icons.help_outline,
                                        color: white,
                                        size: 44,
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      tooltip: 'Lab options',
                                      icon: const Icon(
                                        Icons.more_vert,
                                        color: white,
                                        size: 32,
                                      ),
                                      onSelected: options,
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'learn',
                                          child: Text('Learn'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'experiment',
                                          child: Text('Experiment'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'visualize',
                                          child: Text('Visualize'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'formulas',
                                          child: Text('Formulas'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'results',
                                          child: Text('Results'),
                                        ),

                                        const PopupMenuItem(
                                          value: 'controls',
                                          child: Text(
                                            'Controls & investigation',
                                          ),
                                        ),

                                        const PopupMenuItem(
                                          value: 'reset',
                                          child: Text('Reset experiment'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'record',
                                          child: Text('Record Trial'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'save',
                                          child: Text('Save session'),
                                        ),
                                        const PopupMenuItem(
                                          value: 'guide',
                                          child: Text('Experiment guide'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: 122,
                              left: 10,
                              right: 10,
                              height: 76,
                              child: Container(
                                decoration: glass(radius: 36),
                                child: Row(
                                  children: List.generate(
                                    4,
                                    (i) => Expanded(
                                      flex: i == 0 ? 13 : 10,
                                      child: GestureDetector(
                                        key: Key(
                                          [
                                            'workspace-scene',
                                            'workspace-graph',
                                            'workspace-inspect',
                                            'workspace-results',
                                          ][i],
                                        ),
                                        onTap: () {
                                          s.pause();
                                          setState(() => tab = i);
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              36,
                                            ),
                                            gradient: tab == i
                                                ? const LinearGradient(
                                                    colors: [
                                                      Color(0xff00b5ff),
                                                      Color(0xff005af5),
                                                    ],
                                                  )
                                                : null,
                                            border: tab == i
                                                ? Border.all(
                                                    color: const Color(
                                                      0xff69d5ff,
                                                    ),
                                                    width: 2,
                                                  )
                                                : null,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  [
                                                    Icons.science_outlined,
                                                    Icons.show_chart,
                                                    Icons.tune,
                                                    Icons.bar_chart,
                                                  ][i],
                                                  size: 34,
                                                  color: white,
                                                ),
                                                const SizedBox(width: 12),
                                                label(
                                                  [
                                                    'Apparatus',
                                                    'Graph',
                                                    'Inspect',
                                                    'Results',
                                                  ][i],
                                                  21,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (tab == 0) ...apparatus(),
                            if (tab != 0)
                              Positioned(
                                top: 212,
                                left: 16,
                                right: 16,
                                bottom: 122,
                                child: Container(
                                  decoration: glass(),
                                  padding: const EdgeInsets.all(20),
                                  child: tab == 1
                                      ? Column(
                                          children: [
                                            label('Live Graph', 26),
                                            const SizedBox(height: 20),
                                            Expanded(child: s.graph()),
                                          ],
                                        )
                                      : SingleChildScrollView(
                                          child: tab == 2
                                              ? Column(
                                                  children: [
                                                    for (final c in controls)
                                                      _SheetControl(
                                                        control: c,
                                                        pause: s.pause,
                                                      ),
                                                    if (s.researchSelection !=
                                                        null)
                                                      s.researchSelection!(),
                                                    ...?s.investigationTools
                                                        ?.call(),
                                                  ],
                                                )
                                              : Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      '${s.store.trials.where((t) => t.labId == s.id).length} recorded trials',
                                                    ),
                                                    if (s.data != null)
                                                      s.data!()
                                                    else
                                                      ...s.readings().map(
                                                        (r) => ListTile(
                                                          title: Text(r.label),
                                                          trailing: Text(
                                                            '${r.value} ${r.unit}',
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 12),
                                                    FilledButton.icon(
                                                      onPressed: s.canRecord()
                                                          ? s.record
                                                          : null,
                                                      icon: const Icon(
                                                        Icons.add_chart,
                                                      ),
                                                      label: const Text(
                                                        'Record Trial',
                                                      ),
                                                    ),
                                                    ...s.results(),
                                                  ],
                                                ),
                                        ),
                                ),
                              ),
                            Positioned(
                              left: 4,
                              right: 4,
                              bottom: 0,
                              height: 108,
                              child: Container(
                                decoration: glass(radius: 32),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: List.generate(
                                    4,
                                    (i) => GestureDetector(
                                      key: Key(
                                        'home-nav-${['home', 'explore', 'saved', 'settings'][i]}',
                                      ),
                                      onTap: () {
                                        s.pause();
                                        context.push(
                                          i == 3
                                              ? '/settings'
                                              : i == 0
                                              ? '/'
                                              : i == 1
                                              ? '/?tab=explore'
                                              : '/?tab=saved',
                                        );
                                      },
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            [
                                              Icons.home_rounded,
                                              Icons.grid_view_rounded,
                                              Icons.bookmark_outline,
                                              Icons.settings_outlined,
                                            ][i],
                                            size: 42,
                                            color: i == 1 ? blue : muted,
                                          ),
                                          const SizedBox(height: 8),
                                          label(
                                            [
                                              'Home',
                                              'Explore',
                                              'Saved',
                                              'Settings',
                                            ][i],
                                            22,
                                            color: i == 1 ? blue : muted,
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: 90,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: i == 1
                                                  ? blue
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  List<Widget> apparatus() {
    final rows = spec.keys.length;
    return [
      if (s.id == 's02-e00' || s.id == 's02-e03' || s.id == 's02-e07')
        Positioned(
          top: spec.controlsTop - 101,
          left: 14,
          right: 14,
          height: 90,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: glass(),
            child: Row(
              children: [
                Expanded(
                  child: label(
                    s.id == 's02-e03'
                        ? 'Net Torque = ${(values['netTorque'] ?? 0).toStringAsFixed(2)} N·m'
                        : s.id == 's02-e07'
                        ? 'a = ${(values['acceleration'] ?? 0).toStringAsFixed(2)} m/s²    t = ${time.toStringAsFixed(3)} s'
                        : 't = ${time.toStringAsFixed(3)} s',
                    27,
                  ),
                ),
                if (s.dynamicModel()) ...[
                  square(
                    s.playing() ? Icons.pause : Icons.play_arrow,
                    play,
                    active: true,
                    tooltip: s.playing() ? 'Pause' : 'Play',
                  ),
                  const SizedBox(width: 12),
                  square(Icons.restart_alt, () {
                    s.reset();
                    setState(() {});
                  }, tooltip: 'Reset'),
                ],
              ],
            ),
          ),
        ),
      if (s.id != 's02-e02' && s.id != 's02-e04')
        Positioned(
          top: spec.controlsTop,
          left: 16,
          right: 16,
          height: s.id == 's02-e08'
              ? 224
              : rows == 4
              ? 282
              : 270,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: glass(),
            child: s.id == 's02-e05'
                ? collisionControls()
                : Column(
                    children: [
                      for (int i = 0; i < rows; i++)
                        Expanded(
                          child: controlRow(
                            control(spec.keys[i]),
                            spec.labels[i],
                            i,
                          ),
                        ),
                      if (s.id == 's02-e08')
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(child: label('Show graph', 25)),
                              Switch(
                                value: springGraph,
                                activeThumbColor: white,
                                activeTrackColor: blue,
                                onChanged: (v) {
                                  setState(() {
                                    springGraph = v;
                                    if (v) tab = 1;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ),
      if (s.id == 's02-e02')
        Positioned(
          top: 1099,
          left: 14,
          right: 14,
          height: 65,
          child: Container(
            decoration: glass(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => options('controls'),
                    child: label('Load & pulley setup', 22),
                  ),
                ),
                square(
                  s.playing() ? Icons.pause : Icons.play_arrow,
                  play,
                  active: true,
                  tooltip: 'Play',
                ),
                const SizedBox(width: 12),
                square(Icons.restart_alt, () {
                  s.reset();
                  setState(() {});
                }, tooltip: 'Reset'),
              ],
            ),
          ),
        ),
      if (s.id == 's02-e04')
        Positioned(
          top: 935,
          left: 8,
          right: 8,
          height: 234,
          child: comControls(),
        ),
      if (s.dynamicModel() && !['s02-e00', 's02-e02'].contains(s.id))
        Positioned(
          top: spec.controlsTop - 76,
          right: 20,
          child: Row(
            children: [
              square(
                s.playing() ? Icons.pause : Icons.play_arrow,
                play,
                active: true,
                tooltip: s.playing() ? 'Pause' : 'Play',
              ),
              const SizedBox(width: 10),
              square(Icons.restart_alt, () {
                s.reset();
                setState(() {});
              }, tooltip: 'Reset'),
            ],
          ),
        ),
    ];
  }

  Widget comControls() => Container(
    decoration: glass(),
    padding: const EdgeInsets.all(20),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Shape', 24),
              const SizedBox(height: 16),
              Row(
                children: List.generate(
                  3,
                  (i) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color: shape == i ? blue : const Color(0xff102a3b),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xff41647a)),
                          ),
                          child: IconButton(
                            tooltip: [
                              'Triangle',
                              'Wide triangle',
                              'Irregular triangle',
                            ][i],
                            onPressed: () => selectShape(i),
                            icon: Icon(
                              [
                                Icons.change_history,
                                Icons.change_history,
                                Icons.polyline_outlined,
                              ][i],
                              size: 52,
                              color: white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const VerticalDivider(width: 36, color: Color(0xff45677e)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              label('Mass distribution', 24),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                initialValue: 0,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Equal masses')),
                  DropdownMenuItem(value: 1, child: Text('Weighted A')),
                  DropdownMenuItem(value: 2, child: Text('Weighted C')),
                ],
                onChanged: (v) {
                  for (final key in ['m', 'm2', 'm3']) {
                    final c = control(key);
                    change(
                      c,
                      (v == 1 && key == 'm') || (v == 2 && key == 'm3') ? 3 : 1,
                    );
                  }
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: label('Show plumb line', 20)),
                  Switch(
                    value: plumb,
                    activeThumbColor: white,
                    activeTrackColor: blue,
                    onChanged: (v) {
                      for (final tool
                          in s.investigationTools?.call() ?? <Widget>[]) {
                        if (tool is SwitchListTile &&
                            tool.title is Text &&
                            (tool.title as Text).data == 'Show plumb line') {
                          tool.onChanged?.call(v);
                        }
                      }
                      setState(() {
                        plumb = v;
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
  void selectShape(int value) {
    // Existing COM model is a system of three point masses. Presets alter real
    // coordinates rather than claiming unsupported continuous plate physics.
    final presets = [
      [-.8, .4, .6, 0.0, .2, .7],
      [-.7, 0.0, .7, 0.0, 0.0, 1.4],
      [-1.0, .2, .5, .8, .2, 1.6],
    ];
    final keys = ['x0', 'y1', 'x2', 'y2', 'x3', 'y3'];
    for (int i = 0; i < keys.length; i++) {
      change(control(keys[i]), presets[value][i]);
    }
    setState(() => shape = value);
  }

  Widget collisionControls() => Column(
    children: [
      Expanded(
        child: Row(
          children: [
            for (final key in ['m', 'm2'])
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: GestureDetector(
                    onTap: () => numeric(control(key)),
                    child: Container(
                      decoration: glass(radius: 14),
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          label(key == 'm' ? 'Mass A' : 'Mass B', 22),
                          const Spacer(),
                          label('${input(key).toStringAsFixed(1)} kg', 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      Expanded(child: controlRow(control('v0'), 'Initial velocity A', 2)),
      Expanded(child: controlRow(control('v2'), 'Initial velocity B', 3)),
    ],
  );
  String formatted(InstrumentControl c) {
    if (s.id == 's02-e09' && c.keyName == 'radius') {
      return '${(c.value * 2000).toStringAsFixed(3)} mm';
    }
    final value = s.id == 's02-e03' && c.keyName == 'r1'
        ? c.value.abs()
        : c.value;
    final decimals = s.id == 's02-e00' && c.keyName == 'm'
        ? 2
        : c.unit == 'm' && s.id == 's02-e08'
        ? 3
        : c.unit == 'kg' || c.unit == 'N' || c.unit == '°'
        ? 1
        : 2;
    return '${value.toStringAsFixed(decimals)} ${c.unit}'.trim();
  }

  void numeric(InstrumentControl c) {
    s.pause();
    final isDiameter = s.id == 's02-e09' && c.keyName == 'radius';
    final scale = isDiameter ? 2000.0 : 1.0;
    final inputUnit = isDiameter ? 'mm' : c.unit;
    final controller = TextEditingController(
      text: (c.value * scale).toString(),
    );
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${isDiameter ? 'Diameter' : c.label} ($inputUnit)'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          decoration: InputDecoration(
            helperText: '${c.min * scale} to ${c.max * scale} $inputUnit',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final raw = double.tryParse(controller.text);
              final n = raw == null ? null : raw / scale;
              if (n != null && n.isFinite && n >= c.min && n <= c.max) {
                change(c, n);
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    ).then((_) {
      controller.dispose();
    });
  }

  Widget freeBodyRow(InstrumentControl c, String title, int i) => Container(
    decoration: BoxDecoration(
      border: i == 0
          ? null
          : const Border(top: BorderSide(color: Color(0xff314c60))),
    ),
    child: Row(
      children: [
        Icon(
          [Icons.shopping_bag_outlined, Icons.speed, Icons.timer_outlined][i],
          color: white,
          size: 42,
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 132,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: label(title, 22),
          ),
        ),
        GestureDetector(
          onTap: () => numeric(c),
          child: Container(
            width: 128,
            height: 54,
            alignment: Alignment.center,
            decoration: glass(radius: 10),
            child: label(formatted(c), 24),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 8,
              activeTrackColor: const Color(0xffd5f4ff),
              inactiveTrackColor: const Color(0xff455f75),
              thumbColor: blue,
              thumbShape: const _GlowThumb(),
            ),
            child: Slider(
              key: Key('mechanics-control-${c.keyName}'),
              value: c.value.clamp(c.min, c.max),
              min: c.min,
              max: c.max,
              onChanged: (v) => change(c, v),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Edit $title',
          onPressed: () => numeric(c),
          icon: const Icon(Icons.keyboard_arrow_down, color: white, size: 25),
        ),
      ],
    ),
  );
  Widget controlRow(InstrumentControl c, String title, int i) =>
      s.id == 's02-e00'
      ? freeBodyRow(c, title, i)
      : Container(
          decoration: BoxDecoration(
            border: i == 0
                ? null
                : const Border(top: BorderSide(color: Color(0xff314c60))),
          ),
          child: Row(
            children: [
              if (s.id != 's02-e08' && s.id != 's02-e05') ...[
                Icon(
                  [
                    Icons.shopping_bag_outlined,
                    Icons.speed,
                    Icons.timer_outlined,
                    Icons.straighten,
                  ][i % 4],
                  color: white,
                  size: 39,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                flex: 4,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: label(title, 24),
                ),
              ),
              Expanded(
                flex: 5,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 8,
                    activeTrackColor: const Color(0xffd5f4ff),
                    inactiveTrackColor: const Color(0xff455f75),
                    thumbColor: blue,
                    overlayColor: blue.withValues(alpha: .15),
                    thumbShape: const _GlowThumb(),
                  ),
                  child: Slider(
                    key: Key('mechanics-control-${c.keyName}'),
                    value: c.value.clamp(c.min, c.max),
                    min: c.min,
                    max: c.max,
                    onChanged: (v) => change(c, v),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => numeric(c),
                child: Container(
                  width: 152,
                  height: 54,
                  alignment: Alignment.center,
                  decoration: glass(radius: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 7),
                  child: FittedBox(child: label(formatted(c), 25)),
                ),
              ),
            ],
          ),
        );
}

class _GlowThumb extends SliderComponentShape {
  const _GlowThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(34, 34);
  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    context.canvas.drawCircle(
      center,
      19,
      Paint()
        ..color = const Color(0x88007dff)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    context.canvas.drawCircle(
      center,
      15,
      Paint()..color = const Color(0xff008cff),
    );
    context.canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = const Color(0xffd0f6ff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }
}

class _SheetControl extends StatefulWidget {
  final InstrumentControl control;
  final VoidCallback pause;
  const _SheetControl({required this.control, required this.pause});
  @override
  State<_SheetControl> createState() => _SheetControlState();
}

class _SheetControlState extends State<_SheetControl> {
  late double value = widget.control.value;
  @override
  Widget build(BuildContext context) {
    final c = widget.control;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${c.label}: ${value.toStringAsPrecision(4)} ${c.unit}'),
        Slider(
          value: value.clamp(c.min, c.max),
          min: c.min,
          max: c.max,
          onChanged: (v) {
            widget.pause();
            c.change(v);
            setState(() => value = v);
          },
        ),
      ],
    );
  }
}
