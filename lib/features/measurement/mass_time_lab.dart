import '../../core/rendering/interactive_mechanics.dart';
import '../workbench/instrument_types.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'experiment.dart';

/// Live balance and track apparatus driven by the measurement experiment.
class MassTimeLab extends StatefulWidget {
  final Experiment experiment;
  const MassTimeLab({super.key, required this.experiment});
  @override
  State<MassTimeLab> createState() => _MassTimeLabState();
}

class _MassTimeLabState extends State<MassTimeLab> {
  Experiment get e => widget.experiment;
  int tab = 0;
  bool speedGraph = false;
  static const ink = Color(0xfff1f3ff);
  static const blue = Color(0xff0087ff);
  Widget text(
    String value,
    double size, {
    Color color = ink,
    FontWeight weight = FontWeight.w500,
  }) => Text(
    value,
    style: TextStyle(
      fontSize: size,
      color: color,
      fontWeight: weight,
      fontFamily: 'HomeManrope',
    ),
  );
  Widget panel(Widget child, {EdgeInsets padding = const EdgeInsets.all(18)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xe52a3641), Color(0xef071923)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: const Color(0xff506577), width: 1.5),
          borderRadius: BorderRadius.circular(22),
        ),
        child: child,
      );
  void change(VoidCallback action) {
    e.pause();
    action();
    e.resetTimer();
    e.changed();
  }

  void run() {
    e.running ? e.pause() : e.start();
  }

  Widget icon(IconData data, double size) => Icon(data, size: size, color: ink);
  Widget button(
    IconData data,
    String label,
    VoidCallback action, {
    bool primary = false,
  }) => GestureDetector(
    onTap: action,
    child: Container(
      height: 86,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary ? const Color(0xff62b7ff) : const Color(0xff647d92),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: primary
              ? [const Color(0xff098eff), const Color(0xff0060fa)]
              : [const Color(0xff263b4a), const Color(0xff152633)],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon(data, 38),
          if (label.isNotEmpty) ...[const SizedBox(width: 22), text(label, 28)],
        ],
      ),
    ),
  );
  Widget slider(
    String title,
    IconData symbol,
    double value,
    double min,
    double max,
    String label,
    String left,
    String right,
    ValueChanged<double> update,
  ) => panel(
    Row(
      children: [
        icon(symbol, 40),
        const SizedBox(width: 22),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              text(title, 23, weight: FontWeight.w600),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 11,
                  activeTrackColor: blue,
                  inactiveTrackColor: const Color(0xff455c70),
                  thumbColor: blue,
                  overlayColor: blue.withValues(alpha: .15),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 15,
                  ),
                ),
                child: Slider(
                  value: value.clamp(min, max),
                  min: min,
                  max: max,
                  onChanged: (v) => change(() => update(v)),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [text(left, 18), text(right, 18)],
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        SizedBox(
          width: 226,
          child: panel(
            Row(
              children: [
                Expanded(child: text(label, 28)),
                Column(
                  children: [
                    InkWell(
                      onTap: () => change(
                        () =>
                            update((value + (max - min) / 100).clamp(min, max)),
                      ),
                      child: icon(Icons.keyboard_arrow_up, 28),
                    ),
                    InkWell(
                      onTap: () => change(
                        () =>
                            update((value - (max - min) / 100).clamp(min, max)),
                      ),
                      child: icon(Icons.keyboard_arrow_down, 28),
                    ),
                  ],
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
        ),
      ],
    ),
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
  );
  void help() => showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Mass & Time'),
      content: const Text(
        'Adjust mass, track length and launch speed, then run the experiment. Position follows x = v₀t + ½at². Acceleration is 0.30 m/s² and is independent of mass. Use the graph selector to compare position and speed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c),
          child: const Text('Close'),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge([e, e.clockTick]),
    builder: (context, _) => Scaffold(
      backgroundColor: const Color(0xff071923),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final width = math.min(box.maxWidth, 941.0);
            return Center(
              child: SizedBox(
                width: width,
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 1672 * width / 941,
                    child: FittedBox(
                      alignment: Alignment.topCenter,
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: 941,
                        height: 1672,
                        child: DefaultTextStyle(
                          style: const TextStyle(
                            color: ink,
                            fontFamily: 'HomeManrope',
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Container(
                                  color: const Color(0xff081b28),
                                ),
                              ),
                              Positioned(
                                top: 202,
                                left: 0,
                                right: 0,
                                height: 408,
                                child: InteractiveMechanics(
                                  id: 's01-e04',
                                  parameters: {
                                    'a': e.a,
                                    'v0': e.v0,
                                    'distance': e.distance,
                                  },
                                  values: {
                                    'travelled': e.travelled,
                                    'timerReading': e.timerReading,
                                  },
                                  time: e.elapsed,
                                  pause: e.pause,
                                  play: e.start,
                                  controls: [
                                    InstrumentControl(
                                      'a',
                                      'Mass',
                                      'kg',
                                      e.a,
                                      .001,
                                      1,
                                      (v) => change(() => e.a = v),
                                    ),
                                    InstrumentControl(
                                      'v0',
                                      'Launch speed',
                                      'm/s',
                                      e.v0,
                                      0,
                                      2,
                                      (v) => change(() => e.v0 = v),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 132,
                                child: Container(
                                  color: const Color(0x99203040),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        onPressed: () =>
                                            context.go('/?tab=explore'),
                                        icon: icon(
                                          Icons.arrow_back_ios_new,
                                          36,
                                        ),
                                      ),
                                      const SizedBox(width: 58),
                                      icon(Icons.timer_outlined, 60),
                                      const SizedBox(width: 36),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            text(
                                              'Mass & Time',
                                              44,
                                              weight: FontWeight.w600,
                                            ),
                                            text(
                                              'Measure how mass and time affect motion',
                                              23,
                                              color: const Color(0xffc3d4ec),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: help,
                                        icon: icon(Icons.help_outline, 44),
                                      ),
                                      const SizedBox(width: 35),
                                      PopupMenuButton<String>(
                                        icon: icon(Icons.more_vert, 34),
                                        onSelected: (_) => help(),
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'help',
                                            child: Text('Experiment guide'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 132,
                                left: 39,
                                right: 25,
                                height: 70,
                                child: panel(
                                  Row(
                                    children: List.generate(
                                      4,
                                      (i) => Expanded(
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() => tab = i);
                                            // ignore: curly_braces_in_flow_control_structures
                                            if (i > 0) {
                                              showDialog<void>(
                                                context: context,
                                                builder: (c) => AlertDialog(
                                                  title: Text(
                                                    [
                                                      'Apparatus',
                                                      'Graph',
                                                      'Inspect',
                                                      'Results',
                                                    ][i],
                                                  ),
                                                  content: SizedBox(
                                                    width: 440,
                                                    height: i == 1 ? 320 : 180,
                                                    child: i == 1
                                                        ? CustomPaint(
                                                            painter: _MotionPlot(
                                                              e.v0,
                                                              e.acceleration,
                                                              speedGraph,
                                                            ),
                                                          )
                                                        : Text(
                                                            i == 2
                                                                ? 'Mass: ${(e.a * 1000).toStringAsFixed(2)} g\nTrack: ${(e.distance * 1000).round()} mm\nLaunch speed: ${e.v0.toStringAsFixed(2)} m/s\nAcceleration: ${e.acceleration.toStringAsFixed(2)} m/s²\nResolution: ${(e.resolution * 1000).round()} ms'
                                                                : 'Elapsed: ${e.timerReading.toStringAsFixed(3)} s\nPosition: ${e.travelled.toStringAsFixed(3)} m\nSpeed: ${(e.v0 + e.acceleration * e.elapsed).toStringAsFixed(3)} m/s\nPredicted finish: ${e.duration.toStringAsFixed(3)} s',
                                                          ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(c),
                                                      child: const Text(
                                                        'Close',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }
                                          },
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: tab == i
                                                  ? blue
                                                  : Colors.transparent,
                                              borderRadius:
                                                  BorderRadius.circular(38),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                icon(
                                                  [
                                                    Icons.science_outlined,
                                                    Icons.show_chart,
                                                    Icons.tune,
                                                    Icons.bar_chart,
                                                  ][i],
                                                  36,
                                                ),
                                                const SizedBox(width: 22),
                                                text(
                                                  [
                                                    'Apparatus',
                                                    'Graph',
                                                    'Inspect',
                                                    'Results',
                                                  ][i],
                                                  23,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              Positioned(
                                top: 620,
                                left: 19,
                                right: 18,
                                height: 131,
                                child: panel(
                                  Row(
                                    children: [
                                      Expanded(
                                        child: metric(
                                          Icons.shopping_bag,
                                          'Mass',
                                          '${(e.a * 1000).toStringAsFixed(2)} g',
                                          () => change(
                                            () => e.a = (e.a + .001).clamp(
                                              .001,
                                              1,
                                            ),
                                          ),
                                          () => change(
                                            () => e.a = (e.a - .001).clamp(
                                              .001,
                                              1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(
                                        color: Color(0xff64798c),
                                      ),
                                      Expanded(
                                        child: metric(
                                          Icons.speed,
                                          'Speed',
                                          '${(e.v0 + e.acceleration * e.elapsed).toStringAsFixed(3)} m/s',
                                          () => change(
                                            () =>
                                                e.v0 = (e.v0 + .05).clamp(0, 2),
                                          ),
                                          () => change(
                                            () =>
                                                e.v0 = (e.v0 - .05).clamp(0, 2),
                                          ),
                                        ),
                                      ),
                                      const VerticalDivider(
                                        color: Color(0xff64798c),
                                      ),
                                      Expanded(
                                        child: metric(
                                          Icons.timer_outlined,
                                          'Resolution',
                                          '${(e.resolution * 1000).toStringAsFixed(0)} ms',
                                          () => change(
                                            () => e.resolution =
                                                (e.resolution + .001).clamp(
                                                  .001,
                                                  .1,
                                                ),
                                          ),
                                          () => change(
                                            () => e.resolution =
                                                (e.resolution - .001).clamp(
                                                  .001,
                                                  .1,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 759,
                                left: 19,
                                right: 18,
                                height: 124,
                                child: slider(
                                  'Track Length',
                                  Icons.straighten,
                                  e.distance,
                                  .1,
                                  1,
                                  '${(e.distance * 1000).round()} mm',
                                  '100 mm',
                                  '1000 mm',
                                  (v) => e.distance = v,
                                ),
                              ),
                              Positioned(
                                top: 891,
                                left: 19,
                                right: 18,
                                height: 125,
                                child: slider(
                                  'Start Speed (Launch)',
                                  Icons.play_arrow,
                                  e.v0,
                                  0,
                                  2,
                                  '${e.v0.toStringAsFixed(2)} m/s',
                                  '0 m/s',
                                  '2.0 m/s',
                                  (v) => e.v0 = v,
                                ),
                              ),
                              Positioned(
                                top: 1031,
                                left: 24,
                                right: 23,
                                height: 86,
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 55,
                                      child: button(
                                        e.running
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                        e.running
                                            ? 'Pause Experiment'
                                            : 'Run Experiment',
                                        run,
                                        primary: true,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      flex: 24,
                                      child: button(
                                        Icons.restart_alt,
                                        'Reset',
                                        e.reset,
                                      ),
                                    ),
                                    const SizedBox(width: 17),
                                    Expanded(
                                      flex: 10,
                                      child: button(
                                        Icons.settings_outlined,
                                        '',
                                        help,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: 1136,
                                left: 19,
                                width: 496,
                                height: 362,
                                child: panel(
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.show_chart,
                                            color: Colors.lightBlueAccent,
                                            size: 35,
                                          ),
                                          const SizedBox(width: 12),
                                          text('Live Graph', 23),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: DropdownButton<bool>(
                                              isExpanded: true,
                                              value: speedGraph,
                                              style: const TextStyle(
                                                color: ink,
                                                fontFamily: 'HomeManrope',
                                                fontSize: 18,
                                              ),
                                              dropdownColor: const Color(
                                                0xff132b3c,
                                              ),
                                              items: const [
                                                DropdownMenuItem(
                                                  value: false,
                                                  child: Text(
                                                    'Position vs Time',
                                                  ),
                                                ),
                                                DropdownMenuItem(
                                                  value: true,
                                                  child: Text('Speed vs Time'),
                                                ),
                                              ],
                                              onChanged: (v) => setState(
                                                () => speedGraph = v!,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Expanded(
                                        child: CustomPaint(
                                          painter: _MotionPlot(
                                            e.v0,
                                            e.acceleration,
                                            speedGraph,
                                          ),
                                          size: Size.infinite,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 1136,
                                left: 530,
                                right: 18,
                                height: 362,
                                child: panel(
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          icon(Icons.table_chart_outlined, 28),
                                          const SizedBox(width: 18),
                                          text('Real-time Data', 23),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Expanded(
                                        child: Table(
                                          border: TableBorder.all(
                                            color: const Color(0xff304d63),
                                          ),
                                          children: [
                                            TableRow(
                                              decoration: const BoxDecoration(
                                                color: Color(0xff1b324b),
                                              ),
                                              children:
                                                  [
                                                        'Time (s)',
                                                        'Position (m)',
                                                        'Speed (m/s)',
                                                      ]
                                                      .map(
                                                        (s) => Padding(
                                                          padding:
                                                              const EdgeInsets.symmetric(
                                                                vertical: 12,
                                                              ),
                                                          child: Center(
                                                            child: text(s, 17),
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),
                                            ),
                                            ...List.generate(6, (i) {
                                              final t = i * .1;
                                              return TableRow(
                                                children:
                                                    [
                                                          t.toStringAsFixed(3),
                                                          (e.v0 * t +
                                                                  .5 *
                                                                      e.acceleration *
                                                                      t *
                                                                      t)
                                                              .toStringAsFixed(
                                                                3,
                                                              ),
                                                          (e.v0 +
                                                                  e.acceleration *
                                                                      t)
                                                              .toStringAsFixed(
                                                                2,
                                                              ),
                                                        ]
                                                        .map(
                                                          (s) => Padding(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  vertical: 8,
                                                                ),
                                                            child: Center(
                                                              child: text(
                                                                s,
                                                                18,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                        .toList(),
                                              );
                                            }),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 1526,
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: panel(
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceAround,
                                    children: List.generate(
                                      4,
                                      (i) => GestureDetector(
                                        onTap: () => i == 3
                                            ? help()
                                            : context.go(
                                                i == 0
                                                    ? '/'
                                                    : i == 1
                                                    ? '/?tab=explore'
                                                    : '/?tab=saved',
                                              ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              [
                                                Icons.home_rounded,
                                                Icons.grid_view_rounded,
                                                Icons.bookmark_border,
                                                Icons.settings_outlined,
                                              ][i],
                                              color: i == 1
                                                  ? blue
                                                  : const Color(0xffbdd0ef),
                                              size: 40,
                                            ),
                                            const SizedBox(height: 12),
                                            text(
                                              [
                                                'Home',
                                                'Explore',
                                                'Saved',
                                                'Settings',
                                              ][i],
                                              22,
                                              color: i == 1
                                                  ? blue
                                                  : const Color(0xffbdd0ef),
                                            ),
                                          ],
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
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  Widget metric(
    IconData symbol,
    String label,
    String value,
    VoidCallback up,
    VoidCallback down,
  ) => Row(
    children: [
      icon(symbol, 44),
      const SizedBox(width: 20),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            text(label, 18, color: const Color(0xffc4d0e6)),
            const SizedBox(height: 8),
            FittedBox(child: text(value, 34, weight: FontWeight.w600)),
          ],
        ),
      ),
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(onTap: up, child: icon(Icons.keyboard_arrow_up, 28)),
          InkWell(onTap: down, child: icon(Icons.keyboard_arrow_down, 28)),
        ],
      ),
    ],
  );
}

class _MotionPlot extends CustomPainter {
  final double v, a;
  final bool speed;
  _MotionPlot(this.v, this.a, this.speed);
  @override
  void paint(Canvas canvas, Size size) {
    final area = Rect.fromLTWH(65, 24, size.width - 80, size.height - 78);
    final grid = Paint()
      ..color = const Color(0xff294656)
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = const Color(0xffd2dcec)
      ..strokeWidth = 1.5;
    void label(String s, Offset p) {
      final tp = TextPainter(
        text: TextSpan(
          text: s,
          style: const TextStyle(color: Color(0xffe0eaff), fontSize: 15),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, p);
    }

    final maxY = speed ? 1.0 : math.max(.5, v * 2.2 + .5 * a * 2.2 * 2.2);
    for (int i = 0; i <= 10; i++) {
      final x = area.left + area.width * i / 10;
      final y = area.bottom - area.height * i / 10;
      canvas.drawLine(Offset(x, area.top), Offset(x, area.bottom), grid);
      canvas.drawLine(Offset(area.left, y), Offset(area.right, y), grid);
      if (i % 2 == 0) {
        label((maxY * i / 10).toStringAsFixed(1), Offset(26, y - 8));
        label(
          (2.2 * i / 10).toStringAsFixed(1),
          Offset(x - 10, area.bottom + 14),
        );
      }
    }
    canvas.drawLine(area.bottomLeft, area.topLeft, axis);
    canvas.drawLine(area.bottomLeft, area.bottomRight, axis);
    final path = Path();
    final line = Paint()
      ..color = const Color(0xff008bff)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (int i = 0; i <= 100; i++) {
      final t = 2.2 * i / 100;
      final y = speed ? v + a * t : v * t + .5 * a * t * t;
      final p = Offset(
        area.left + area.width * i / 100,
        area.bottom - y / maxY * area.height,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
      if (i % 10 == 0) {
        canvas.drawCircle(p, 4, Paint()..color = const Color(0xff0796ff));
      }
    }
    canvas.drawPath(path, line);
    label('Time (s)', Offset(area.center.dx - 30, size.height - 21));
    canvas.save();
    canvas.translate(3, area.center.dy + 50);
    canvas.rotate(-math.pi / 2);
    label(speed ? 'Speed (m/s)' : 'Position (m)', Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MotionPlot old) =>
      old.v != v || old.a != a || old.speed != speed;
}
