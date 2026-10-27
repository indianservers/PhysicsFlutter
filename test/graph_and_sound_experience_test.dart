import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/features/advanced/scene.dart';
import 'package:physics_atelier/features/workbench/graph_measurement.dart';
import 'package:physics_atelier/features/waves/tone_preview.dart';

void main() {
  testWidgets(
    'Interval tools recover analytic slope and area without changing the curve',
    (t) async {
      final data = [
        {'t': 0.0, 'x': 1.0},
        {'t': 1.0, 'x': 3.0},
        {'t': 2.0, 'x': 5.0},
      ];
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GraphMeasurement(
                LabPlot(data, ['x'], 'Physical time (s)', 'm', 0),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Secant slope Δy/Δx: 2 m/(s)'), findsOneWidget);
      expect(
        find.text('Signed area (trapezoidal approximation): 6 m·(s)'),
        findsOneWidget,
      );
      t.widget<RangeSlider>(find.byType(RangeSlider)).onChanged!(
        const RangeValues(.5, 1),
      );
      await t.pumpAndSettle();
      expect(
        find.text('Signed area (trapezoidal approximation): 4 m·(s)'),
        findsOneWidget,
      );
      expect(data, [
        {'t': 0.0, 'x': 1.0},
        {'t': 1.0, 'x': 3.0},
        {'t': 2.0, 'x': 5.0},
      ]);
    },
  );
  testWidgets(
    'Histogram keeps discrete rendering and does not imply a continuous area',
    (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GraphMeasurement(
                const LabPlot(
                  [
                    {'t': 0.0, 'count': 2.0},
                    {'t': 1.0, 'count': 3.0},
                  ],
                  ['count'],
                  'Position (m)',
                  'count',
                  0,
                  histogramKeys: {'count'},
                ),
              ),
            ),
          ),
        ),
      );
      expect(
        find.textContaining('Signed area (trapezoidal approximation):'),
        findsNothing,
      );
      final paint = t
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<LabPlot>()
          .single;
      expect(paint.histogramKeys, {'count'});
    },
  );
  testWidgets(
    'Generated preview is explicit, bounded PCM and stops on disposal',
    (t) async {
      const channel = MethodChannel('physics_atelier/generated_audio');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );
      await t.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TonePreview(
              parameters: {
                'frequency': 440,
                'frequency2': 880,
                'amplitude': .6,
                'ratio': .5,
              },
              mode: 0,
            ),
          ),
        ),
      );
      expect(calls, isEmpty);
      await t.tap(find.byKey(const Key('generated-audio-play')));
      await t.pumpAndSettle();
      final play = calls.single;
      expect(play.method, 'play');
      expect(play.arguments['rate'], 16384);
      expect(play.arguments['volume'], lessThanOrEqualTo(.2));
      final pcm = (play.arguments['pcm'] as Uint8List);
      expect(pcm.length, 65536);
      final samples = ByteData.sublistView(pcm);
      expect(samples.getInt16(0, Endian.little), 0);
      expect(samples.getInt16(pcm.length - 2, Endian.little), 0);
      await t.pumpWidget(const SizedBox());
      await t.pumpAndSettle();
      expect(calls.last.method, 'stop');
      expect(t.takeException(), isNull);
    },
  );
}
