import 'dart:convert';

import 'package:flutter/material.dart';

import '../../content/catalog.dart';
import '../../content/studio_evidence_routes.dart';
import '../../core/persistence/notebook.dart';
import '../../core/design_system/reading_presentation.dart';

class StudioEvidenceSession extends ChangeNotifier {
  static const version = 'studio-evidence-1.0';
  final StudioEvidenceRoute route;
  final LocalNotebook store;
  int goal = 0;
  int? plan;
  String? aId, bId;
  String claim = '', reason = '', feedback = '';
  String? retained;
  late String saved;
  bool saving = false, disposed = false;
  void changed() {
    if (!disposed) notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }

  StudioEvidenceSession(this.route, this.store) {
    final raw = store.preferences.getString('studio-evidence:${route.studio}');
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map;
        if (data['version'] != version ||
            data['studio'] != route.studio ||
            data['goal'] is! int ||
            data['goal'] < 0 ||
            data['goal'] >= route.goals.length ||
            (data['plan'] != null &&
                (data['plan'] is! int ||
                    data['plan'] < 0 ||
                    data['plan'] >= route.answers.length)) ||
            (data['a'] != null && data['a'] is! String) ||
            (data['b'] != null && data['b'] is! String) ||
            (data['a'] != null && data['a'] == data['b']) ||
            data['claim'] is! String ||
            data['reason'] is! String ||
            (data['claim'] as String).characters.length > 4000 ||
            (data['reason'] as String).characters.length > 4000) {
          throw const FormatException();
        }
        goal = data['goal'];
        plan = data['plan'];
        aId = data['a'];
        bId = data['b'];
        claim = data['claim'];
        reason = data['reason'];
      } catch (_) {
        retained = raw;
        feedback = 'Stored investigation could not be loaded. Its original text is retained; an explicit save backs it up first.';
      }
    }
    saved = jsonEncode(document());
  }
  Map<String, dynamic> document() => {
    'version': version,
    'studio': route.studio,
    'goal': goal,
    'plan': plan,
    'a': aId,
    'b': bId,
    'claim': claim,
    'reason': reason,
  };
  bool get dirty => jsonEncode(document()) != saved;
  List<Trial> get bank {
    final seen = <String>{};
    return store.trials.reversed
        .where(
          (t) =>
              t.value.isFinite &&
              allEntries.any(
                (e) =>
                    e.id == t.labId &&
                    studios[e.studioIndex].id == route.studio,
              ) &&
              seen.add(t.id),
        )
        .toList();
  }

  Trial? trial(String? id) => bank.where((t) => t.id == id).firstOrNull;
  Trial? get a => trial(aId);
  Trial? get b => trial(bId);
  void chooseGoal(int next) {
    if (next < 0 || next >= route.goals.length) return;
    goal = next;
    feedback = '';
    changed();
  }

  void choosePlan(int next) {
    if (next < 0 || next >= route.answers.length) return;
    plan = next;
    feedback = '';
    changed();
  }

  bool pick(bool second, String? id) {
    if (id != null && (trial(id) == null || id == (second ? aId : bId))) {
      return false;
    }
    if (second) {
      bId = id;
    } else {
      aId = id;
    }
    feedback = '';
    changed();
    return true;
  }

  void writeClaim(String value) {
    if (value.characters.length > 4000) return;
    claim = value;
    changed();
  }

  void writeReason(String value) {
    if (value.characters.length > 4000) return;
    reason = value;
    changed();
  }

  String get comparison {
    final first = a, second = b;
    if (first == null || second == null) {
      return 'Select two distinct recorded Trials. Missing or unavailable records are never replaced with sample data.';
    }
    final compatible =
        first.labId == second.labId &&
        first.model == second.model &&
        first.quantity == second.quantity &&
        first.unit == second.unit &&
        [
          'mode',
          'frame',
          'selectedPart',
        ].every((k) => first.configuration[k] == second.configuration[k]);
    if (!compatible) {
      return 'Different lab, model, quantity, unit, mode, frame or component: compare the evidence qualitatively. No numeric difference is calculated.';
    }
    final difference = second.value - first.value;
    if (!difference.isFinite) {
      return 'Difference exceeds the finite numeric range. The original readings remain available.';
    }
    return 'Recorded difference B − A = ${conciseNumber(difference, precision: 6)} ${first.unit}. Descriptive only: time, topology and inputs may differ; this is not proof of causation.';
  }

  Future<bool> save() async {
    if (saving) return false;
    saving = true;
    changed();
    final body = jsonEncode(document());
    try {
      final ok = await store.saveStudioInvestigation(
        route.studio,
        body,
        retained: retained,
      );
      if (ok) {
        saved = body;
        retained = null;
        feedback = dirty
            ? 'Snapshot saved; newer edits still need saving.'
            : 'Investigation saved on this device. Reopen it from this studio.';
      } else {
        feedback = 'Save failed. Existing stored content was retained.';
      }
      return ok;
    } catch (_) {
      feedback = 'Save failed. Existing stored content was retained.';
      return false;
    } finally {
      saving = false;
      changed();
    }
  }
}

