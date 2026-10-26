import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/theme.dart';
import '../../core/design_system/reading_presentation.dart';
import '../../core/design_system/reference_style.dart';
import '../../content/catalog.dart';
import '../../core/persistence/notebook.dart';
import '../lab_workspace/workspace.dart' show NumericInputDialog;
import '../advanced/scene.dart' show LabPlot;

/// Layout and camera state only. Scientific state stays in the owning workspace.
class InstrumentControl {
  final String keyName, label, unit;
  final double value, min, max;
  final ValueChanged<double> change;
  const InstrumentControl(
    this.keyName,
    this.label,
    this.unit,
    this.value,
    this.min,
    this.max,
    this.change,
  );
}

class InstrumentReading {
  final String label, value, unit;
  const InstrumentReading(this.label, this.value, [this.unit = '']);
}

enum WorkspacePane {
  scene,
  sceneGraph,
  sceneData,
  graph,
  fullscreen,
  fullscreenGraph,
}

const paneNames = [
  'Scene',
  'Scene + Graph',
  'Scene + Data',
  'Graph focus',
  'Full-screen Scene',
  'Full-screen Graph',
];

/// Reuses the apparatus transform while contextual tools supply camera gestures.
/// Applies an existing apparatus transform without claiming its drag gestures.
/// The shared explicit camera mode supplies all pan/pinch recognition.
class ApparatusTransform extends StatelessWidget {
  final TransformationController transformationController;
  final Widget child;
  final double minScale, maxScale;
  const ApparatusTransform({
    super.key,
    required this.transformationController,
    required this.child,
    this.minScale = 1,
    this.maxScale = 5,
  });
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Matrix4>(
    valueListenable: transformationController,
    builder: (context, matrix, _) => Transform(transform: matrix, child: child),
  );
}

class LabBackButton extends StatelessWidget {
  final String studioId;
  final VoidCallback? onBack;
  const LabBackButton(this.studioId, {super.key, this.onBack});
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    icon: const Icon(Icons.chevron_left),
    onPressed:
        onBack ??
        () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/studio/$studioId');
          }
        },
  );
}

class LabSectionMenu extends StatelessWidget {
  final int section;
  final ValueChanged<int> select;
  final VoidCallback? controls, save, camera, guide;
  final String? labId;
  final LocalNotebook? notebook;
  final bool showSections;
  const LabSectionMenu({
    super.key,
    required this.section,
    required this.select,
    this.controls,
    this.save,
    this.camera,
    this.guide,
    this.labId,
    this.notebook,
    this.showSections = true,
  });
  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    tooltip: 'Lab options',
    icon: const Icon(Icons.more_vert),
    onSelected: (value) async {
      if (value == 8 && notebook != null && labId != null) {
        await notebook!.toggleFavorite(labId!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                notebook!.favorites.contains(labId)
                    ? 'Lab saved to your collection'
                    : 'Lab removed from your collection',
              ),
            ),
          );
        }
      } else if (value == 9 && labId != null) {
        context.push('/studio/${labId!.split('-').first}');
      } else if (value == 10) {
        guide?.call();
      } else if (value == 7) {
        camera?.call();
      } else if (value == 5) {
        controls?.call();
      } else if (value == 6) {
        save?.call();
      } else {
        select(value);
      }
    },
    itemBuilder: (_) => [
      if (camera != null)
        const PopupMenuItem(value: 7, child: Text('Camera tools')),
      if (controls != null)
        const PopupMenuItem(value: 5, child: Text('Controls & investigation')),
      if (showSections)
        for (final pair in const [
          (1, 'Experiment'),
          (0, 'Learn'),
          (3, 'Formulas'),
          (2, 'Visualize'),
          (4, 'Results'),
        ])
          PopupMenuItem(value: pair.$1, child: Text(pair.$2)),
      if (guide != null)
        const PopupMenuItem(value: 10, child: Text('Guided investigation')),
      if (notebook != null &&
          allEntries.any((e) => e.id == labId && e.interactive))
        PopupMenuItem(
          value: 8,
          child: Text(
            notebook!.favorites.contains(labId)
                ? 'Remove from saved labs'
                : 'Save to your collection',
          ),
        ),
      if (labId != null)
        const PopupMenuItem(value: 9, child: Text('Explore this studio')),
      if (save != null)
        const PopupMenuItem(value: 6, child: Text('Save session')),
    ],
  );
}

