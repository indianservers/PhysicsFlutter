import '../dynamics/workspace.dart' show dynamicsRouteObserver;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart' show notebookProvider;
import '../../core/physics/live_optics.dart';
import '../../core/persistence/notebook.dart';
import 'scene.dart';

class LiveOpticsWorkspace extends ConsumerStatefulWidget {
  final String id;
  const LiveOpticsWorkspace({super.key, required this.id});
  @override
  ConsumerState<LiveOpticsWorkspace> createState() =>
      LiveOpticsWorkspaceState();
}

class LiveOpticsWorkspaceState extends ConsumerState<LiveOpticsWorkspace>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final LiveOpticsModel model;
  late final LocalNotebook store;
  late final Ticker ticker;
  int tab = 0;
  bool ready = false;
  double scanBase = 0;
  String message = '';
  static const blue = Color(0xff0087ff),
      ink = Color(0xffecf6ff),
      muted = Color(0xff9bc9e4),
      panel = Color(0xff071d2c);
  OpticsDefinition get definition => model.definition;
  String get sessionKey => 'optics-live:${widget.id}';
  bool get running => ticker.isActive;
  @override
  void initState() {
    super.initState();
    model = LiveOpticsModel(opticsById(widget.id));
    store = ref.read(notebookProvider);
    ticker = createTicker(scan);
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) dynamicsRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    pause();
  }

  Future<void> load() async {
    final saved = await store.readSession(sessionKey);
    if (saved != null && !model.restore(saved)) {
      await store.retainRejectedSession(sessionKey, saved);
    }
    await store.visit(widget.id);
    if (mounted) setState(() => ready = true);
  }

  void scan(Duration elapsed) {
    final control = definition.primary;
    final range = control.max - control.min;
    final value =
        (scanBase + math.sin(elapsed.inMicroseconds / 1e6 * .55) * range * .25)
            .clamp(control.min, control.max);
    model.set(control.key, value);
    if (mounted) setState(() {});
  }

  void pause() {
    if (ticker.isActive) {
      ticker.stop();
      if (mounted) setState(() {});
    }
  }

  void toggle() {
    if (running) {
      pause();
    } else {
      scanBase = model.p[definition.primary.key]!;
      ticker.start();
    }
    setState(() {});
  }

  void change(String key, double value) {
    pause();
    model.set(key, value);
    setState(() {});
  }

  void changed() {
    setState(() {});
  }

  Future<void> save() async {
    await store.saveSession(sessionKey, model.toJson());
    if (mounted) setState(() => message = 'Configuration saved.');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      pause();
      store.saveSession(sessionKey, model.toJson());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    dynamicsRouteObserver.unsubscribe(this);
    ticker.dispose();
    store.saveSession(sessionKey, model.toJson());
    super.dispose();
  }

  void reset() {
    pause();
    model.p = definition.defaults;
    model.mode = 0;
    model.spectrum = true;
    setState(() => message = '');
  }

  Future<void> record() async {
    pause();
    final observation = model.observation;
    if (observation == null) {
      setState(
        () => message = model.invalid.isNotEmpty
            ? model.invalid
            : 'No finite ${definition.kind == 9 ? 'magnification for this lens spacing' : 'transmitted response in this configuration'}. Adjust the apparatus before recording.',
      );
      return;
    }
    await store.addTrial(
      Trial(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        labId: widget.id,
        quantity: observation.quantity,
        unit: observation.unit,
        value: observation.value,
        resolution: null,
        configuration: model.toJson(),
        model: liveOpticsVersion,
        note:
            '${observation.label}; calculated ${definition.title} configuration; ${model.p.entries.map((e) => '${e.key}=${e.value}').join(', ')}',
      ),
    );
    await store.saveSession(sessionKey, model.toJson());
    if (mounted) setState(() => message = 'Trial recorded in Saved.');
  }

  Future<void> edit(String key) async {
    pause();
    final control = definition.controls.firstWhere((c) => c.key == key);
    final controller = TextEditingController(
      text: (model.p[key]! * control.multiplier).toStringAsFixed(
        control.digits + 2,
      ),
    );
    String? error;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(control.label),
          content: TextField(
            key: const Key('optics-number'),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(
              decimal: true,
              signed: true,
            ),
            decoration: InputDecoration(
              suffixText: control.unit,
              errorText: error,
              helperText:
                  '${control.format(control.min)} to ${control.format(control.max)}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final number = double.tryParse(controller.text);
                if (number == null ||
                    !number.isFinite ||
                    number / control.multiplier < control.min ||
                    number / control.multiplier > control.max) {
                  setDialog(
                    () => error = 'Enter a value in the displayed range.',
                  );
                  return;
                }
                change(key, number / control.multiplier);
                Navigator.pop(context);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  void mode(int value) {
    pause();
    model.mode = value;
    if (definition.kind == 9) {
      if (value == 1) {
        model.set('f1', .05);
        model.set('f2', .05);
        model.set('separation', .3);
      } else {
        model.set('f1', .2);
        model.set('f2', .05);
        model.set('separation', .25);
      }
    }
    setState(() {});
  }

  void help() {
    pause();
    showHelp();
  }

  void showHelp() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(definition.title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(definition.equation, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            Text(definition.principle),
            const SizedBox(height: 16),
            const Text(
              'Play starts a slow motor scan of the first control. Dragging any apparatus or editing a value stops the scan. Beam brightness represents relative intensity with an exposure curve; wavelength colors approximate the visible spectrum.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  Widget title(
    String value,
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w600,
  }) => Text(
    value,
    style: TextStyle(
      fontFamily: 'HomeManrope',
      fontSize: size,
      color: color,
      fontWeight: weight,
    ),
  );
  BoxDecoration glass() => BoxDecoration(
    color: panel,
    border: Border.all(color: const Color(0xff24516c)),
    borderRadius: BorderRadius.circular(15),
  );
  Widget control(OpticsParameter c, {bool compact = false}) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: compact ? 4 : 9,
      horizontal: compact ? 4 : 12,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: title(c.label, compact ? 12 : 13, color: muted)),
            IconButton(
              tooltip: 'Edit ${c.label}',
              onPressed: () => edit(c.key),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.edit_outlined, size: 14, color: muted),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => edit(c.key),
          child: title(c.format(model.p[c.key]!), compact ? 18 : 20),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 5,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            activeTrackColor: blue,
            inactiveTrackColor: const Color(0xff28435b),
            thumbColor: blue,
            overlayColor: blue.withValues(alpha: .12),
          ),
          child: SizedBox(
            height: 32,
            child: Slider(
              key: Key('optics-control-${c.key}'),
              value: model.p[c.key]!.clamp(c.min, c.max),
              min: c.min,
              max: c.max,
              onChanged: (v) => change(c.key, v),
            ),
          ),
        ),
        if (c.key == 'wavelength')
          Container(
            height: 9,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              gradient: const LinearGradient(
                colors: [
                  Color(0xff7300ff),
                  Color(0xff004cff),
                  Color(0xff00eeff),
                  Color(0xff31ff00),
                  Color(0xffffe000),
                  Color(0xffff0000),
                ],
              ),
            ),
          ),
        if (!compact)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              title(
                (c.min * c.multiplier).toStringAsFixed(c.digits),
                10,
                color: muted,
              ),
              title(
                (c.max * c.multiplier).toStringAsFixed(c.digits),
                10,
                color: muted,
              ),
            ],
          ),
      ],
    ),
  );
  List<OpticsParameter> get mainControls => definition.controls
      .where(
        (c) => !['power', 'optic', 'height', 'probe', 'n1'].contains(c.key),
      )
      .where(
        (c) =>
            !(definition.kind == 7 && model.spectrum && c.key == 'wavelength'),
      )
      .take(3)
      .toList();
  Widget spectrumControl() => DropdownButtonFormField<bool>(
    initialValue: model.spectrum,
    isExpanded: true,
    decoration: const InputDecoration(
      labelText: 'Show',
      isDense: true,
      border: OutlineInputBorder(),
    ),
    items: const [
      DropdownMenuItem(value: true, child: Text('Spectrum')),
      DropdownMenuItem(value: false, child: Text('Monochromatic')),
    ],
    onChanged: (value) {
      pause();
      setState(() => model.spectrum = value!);
    },
  );
  Widget modeControl() => DropdownButtonFormField<int>(
    key: ValueKey('mode-${widget.id}'),
    initialValue: model.mode,
    isExpanded: true,
    style: const TextStyle(fontFamily: 'HomeManrope', fontSize: 12, color: ink),
    decoration: InputDecoration(
      labelText: definition.kind == 7
          ? 'Material'
          : definition.kind == 8
          ? 'Show'
          : 'Configuration',
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9)),
    ),
    items: [
      for (int i = 0; i < definition.modes.length; i++)
        DropdownMenuItem(
          value: i,
          child: Text(definition.modes[i], maxLines: 2),
        ),
    ],
    onChanged: (v) => mode(v!),
  );
  Widget actions() => Row(
    children: [
      FilledButton(
        onPressed: toggle,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(13),
          minimumSize: const Size(48, 48),
        ),
        child: Icon(running ? Icons.pause : Icons.play_arrow, size: 26),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: OutlinedButton(onPressed: reset, child: const Text('Reset')),
      ),
    ],
  );
  Widget dock(bool landscape) => Container(
    margin: const EdgeInsets.all(7),
    padding: const EdgeInsets.all(8),
    decoration: glass(),
    child: Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: landscape
                ? Column(
                    children: [
                      if (definition.modes.isNotEmpty) modeControl(),
                      ...mainControls.map((c) => control(c)),
                      if (definition.kind == 7) spectrumControl(),
                    ],
                  )
                : Column(
                    children: [
                      if (definition.modes.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: modeControl(),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final c in mainControls.take(2))
                            Expanded(child: control(c, compact: true)),
                        ],
                      ),
                      if (mainControls.length > 2)
                        control(mainControls[2], compact: true),
                      if (definition.kind == 7) spectrumControl(),
                    ],
                  ),
          ),
        ),
        actions(),
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              message,
              style: const TextStyle(color: muted, fontSize: 11),
            ),
          ),
      ],
    ),
  );
  Widget graph() => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title('${definition.title} • ${model.responseKey}', 17),
        if (model.invalid.isNotEmpty) Text(model.invalid),
        const SizedBox(height: 10),
        Expanded(
          child: CustomPaint(
            key: const Key('optics-graph'),
            painter: OpticsCurvePainter(model.curve(), model),
            size: Size.infinite,
          ),
        ),
        title(
          definition.kind == 4 || definition.kind == 5
              ? 'Lateral screen position (mm)'
              : '${definition.primary.label} (${definition.primary.unit})',
          12,
          color: muted,
        ),
      ],
    ),
  );
  Widget inspector() => ListView(
    padding: const EdgeInsets.all(14),
    children: [
      title(definition.equation, 21),
      const SizedBox(height: 12),
      Text(
        definition.principle,
        style: const TextStyle(color: muted, fontSize: 13),
      ),
      if (definition.modes.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: modeControl(),
        ),
      ...definition.controls.map((c) => control(c)),
      if (definition.kind == 7) spectrumControl(),
      ...model.state.entries.map(
        (e) => ListTile(
          dense: true,
          title: Text(e.key),
          trailing: Text(e.value.toStringAsPrecision(5)),
        ),
      ),
      if (definition.kind == 1)
        OutlinedButton(
          onPressed: () {
            pause();
            final a = model.v('n1');
            model.set('n1', model.v('n2'));
            model.set('n2', a);
            setState(() {});
          },
          child: const Text('Swap incident and transmitted media'),
        ),
    ],
  );
  Widget results() {
    final trials = store.trials
        .where(
          (t) =>
              t.labId == widget.id &&
              [liveOpticsVersion, legacyLiveOpticsVersion].contains(t.model),
        )
        .toList()
        .reversed;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        title('Live readings', 21),
        if (model.invalid.isNotEmpty) Text(model.invalid),
        ...model.state.entries.map(
          (e) => ListTile(
            title: Text(e.key),
            trailing: Text(e.value.toStringAsPrecision(5)),
          ),
        ),
        FilledButton.icon(
          onPressed: model.observation == null ? null : record,
          icon: const Icon(Icons.add_chart),
          label: const Text('Record this configuration'),
        ),
        const SizedBox(height: 20),
        title('${trials.length} recorded trials', 18),
        ...trials.map(
          (t) => ListTile(
            title: Text('${t.value.toStringAsPrecision(6)} ${t.unit}'),
            subtitle: Text(
              t.model == liveOpticsVersion
                  ? t.created
                  : '${t.created} • Earlier model; reopen to recalculate',
            ),
            trailing: IconButton(
              tooltip: 'Reopen configuration',
              icon: const Icon(Icons.restore),
              onPressed: () {
                pause();
                if (model.restore(t.configuration)) setState(() => tab = 0);
              },
            ),
          ),
        ),
        if (message.isNotEmpty) Text(message),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: 'HomeManrope',
      colorScheme: const ColorScheme.dark(primary: blue, surface: panel),
      scaffoldBackgroundColor: const Color(0xff051824),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xff051824),
      body: SafeArea(
        child: !ready
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, box) {
                  final landscape = box.maxWidth > box.maxHeight * 1.15;
                  return Column(
                    children: [
                      SizedBox(
                        height: landscape ? 58 : 68,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              IconButton(
                                tooltip: 'Back to Optics',
                                onPressed: () => context.go('/studio/s09'),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  size: 23,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.shutter_speed_outlined,
                                size: 30,
                                color: ink,
                              ),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: title(
                                        '${definition.kind + 1}. ${definition.title}',
                                        landscape ? 22 : 23,
                                      ),
                                    ),
                                    Text(
                                      definition.subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'Help',
                                onPressed: help,
                                icon: const Icon(Icons.help_outline, size: 25),
                              ),
                              PopupMenuButton<String>(
                                tooltip: 'Lab options',
                                onSelected: (value) {
                                  pause();
                                  if (value == 'save') {
                                    save();
                                  } else if (value == 'record') {
                                    record();
                                  } else if (value == 'bench') {
                                    context.push('/lab/${widget.id}/bench');
                                  } else if (value == 'classic') {
                                    context.push('/lab/${widget.id}?classic=1');
                                  } else {
                                    context.go('/lab/$value');
                                  }
                                },
                                itemBuilder: (_) => [
                                  ...opticsDefinitions.map(
                                    (d) => PopupMenuItem(
                                      value: d.id,
                                      child: Text('${d.kind + 1}. ${d.title}'),
                                    ),
                                  ),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(
                                    value: 'save',
                                    child: Text('Save configuration'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'record',
                                    child: Text('Record Trial'),
                                  ),
                                  if (definition.kind <= 3)
                                    const PopupMenuItem(
                                      value: 'bench',
                                      child: Text('Advanced material bench'),
                                    ),
                                  if (definition.kind <= 6)
                                    const PopupMenuItem(
                                      value: 'classic',
                                      child: Text('Classic calculation view'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        height: 42,
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                        decoration: glass(),
                        child: Row(
                          children: List.generate(
                            4,
                            (i) => Expanded(
                              child: InkWell(
                                key: Key(
                                  [
                                    'workspace-scene',
                                    'workspace-graph',
                                    'workspace-inspect',
                                    'workspace-results',
                                  ][i],
                                ),
                                onTap: () {
                                  pause();
                                  setState(() => tab = i);
                                },
                                borderRadius: BorderRadius.circular(18),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: tab == i ? blue : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        [
                                          Icons.science_outlined,
                                          Icons.show_chart,
                                          Icons.tune,
                                          Icons.bar_chart,
                                        ][i],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            [
                                              'Apparatus',
                                              'Graph',
                                              'Inspect',
                                              'Results',
                                            ][i],
                                            style: const TextStyle(
                                              fontSize: 12,
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
                      ),
                      Expanded(
                        child: tab == 0
                            ? (landscape
                                  ? Row(
                                      children: [
                                        Expanded(
                                          child: InteractiveOpticsScene(
                                            key: ValueKey(
                                              'optics-scene-${widget.id}',
                                            ),
                                            model: model,
                                            pause: pause,
                                            changed: changed,
                                            inspect: edit,
                                          ),
                                        ),
                                        SizedBox(
                                          width: (box.maxWidth * .28).clamp(
                                            190,
                                            270,
                                          ),
                                          child: dock(true),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      children: [
                                        Expanded(
                                          child: InteractiveOpticsScene(
                                            key: ValueKey(
                                              'optics-scene-${widget.id}',
                                            ),
                                            model: model,
                                            pause: pause,
                                            changed: changed,
                                            inspect: edit,
                                          ),
                                        ),
                                        SizedBox(
                                          height: definition.modes.isEmpty
                                              ? 210
                                              : 250,
                                          child: dock(false),
                                        ),
                                      ],
                                    ))
                            : tab == 1
                            ? graph()
                            : tab == 2
                            ? inspector()
                            : results(),
                      ),
                      if (!landscape)
                        Container(
                          height: 57,
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xff24445a)),
                            ),
                          ),
                          child: Row(
                            children: List.generate(
                              4,
                              (i) => Expanded(
                                child: InkWell(
                                  key: Key(
                                    'home-nav-${['home', 'explore', 'saved', 'settings'][i]}',
                                  ),
                                  onTap: () {
                                    pause();
                                    context.push(
                                      i == 3
                                          ? '/settings'
                                          : i == 2
                                          ? '/?tab=saved'
                                          : i == 1
                                          ? '/?tab=explore'
                                          : '/',
                                    );
                                  },
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        [
                                          Icons.home_outlined,
                                          Icons.grid_view_rounded,
                                          Icons.bookmark_border,
                                          Icons.settings_outlined,
                                        ][i],
                                        size: 22,
                                        color: i == 1 ? blue : muted,
                                      ),
                                      Text(
                                        [
                                          'Home',
                                          'Explore',
                                          'Saved',
                                          'Settings',
                                        ][i],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: i == 1 ? blue : muted,
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
                  );
                },
              ),
      ),
    ),
  );
}

class OpticsCurvePainter extends CustomPainter {
  final List<({double x, double y})> points;
  final LiveOpticsModel model;
  const OpticsCurvePainter(this.points, this.model);
  @override
  void paint(Canvas c, Size size) {
    final valid = points.where((p) => p.y.isFinite).toList();
    if (valid.isEmpty) return;
    final area = Rect.fromLTRB(50, 18, size.width - 12, size.height - 34);
    if (area.width <= 0 || area.height <= 0) return;
    var minY = valid.map((p) => p.y).reduce(math.min),
        maxY = valid.map((p) => p.y).reduce(math.max);
    if ((maxY - minY).abs() < 1e-10) {
      minY -= .5;
      maxY += .5;
    }
    final minX = points.first.x, maxX = points.last.x;
    void label(String value, Offset at) {
      final p = TextPainter(
        text: TextSpan(
          text: value,
          style: const TextStyle(color: Color(0xffa8c9df), fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      p.paint(c, at);
    }

    for (int i = 0; i <= 5; i++) {
      final y = area.bottom - area.height * i / 5,
          x = area.left + area.width * i / 5;
      c.drawLine(
        Offset(area.left, y),
        Offset(area.right, y),
        Paint()..color = const Color(0xff244356),
      );
      c.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        Paint()..color = const Color(0xff244356),
      );
      label(
        (minY + (maxY - minY) * i / 5).toStringAsPrecision(3),
        Offset(0, y - 7),
      );
      final mult = model.definition.kind == 4 || model.definition.kind == 5
          ? 1000
          : model.definition.primary.multiplier;
      label(
        ((minX + (maxX - minX) * i / 5) * mult).toStringAsPrecision(3),
        Offset(x - 13, area.bottom + 8),
      );
    }
    final path = Path();
    bool open = false;
    for (final p in points) {
      if (!p.y.isFinite) {
        open = false;
        continue;
      }
      final at = Offset(
        area.left + (p.x - minX) / (maxX - minX) * area.width,
        area.bottom - (p.y - minY) / (maxY - minY) * area.height,
      );
      if (!open) {
        path.moveTo(at.dx, at.dy);
        open = true;
      } else {
        path.lineTo(at.dx, at.dy);
      }
    }
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xff03bdff)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant OpticsCurvePainter old) => true;
}