class StudioEvidenceSheet extends StatefulWidget {
  final StudioEvidenceSession session;
  const StudioEvidenceSheet({super.key, required this.session});
  @override
  State<StudioEvidenceSheet> createState() => _StudioEvidenceSheetState();
}

class _StudioEvidenceSheetState extends State<StudioEvidenceSheet> {
  bool get compact =>
      MediaQuery.viewInsetsOf(context).bottom > 0 ||
      MediaQuery.textScalerOf(context).scale(1) > 1.5 ||
      MediaQuery.sizeOf(context).height -
              MediaQuery.viewInsetsOf(context).bottom <
          400;
  StudioEvidenceSession get s => widget.session;
  late final claim = TextEditingController(text: s.claim),
      reason = TextEditingController(text: s.reason);
  bool allowClose = false, closing = false;
  Future<void> leave([String? lab]) async {
    if (closing || s.saving) return;
    closing = true;
    try {
      FocusScope.of(context).unfocus();
      if (s.dirty) {
        final choice = await showDialog<int>(
          context: context,
          builder: (context) => AlertDialog(
            scrollable: true,
            title: const Text('Save this investigation?'),
            content: const Text(
              'Your plan, evidence choices or explanation have unsaved changes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Keep editing'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 0),
                child: const Text('Leave without saving'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 1),
                child: const Text('Save and continue'),
              ),
            ],
          ),
        );
        if (choice == null) return;
        if (choice == 1 && (!await s.save() || s.dirty)) return;
      }
      if (!mounted) return;
      setState(() => allowClose = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, lab);
      });
    } finally {
      if (!allowClose) closing = false;
    }
  }

  @override
  void dispose() {
    claim.dispose();
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([s, s.store]),
    builder: (context, _) => PopScope(
      canPop: allowClose || (!s.dirty && !s.saving),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      compact ? 'Investigation' : s.route.title,
                      maxLines: compact ? 1 : null,
                      overflow: compact ? TextOverflow.ellipsis : null,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Close studio investigation',
                  onPressed: s.saving ? null : () => leave(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                key: const Key('studio-evidence-scroll'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  const Text('Choose → plan → collect real evidence → explain'),
                  if (compact) Text(s.route.title),
                  Text(
                    '1. Choose an investigation goal',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (int i = 0; i < s.route.goals.length; i++)
                        ChoiceChip(
                          label: Text(s.route.goals[i].title),
                          selected: s.goal == i,
                          onSelected: (_) => s.chooseGoal(i),
                        ),
                    ],
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(s.route.goals[s.goal].task),
                          OutlinedButton.icon(
                            key: const Key('evidence-open-lab'),
                            onPressed: () => leave(s.route.goals[s.goal].lab),
                            icon: const Icon(Icons.science_outlined),
                            label: Text(
                              'Open ${entryById(s.route.goals[s.goal].lab).title}',
                            ),
                          ),
                          const Text(
                            'Record a Trial in the lab, then return with Back. New records appear here. Opening a lab applies no setup and awards no completion.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '2. Check the reasoning',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(s.route.question),
                  RadioGroup<int>(
                    groupValue: s.plan,
                    onChanged: (value) {
                      if (value != null) s.choosePlan(value);
                    },
                    child: Column(
                      children: [
                        for (int i = 0; i < s.route.answers.length; i++)
                          RadioListTile<int>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(s.route.answers[i]),
                            value: i,
                          ),
                      ],
                    ),
                  ),
                  if (s.plan != null)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        '${s.plan == s.route.correct ? 'That reasoning fits.' : 'Reconsider this choice.'} ${s.route.explanation}',
                        key: const Key('evidence-plan-feedback'),
                      ),
                    ),
                  Text(
                    '3. Attach recorded evidence',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    '${s.bank.length} recorded Trials in this studio. Only real notebook records are offered.',
                  ),
                  if (s.bank.isEmpty)
                    const Text(
                      'No recorded evidence yet. Use the lab above and its Record Trial action. A preview or worksheet is not a recorded Trial.',
                    ),
                  for (final second in [false, true]) ...[
                    DropdownButtonFormField<String>(
                      key: ValueKey(
                        'evidence-${second ? 'B' : 'A'}-${second ? s.bId : s.aId}',
                      ),
                      isExpanded: true,
                      itemHeight: null,
                      initialValue:
                          s.bank.any((t) => t.id == (second ? s.bId : s.aId))
                          ? (second ? s.bId : s.aId)
                          : null,
                      decoration: InputDecoration(
                        labelText: 'Evidence ${second ? 'B' : 'A'}',
                      ),
                      items: [
                        for (final t in s.bank)
                          DropdownMenuItem(
                            value: t.id,
                            enabled: t.id != (second ? s.aId : s.bId),
                            child: Text(
                              '${entryById(t.labId).title} · ${t.quantity} ${conciseNumber(t.value)} ${t.unit}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: s.bank.isEmpty
                          ? null
                          : (id) => s.pick(second, id),
                    ),
                    if ((second ? s.bId : s.aId) != null) ...[
                      evidenceCard(second ? s.b : s.a),
                      TextButton(
                        onPressed: () => s.pick(second, null),
                        child: Text('Clear evidence ${second ? 'B' : 'A'}'),
                      ),
                    ],
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      s.comparison,
                      key: const Key('evidence-comparison'),
                    ),
                  ),
                  Text(
                    '4. Explain the connection',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextField(
                    key: const Key('studio-evidence-claim'),
                    controller: claim,
                    onChanged: s.writeClaim,
                    maxLength: 4000,
                    minLines: 2,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'What does your evidence support?',
                    ),
                  ),
                  TextField(
                    key: const Key('studio-evidence-reason'),
                    controller: reason,
                    onChanged: s.writeReason,
                    maxLength: 4000,
                    minLines: 3,
                    maxLines: 7,
                    decoration: const InputDecoration(
                      labelText: 'Explain the physics, controls and next test',
                    ),
                  ),
                  FilledButton(
                    key: const Key('save-studio-evidence'),
                    onPressed: s.saving ? null : () => s.save(),
                    child: Text(s.saving ? 'Saving…' : 'Save investigation'),
                  ),
                  Text(s.dirty ? 'Unsaved changes' : 'No unsaved changes'),
                  if (s.feedback.isNotEmpty)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        s.feedback,
                        key: const Key('studio-evidence-status'),
                      ),
                    ),
                  const Text(
                    'Saved separately from lab notes, Trials and mastery. Trial links contain IDs only; deleting a source record makes that evidence unavailable.',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget evidenceCard(Trial? trial) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            trial == null
                ? 'This recorded Trial is no longer available.'
                : '${entryById(trial.labId).title}\n${trial.quantity}: ${conciseNumber(trial.value, precision: 6)} ${trial.unit}\nModel: ${trial.model}\nRecorded UTC: ${trial.created}\n${clock(trial.configuration)}',
          ),
          if (trial != null)
            ExpansionTile(
              title: const Text('Recorded settings'),
              children: [
                for (final input in settings(trial.configuration).entries)
                  Text('${input.key}: ${input.value}'),
                if (settings(trial.configuration).isEmpty)
                  const Text(
                    'No numeric input settings were stored in this record.',
                  ),
              ],
            ),
        ],
      ),
    ),
  );
  String clock(Map<String, dynamic> config) {
    for (final key in ['t', 'time', 'elapsed', 'ticks']) {
      final value = config[key];
      if (value is num && value.isFinite) {
        return 'Saved model clock: $key = $value';
      }
    }
    return 'No model clock included in this record.';
  }

  Map<String, Object> settings(Map<String, dynamic> config) {
    final result = <String, Object>{};
    final parameters = config['parameters'];
    if (parameters is Map) {
      for (final entry in parameters.entries) {
        final value = entry.value;
        if (entry.key is String &&
            (value is bool || (value is num && value.isFinite))) {
          result[entry.key as String] = value as Object;
        }
      }
    }
    for (final key in [
      'mode',
      'frame',
      'selectedPart',
      'a',
      'b',
      'zero',
      'resolution',
      'distance',
      'v0',
      'acceleration',
    ]) {
      final value = config[key];
      if (value is bool ||
          (value is num && value.isFinite) ||
          (key == 'selectedPart' && value is String)) {
        result[key] = value as Object;
      }
    }
    return result;
  }
}