class InstrumentShell extends StatefulWidget {
  final String id, title;
  final CustomPainter Function()? referenceChart;
  final List<Widget> toolbarActions;
  final Widget Function()? parameterDock;
  final double? dockExtent;
  final bool fitScene;
  final bool Function(Trial)? reopenTrial;
  final Future<void> Function(List<Trial>)? exportRecorded;
  final bool showLabSections;
  final String recordLabel;
  final String? highlightControl;
  final Widget Function()? data;
  final int Function()? guidedStep;
  final ValueChanged<int>? changeGuidedStep;
  final List<String> Function()? guideInstructions;
  final bool Function(int)? canAdvanceGuide;
  final LocalNotebook store;
  final Listenable changes;
  final Widget Function() scene, graph;
  final List<InstrumentControl> Function() controls;
  final List<InstrumentReading> Function() readings;
  final List<Widget> Function() advanced, results;
  final String Function() notice;
  final bool Function() playing, dynamicModel, canRecord;
  final VoidCallback play, pause, reset, save;
  final VoidCallback? step;
  final Future<void> Function() record;
  final ValueChanged<int> selectSection;
  final int section;
  final Widget Function()? selection;
  final VoidCallback? resetOriginalView;
  const InstrumentShell({
    super.key,
    required this.id,
    required this.title,
    required this.store,
    required this.changes,
    required this.scene,
    required this.graph,
    required this.controls,
    required this.readings,
    required this.advanced,
    required this.results,
    required this.notice,
    required this.playing,
    required this.dynamicModel,
    required this.canRecord,
    required this.play,
    required this.pause,
    required this.reset,
    required this.save,
    required this.record,
    required this.selectSection,
    required this.section,
    this.referenceChart,
    this.toolbarActions = const [],
    this.parameterDock,
    this.dockExtent,
    this.fitScene = true,
    this.reopenTrial,
    this.exportRecorded,
    this.step,
    this.selection,
    this.resetOriginalView,
    this.showLabSections = true,
    this.recordLabel = 'Record Trial',
    this.data,
    this.highlightControl,
    this.guidedStep,
    this.changeGuidedStep,
    this.guideInstructions,
    this.canAdvanceGuide,
  });
  @override
  State<InstrumentShell> createState() => _InstrumentShellState();
}

class _InstrumentShellState extends State<InstrumentShell> {
  final camera = TransformationController();
  final graphCamera = TransformationController();
  int graphViewRevision = 0;
  bool get full =>
      pane == WorkspacePane.fullscreen || pane == WorkspacePane.fullscreenGraph;
  bool get graphFocused =>
      pane == WorkspacePane.graph || pane == WorkspacePane.fullscreenGraph;
  final scaffold = GlobalKey<ScaffoldState>();
  WorkspacePane pane = WorkspacePane.scene;
  double split = .6;
  bool pan = false;
  bool cameraExpanded = false;
  bool guideVisible = false;
  int currentGuideStep = 0;
  PersistentBottomSheetController? sheet;
  @override
  void initState() {
    super.initState();
    currentGuideStep =
        (widget.store.preferences.getInt('workspaceGuide:${widget.id}') ??
                widget.guidedStep?.call() ??
                0)
            .clamp(0, 3);
    try {
      final raw = widget.store.preferences.getString('workspace:${widget.id}');
      if (raw != null) {
        final saved = jsonDecode(raw);
        final index = saved['pane'];
        if (index is int && index >= 0 && index < 4) {
          pane = WorkspacePane.values[index];
        }
        final fraction = saved['split'];
        if (fraction is num && fraction.isFinite) {
          split = fraction.toDouble().clamp(.25, .75);
        }
      }
    } catch (_) {
      /* Invalid view preferences never change scientific state. */
    }
    if (widget.section == 2) pane = WorkspacePane.graph;
  }

