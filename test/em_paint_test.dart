import 'package:flutter_test/flutter_test.dart';
import 'package:physics_atelier/core/physics/electromagnetism.dart';
import 'package:physics_atelier/features/electromagnetism/curriculum.dart';
import 'package:physics_atelier/features/electromagnetism/scene.dart';

void main() {
  test(
    'EM repaint snapshots include physics, layout and presentation changes',
    () {
      final run = EMRun(4, emLessons[4].defaults);
      final first = EMPainter(run);
      expect(EMPainter(run).shouldRepaint(first), isFalse);
      run.refresh();
      expect(EMPainter(run).shouldRepaint(first), isTrue);
      final next = EMPainter(run);
      run.circuit.parts.first.x += .1;
      expect(EMPainter(run).shouldRepaint(next), isTrue);
      final last = EMPainter(run);
      expect(EMPainter(run, overlays: false).shouldRepaint(last), isTrue);
      expect(EMPainter(run, azimuth: 1).shouldRepaint(last), isTrue);
      expect(EMPainter(run, selected: 'R1').shouldRepaint(last), isTrue);
    },
  );
}
