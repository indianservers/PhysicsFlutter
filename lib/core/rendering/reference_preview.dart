import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../content/catalog.dart';

const referenceFiles = [
  '01_Concept_Overview.png',
  '02_Measurement.png',
  '03_Mechanics.png',
  '04_Motion_and_Kinematics.png',
  '05_Force_and_Newtons_Laws.png',
  '06_Work_Energy_and_Power.png',
  '07_Gravitation.png',
  '08_Oscillations.png',
  '09_Waves_and_Sound.png',
  '10_Optics.png',
  '11_Electricity.png',
  '12_Magnetism.png',
  '13_Electronics.png',
  '14_Thermodynamics.png',
  '15_Fluid_Mechanics.png',
  '16_Modern_Physics.png',
  '17_Astronomy_and_Astrophysics.png',
];

/// A clearly labeled static preview from the user's supplied visual references.
/// Never used in place of a live scientific scene or a measured observation.
class ReferencePreview extends StatefulWidget {
  final Entry entry;
  final Widget fallback;
  const ReferencePreview(this.entry, {super.key, required this.fallback});
  @override
  State<ReferencePreview> createState() => _ReferencePreviewState();
}

class _ReferencePreviewState extends State<ReferencePreview> {
  ImageStream? stream;
  ImageInfo? info;
  late final ImageStreamListener listener = ImageStreamListener((
    image,
    synchronous,
  ) {
    if (!mounted) {
      image.dispose();
      return;
    }
    setState(() {
      info?.dispose();
      info = image;
    });
  }, onError: (Object error, StackTrace? stack) {});
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    resolve();
  }

  @override
  void didUpdateWidget(covariant ReferencePreview old) {
    super.didUpdateWidget(old);
    if (old.entry.studioIndex != widget.entry.studioIndex) {
      info?.dispose();
      info = null;
      resolve();
    }
  }

  void resolve() {
    final next = ResizeImage(
      AssetImage(
        'assets/reference_previews/${referenceFiles[widget.entry.studioIndex]}',
      ),
      width: 660,
    ).resolve(createLocalImageConfiguration(context));
    if (next.key == stream?.key) return;
    stream?.removeListener(listener);
    stream = next..addListener(listener);
  }

  @override
  void dispose() {
    stream?.removeListener(listener);
    info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => info == null
      ? widget.fallback
      : Semantics(
          image: true,
          label:
              '${widget.entry.title}, static supplied apparatus reference preview',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              painter: _ReferenceImage(info!.image, widget.entry),
              size: Size.infinite,
            ),
          ),
        );
}

class _ReferenceImage extends CustomPainter {
  final ui.Image image;
  final Entry entry;
  _ReferenceImage(this.image, this.entry);
  @override
  void paint(Canvas c, Size s) {
    final tall = entry.studioIndex >= 10;
    final col = entry.index % 3, row = entry.index ~/ 3;
    // Source atlas regions contain apparatus/diagrams only, not the full phone UI.
    final x = tall ? .025 + col * .324 : .08 + col * .296;
    final y = tall ? .037 + row * .51 : .10 + row * .493;
    final w = tall ? .293 : .274, h = tall ? .135 : .145;
    final src = Rect.fromLTWH(
      x * image.width,
      y * image.height,
      w * image.width,
      h * image.height,
    );
    final out = applyBoxFit(BoxFit.cover, src.size, s);
    final crop = Alignment.center.inscribe(out.source, src);
    final dest = Alignment.center.inscribe(out.destination, Offset.zero & s);
    c.drawImageRect(
      image,
      crop,
      dest,
      Paint()..filterQuality = FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(covariant _ReferenceImage old) =>
      image != old.image || entry.id != old.entry.id;
}
