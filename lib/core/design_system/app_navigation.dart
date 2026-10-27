import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'theme.dart';

const _ink = navy, _blue = cobalt;

class HomeNavigation extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const HomeNavigation({
    super.key,
    required this.selected,
    required this.onSelect,
  });
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      margin: const EdgeInsets.fromLTRB(21, 2, 21, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xffe7edf5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080c3b71),
            blurRadius: 16,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          for (int i = 0; i < 4; i++)
            Expanded(
              child: Semantics(
                selected: selected == i,
                button: true,
                child: InkWell(
                  key: Key(
                    'home-nav-${['home', 'explore', 'saved', 'settings'][i]}',
                  ),
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HomeGlyph(
                          [
                            HomeSymbol.home,
                            HomeSymbol.explore,
                            HomeSymbol.saved,
                            HomeSymbol.settings,
                          ][i],
                          size: 20,
                          color: selected == i ? _blue : muted,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          ['Home', 'Explore', 'Saved', 'Settings'][i],
                          maxLines:
                              MediaQuery.textScalerOf(context).scale(1) > 1.4
                              ? 2
                              : 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected == i ? _blue : muted,
                            fontWeight: selected == i
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                        Container(
                          height: 2,
                          width: 29,
                          margin: const EdgeInsets.only(top: 5),
                          decoration: BoxDecoration(
                            color: selected == i ? _blue : Colors.transparent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ],
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

enum HomeSymbol { home, explore, saved, settings, search, arrow }

class HomeGlyph extends StatelessWidget {
  final HomeSymbol symbol;
  final double size;
  final Color color;
  const HomeGlyph(this.symbol, {super.key, this.size = 22, this.color = _ink});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter(symbol, color)),
    ),
  );
}

class _GlyphPainter extends CustomPainter {
  final HomeSymbol symbol;
  final Color color;
  _GlyphPainter(this.symbol, this.color);
  @override
  void paint(Canvas c, Size s) {
    c.scale(s.width / 24, s.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    switch (symbol) {
      case HomeSymbol.home:
        c.drawPath(
          Path()
            ..moveTo(3, 11)
            ..lineTo(12, 3)
            ..lineTo(21, 11)
            ..lineTo(21, 22)
            ..lineTo(14, 22)
            ..lineTo(14, 15)
            ..lineTo(10, 15)
            ..lineTo(10, 22)
            ..lineTo(3, 22)
            ..close(),
          p..style = PaintingStyle.fill,
        );
      case HomeSymbol.explore:
        for (final o in [
          const Offset(3, 3),
          const Offset(14, 3),
          const Offset(3, 14),
          const Offset(14, 14),
        ]) {
          c.drawRRect(
            RRect.fromRectAndRadius(
              o & const Size(7, 7),
              const Radius.circular(.5),
            ),
            p,
          );
        }
      case HomeSymbol.saved:
        c.drawPath(
          Path()
            ..moveTo(5, 3)
            ..lineTo(19, 3)
            ..lineTo(19, 22)
            ..lineTo(12, 17)
            ..lineTo(5, 22)
            ..close(),
          p,
        );
      case HomeSymbol.search:
        c.drawCircle(const Offset(10, 10), 7.3, p);
        c.drawLine(const Offset(15.5, 15.5), const Offset(22, 22), p);
      case HomeSymbol.arrow:
        c.drawPath(
          Path()
            ..moveTo(5, 19)
            ..lineTo(19, 5)
            ..moveTo(8, 5)
            ..lineTo(19, 5)
            ..lineTo(19, 16),
          p,
        );
      case HomeSymbol.settings:
        final path = Path();
        for (int i = 0; i < 64; i++) {
          final a = i * math.pi / 32, r = i % 8 < 4 ? 10.5 : 8.5;
          final point = Offset(12 + r * math.cos(a), 12 + r * math.sin(a));
          if (i == 0) {
            path.moveTo(point.dx, point.dy);
          } else {
            path.lineTo(point.dx, point.dy);
          }
        }
        c.drawPath(path..close(), p);
        c.drawCircle(const Offset(12, 12), 3.5, p);
    }
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      symbol != old.symbol || color != old.color;
}
