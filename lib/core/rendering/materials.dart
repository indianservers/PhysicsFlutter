import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Deterministic apparatus materials. No motion or numerical state lives here.
class LabMaterials {
  // A unit mesh survives camera/position changes; at most four texture resources.
  static final _sphereMeshes =
      <ui.Image, ({ui.Vertices vertices, Paint paint})>{};
  static ({ui.Vertices vertices, Paint paint}) _mesh(ui.Image texture) {
    final existing = _sphereMeshes[texture];
    if (existing != null) return existing;
    if (_sphereMeshes.length >= 4) {
      final key = _sphereMeshes.keys.first;
      _sphereMeshes.remove(key)!.vertices.dispose();
    }
    final positions = <Offset>[], coords = <Offset>[], indices = <int>[];
    const n = 24;
    for (int j = 0; j <= n; j++) {
      final lat = -math.pi / 2 + j * math.pi / n;
      for (int i = 0; i <= n; i++) {
        final lon = -math.pi / 2 + i * math.pi / n;
        positions.add(Offset(math.cos(lat) * math.sin(lon), math.sin(lat)));
        coords.add(
          Offset(
            (.5 + lon / (2 * math.pi)) * texture.width,
            (.5 + lat / math.pi) * texture.height,
          ),
        );
        if (i < n && j < n) {
          final a = j * (n + 1) + i;
          indices.addAll([a, a + 1, a + n + 1, a + 1, a + n + 2, a + n + 1]);
        }
      }
    }
    final result = (
      vertices: ui.Vertices(
        ui.VertexMode.triangles,
        positions,
        textureCoordinates: coords,
        indices: indices,
      ),
      paint: Paint()
        ..shader = ui.ImageShader(
          texture,
          TileMode.clamp,
          TileMode.clamp,
          Float64List.fromList([
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            1,
          ]),
        ),
    );
    _sphereMeshes[texture] = result;
    return result;
  }

  static void shadow(Canvas c, Rect r) => c.drawOval(
    r,
    Paint()
      ..color = Colors.black.withValues(alpha: .16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
  );
  static void metal(Canvas c, Rect r, {bool brass = false}) {
    final colors = brass
        ? const [
            Color(0xff76511e),
            Color(0xfff6de93),
            Color(0xffbb8937),
            Color(0xffffe9aa),
            Color(0xff68491c),
          ]
        : const [
            Color(0xff52616a),
            Color(0xffeef4f5),
            Color(0xffa8b4b9),
            Color(0xfff9fbfc),
            Color(0xff566b77),
          ];
    c.drawRRect(
      RRect.fromRectAndRadius(
        r.shift(const Offset(1, 3)),
        const Radius.circular(3),
      ),
      Paint()..color = Colors.black.withValues(alpha: .12),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(
          colors: colors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(r),
    );
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)));
    for (double y = r.top + 1; y < r.bottom; y += 2.7) {
      c.drawLine(
        Offset(r.left, y),
        Offset(r.right, y + .3),
        Paint()
          ..color = Colors.white.withValues(alpha: .17)
          ..strokeWidth = .45,
      );
    }
    c.restore();
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(.4), const Radius.circular(3)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .65
        ..color = const Color(0xff536776),
    );
  }

  static void screw(Canvas c, Offset p) {
    c.drawCircle(p, 2, Paint()..color = const Color(0xff47535d));
    c.drawLine(
      p + const Offset(-1, -.5),
      p + const Offset(1, .5),
      Paint()
        ..color = const Color(0xffe1e8eb)
        ..strokeWidth = .7,
    );
  }

  static void wood(Canvas c, Rect r) {
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffe5bf85), Color(0xffb57a3a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(r),
    );
    c.save();
    c.clipRect(r);
    for (int i = 0; i < 22; i++) {
      final y = r.top + r.height * i / 22, path = Path()..moveTo(r.left, y);
      for (double x = r.left; x <= r.right; x += 4) {
        path.lineTo(x, y + math.sin(x * .07 + i) * .8);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xff6d431f).withValues(alpha: .18)
          ..strokeWidth = .55,
      );
    }
    c.restore();
  }

  static void sphere(
    Canvas c,
    Offset centre,
    double radius,
    Color color, {
    ui.Image? texture,
  }) {
    final rect = Rect.fromCircle(center: centre, radius: radius);
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.45),
          colors: [
            Color.lerp(color, Colors.white, .75)!,
            color,
            Color.lerp(color, Colors.black, .7)!,
          ],
        ).createShader(rect),
    );
    if (texture != null) {
      final mesh = _mesh(texture);
      c.save();
      c.translate(centre.dx, centre.dy);
      c.scale(radius);
      c.drawVertices(mesh.vertices, BlendMode.srcOver, mesh.paint);
      c.restore();
      c.drawCircle(
        centre,
        radius,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-.4, -.4),
            radius: 1.1,
            colors: [Colors.transparent, Color(0x10000000), Color(0xdd000b20)],
            stops: [0, .45, 1],
          ).createShader(rect),
      );
    }
    c.drawCircle(
      centre,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = .7
        ..color = Colors.white.withValues(alpha: .45),
    );
  }

  static void spring(
    Canvas c,
    Offset start,
    Offset end, {
    int turns = 14,
    double amplitude = 7,
  }) {
    final d = end - start, length = d.distance;
    if (length < 1) return;
    final u = d / length,
        normal = Offset(-u.dy, u.dx),
        path = Path()..moveTo(start.dx, start.dy);
    for (int i = 0; i <= turns * 12; i++) {
      final t = i / (turns * 12), taper = math.min(1, math.min(t, 1 - t) * 12);
      final p =
          start +
          d * t +
          normal * (amplitude * math.sin(t * turns * 2 * math.pi) * taper);
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      path.shift(const Offset(0, 1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..color = const Color(0xff35444d),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.9
        ..shader = const LinearGradient(
          colors: [Color(0xffeff3f5), Color(0xff87949c), Color(0xffe3e9ec)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromPoints(start, end).inflate(8)),
    );
  }
}
