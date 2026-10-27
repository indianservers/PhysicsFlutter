import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/rendering/micrometer.dart';
import 'experiment.dart';

class MicrometerViewport extends StatefulWidget {
  final Experiment experiment;
  const MicrometerViewport({super.key, required this.experiment});
  @override
  State<MicrometerViewport> createState() => MicrometerViewportState();
}

class MicrometerViewportState extends State<MicrometerViewport> {
  bool lens = true, turning = false;
  Offset lensPosition = const Offset(.95, .95);
  double dragOpening = 0;
  MicrometerGeometry get geometry => MicrometerGeometry(
    widget.experiment.a,
    widget.experiment.b,
    widget.experiment.zero,
  );
  double lensHeight(BoxConstraints b) => math.min(100, b.maxHeight * .35);
  void precision() => showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Precision reading'),
          leading: IconButton(
            tooltip: 'Close precision reading',
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: widget.experiment,
            builder: (context, _) => Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: MicrometerLensPainter(geometry, zoom: 5),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Sleeve ${(geometry.reading.main * 1000).toStringAsFixed(2)} + thimble ${(geometry.reading.fraction * 1000).toStringAsFixed(2)} = ${(geometry.reading.observed * 1000).toStringAsFixed(2)} mm · LC 0.01 mm',
                  ),
                ),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Close spindle by 0.01 mm',
                      onPressed: () =>
                          widget.experiment.setA(widget.experiment.a - .00001),
                      icon: const Icon(Icons.remove),
                    ),
                    const Text('0.01 mm / division'),
                    IconButton(
                      tooltip: 'Open spindle by 0.01 mm',
                      onPressed: () =>
                          widget.experiment.setA(widget.experiment.a + .00001),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.experiment,
    builder: (context, _) => SizedBox(
      width: 360,
      height: 300,
      child: LayoutBuilder(
        builder: (context, b) => Stack(
          children: [
            Positioned.fill(
              child: Semantics(
                label:
                    'Outside micrometer. Opposed anvil and spindle faces; ${(geometry.opening * 1000).toStringAsFixed(2)} mm opening. ${geometry.contact ? 'Object in contact.' : 'Open gap; close spindle to contact the object.'} Sleeve ${(geometry.reading.main * 1000).toStringAsFixed(2)} mm, thimble division ${geometry.reading.division}, observed ${(geometry.reading.observed * 1000).toStringAsFixed(2)} mm.',
                child: GestureDetector(
                  key: const Key('micrometer-thimble'),
                  onPanDown: (d) {
                    final point = geometry.toWorld(
                      d.localPosition,
                      Size(b.maxWidth, b.maxHeight),
                    );
                    turning = geometry.thimble.inflate(12).contains(point);
                    dragOpening = widget.experiment.a;
                  },
                  onPanUpdate: (d) {
                    if (!turning) return;
                    final fit = math.min(b.maxWidth / 440, b.maxHeight / 250);
                    // Dragging over the thimble rotates its front surface: one full
                    // circumference corresponds to one 0.5 mm spindle revolution.
                    dragOpening +=
                        d.delta.dy /
                        fit /
                        (2 * math.pi * 28) *
                        MicrometerGeometry.pitch;
                    widget.experiment.setA(dragOpening);
                  },
                  onPanEnd: (_) => turning = false,
                  onPanCancel: () => turning = false,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MicrometerPainter(
                        geometry,
                        labels: widget.experiment.guides,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: lens ? 'Hide scale lens' : 'Show scale lens',
                    onPressed: () => setState(() => lens = !lens),
                    isSelected: lens,
                    icon: const Icon(Icons.search),
                  ),
                  IconButton(
                    tooltip: 'Enlarge precision reading',
                    onPressed: precision,
                    icon: const Icon(Icons.center_focus_strong),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 2,
              left: 8,
              child: IgnorePointer(
                child: Text(
                  geometry.contact ? 'Contact' : 'Open gap',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xff4d6475),
                  ),
                ),
              ),
            ),
            if (lens && b.maxHeight > 95)
              Positioned(
                left: ((b.maxWidth - 174) * lensPosition.dx).clamp(
                  0,
                  math.max(0, b.maxWidth - 174),
                ),
                top: ((b.maxHeight - lensHeight(b)) * lensPosition.dy).clamp(
                  0,
                  math.max(0, b.maxHeight - lensHeight(b)),
                ),
                width: 174,
                height: lensHeight(b),
                child: Semantics(
                  label:
                      'Draggable lens of the actual sleeve and thimble scale. Observed ${(geometry.reading.observed * 1000).toStringAsFixed(2)} millimeters.',
                  child: GestureDetector(
                    key: const Key('micrometer-lens'),
                    onPanUpdate: (d) => setState(
                      () => lensPosition = Offset(
                        (lensPosition.dx +
                                d.delta.dx / math.max(1, b.maxWidth - 174))
                            .clamp(0, 1),
                        (lensPosition.dy +
                                d.delta.dy / math.max(1, b.maxHeight - 100))
                            .clamp(.24, 1),
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: const Color(0xff4b709a),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: CustomPaint(
                          painter: MicrometerLensPainter(geometry, zoom: 3),
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
  );
}
