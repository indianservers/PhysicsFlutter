import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../content/lab_research_profiles.dart';
import '../../core/design_system/reading_presentation.dart';
import '../../core/persistence/notebook.dart';
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'instrument_types.dart';

/// A deliberately compact, immutable capture. Source notes, trial histories and
/// credentials are never copied into a worksheet. A point is an explicit model
/// snapshot, not an instrument measurement or an automatically generated curve.
class ResearchSnapshot {
  final Map<String, double> inputs;
  final Map<String, String> inputUnits;
  final List<InstrumentReading> readings;
  final String model, mode;
  final double? time;
  final String created;
  ResearchSnapshot(
    this.inputs,
    this.inputUnits,
    this.readings,
    this.model,
    this.mode,
    this.time,
    this.created,
  );
  InstrumentReading? reading(String key) =>
      readings.where((r) => r.label == key).firstOrNull;
  Map<String, dynamic> toJson() => {
    'inputs': inputs,
    'inputUnits': inputUnits,
    'readings': [
      for (final r in readings)
        {'key': r.label, 'value': r.value, 'unit': r.unit},
    ],
    'model': model,
    'mode': mode,
    'time': time,
    'created': created,
  };
  factory ResearchSnapshot.fromJson(Map<String, dynamic> value) {
    final inputs = Map<String, dynamic>.from(value['inputs']);
    final units = Map<String, dynamic>.from(value['inputUnits']);
    final raw = value['readings'] as List;
    final time = (value['time'] as num?)?.toDouble();
    if (inputs.length > 100 ||
        units.length != inputs.length ||
        raw.length > 150 ||
        time != null && !time.isFinite) {
      throw const FormatException('Invalid worksheet snapshot');
    }
    final numbers = inputs.map((k, v) => MapEntry(k, (v as num).toDouble()));
    if (numbers.values.any((v) => !v.isFinite) ||
        numbers.keys.any((k) => units[k] is! String)) {
      throw const FormatException('Invalid snapshot input');
    }
    final readings = <InstrumentReading>[];
    for (final r in raw) {
      if (r['key'] is! String ||
          r['unit'] is! String ||
          r['value'] is! String ||
          !(double.tryParse(r['value'])?.isFinite ?? false)) {
        throw const FormatException('Invalid snapshot reading');
      }
      readings.add(InstrumentReading(r['key'], r['value'], r['unit']));
    }
    return ResearchSnapshot(
      Map.unmodifiable(numbers),
      Map.unmodifiable(units.cast<String, String>()),
      List.unmodifiable(readings),
      value['model'] as String,
      value['mode'] as String,
      time,
      value['created'] as String,
    );
  }
}

class ResearchPoint {
  final String input, inputUnit, output, outputUnit;
  final double x, y;
  final ResearchSnapshot snapshot;
  const ResearchPoint(
    this.input,
    this.inputUnit,
    this.output,
    this.outputUnit,
    this.x,
    this.y,
    this.snapshot,
  );
  Map<String, dynamic> toJson() => {
    'input': input,
    'inputUnit': inputUnit,
    'output': output,
    'outputUnit': outputUnit,
    'x': x,
    'y': y,
    'snapshot': snapshot.toJson(),
  };
  factory ResearchPoint.fromJson(Map<String, dynamic> value) {
    final x = (value['x'] as num).toDouble(),
        y = (value['y'] as num).toDouble();
    final s = ResearchSnapshot.fromJson(
      Map<String, dynamic>.from(value['snapshot']),
    );
    if (!x.isFinite ||
        !y.isFinite ||
        s.inputs[value['input']] != x ||
        s.inputUnits[value['input']] != value['inputUnit'] ||
        double.tryParse(s.reading(value['output'])?.value ?? '') != y ||
        s.reading(value['output'])?.unit != value['outputUnit']) {
      throw const FormatException('Point does not match its source snapshot');
    }
    return ResearchPoint(
      value['input'],
      value['inputUnit'],
      value['output'],
      value['outputUnit'],
      x,
      y,
      s,
    );
  }
}

