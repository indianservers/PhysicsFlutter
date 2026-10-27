import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../content/catalog.dart';
import '../../content/studio_investigations.dart';
import '../../core/design_system/reading_presentation.dart';
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import 'instrument_types.dart';

class ExplorationCapture {
  final Map<String, double> inputs;
  final Map<String, String> units;
  final List<InstrumentReading> readings;
  final String context;
  final double? time;
  ExplorationCapture(
    this.inputs,
    this.units,
    this.readings,
    this.context,
    this.time,
  );
  InstrumentReading? reading(String key) =>
      readings.where((r) => r.label == key).firstOrNull;
  Map<String, dynamic> toJson() => {
    'inputs': inputs,
    'inputUnits': units,
    'context': context,
    'modelTime': time,
    'calculatedReadings': [
      for (final r in readings)
        {'quantity': r.label, 'value': r.value, 'unit': r.unit},
    ],
  };
}

/// No persistence, notes, trial insertion or mastery mutation. History contains
/// full private source configurations only in memory for exact setup replay.
class ExplorationController extends ChangeNotifier {
  final List<InstrumentControl> Function() controls;
  final List<InstrumentReading> Function() readings;
  final Map<String, dynamic> Function() configuration;
  final bool Function(Map<String, dynamic>) restore;
  final bool Function() valid;
  final VoidCallback pause;
  late Map<String, dynamic> baseline;
  late Map<String, double> baselineInputs;
  late Map<String, String> baselineUnits;
  final List<Map<String, dynamic>> _past = [], _future = [];
  ExplorationCapture? a, b;
  String feedback = '';
  bool disposed = false;
  ExplorationController({
    required this.controls,
    required this.readings,
    required this.configuration,
    required this.restore,
    required this.valid,
    required this.pause,
  }) {
    _baseline();
  }
  static Map<String, dynamic> clone(Map<String, dynamic> value) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(value)));
  void changed() {
    if (!disposed) notifyListeners();
  }

  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  InstrumentControl? control(String key) =>
      controls().where((c) => c.keyName == key).firstOrNull;
  void _baseline() {
    baseline = clone(configuration());
    baselineInputs = {for (final c in controls()) c.keyName: c.value};
    baselineUnits = {for (final c in controls()) c.keyName: c.unit};
  }

  void replaceBaseline() {
    pause();
    _baseline();
    feedback =
        'Temporary setup reference replaced. No observation was recorded.';
    changed();
  }

  List<String> get changedKeys => controls()
      .where(
        (c) =>
            !baselineInputs.containsKey(c.keyName) ||
            baselineUnits[c.keyName] != c.unit ||
            baselineInputs[c.keyName] != c.value,
      )
      .map((c) => c.keyName)
      .toList();
  List<String> problems(Map<String, double> values) => [
    for (final e in values.entries)
      if (control(e.key) == null)
        '${e.key}: unavailable in the current model options'
      else if (!e.value.isFinite ||
          e.value < control(e.key)!.min ||
          e.value > control(e.key)!.max)
        '${control(e.key)!.label}: outside the current bounds',
  ];
  void _remember(Map<String, dynamic> state) {
    _past.add(state);
    if (_past.length > 20) _past.removeAt(0);
    _future.clear();
  }

  bool apply(Map<String, double> values) {
    pause();
    final errors = problems(values);
    if (values.isEmpty || errors.isNotEmpty) {
      feedback = errors.isEmpty
          ? 'No setup changes selected.'
          : 'Setup not applied. ${errors.join('; ')}.';
      changed();
      return false;
    }
    final before = clone(configuration());
    try {
      for (final e in values.entries) {
        final c = control(e.key);
        if (c == null ||
            !e.value.isFinite ||
            e.value < c.min ||
            e.value > c.max) {
          throw StateError('Changed bounds');
        }
        c.change(e.value);
      }
      _remember(before);
      feedback = 'Setup applied through the experiment controls. Check the live values; Undo is available.';
      changed();
      return true;
    } catch (_) {
      final restored = restore(before);
      feedback = restored
          ? 'Setup could not be applied; the prior configuration was restored.'
          : 'Setup failed and automatic restoration was unavailable. Inspect the experiment before continuing.';
      changed();
      return false;
    }
  }

  bool nudge(String key, double fraction, int direction) {
    final c = control(key);
    if (c == null ||
        !fraction.isFinite ||
        fraction <= 0 ||
        ![-1, 1].contains(direction)) {
      return false;
    }
    final next = (c.value + direction * (c.max - c.min) * fraction)
        .clamp(c.min, c.max)
        .toDouble();
    if (next == c.value) return false;
    return apply({key: next});
  }

  bool _replay(List<Map<String, dynamic>> from, List<Map<String, dynamic>> to) {
    if (from.isEmpty) return false;
    pause();
    final now = clone(configuration());
    if (!restore(clone(from.last))) {
      feedback = 'This configuration cannot be restored; history is retained.';
      changed();
      return false;
    }
    from.removeLast();
    to.add(now);
    feedback = 'Experiment configuration restored. Recorded trials are kept.';
    changed();
    return true;
  }

  bool undo() => _replay(_past, _future);
  bool redo() => _replay(_future, _past);
  bool restoreBaseline() {
    pause();
    final before = clone(configuration());
    final ok = restore(clone(baseline));
    if (ok) _remember(before);
    feedback = ok
        ? 'Opening/reference setup restored. Undo is available.'
        : 'The reference setup could not be restored.';
    changed();
    return ok;
  }

  ExplorationCapture? capture() {
    pause();
    final rs = readings()
        .where((r) => double.tryParse(r.value)?.isFinite ?? false)
        .toList();
    if (!valid() || rs.isEmpty) {
      feedback = 'Evidence not ready. Finish the apparatus procedure or resolve the model notice first.';
      changed();
      return null;
    }
    final config = configuration();
    final time =
        (config['time'] as num?)?.toDouble() ??
        double.tryParse(
          rs
                  .where((r) => r.label == 't' || r.label == 'elapsed')
                  .firstOrNull
                  ?.value ??
              '',
        );
    return ExplorationCapture(
      Map.unmodifiable({for (final c in controls()) c.keyName: c.value}),
      Map.unmodifiable({for (final c in controls()) c.keyName: c.unit}),
      List.unmodifiable(rs),
      jsonEncode({
        for (final k in [
          'model',
          'kind',
          'mode',
          'frame',
          'dataset',
          'epoch',
          'selectedPart',
          'materialId',
          'planet',
          'nuclide',
          'sensor',
        ])
          if (config[k] is String || config[k] is num || config[k] is bool)
            k: config[k],
      }),
      time,
    );
  }

  bool captureState(bool second) {
    final snap = capture();
    if (snap == null) return false;
    if (second) {
      b = snap;
    } else {
      a = snap;
    }
    feedback =
        '${second ? 'B' : 'A'} captured from the paused calculated state. Evidence stays available during this lab visit.';
    changed();
    return true;
  }

  List<String> get comparisonChanges {
    if (a == null || b == null) return [];
    return {...a!.inputs.keys, ...b!.inputs.keys}
        .where(
          (k) => a!.inputs[k] != b!.inputs[k] || a!.units[k] != b!.units[k],
        )
        .toList();
  }

  bool get matchedContext =>
      a != null && b != null && a!.context == b!.context && a!.time == b!.time;
  double? secant(String output) {
    if (!matchedContext || comparisonChanges.length != 1) return null;
    final key = comparisonChanges.single;
    final x = a!.inputs[key],
        nx = b!.inputs[key],
        r = a!.reading(output),
        nr = b!.reading(output);
    if (x == null ||
        nx == null ||
        nx == x ||
        a!.units[key] != b!.units[key] ||
        r == null ||
        nr == null ||
        r.unit != nr.unit) {
      return null;
    }
    final y = double.tryParse(r.value), ny = double.tryParse(nr.value);
    // Numeric category codes are labels, not quantities with a meaningful slope.
    if (r.unit.isEmpty &&
        const {
          'region',
          'regime',
          'phase',
          'imageType',
          'tir',
          'bound',
          'collision',
          'infinity',
          'emitting',
        }.contains(output)) {
      return null;
    }
    if (y == null || ny == null) return null;
    final slope = (ny - y) / (nx - x);
    return slope.isFinite ? slope : null;
  }

  Map<String, dynamic> sharedEvidence(String labId) => {
    'format': 'exploration-evidence-1.0',
    'labId': labId,
    'currentInputs': [
      for (final c in controls())
        {'key': c.keyName, 'label': c.label, 'value': c.value, 'unit': c.unit},
    ],
    'calculatedReadings': [
      for (final r in readings())
        {'key': r.label, 'value': r.value, 'unit': r.unit},
    ],
    'A': a?.toJson(),
    'B': b?.toJson(),
  };
  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