  @override
  void didUpdateWidget(covariant InstrumentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section && widget.section == 2) {
      pane = WorkspacePane.graph;
    }
    if (oldWidget.section == 2 && widget.section == 1) {
      pane = WorkspacePane.scene;
    }
    if (sheet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (oldWidget.section != widget.section) {
          sheet?.close();
          sheet = null;
        } else {
          sheet?.setState?.call(() {});
        }
      });
    }
  }

  void persist() {
    widget.store.preferences.setString(
      'workspace:${widget.id}',
      jsonEncode({'version': 1, 'pane': full ? 0 : pane.index, 'split': split}),
    );
  }

  @override
  void dispose() {
    camera.dispose();
    graphCamera.dispose();
    super.dispose();
  }

  void fit() {
    if (graphFocused) {
      graphCamera.value = Matrix4.identity();
      setState(() => graphViewRevision++);
    } else {
      camera.value = Matrix4.identity();
      widget.resetOriginalView?.call();
    }
  }

  void zoom(double factor) {
    final target = graphFocused ? graphCamera : camera;
    final scale = target.value.getMaxScaleOnAxis();
    final next = (scale * factor).clamp(.5, 5);
    target.value = target.value.clone()
      ..scaleByDouble(next / scale, next / scale, 1, 1);
  }

  void choose(WorkspacePane next) {
    setState(() {
      pane = next;
      cameraExpanded = false;
    });
    persist();
  }

  void more() {
    widget.pause();
    sheet?.close();
    sheet = scaffold.currentState!.showBottomSheet(
      (context) => ListenableBuilder(
        listenable: Listenable.merge([widget.changes, widget.store]),
        builder: (context, _) => SafeArea(
          top: false,
          child: Container(
            height: math.max(
              MediaQuery.sizeOf(context).height * .65,
              MediaQuery.viewInsetsOf(context).bottom + 120,
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        'Controls & investigation',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close controls',
                      onPressed: () => sheet?.close(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: widget.section == 4
                        ? notebookSummary()
                        : widget.advanced(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      showDragHandle: true,
      enableDrag: true,
    );
  }

  List<Widget> notebookSummary() {
    // Trial details and reopen belong to the selected record, not a second stacked history.
    final content = widget.results();
    bool includedSummary = false;
    return content.where((w) {
      if (w is! Panel) return true;
      if (w.child is Paragraph) {
        includedSummary = true;
        return true;
      }
      if (includedSummary) return false;
      includedSummary = true;
      return true;
    }).toList();
  }

  Widget parameter(InstrumentControl c) => DecoratedBox(
    decoration: BoxDecoration(
      color: c.keyName == widget.highlightControl
          ? const Color(0xffedf3ff)
          : Colors.transparent,
      border: Border(
        left: BorderSide(
          width: 3,
          color: c.keyName == widget.highlightControl
              ? cobalt
              : Colors.transparent,
        ),
      ),
    ),
    child: parameterRow(c),
  );
  Widget parameterRow(InstrumentControl c) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${c.label}${c.unit.isEmpty ? '' : ' (${c.unit})'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Decrease ${c.label}',
              onPressed: c.max > c.min
                  ? () => c.change(
                      (c.value - (c.max - c.min) / 100).clamp(c.min, c.max),
                    )
                  : null,
              icon: const Icon(Icons.chevron_left, size: 19),
            ),
            Expanded(
              child: Slider(
                key: ValueKey('dock-control-${c.keyName}'),
                min: c.min,
                max: c.max,
                value: c.value.clamp(c.min, c.max),
                label: '${c.value.toStringAsPrecision(4)} ${c.unit}',
                onChanged: c.max > c.min ? c.change : null,
              ),
            ),
            IconButton(
              tooltip: 'Increase ${c.label}',
              onPressed: c.max > c.min
                  ? () => c.change(
                      (c.value + (c.max - c.min) / 100).clamp(c.min, c.max),
                    )
                  : null,
              icon: const Icon(Icons.chevron_right, size: 19),
            ),
            SizedBox(
              width: 76,
              child: OutlinedButton(
                key: ValueKey('dock-edit-${c.keyName}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                ),
                onPressed: () async {
                  widget.pause();
                  await showDialog<void>(
                    context: context,
                    builder: (_) => NumericInputDialog(
                      label: '${c.label} (${c.unit})',
                      initial: c.value,
                      min: c.min,
                      max: c.max,
                      onApply: c.change,
                    ),
                  );
                },
                child: Text(
                  c.value.toStringAsPrecision(4),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

  Widget dock() => ListenableBuilder(
    listenable: widget.changes,
    builder: (context, _) => dockContent(),
  );
  Widget dockContent() {
    final available = List<InstrumentControl>.of(widget.controls());
    final index = available.indexWhere(
      (c) => c.keyName == widget.highlightControl,
    );
    if (index > 0) {
      available.insert(0, available.removeAt(index));
    }
    if (widget.parameterDock != null) {
      return ColoredBox(
        color: Colors.white,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            if (guideVisible)
              SizedBox(
                height: 100,
                child: SingleChildScrollView(child: guideStrip()),
              ),
            widget.parameterDock!(),
          ],
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffe3e9f1))),
      ),
      child: ListView(
        key: ValueKey('parameter-dock-${widget.id}'),
        padding: EdgeInsets.zero,
        children: [
          if (widget.selection != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: widget.selection!(),
            ),
          if (guideVisible)
            SizedBox(
              height: 100,
              child: SingleChildScrollView(child: guideStrip()),
            ),
          ...available.take(2).map(parameter),
          if (available.isEmpty)
            ListTile(
              dense: true,
              title: const Text('Contextual apparatus controls'),
              trailing: const Icon(Icons.tune),
              onTap: more,
            ),
        ],
      ),
    );
  }

  Widget readingStrip() => ListenableBuilder(
    listenable: widget.changes,
    builder: (context, _) => readingsContent(),
  );
  Widget readingsContent() => InkWell(
    onTap: () => widget.selectSection(3),
    child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xffedf6ff),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item
              in widget
                  .readings()
                  .take(3)
                  .map((r) => presentReading(r.label, r.value, r.unit))
                  .indexed) ...[
            if (item.$1 > 0)
              Container(
                width: 1,
                height: 38,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: const Color(0xffc8dced),
              ),
            Expanded(
              flex: item.$1 == 0 ? 13 : 10,
              child: Tooltip(
                message: item.$2.tooltip,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2.label.replaceAllMapped(
                        RegExp(r'([a-z])([A-Z])'),
                        (m) => '${m[1]} ${m[2]}',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        height: 1.2,
                        color: navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${item.$2.value}${item.$2.unit.isEmpty ? '' : ' ${item.$2.unit}'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: item.$1 == 0 ? 18 : 13,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: navy,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    ),
  );

  Widget cameraLayer(
    TransformationController controller,
    Widget child, {
    Key? key,
  }) => Stack(
    key: key,
    fit: StackFit.expand,
    children: [
      ValueListenableBuilder<Matrix4>(
        valueListenable: controller,
        builder: (context, matrix, _) => Transform(
          transform: matrix,
          child: IgnorePointer(ignoring: pan, child: child),
        ),
      ),
      if (pan)
        InteractiveViewer(
          transformationController: controller,
          minScale: .5,
          maxScale: 5,
          child: const ColoredBox(
            color: Colors.transparent,
            child: SizedBox.expand(),
          ),
        ),
    ],
  );

  Widget viewport() => ClipRect(
    child: ColoredBox(
      color: const Color(0xfff7faff),
      child: cameraLayer(
        camera,
        widget.fitScene
            ? Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(width: 360, child: widget.scene()),
                ),
              )
            : SizedBox.expand(child: widget.scene()),
        key: const Key('workspace-camera'),
      ),
    ),
  );

  Widget graph() => cameraLayer(
    graphCamera,
    KeyedSubtree(key: ValueKey(graphViewRevision), child: graphContent()),
  );

  Widget graphContent() => ColoredBox(
    color: Colors.white,
    child: SingleChildScrollView(
      key: const Key('graph-pane-scroll'),
      padding: const EdgeInsets.all(8),
      child: widget.graph(),
    ),
  );

  Widget divider(bool horizontal, double extent) => Semantics(
    label: 'Resize scientific panes',
    slider: true,
    value: '${(split * 100).round()} percent scene',
    increasedValue:
        '${((split + .05).clamp(.25, .75) * 100).round()} percent scene',
    decreasedValue:
        '${((split - .05).clamp(.25, .75) * 100).round()} percent scene',
    onIncrease: () {
      setState(() => split = (split + .05).clamp(.25, .75));
      persist();
    },
    onDecrease: () {
      setState(() => split = (split - .05).clamp(.25, .75));
      persist();
    },
    child: GestureDetector(
      key: const Key('pane-divider'),
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (d) {
        setState(
          () => split =
              (split +
                      (horizontal ? d.delta.dx : d.delta.dy) /
                          math.max(1, extent))
                  .clamp(.25, .75),
        );
      },
      onPanEnd: (_) => persist(),
      child: SizedBox(
        width: horizontal ? 24 : double.infinity,
        height: horizontal ? double.infinity : 24,
        child: Center(
          child: Icon(
            horizontal ? Icons.drag_indicator : Icons.drag_handle,
            size: 20,
            color: muted,
          ),
        ),
      ),
    ),
  );

  Widget panes() => LayoutBuilder(
    builder: (context, b) {
      if (graphFocused) return graph();
      if (pane == WorkspacePane.scene || pane == WorkspacePane.fullscreen) {
        return viewport();
      }
      final second = pane == WorkspacePane.sceneData
          ? (widget.data?.call() ?? notebook(compact: true))
          : graph();
      final horizontal =
          MediaQuery.orientationOf(context) == Orientation.landscape ||
          MediaQuery.sizeOf(context).width >= 840;
      final first = Expanded(flex: (split * 100).round(), child: viewport());
      final last = Expanded(flex: ((1 - split) * 100).round(), child: second);
      return horizontal
          ? Row(children: [first, divider(true, b.maxWidth), last])
          : Column(children: [first, divider(false, b.maxHeight), last]);
    },
  );

  bool get referenceHintVisible =>
      MediaQuery.sizeOf(context).height >= 600 &&
      MediaQuery.textScalerOf(context).scale(1) < 1.5;
  Widget referenceHint() {
    final entries = allEntries.where((e) => e.id == widget.id);
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 3, 10, 2),
      decoration: BoxDecoration(
        color: const Color(0xffedf6ff),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => widget.selectSection(0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline,
                        color: Color(0xffefa600),
                        size: 21,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entries.first.principle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.25,
                            color: navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (widget.dynamicModel())
            IconButton(
              key: const Key('record-trial'),
              tooltip: widget.recordLabel,
              onPressed: widget.canRecord() ? widget.record : null,
              icon: const Icon(Icons.add_circle_outline, size: 20),
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  Widget actions() => ListenableBuilder(
    listenable: widget.changes,
    builder: (context, _) => actionContent(),
  );
  Widget actionContent() => Padding(
    padding: const EdgeInsets.fromLTRB(10, 5, 10, 6),
    child: LayoutBuilder(
      builder: (context, b) {
        final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
        return Row(
          children: [
            Expanded(
              child: widget.dynamicModel()
                  ? FilledButton.icon(
                      key: const Key('play'),
                      onPressed: widget.playing() ? widget.pause : widget.play,
                      icon: Icon(
                        widget.playing() ? Icons.pause : Icons.play_arrow,
                        size: 20,
                      ),
                      label: Text(
                        widget.playing() ? 'Pause' : 'Run Experiment',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    )
                  : FilledButton.icon(
                      key: const Key('record-trial'),
                      onPressed: widget.canRecord() ? widget.record : null,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(
                        widget.recordLabel,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 7),
            Tooltip(
              message: 'Reset',
              child: OutlinedButton(
                onPressed: widget.reset,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: large ? 10 : 14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.restart_alt, size: 20),
                    if (!large) ...[
                      const SizedBox(width: 5),
                      const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.dynamicModel() && !referenceHintVisible) ...[
              const SizedBox(width: 7),
              Tooltip(
                message: widget.recordLabel,
                child: FilledButton.tonal(
                  key: const Key('record-trial'),
                  onPressed: widget.canRecord() ? widget.record : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: const Icon(Icons.add, size: 20),
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  Widget notebook({bool compact = false}) {
    final trials = widget.store.trials
        .where((t) => t.labId == widget.id)
        .toList()
        .reversed
        .toList();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${trials.length} recorded trials',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextButton(onPressed: more, child: const Text('Summary / export')),
          ],
        ),
        if (trials.isEmpty)
          const Text('Record a calculated state to start this notebook.'),
        for (final trial in trials.take(compact ? 10 : 100))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('${trial.value.toStringAsPrecision(5)} ${trial.unit}'),
            subtitle: Text(
              '${trial.quantity} · ${trial.created.substring(0, math.min(19, trial.created.length))}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => trialDetails(trial, trials),
          ),
      ],
    );
  }

  void trialDetails(Trial trial, List<Trial> trials) {
    widget.pause();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .7,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${trial.quantity}: ${trial.value.toStringAsPrecision(6)} ${trial.unit}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${trial.created} · ${trial.model}'),
              const SizedBox(height: 12),
              Text(trial.note.isEmpty ? 'No recorded notes' : trial.note),
              Wrap(
                spacing: 8,
                children: [
                  if (widget.reopenTrial != null)
                    FilledButton.icon(
                      icon: const Icon(Icons.restore),
                      label: const Text('Reopen configuration'),
                      onPressed: () {
                        final restored = widget.reopenTrial!(trial);
                        Navigator.pop(context);
                        if (restored) widget.selectSection(1);
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            content: Text(
                              restored
                                  ? (widget.dynamicModel()
                                        ? 'Recorded configuration restored; model paused.'
                                        : 'Recorded configuration restored.')
                                  : 'Incompatible configuration; active experiment preserved.',
                            ),
                          ),
                        );
                      },
                    ),
                  if (widget.exportRecorded != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.ios_share),
                      label: const Text('Export trial'),
                      onPressed: () => widget.exportRecorded!([trial]),
                    ),
                ],
              ),
              ExpansionTile(
                title: const Text('Recorded configuration'),
                children: [
                  SelectableText(
                    const JsonEncoder.withIndent('  ')
                        .convert(trial.configuration),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Compare recorded observations',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const Text(
                'Same lab, quantity, unit and model version. Values below are recorded observations, not synchronized trajectories.',
              ),
              for (final other
                  in trials
                      .where(
                        (t) =>
                            t.id != trial.id &&
                            t.model == trial.model &&
                            t.quantity == trial.quantity &&
                            t.unit == trial.unit,
                      )
                      .take(20))
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${other.value.toStringAsPrecision(6)} ${other.unit}',
                  ),
                  subtitle: Text(
                    '${other.created} · Δ ${(other.value - trial.value).toStringAsPrecision(5)} ${trial.unit}',
                  ),
                  trailing: widget.exportRecorded == null
                      ? null
                      : IconButton(
                          tooltip: 'Export comparison',
                          icon: const Icon(Icons.ios_share),
                          onPressed: () =>
                              widget.exportRecorded!([trial, other]),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void moveGuide(int step) {
    setState(() => currentGuideStep = step.clamp(0, 3));
    widget.store.preferences.setInt(
      'workspaceGuide:${widget.id}',
      currentGuideStep,
    );
    // Preserve the existing two-stage investigation evidence contract.
    widget.changeGuidedStep?.call(math.min(currentGuideStep, 2));
  }

  Widget guideStrip() => ListenableBuilder(
    listenable: widget.changes,
    builder: (context, _) {
      final step = currentGuideStep;
      final instructions =
          widget.guideInstructions?.call() ??
          const [
            'Change a scientific input.',
            'Run or inspect the calculated state.',
            'Record the current state.',
            'Check your prediction and explain your observation.',
          ];
      return Material(
        color: const Color(0xffeef4ff),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous guided step',
              onPressed: step > 0 ? () => moveGuide(step - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                '${step + 1}/4 · ${instructions[step.clamp(0, instructions.length - 1)]}',
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            IconButton(
              tooltip: step == 3 ? 'Check investigation' : 'Next guided step',
              onPressed: widget.canAdvanceGuide?.call(step) ?? true
                  ? () {
                      if (step == 3) {
                        more();
                      } else {
                        moveGuide(step + 1);
                      }
                    }
                  : null,
              icon: Icon(
                step == 3 ? Icons.fact_check_outlined : Icons.chevron_right,
              ),
            ),
            IconButton(
              tooltip: 'Exit guided mode',
              onPressed: () => setState(() => guideVisible = false),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      );
    },
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !full,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && full) {
        choose(WorkspacePane.scene);
      }
    },
    child: Scaffold(
      key: scaffold,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        leading: LabBackButton(
          widget.id.split('-').first,
          onBack: full ? () => choose(WorkspacePane.scene) : null,
        ),
        title: ReferenceLabHeading(widget.id, widget.title),
        actions: [
          ...widget.toolbarActions,
          IconButton(
            tooltip: 'Learn / contextual help',
            onPressed: () => widget.selectSection(0),
            icon: const Icon(Icons.help_outline),
          ),
          LabSectionMenu(
            labId: widget.id,
            notebook: widget.store,
            guide: widget.guidedStep == null
                ? null
                : () {
                    widget.pause();
                    setState(() => guideVisible = !guideVisible);
                  },
            showSections: widget.showLabSections,
            section: widget.section,
            controls: more,
            camera: () => setState(() => cameraExpanded = !cameraExpanded),
            save: widget.save,
            select: (value) {
              sheet?.close();
              widget.selectSection(value);
            },
          ),
        ],
      ),
      bottomNavigationBar: full
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.section != 4 && referenceHintVisible)
                  ListenableBuilder(
                    listenable: widget.changes,
                    builder: (context, _) => referenceHint(),
                  ),
                if (widget.section != 4) actions(),
                ReferenceNavigation(
                  selected: widget.section == 4
                      ? 2
                      : widget.section == 0 || widget.section == 3
                      ? 0
                      : 1,
                  firstIcon:
                      allEntries.any(
                        (e) =>
                            e.id == widget.id &&
                            [0, 10, 11, 13].contains(e.studioIndex),
                      )
                      ? Icons.home_outlined
                      : Icons.menu_book_outlined,
                  onFirst: () => widget.selectSection(0),
                  onLabs: () => widget.selectSection(1),
                  onResults: () => widget.selectSection(4),
                ),
              ],
            ),
      body: SafeArea(
        child: widget.section == 4
            ? notebook()
            : LayoutBuilder(
                builder: (context, b) {
                  final wide = b.maxWidth > b.maxHeight * 1.35;
                  final full = this.full;
                  final cameraBar = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        PopupMenuButton<Object>(
                          tooltip: 'Workspace panes',
                          initialValue: pane,
                          onSelected: (value) {
                            if (value == 'guide') {
                              setState(() => guideVisible = !guideVisible);
                            } else {
                              choose(value as WorkspacePane);
                            }
                          },
                          itemBuilder: (_) => [
                            if (widget.guidedStep != null)
                              const PopupMenuItem(
                                value: 'guide',
                                child: Text('Guided investigation'),
                              ),
                            for (final p in WorkspacePane.values)
                              PopupMenuItem(
                                value: p,
                                child: Text(paneNames[p.index]),
                              ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 14,
                            ),
                            child: Text(
                              graphFocused
                                  ? 'Graph'
                                  : full
                                  ? 'Full'
                                  : 'View',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Inspect graph',
                          onPressed: () => choose(
                            pane == WorkspacePane.sceneGraph
                                ? WorkspacePane.scene
                                : WorkspacePane.sceneGraph,
                          ),
                          icon: const Icon(Icons.insights_outlined),
                        ),
                        if (widget.step != null)
                          IconButton(
                            tooltip: 'Step',
                            onPressed: widget.step,
                            icon: const Icon(Icons.skip_next),
                          ),
                        const SizedBox(width: 4),
                        IconButton(
                          tooltip: pan
                              ? 'Manipulate apparatus'
                              : 'Pan / zoom camera',
                          onPressed: () => setState(() => pan = !pan),
                          icon: Icon(
                            pan ? Icons.pan_tool : Icons.touch_app_outlined,
                          ),
                          color: pan ? cobalt : muted,
                        ),
                        IconButton(
                          tooltip: 'Zoom out',
                          onPressed: () => zoom(1 / 1.25),
                          icon: const Icon(Icons.remove),
                        ),
                        IconButton(
                          tooltip: 'Zoom in',
                          onPressed: () => zoom(1.25),
                          icon: const Icon(Icons.add),
                        ),
                        IconButton(
                          tooltip: 'Fit apparatus / reset view',
                          onPressed: fit,
                          icon: const Icon(Icons.fit_screen),
                        ),
                      ],
                    ),
                  );
                  final readingHeight = math
                      .min(
                        (64.0 * MediaQuery.textScalerOf(context).scale(1))
                            .clamp(56, 112),
                        math.max(24, b.maxHeight * .24),
                      )
                      .toDouble();
                  Widget visual() => Column(
                    children: [
                      if (cameraExpanded)
                        Row(
                          children: [
                            Expanded(child: cameraBar),
                            IconButton(
                              tooltip: 'Close camera tools',
                              onPressed: () =>
                                  setState(() => cameraExpanded = false),
                              icon: const Icon(Icons.close, size: 20),
                            ),
                          ],
                        ),
                      Expanded(child: panes()),
                    ],
                  );
                  final content = Column(
                    children: [
                      Expanded(child: visual()),
                      SizedBox(
                        height: readingHeight,
                        child: SingleChildScrollView(child: readingStrip()),
                      ),
                      if (RegExp(
                        'invalid|limited|outside|unsupported|incompatible|failed|undefined|denied|cannot|exceeds',
                        caseSensitive: false,
                      ).hasMatch(widget.notice()))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            widget.notice(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  );
                  if (full) {
                    return content;
                  }
                  if (wide) {
                    return Row(
                      children: [
                        Expanded(child: content),
                        SizedBox(
                          width: math.min(310, b.maxWidth * .4),
                          child: Column(children: [Expanded(child: dock())]),
                        ),
                      ],
                    );
                  }
                  final dockHeight = math.min(
                    b.maxHeight * .43,
                    (widget.dockExtent ??
                            (widget.controls().take(2).length * 76 +
                                (widget.selection == null ? 0 : 52))) *
                        math.max(1, MediaQuery.textScalerOf(context).scale(1)),
                  );
                  final hasPlot =
                      widget.referenceChart != null &&
                      pane == WorkspacePane.scene &&
                      b.maxHeight > 320 &&
                      MediaQuery.textScalerOf(context).scale(1) < 1.5;
                  if (hasPlot) {
                    return SingleChildScrollView(
                      key: const Key('reference-instrument-scroll'),
                      child: SizedBox(
                        height: math.max(
                          b.maxHeight,
                          520.0 + (widget.selection == null ? 0 : 52),
                        ),
                        child: Column(
                          children: [
                            Expanded(flex: 65, child: visual()),
                            SizedBox(
                              height: readingHeight,
                              child: SingleChildScrollView(
                                child: readingStrip(),
                              ),
                            ),
                            SizedBox(
                              height:
                                  (widget.dockExtent ??
                                      (widget.controls().take(2).length * 76.0 +
                                          (widget.selection == null
                                              ? 0
                                              : 52))) *
                                  math.max(
                                    1,
                                    MediaQuery.textScalerOf(context).scale(1),
                                  ),
                              child: dock(),
                            ),
                            Expanded(
                              flex: 35,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  12,
                                  2,
                                  12,
                                  5,
                                ),
                                child: Semantics(
                                  label: 'Open interactive graph',
                                  button: true,
                                  child: InkWell(
                                    onTap: () => choose(WorkspacePane.graph),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xffdce7f1),
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(3),
                                        child: ListenableBuilder(
                                          listenable: widget.changes,
                                          builder: (c, _) => CustomPaint(
                                            key: const Key(
                                              'reference-compact-chart',
                                            ),
                                            size: Size.infinite,
                                            painter: widget.referenceChart!(),
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
                    );
                  }
                  return Column(
                    children: [
                      Expanded(child: content),
                      SizedBox(height: dockHeight, child: dock()),
                    ],
                  );
                },
              ),
      ),
    ),
  );
}

class RecordedTrialGraph extends StatelessWidget {
  final LocalNotebook store;
  final String labId, quantity, unit;
  const RecordedTrialGraph({
    super.key,
    required this.store,
    required this.labId,
    required this.quantity,
    required this.unit,
  });
  @override
  Widget build(BuildContext context) {
    final trials = store.trials
        .where(
          (t) => t.labId == labId && t.quantity == quantity && t.unit == unit,
        )
        .toList();
    if (trials.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Record a trial to plot actual recorded values. No sample observations are supplied.',
        ),
      );
    }
    return Column(
      children: [
        Text('Recorded $quantity ($unit) by trial index'),
        SizedBox(
          height: 230,
          child: InteractiveViewer(
            minScale: .5,
            maxScale: 5,
            child: CustomPaint(
              painter: LabPlot(
                [
                  for (int i = 0; i < trials.length; i++)
                    {'t': i + 1.0, 'value': trials[i].value},
                ],
                const ['value'],
                'Trial index',
                unit,
                trials.length - 1,
              ),
              size: const Size(double.infinity, 230),
            ),
          ),
        ),
      ],
    );
  }
}