class LabResearchSession extends ChangeNotifier {
  static const version = 'lab-research-1.0';
  final LabResearchProfile profile;
  final LocalNotebook store;
  final List<InstrumentControl> Function() controls;
  final List<InstrumentReading> Function() readings;
  final Map<String, dynamic> Function() configuration;
  final bool Function(Map<String, dynamic>) restore;
  final bool Function() valid;
  final VoidCallback pause;
  ResearchSnapshot? a, b;
  final points = <ResearchPoint>[];
  Map<String, dynamic>? undo;
  String claim = '', reasoning = '', question = '', feedback = '';
  String? retainedWorksheet;
  bool dirty = false;
  bool disposed = false;
  String get preferenceKey => 'lab-research:${profile.id}';
  LabResearchSession({
    required this.profile,
    required this.store,
    required this.controls,
    required this.readings,
    required this.configuration,
    required this.restore,
    required this.valid,
    required this.pause,
  }) {
    final saved = store.preferences.getString(preferenceKey);
    if (saved != null && !load(saved)) {
      retainedWorksheet = saved;
      feedback = 'Saved worksheet unavailable; original retained. Saving a new worksheet keeps a backup.';
    }
  }
  void changed() {
    if (!disposed) notifyListeners();
  }

  InstrumentControl? control(String key) =>
      controls().where((c) => c.keyName == key).firstOrNull;
  static String show(double value) => conciseNumber(value, precision: 6);
  static Map<String, dynamic> clone(Map<String, dynamic> input) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(input)));
  bool apply(String key, double value) {
    pause();
    final c = control(key);
    if (c == null || !value.isFinite || value < c.min || value > c.max) {
      feedback = c == null
          ? 'This control is unavailable in the selected mode. Choose the corresponding source mode in Inspect.'
          : 'Value is outside this mode’s current bounds. No setup change applied.';
      changed();
      return false;
    }
    final before = clone(configuration());
    try {
      c.change(value);
      undo = before;
      final actual = control(key);
      feedback =
          '${c.label}: ${show(c.value)} → ${actual == null ? 'mode changed' : show(actual.value)} ${c.unit}. '
          '${valid() ? 'Calculated state ready.' : 'Finish the apparatus procedure or inspect the model notice before capturing.'}';
      changed();
      return true;
    } catch (_) {
      restore(before);
      feedback = 'Setup change could not be applied; restoration of the previous configuration was requested.';
      changed();
      return false;
    }
  }

  bool undoSetup() {
    pause();
    final saved = undo;
    if (saved == null) return false;
    final ok = restore(clone(saved));
    if (ok) undo = null;
    feedback = ok
        ? 'Previous experiment configuration restored; recorded trials kept.'
        : 'Restore unavailable; the original configuration remains retained in this panel.';
    changed();
    return ok;
  }

  ResearchSnapshot? capture() {
    pause();
    if (!valid()) {
      feedback = 'Capture not ready. Complete the source apparatus procedure or correct its model notice. No observation was inserted.';
      changed();
      return null;
    }
    final config = configuration();
    final values = readings()
        .where((r) => double.tryParse(r.value)?.isFinite ?? false)
        .toList();
    if (values.isEmpty) {
      feedback = 'No finite source reading is ready for this state.';
      changed();
      return null;
    }
    final cs = controls();
    final time =
        (config['time'] as num?)?.toDouble() ??
        double.tryParse(
          values
                  .where((r) => ['t', 'elapsed'].contains(r.label))
                  .firstOrNull
                  ?.value ??
              '',
        );
    return ResearchSnapshot(
      Map.unmodifiable({for (final c in cs) c.keyName: c.value}),
      Map.unmodifiable({for (final c in cs) c.keyName: c.unit}),
      List.unmodifiable(values),
      '${config['model'] ?? 'source model'}',
      jsonEncode({
        for (final k in [
          'mode',
          'frame',
          'kind',
          'dataset',
          'epoch',
          'selectedPart',
        ])
          if (config.containsKey(k)) k: config[k],
      }),
      time,
      DateTime.now().toUtc().toIso8601String(),
    );
  }

  bool captureComparison(bool second) {
    final value = capture();
    if (value == null) return false;
    if (second) {
      b = value;
    } else {
      a = value;
    }
    dirty = true;
    feedback = 'State ${second ? 'B' : 'A'} captured from this paused model.';
    changed();
    return true;
  }

  bool capturePoint(String input, String output) {
    final s = capture();
    if (s == null) return false;
    final y = s.reading(output), x = s.inputs[input];
    final numeric = double.tryParse(y?.value ?? '');
    if (x == null || y == null || numeric == null || !numeric.isFinite) {
      feedback = 'The selected axes are not both available in this state. No point added.';
      changed();
      return false;
    }
    final p = ResearchPoint(
      input,
      s.inputUnits[input]!,
      output,
      y.unit,
      x,
      numeric,
      s,
    );
    if (points.length >= 24) {
      feedback = 'This worksheet holds 24 points. Remove a point before adding another.';
      changed();
      return false;
    }
    if (points.isNotEmpty &&
        points.any(
          (q) =>
              q.input != p.input ||
              q.inputUnit != p.inputUnit ||
              q.output != p.output ||
              q.outputUnit != p.outputUnit ||
              q.snapshot.model != s.model ||
              q.snapshot.mode != s.mode,
        )) {
      feedback = 'Existing points use different axes, units, experiment modes or model versions. Start a separate worksheet series before changing these conditions.';
      changed();
      return false;
    }
    points.add(p);
    dirty = true;
    feedback =
        'Model point ${points.length} captured. Its time, mode and inputs are attached.';
    changed();
    return true;
  }

  Map<String, dynamic> document() => {
    'version': version,
    'labId': profile.id,
    'claim': claim,
    'reasoning': reasoning,
    'question': question,
    'a': a?.toJson(),
    'b': b?.toJson(),
    'points': [for (final p in points) p.toJson()],
  };
  bool load(String raw) {
    try {
      final value = jsonDecode(raw) as Map<String, dynamic>;
      if (value['version'] != version ||
          value['labId'] != profile.id ||
          ['claim', 'reasoning', 'question'].any(
            (k) => value[k] is! String || (value[k] as String).length > 4000,
          ) ||
          value['points'] is! List ||
          (value['points'] as List).length > 24) {
        return false;
      }
      final loaded = [
        for (final p in value['points'])
          ResearchPoint.fromJson(Map<String, dynamic>.from(p)),
      ];
      if (loaded.isNotEmpty &&
          loaded.any(
            (p) =>
                p.input != loaded.first.input ||
                p.inputUnit != loaded.first.inputUnit ||
                p.output != loaded.first.output ||
                p.outputUnit != loaded.first.outputUnit ||
                p.snapshot.model != loaded.first.snapshot.model ||
                p.snapshot.mode != loaded.first.snapshot.mode,
          )) {
        return false;
      }
      final a = value['a'] == null
          ? null
          : ResearchSnapshot.fromJson(Map<String, dynamic>.from(value['a']));
      final b = value['b'] == null
          ? null
          : ResearchSnapshot.fromJson(Map<String, dynamic>.from(value['b']));
      this.a = a;
      this.b = b;
      points
        ..clear()
        ..addAll(loaded);
      claim = value['claim'];
      reasoning = value['reasoning'];
      question = value['question'];
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> save() async {
    try {
      if ([claim, reasoning, question].any((v) => v.length > 4000)) {
        return false;
      }
      final retained = retainedWorksheet;
      if (retained != null) {
        final ok = await store.preferences.setString(
          'lab-research-backup:${profile.id}:${DateTime.now().microsecondsSinceEpoch}',
          retained,
        );
        if (!ok) return false;
        retainedWorksheet = null;
      }
      final snapshot = jsonEncode(document());
      final ok = await store.saveLabWorksheet(profile.id, snapshot);
      if (ok) {
        dirty = jsonEncode(document()) != snapshot;
        feedback = dirty
            ? 'Saved snapshot; newer edits still need saving.'
            : 'Worksheet saved on this device.';
      } else {
        feedback =
            'Worksheet could not be saved. Existing stored content retained.';
      }
      changed();
      return ok;
    } catch (_) {
      feedback = 'Save failed; existing stored worksheet retained.';
      changed();
      return false;
    }
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

class LabResearchSheet extends StatefulWidget {
  final String title;
  final LabResearchSession session;
  final Listenable sourceChanges;
  final String Function() notice;
  final Widget Function()? selection;
  final bool Function() playing, dynamicModel;
  final VoidCallback play, pause;
  final VoidCallback? step;
  final int initialPage;
  const LabResearchSheet({
    super.key,
    required this.title,
    required this.session,
    required this.sourceChanges,
    required this.notice,
    this.selection,
    this.initialPage = 0,
    required this.playing,
    required this.dynamicModel,
    required this.play,
    required this.pause,
    this.step,
  });
  @override
  State<LabResearchSheet> createState() => _LabResearchSheetState();
}

class _LabResearchSheetState extends State<LabResearchSheet> {
  late final claim = TextEditingController(text: s.claim),
      reasoning = TextEditingController(text: s.reasoning),
      question = TextEditingController(text: s.question);
  late final Listenable changes = Listenable.merge([widget.sourceChanges, s]);
  LabResearchSession get s => widget.session;
  LabResearchProfile get p => s.profile;
  bool get compact =>
      MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom <
      440;
  String? xKey, yKey;
  bool allowClose = false, closing = false;
  @override
  void initState() {
    super.initState();
    if (s.points.isNotEmpty) {
      xKey = s.points.first.input;
      yKey = s.points.first.output;
    }
  }

  Future<void> requestClose() async {
    if (closing) return;
    closing = true;
    try {
      if (s.dirty) {
        FocusScope.of(context).unfocus();
        final choice = await showDialog<int>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Save this worksheet?'),
            content: const Text(
              'Your captures and explanation have unsaved changes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep editing'),
              ),
              TextButton(
                key: const Key('research-close-unsaved'),
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('Close without saving'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 1),
                child: const Text('Save and close'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        if (choice == 1 && !await s.save()) return;
      }
      if (!mounted) return;
      setState(() => allowClose = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } finally {
      closing = false;
    }
  }

  @override
  void dispose() {
    claim.dispose();
    reasoning.dispose();
    question.dispose();
    super.dispose();
  }

  String label(String key) {
    const names = {
      'emf': 'Electromotive force (EMF)',
      'reynolds': 'Reynolds number',
      'sem': 'Standard error of the mean',
      'sd': 'Sample standard deviation',
      'instrument': 'Resolution uncertainty',
      'combined': 'Combined standard uncertainty',
      'sampleCount': 'Repeated readings',
      'sagitta': 'Signed sagitta',
      'indication': 'Screw indication',
      'legRadius': 'Centre-to-leg distance',
      'main': 'Main-scale contribution',
      'fraction': 'Fractional-scale contribution',
      'ax': 'Acceleration (x)',
      'ay': 'Acceleration (y)',
      'fx': 'Net force (x)',
      'fy': 'Net force (y)',
      'vx': 'Velocity (x)',
      'vy': 'Velocity (y)',
    };
    if (names.containsKey(key)) return names[key]!;
    final standard = presentReading(key, '0', '').label;
    if (standard != key) return standard;
    final words = key.replaceAllMapped(
      RegExp(r'([a-z0-9])([A-Z])'),
      (m) => '${m[1]} ${m[2]}',
    );
    return words.isEmpty ? key : words[0].toUpperCase() + words.substring(1);
  }

  String value(InstrumentReading r) {
    if (double.tryParse(r.value)?.isNaN ?? false) {
      return 'Not defined in this source state';
    }
    if (r.value == 'Infinity') return '∞ ${r.unit}';
    if (r.value == '-Infinity') return '−∞ ${r.unit}';
    final display = presentReading(r.label, r.value, r.unit);
    return '${display.value} ${display.unit}';
  }

  Widget heading(String title, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(text),
      ],
    ),
  );
  Widget reading(InstrumentReading r) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label(r.label)),
    subtitle: SelectableText(value(r)),
  );
  Widget input(InstrumentControl c) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(c.label),
    subtitle: Text('${LabResearchSession.show(c.value)} ${c.unit}'),
    trailing: IconButton(
      tooltip: 'Set ${c.label} precisely',
      icon: const Icon(Icons.edit_outlined),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => NumericInputDialog(
          label: '${c.label} (${c.unit})',
          initial: c.value,
          min: c.min,
          max: c.max,
          onApply: (v) => s.apply(c.keyName, v),
        ),
      ),
    ),
  );
  List<Widget> sourceStatus() => [
    if (widget.dynamicModel())
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            key: const Key('research-run'),
            onPressed: widget.playing() ? widget.pause : widget.play,
            icon: Icon(widget.playing() ? Icons.pause : Icons.play_arrow),
            label: Text(
              widget.playing() ? 'Pause experiment' : 'Run experiment',
            ),
          ),
          if (widget.step != null)
            OutlinedButton(
              onPressed: widget.step,
              child: const Text('Step experiment'),
            ),
        ],
      ),
    Text(widget.notice(), style: Theme.of(context).textTheme.bodySmall),
    const SizedBox(height: 12),
  ];
  Widget setup() {
    final c = s.control(p.focusKey);
    return ListView(
      key: const Key('research-setup-scroll'),
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          p.focusTitle,
          'Preview and apply this experiment-specific setting. Only the named control changes; your other inputs and selected source mode are retained.',
        ),
        if (widget.selection != null)
          ExpansionTile(
            title: const Text('Model options'),
            children: [widget.selection!()],
          ),
        if (c != null) ...[
          input(c),
          Text(
            'Suggested setting: ${LabResearchSession.show(p.focusValue)} ${c.unit}',
          ),
          const SizedBox(height: 12),
          FilledButton(
            key: const Key('research-apply-focus'),
            onPressed: () => s.apply(p.focusKey, p.focusValue),
            child: const Text('Apply suggested setting'),
          ),
        ] else
          Text(
            'This investigation uses ${p.focusKey} in the corresponding source mode. Choose that mode in Inspect; no different control is substituted.',
          ),
        if (s.undo != null)
          OutlinedButton(
            key: const Key('research-undo'),
            onPressed: s.undoSetup,
            child: const Text('Undo latest setup change'),
          ),
        const SizedBox(height: 20),
        ...sourceStatus(),
        for (final r in s.readings().where(
          (r) => p.watchKeys.contains(r.label),
        ))
          reading(r),
      ],
    );
  }

  Widget comparison() {
    final c = p.compareKey == null ? null : s.control(p.compareKey!);
    return ListView(
      key: const Key('research-comparison-scroll'),
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          p.compareTitle,
          'Try the proposed settings, run to the same stage where needed, and capture each state. Other current inputs and the source mode are retained. These are model snapshots.',
        ),
        if (c != null) ...[
          input(c),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                key: const Key('research-preset-a'),
                onPressed: () => s.apply(c.keyName, p.compareA!),
                child: Text(
                  'Try A: ${LabResearchSession.show(p.compareA!)} ${c.unit}',
                ),
              ),
              OutlinedButton(
                key: const Key('research-preset-b'),
                onPressed: () => s.apply(c.keyName, p.compareB!),
                child: Text(
                  'Try B: ${LabResearchSession.show(p.compareB!)} ${c.unit}',
                ),
              ),
            ],
          ),
        ] else if (p.compareKey == null) ...[
          const Text(
            'Choose a nuclide in the source selector, capture A, choose another and capture B. Camera rotation alone does not change nuclear properties.',
          ),
          if (widget.selection != null)
            ExpansionTile(
              title: const Text('Model options'),
              children: [widget.selection!()],
            ),
        ] else
          const Text(
            'The comparison control is unavailable in this mode. Use the corresponding source mode before applying the proposed A/B settings.',
          ),
        const SizedBox(height: 12),
        ...sourceStatus(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const Key('research-capture-a'),
              onPressed: () => s.captureComparison(false),
              child: const Text('Capture A'),
            ),
            FilledButton.tonal(
              key: const Key('research-capture-b'),
              onPressed: () => s.captureComparison(true),
              child: const Text('Capture B'),
            ),
          ],
        ),
        if (s.a != null) contextLine('A', s.a!),
        if (s.b != null) contextLine('B', s.b!),
        if (s.a != null && s.b != null) ...[
          if (s.a!.time != s.b!.time || s.a!.mode != s.b!.mode)
            const Text(
              'Capture times or model variants differ. Check whether your investigation holds time, process stage and other inputs fixed before attributing a difference to one setting.',
            ),
          for (final key in {...s.a!.inputs.keys, ...s.b!.inputs.keys})
            if (s.a!.inputs[key] != s.b!.inputs[key] ||
                s.a!.inputUnits[key] != s.b!.inputUnits[key])
              Text(
                '${s.control(key)?.label ?? label(key)}: ${s.a!.inputs[key]} ${s.a!.inputUnits[key] ?? ""} → ${s.b!.inputs[key]} ${s.b!.inputUnits[key] ?? ""}',
              ),
          for (final key in p.watchKeys) ...delta(key),
        ],
      ],
    );
  }

  Widget contextLine(String name, ResearchSnapshot snapshot) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Text(
      '$name · ${snapshot.time == null ? 'source conditions attached' : 'model time ${LabResearchSession.show(snapshot.time!)} s'}',
    ),
  );
  List<Widget> delta(String key) {
    final a = s.a!.reading(key), b = s.b!.reading(key);
    if (a == null ||
        b == null ||
        a.unit != b.unit ||
        s.a!.model != s.b!.model) {
      return [];
    }
    final x = double.parse(a.value),
        y = double.parse(b.value),
        difference = y - x;
    final formattedDifference = presentReading(
      key,
      difference.toString(),
      a.unit,
    );
    final differenceText =
        '${formattedDifference.value} ${formattedDifference.unit == '%' ? 'percentage points' : formattedDifference.unit}';
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(presentReading(key, a.value, a.unit).label),
        subtitle: Text(
          'A: ${value(a)}\nB: ${value(b)}\nB − A: $differenceText\n'
          '${x == 0 ? 'Relative change undefined because A is zero.' : 'Change relative to |A|: ${LabResearchSession.show(difference / x.abs() * 100)}%'}',
        ),
      ),
    ];
  }

  Widget watch() => ListView(
    key: const Key('research-watch-scroll'),
    padding: const EdgeInsets.all(20),
    children: [
      heading(
        p.watchTitle,
        'Live calculated values for this investigation. Change a source setting to inspect its effect.',
      ),
      ...sourceStatus(),
      for (final key in p.watchKeys)
        if (s.readings().where((r) => r.label == key).firstOrNull
            case final InstrumentReading r)
          reading(r)
        else
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label(key)),
            subtitle: const Text(
              'Not defined or not yet obtained in this source state. Complete the apparatus procedure or choose the relevant mode.',
            ),
          ),
      if (s.a != null && s.b != null) ...[
        const Divider(),
        const Text('Captured A/B evidence'),
        for (final key in p.watchKeys) ...delta(key),
      ],
    ],
  );
  Widget plot() {
    final cs = s.controls();
    final rs = s
        .readings()
        .where((r) => p.watchKeys.contains(r.label) || r.label == p.plotReading)
        .where((r) => double.tryParse(r.value)?.isFinite ?? false)
        .toList();
    final selectedX = xKey ?? p.plotKey, selectedY = yKey ?? p.plotReading;
    final activeX = cs.any((c) => c.keyName == selectedX),
        activeY = rs.any((r) => r.label == selectedY);
    return ListView(
      key: const Key('research-plot-scroll'),
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          p.plotTitle,
          'Capture paused model snapshots to build a scatter plot. Keep other conditions fixed to test one variable. Use Record Trial in the lab for a complete reproducible run.',
        ),
        DropdownButtonFormField<String>(
          key: ValueKey('research-x-$selectedX-$activeX'),
          initialValue: activeX ? selectedX : null,
          isExpanded: true,
          itemHeight: null,
          isDense: false,
          decoration: const InputDecoration(labelText: 'Input axis'),
          hint: Text('$selectedX unavailable in this mode'),
          items: [
            for (final c in cs)
              DropdownMenuItem(
                value: c.keyName,
                child: Text('${c.label} (${c.unit})', maxLines: 2),
              ),
          ],
          onChanged: s.points.isNotEmpty
              ? null
              : (v) => setState(() => xKey = v),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey('research-y-$selectedY-$activeY'),
          initialValue: activeY ? selectedY : null,
          isExpanded: true,
          itemHeight: null,
          isDense: false,
          decoration: const InputDecoration(labelText: 'Output axis'),
          hint: Text('$selectedY not yet available'),
          items: [
            for (final r in rs)
              DropdownMenuItem(
                value: r.label,
                child: Text('${label(r.label)} (${r.unit})', maxLines: 2),
              ),
          ],
          onChanged: s.points.isNotEmpty
              ? null
              : (v) => setState(() => yKey = v),
        ),
        if (activeX) input(s.control(selectedX)!),
        ...sourceStatus(),
        FilledButton.icon(
          key: const Key('research-capture-point'),
          onPressed: activeX && activeY
              ? () => s.capturePoint(selectedX, selectedY)
              : null,
          icon: const Icon(Icons.add_chart),
          label: const Text('Capture model point'),
        ),
        if (s.points.isNotEmpty) ...[
          const SizedBox(height: 12),
          Semantics(
            image: true,
            label:
                '${p.plotTitle}; ${s.points.length} captured points. '
                'Input ${s.points.first.input} in ${s.points.first.inputUnit}; output ${s.points.first.output} in ${s.points.first.outputUnit}.',
            child: SizedBox(
              height: 240,
              child: CustomPaint(
                painter: ResearchScatter(
                  List.of(s.points),
                  inputLabel:
                      s.control(s.points.first.input)?.label ??
                      label(s.points.first.input),
                  outputLabel: label(s.points.first.output),
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          for (int i = 0; i < s.points.length; i++)
            ExpansionTile(
              key: ValueKey('research-point-$i'),
              title: Text(
                '${i + 1}. ${LabResearchSession.show(s.points[i].x)} ${s.points[i].inputUnit} → ${LabResearchSession.show(s.points[i].y)} ${s.points[i].outputUnit}',
              ),
              children: [
                contextLine('Snapshot', s.points[i].snapshot),
                for (final input in s.points[i].snapshot.inputs.entries)
                  Text(
                    '${s.control(input.key)?.label ?? label(input.key)}: ${LabResearchSession.show(input.value)} ${s.points[i].snapshot.inputUnits[input.key]}',
                  ),
                TextButton(
                  onPressed: () {
                    s.points.removeAt(i);
                    s.dirty = true;
                    s.changed();
                  },
                  child: const Text('Remove this point'),
                ),
              ],
            ),
        ] else
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Choose a ready input and output, then capture a point. No synthetic points are inserted.',
            ),
          ),
      ],
    );
  }

  Widget worksheet() => ListView(
    key: const Key('research-worksheet-scroll'),
    padding: const EdgeInsets.all(20),
    children: [
      heading('Explain your ${widget.title} evidence', p.prompt),
      const Text(
        'State a claim, cite your captured values, and explain the result using the model’s assumptions.',
      ),
      const SizedBox(height: 16),
      for (final entry in [
        (claim, 'Your claim', 'claim'),
        (reasoning, 'Reasoning linked to the physics', 'reasoning'),
        (question, 'A limitation or next question', 'question'),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextField(
            key: Key('research-${entry.$3}'),
            controller: entry.$1,
            minLines: 2,
            maxLines: 6,
            maxLength: 4000,
            decoration: InputDecoration(
              labelText: entry.$2,
              alignLabelWithHint: true,
            ),
            onChanged: (v) {
              if (entry.$3 == 'claim') {
                s.claim = v;
              } else if (entry.$3 == 'reasoning') {
                s.reasoning = v;
              } else {
                s.question = v;
              }
              s.dirty = true;
              s.changed();
            },
          ),
        ),
      Text(
        'Evidence attached: ${s.a == null ? 0 : 1} A capture, ${s.b == null ? 0 : 1} B capture, ${s.points.length} model points.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(
            key: const Key('research-save'),
            onPressed: () => s.save(),
            child: const Text('Save worksheet'),
          ),
          OutlinedButton(
            key: const Key('research-copy'),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      '${widget.title}\n${p.prompt}\nClaim: ${s.claim}\nReasoning: ${s.reasoning}\nNext question: ${s.question}\nCalculated-model evidence:\n${const JsonEncoder.withIndent('  ').convert(s.document())}',
                ),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Worksheet copied.')),
                );
              }
            },
            child: const Text('Copy summary'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      Text(
        s.dirty
            ? 'Unsaved worksheet changes'
            : 'Worksheet stored only when you choose Save',
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowClose || !s.dirty,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) requestClose();
    },
    child: DefaultTabController(
      length: 5,
      initialIndex: widget.initialPage,
      child: ListenableBuilder(
        listenable: changes,
        builder: (context, _) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 8, 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${widget.title} · 5 investigations',
                      maxLines: compact ? 1 : 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close lab-specific tools',
                    onPressed: requestClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Tune', height: 60),
                Tab(text: 'Compare', height: 60),
                Tab(text: 'Watch', height: 60),
                Tab(text: 'Plot', height: 60),
                Tab(text: 'Explain', height: 60),
              ],
            ),
            if (s.feedback.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  s.feedback,
                  maxLines: compact ? 1 : 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [setup(), comparison(), watch(), plot(), worksheet()],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Scatter only: deliberately no line connecting snapshots at differing times.
class ResearchScatter extends CustomPainter {
  final List<ResearchPoint> points;
  final String? inputLabel, outputLabel;
  ResearchScatter(this.points, {this.inputLabel, this.outputLabel});
  @override
  bool shouldRepaint(covariant ResearchScatter old) => true;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || size.width < 100 || size.height < 100) return;
    const ink = Color(0xff10214f), blue = Color(0xff1462ed);
    void text(String label, Offset at, {double width = 120}) {
      final painter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: ink, fontSize: 11),
        ),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: width);
      painter.paint(canvas, at);
    }

    final rect = Rect.fromLTRB(65, 16, size.width - 14, size.height - 60);
    double loX = points.map((p) => p.x).reduce(math.min),
        hiX = points.map((p) => p.x).reduce(math.max),
        loY = points.map((p) => p.y).reduce(math.min),
        hiY = points.map((p) => p.y).reduce(math.max);
    if (loX == hiX) {
      final pad = math.max(loX.abs() * .05, 1e-12);
      loX -= pad;
      hiX += pad;
    }
    if (loY == hiY) {
      final pad = math.max(loY.abs() * .05, 1e-12);
      loY -= pad;
      hiY += pad;
    }
    canvas.drawLine(rect.bottomLeft, rect.bottomRight, Paint()..color = ink);
    canvas.drawLine(rect.bottomLeft, rect.topLeft, Paint()..color = ink);
    text(LabResearchSession.show(hiY), Offset(0, rect.top), width: 60);
    text(LabResearchSession.show(loY), Offset(0, rect.bottom - 14), width: 60);
    text(LabResearchSession.show(loX), Offset(rect.left, rect.bottom + 7));
    text(
      LabResearchSession.show(hiX),
      Offset(math.max(rect.left, rect.right - 75), rect.bottom + 7),
      width: 78,
    );
    text(
      '${inputLabel ?? points.first.input} (${points.first.inputUnit}) → ${outputLabel ?? points.first.output} (${points.first.outputUnit})',
      Offset(8, size.height - 30),
      width: size.width - 16,
    );
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final centre = Offset(
        rect.left + (p.x - loX) / (hiX - loX) * rect.width,
        rect.bottom - (p.y - loY) / (hiY - loY) * rect.height,
      );
      canvas.drawCircle(centre, 4, Paint()..color = blue);
      text('${i + 1}', centre + const Offset(5, -15), width: 26);
    }
  }
}