Future<void> showStudioTools(BuildContext context, int studio) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * .88,
          child: StudioToolCatalog(
            studio: studio,
            onOpen: (tool) {
              Navigator.pop(sheet);
              final uri = Uri(
                path: '/lab/${tool.labId}',
                queryParameters: {'studioTool': tool.id},
              );
              context.push(uri.toString());
            },
          ),
        ),
      ),
    );

class StudioToolCatalog extends StatefulWidget {
  final int studio;
  final ValueChanged<StudioInvestigation> onOpen;
  const StudioToolCatalog({
    super.key,
    required this.studio,
    required this.onOpen,
  });
  @override
  State<StudioToolCatalog> createState() => _StudioToolCatalogState();
}

class _StudioToolCatalogState extends State<StudioToolCatalog> {
  String query = '';
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final all = studioInvestigations
        .where((v) => v.studio == widget.studio)
        .toList();
    final shown = all
        .where(
          (v) => '${v.title} ${entryById(v.labId).title} ${v.why}'
              .toLowerCase()
              .contains(query.trim().toLowerCase()),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '10 studio tools',
                  style: Theme.of(context).textTheme.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Close studio tools',
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            key: const Key('studio-tool-search'),
            controller: search,
            decoration: InputDecoration(
              labelText: 'Find a tool or lab',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear tool search',
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        search.clear();
                        setState(() => query = '');
                      },
                    ),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
          child: Text('${shown.length} of 10 tools'),
        ),
        Expanded(
          child: ListView.builder(
            key: const Key('studio-tool-list'),
            padding: const EdgeInsets.all(16),
            itemCount: shown.length,
            itemBuilder: (context, i) {
              final v = shown[i];
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        entryById(v.labId).title,
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        v.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(v.why),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        key: Key('studio-tool-${v.id}'),
                        onPressed: () => widget.onOpen(v),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Open investigation'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ExplorationWorkbench extends StatefulWidget {
  final String id, title;
  final ExplorationController controller;
  final Listenable sourceChanges;
  final String Function() notice;
  final String Function()? limits;
  final Widget Function()? selection;
  final StudioInvestigation? tool;
  final List<String> focus;
  final VoidCallback? onWorksheet;
  final bool Function()? playing, dynamicModel;
  final VoidCallback? play, pause, step;
  const ExplorationWorkbench({
    super.key,
    required this.id,
    required this.title,
    required this.controller,
    required this.sourceChanges,
    required this.notice,
    this.limits,
    this.selection,
    this.tool,
    this.focus = const [],
    this.onWorksheet,
    this.playing,
    this.dynamicModel,
    this.play,
    this.pause,
    this.step,
  });
  @override
  State<ExplorationWorkbench> createState() => _ExplorationWorkbenchState();
}

class _ExplorationWorkbenchState extends State<ExplorationWorkbench> {
  ExplorationController get c => widget.controller;
  final controlSearch = TextEditingController(),
      readingSearch = TextEditingController();
  final pinned = <String>{};
  String controlQuery = '', readingQuery = '';
  double fraction = .001;
  bool focusOnly = false;
  bool previewOpen = false;
  List<String> get focus => widget.tool?.watch ?? widget.focus;
  String number(double x) => conciseNumber(x, precision: 6);
  String label(String key) =>
      c.control(key)?.label ?? presentReading(key, '0', '').label;
  String shown(InstrumentReading r) {
    if (double.tryParse(r.value)?.isNaN ?? false) {
      return 'Not defined in this state';
    }
    final p = presentReading(r.label, r.value, r.unit);
    return '${p.value} ${p.unit}';
  }

  @override
  void dispose() {
    controlSearch.dispose();
    readingSearch.dispose();
    super.dispose();
  }

  Widget heading(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(description),
      ],
    ),
  );
  Widget status() => ExpansionTile(
    title: Text(c.valid() ? 'Calculated state ready' : 'Evidence not ready'),
    leading: Icon(c.valid() ? Icons.check_circle_outline : Icons.info_outline),
    initiallyExpanded: !c.valid(),
    children: [
      Padding(padding: const EdgeInsets.all(12), child: Text(widget.notice())),
    ],
  );
  Widget playback() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (widget.dynamicModel?.call() ?? false)
        OutlinedButton.icon(
          key: const Key('exploration-run'),
          onPressed: (widget.playing?.call() ?? false)
              ? widget.pause
              : widget.play,
          icon: Icon(
            (widget.playing?.call() ?? false) ? Icons.pause : Icons.play_arrow,
          ),
          label: Text(
            (widget.playing?.call() ?? false)
                ? 'Pause experiment'
                : 'Run experiment',
          ),
        ),
      if (widget.step != null)
        OutlinedButton(
          key: const Key('exploration-step'),
          onPressed: widget.step,
          child: const Text('Step experiment'),
        ),
    ],
  );
  Widget search(
    TextEditingController controller,
    String name,
    String value,
    ValueChanged<String> change,
  ) => TextField(
    key: ValueKey(name),
    controller: controller,
    decoration: InputDecoration(
      labelText: name,
      prefixIcon: const Icon(Icons.search),
      suffixIcon: value.isEmpty
          ? null
          : IconButton(
              tooltip: 'Clear $name',
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                change('');
              },
            ),
    ),
    onChanged: change,
  );
  Widget history() => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      OutlinedButton.icon(
        key: const Key('exploration-undo'),
        onPressed: c.canUndo ? c.undo : null,
        icon: const Icon(Icons.undo),
        label: const Text('Undo setup'),
      ),
      OutlinedButton.icon(
        key: const Key('exploration-redo'),
        onPressed: c.canRedo ? c.redo : null,
        icon: const Icon(Icons.redo),
        label: const Text('Redo setup'),
      ),
    ],
  );
  Widget preset(String name, Map<String, double> values) {
    final errors = c.problems(values);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Setup $name', style: Theme.of(context).textTheme.titleMedium),
            for (final e in values.entries)
              Text(
                '${label(e.key)}: ${number(e.value)} ${c.control(e.key)?.unit ?? ''}',
              ),
            if (errors.isNotEmpty) Text(errors.join('\n')),
            const SizedBox(height: 8),
            FilledButton(
              key: Key('exploration-apply-${name.toLowerCase()}'),
              onPressed: errors.isEmpty ? () => c.apply(values) : null,
              child: Text('Apply setup $name'),
            ),
          ],
        ),
      ),
    );
  }

  Widget input(InstrumentControl input) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(input.label, style: Theme.of(context).textTheme.titleSmall),
          SelectableText('${number(input.value)} ${input.unit}'),
          Text(
            'Range ${number(input.min)} to ${number(input.max)} ${input.unit}',
          ),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              IconButton(
                key: Key('exploration-decrease-${input.keyName}'),
                tooltip: 'Decrease ${input.label}',
                onPressed: input.value > input.min
                    ? () => c.nudge(input.keyName, fraction, -1)
                    : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              OutlinedButton.icon(
                key: Key('exploration-edit-${input.keyName}'),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => NumericInputDialog(
                    label:
                        '${input.label} (${displayScale(input.value, input.unit).unit})',
                    initial:
                        input.value /
                        displayScale(input.value, input.unit).factor,
                    min:
                        input.min /
                        displayScale(input.value, input.unit).factor,
                    max:
                        input.max /
                        displayScale(input.value, input.unit).factor,
                    onApply: (v) => c.apply({
                      input.keyName:
                          (v * displayScale(input.value, input.unit).factor)
                              .clamp(input.min, input.max)
                              .toDouble(),
                    }),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Enter value'),
              ),
              IconButton(
                key: Key('exploration-increase-${input.keyName}'),
                tooltip: 'Increase ${input.label}',
                onPressed: input.value < input.max
                    ? () => c.nudge(input.keyName, fraction, 1)
                    : null,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          Text(
            'Requested step ${number((input.max - input.min) * fraction)} ${input.unit}; discrete controls use their own rounding.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    ),
  );
  Widget controls() {
    final all = c.controls();
    final found = all
        .where(
          (v) => '${v.label} ${v.keyName} ${v.unit}'.toLowerCase().contains(
            controlQuery.trim().toLowerCase(),
          ),
        )
        .toList();
    return ListView(
      key: const Key('exploration-controls-scroll'),
      padding: const EdgeInsets.all(20),
      children: [
        search(
          controlSearch,
          'Search controls',
          controlQuery,
          (v) => setState(() => controlQuery = v),
        ),
        Text('${found.length} of ${all.length} current inputs'),
        const SizedBox(height: 16),
        heading(
          widget.tool?.title ?? 'Explore your experiment',
          'Setup changes stay in the lab when you close. Undo or restore the reference before closing if you want the prior setup.',
        ),
        playback(),
        if (widget.selection != null)
          ExpansionTile(
            title: const Text('Model options'),
            children: [widget.selection!()],
          ),
        if (widget.tool != null)
          ExpansionTile(
            key: const Key('exploration-setup-preview'),
            initiallyExpanded: previewOpen,
            onExpansionChanged: (value) => setState(() => previewOpen = value),
            title: const Text('Preview studio setups'),
            children: [
              preset('A', widget.tool!.a),
              preset('B', widget.tool!.b),
            ],
          ),
        history(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 6,
          children: [
            for (final f in [.0001, .001, .01])
              ChoiceChip(
                label: Text('${number(f * 100)}% range step'),
                selected: fraction == f,
                onSelected: (_) => setState(() => fraction = f),
              ),
          ],
        ),
        for (final v in found) input(v),
        if (found.isEmpty)
          const Text(
            'No inputs match. Clear the search or select the corresponding model options.',
          ),
      ],
    );
  }

  Widget readings() {
    final all = c.readings();
    final found =
        all
            .where(
              (r) =>
                  (!focusOnly || focus.contains(r.label)) &&
                  '${label(r.label)} ${r.label} ${r.unit}'
                      .toLowerCase()
                      .contains(readingQuery.trim().toLowerCase()),
            )
            .toList()
          ..sort((a, b) {
            final order =
                (pinned.contains(b.label) ? 1 : 0) -
                (pinned.contains(a.label) ? 1 : 0);
            return order == 0
                ? all.indexOf(a).compareTo(all.indexOf(b))
                : order;
          });
    return ListView(
      key: const Key('exploration-readings-scroll'),
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          'Focus on useful readings',
          'Live calculated values use the experiment’s current settings. Pin important quantities to the top; pinning is temporary.',
        ),
        status(),
        playback(),
        search(
          readingSearch,
          'Search readings',
          readingQuery,
          (v) => setState(() => readingQuery = v),
        ),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('Investigation focus'),
              selected: focusOnly,
              onSelected: focus.isEmpty
                  ? null
                  : (v) => setState(() => focusOnly = v),
            ),
            Text('${found.length} of ${all.length} readings'),
          ],
        ),
        for (final r in found)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(label(r.label)),
            subtitle: SelectableText(shown(r)),
            trailing: IconButton(
              key: Key('exploration-pin-${r.label}'),
              tooltip:
                  '${pinned.contains(r.label) ? 'Unpin' : 'Pin'} ${label(r.label)}',
              icon: Icon(
                pinned.contains(r.label)
                    ? Icons.push_pin
                    : Icons.push_pin_outlined,
              ),
              onPressed: () => setState(() {
                if (!pinned.add(r.label)) pinned.remove(r.label);
              }),
            ),
          ),
        if (found.isEmpty)
          const Text(
            'No matching quantity is available in this state. Try all readings or finish the apparatus procedure.',
          ),
      ],
    );
  }

  Widget compare() {
    final keys = c.comparisonChanges;
    final outputs = c.a == null || c.b == null
        ? <InstrumentReading>[]
        : c.a!.readings
              .where(
                (r) =>
                    c.b!.reading(r.label)?.unit == r.unit &&
                    (!focusOnly || focus.contains(r.label)),
              )
              .toList();
    return ListView(
      key: const Key('exploration-compare-scroll'),
      padding: const EdgeInsets.all(20),
      children: [
        heading(
          'Compare controlled states',
          'Apply a setup, complete the apparatus procedure or run to a chosen model time, then pause and capture. Repeat for B. These captures are temporary calculated evidence.',
        ),
        status(),
        playback(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              key: const Key('exploration-capture-a'),
              onPressed: c.valid() ? () => c.captureState(false) : null,
              child: const Text('Capture A'),
            ),
            FilledButton(
              key: const Key('exploration-capture-b'),
              onPressed: c.valid() ? () => c.captureState(true) : null,
              child: const Text('Capture B'),
            ),
          ],
        ),
        Text(
          'A: ${c.a == null ? 'not captured' : 'captured'} · B: ${c.b == null ? 'not captured' : 'captured'}',
        ),
        if (c.a != null && c.b != null) ...[
          const SizedBox(height: 16),
          Text(
            c.matchedContext ? 'Model context and available model time match.' : 'Model options or available model time differ. A single-variable sensitivity is not shown.',
          ),
          Text('${keys.length} changed visible inputs'),
          for (final key in keys)
            Text(
              '${label(key)}: ${c.a!.inputs[key]} ${c.a!.units[key] ?? ''} → ${c.b!.inputs[key]} ${c.b!.units[key] ?? ''}',
            ),
          if (keys.length != 1)
            const Text(
              'For a secant sensitivity, vary exactly one visible input and keep the other conditions fixed.',
            ),
          for (final r in outputs)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(label(r.label)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('A ${shown(r)} → B ${shown(c.b!.reading(r.label)!)}'),
                  if (c.secant(r.label) != null)
                    Text(
                      'Captured secant: ${number(c.secant(r.label)!)} (${r.unit.isEmpty ? 'dimensionless' : r.unit}) / (${c.a!.units[keys.single]!.isEmpty ? 'dimensionless' : c.a!.units[keys.single]})',
                      key: ValueKey('exploration-secant-${r.label}'),
                    ),
                ],
              ),
            ),
          const Text(
            'A secant describes these two captured states. Check unlisted model options before interpreting it as causal sensitivity; it is not a fitted curve.',
          ),
          TextButton(
            onPressed: () {
              c.a = null;
              c.b = null;
              c.feedback = 'Temporary A/B captures cleared.';
              c.changed();
            },
            child: const Text('Clear captured comparison'),
          ),
        ],
      ],
    );
  }

  Widget guide() => ListView(
    key: const Key('exploration-guide-scroll'),
    padding: const EdgeInsets.all(20),
    children: [
      heading(
        'Reference, method and evidence',
        widget.tool?.prompt ?? 'Change one input, keep other conditions fixed, and explain the calculated response using the model’s assumptions.',
      ),
      if (widget.tool != null)
        for (final step in widget.tool!.method.asMap().entries)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text('${step.key + 1}'),
            title: Text(step.value),
          ),
      Text(
        '${c.changedKeys.length} visible inputs differ from the temporary opening/reference setup.',
      ),
      for (final key in c.changedKeys)
        Text(
          '${label(key)}: ${c.baselineInputs[key] ?? 'not present'} ${c.baselineUnits[key] ?? ''} → ${c.control(key)!.value} ${c.control(key)!.unit}',
        ),
      for (final key in c.baselineInputs.keys.where(
        (key) => c.control(key) == null,
      ))
        Text('${label(key)}: not available in the current model options'),
      const Text(
        'The reference contains the complete setup, including model options. It is not a recorded observation.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton(
            key: const Key('exploration-restore-reference'),
            onPressed: c.restoreBaseline,
            child: const Text('Restore reference setup'),
          ),
          OutlinedButton(
            key: const Key('exploration-new-reference'),
            onPressed: c.replaceBaseline,
            child: const Text('Use current setup as reference'),
          ),
        ],
      ),
      history(),
      if (widget.limits != null)
        ExpansionTile(
          title: const Text('Model assumptions and limits'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(widget.limits!()),
            ),
          ],
        ),
      OutlinedButton.icon(
        key: const Key('exploration-copy'),
        onPressed: () async {
          final payload = {
            'title': widget.title,
            'investigation': widget.tool?.title,
            'question': widget.tool?.prompt,
            ...c.sharedEvidence(widget.id),
          };
          await Clipboard.setData(
            ClipboardData(
              text: const JsonEncoder.withIndent('  ').convert(payload),
            ),
          );
          if (mounted) {
            c.feedback = 'Selected setup and calculated evidence copied. Existing notes and notebook history were excluded.';
            c.changed();
          }
        },
        icon: const Icon(Icons.copy_outlined),
        label: const Text('Copy setup and evidence'),
      ),
      if (widget.onWorksheet != null)
        OutlinedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            widget.onWorksheet!();
          },
          icon: const Icon(Icons.edit_note),
          label: const Text('Open saved explanation worksheet'),
        ),
      const Text(
        'Captures remain available when you close and reopen this workbench during the current lab visit. You can return to the apparatus to finish a procedure. Use Record Trial or the explanation worksheet to keep work for later.',
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 4,
    child: ListenableBuilder(
      listenable: Listenable.merge([c, widget.sourceChanges]),
      builder: (context, _) => LayoutBuilder(
        builder: (context, bounds) => Column(
          children: [
            if (bounds.maxHeight >= 240)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close exploration workbench',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            if (bounds.maxHeight >= 240)
              const TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                tabs: [
                  Tab(text: 'Controls'),
                  Tab(text: 'Readings'),
                  Tab(text: 'Compare'),
                  Tab(text: 'Guide'),
                ],
              ),
            if (bounds.maxHeight < 240)
              Row(
                children: [
                  const Expanded(
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      tabs: [
                        Tab(text: 'Controls'),
                        Tab(text: 'Readings'),
                        Tab(text: 'Compare'),
                        Tab(text: 'Guide'),
                      ],
                    ),
                  ),
                  if (c.feedback.isNotEmpty)
                    IconButton(
                      tooltip: 'Read experiment notice',
                      icon: const Icon(Icons.info_outline),
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => AlertDialog(
                          scrollable: true,
                          title: const Text('Experiment notice'),
                          content: Text(c.feedback),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Close exploration workbench',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            if (c.feedback.isNotEmpty && bounds.maxHeight >= 240)
              Semantics(
                liveRegion: true,
                child: TextButton(
                  key: const Key('exploration-feedback'),
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      scrollable: true,
                      title: const Text('Experiment notice'),
                      content: Text(c.feedback),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ),
                  child: Text(
                    c.feedback,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            Expanded(
              child: TabBarView(
                children: [controls(), readings(), compare(), guide()],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
