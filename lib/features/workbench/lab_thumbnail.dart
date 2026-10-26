import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../content/catalog.dart';
import '../../core/rendering/apparatus.dart';
import '../../core/physics/dynamics.dart';
import '../../core/physics/advanced.dart';
import '../../core/physics/waves_optics.dart';
import '../../core/physics/electromagnetism.dart';
import '../../core/physics/electronics_thermal.dart';
import '../../core/physics/fluid_modern_run.dart';
import '../../core/physics/astronomy_run.dart';
import '../dynamics/curriculum.dart' as d;
import '../advanced/curriculum.dart' as a;
import '../waves/curriculum.dart' as w;
import '../electromagnetism/curriculum.dart' as e;
import '../electronics_thermal/curriculum.dart' as t;
import '../fluid_modern/curriculum.dart' as f;
import '../astronomy/curriculum.dart' as s;
import '../dynamics/scene.dart';
import '../advanced/scene.dart';
import '../waves/scene.dart';
import '../electromagnetism/scene.dart';
import '../electronics_thermal/scene.dart';
import '../fluid_modern/scene.dart';
import '../astronomy/scene.dart';

/// Static, model-derived reference previews. No ticker, user session or recorded trial.
class LabThumbnail extends StatelessWidget {
  final Entry entry;
  const LabThumbnail(this.entry, {super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: '${entry.title}, static apparatus reference preview',
    child: RepaintBoundary(child: CustomPaint(painter: _Preview(entry))),
  );
}

class _Preview extends CustomPainter {
  static final _pictures = <String, ui.Picture>{};
  final Entry entry;
  _Preview(this.entry);
  CustomPainter painter() {
    final k = entry.index, studio = entry.studioIndex;
    if (entry.astronomy) {
      return AstronomyPainter(
        AstronomyRun(k, s.astroLessons[k].defaults),
        overlays: false,
        motion: false,
      );
    }
    if (entry.fluidModern) {
      final i = (studio - 14) * 6 + k;
      return FMPainter(
        FMRun(i, f.fmLessons[i].defaults),
        labels: false,
        overlays: false,
        motion: false,
      );
    }
    if (entry.electronicsThermal) {
      final i = (studio - 12) * 6 + k;
      return ETPainter(
        ETRun(i, t.etLessons[i].defaults),
        labels: false,
        overlays: false,
      );
    }
    if (entry.electromagnetism) {
      final i = (studio - 10) * 6 + k;
      return EMPainter(
        EMRun(i, e.emLessons[i].defaults),
        labels: false,
        overlays: true,
      );
    }
    if (entry.wavesOptics) {
      final i = (studio - 8) * 6 + k;
      return WavePainter(
        WaveOpticsRun(i, w.waveLessons[i].defaults),
        labels: false,
        overlays: true,
      );
    }
    if (entry.advanced) {
      final i = (studio - 5) * 6 + k;
      final p = a.advancedLessons[i].defaults;
      return AdvancedPainter(
        kind: i,
        s: AdvancedRun(i, p).state,
        p: p,
        samples: [],
        labels: false,
        overlays: true,
        trails: false,
      );
    }
    if (entry.dynamics) {
      final i = (studio - 2) * 6 + k;
      final p = d.lessons[i].defaults;
      return DynamicsPainter(
        kind: i,
        s: DynamicsRun(i, p).state,
        p: p,
        samples: [],
        labels: false,
        trails: false,
      );
    }
    return ApparatusPainter(
      k,
      a: [.012, .0236, .00052, .00044, .02845, .001][k],
      b: k == 0
          ? .066
          : k == 3
          ? .05
          : .0005,
      samples: k == 5 ? [.021, .022, .023] : [],
    );
  }

  @override
  void paint(Canvas c, Size size) {
    if (entry.tool) {
      final icons = [
        Icons.public,
        Icons.hub_outlined,
        Icons.route_outlined,
        Icons.search,
        Icons.compare_arrows,
        Icons.quiz_outlined,
      ];
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(icons[entry.index].codePoint),
          style: TextStyle(
            fontFamily: icons[entry.index].fontFamily,
            fontSize: 52,
            color: const Color(0xff245ce7),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      c.drawColor(const Color(0xffeef4fe), BlendMode.srcOver);
      tp.paint(
        c,
        Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2),
      );
      tp.dispose();
      return;
    }
    var picture = _pictures[entry.id];
    if (picture == null) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      painter().paint(canvas, const Size(360, 270));
      picture = recorder.endRecording();
      if (_pictures.length >= 24) {
        _pictures.remove(_pictures.keys.first)!.dispose();
      }
      _pictures[entry.id] = picture;
    }
    final scale = math.min(size.width / 360, size.height / 270);
    c.save();
    c.clipRect(Offset.zero & size);
    c.translate(
      (size.width - 360 * scale) / 2,
      (size.height - 270 * scale) / 2,
    );
    c.scale(scale);
    c.drawPicture(picture);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _Preview oldDelegate) =>
      oldDelegate.entry.id != entry.id;
}
