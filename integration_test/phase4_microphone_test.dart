import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:physics_atelier/main.dart' as app;
import 'package:physics_atelier/app/app.dart';
import 'package:physics_atelier/features/waves/workspace.dart';
import 'package:physics_atelier/core/persistence/notebook.dart';

import 'phase1_test.dart' show capture, show, top;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const allow = bool.fromEnvironment('ALLOW_MIC');
  testWidgets(
    'Native microphone ${allow ? 'PCM capture' : 'permission denial'}',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();
      router.go('/lab/s08-e04');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Experiment').last);
      await tester.pumpAndSettle();
      await show(tester, find.text('Restore documented defaults'));
      await tester.tap(find.text('Restore documented defaults'));
      await tester.pumpAndSettle();
      await show(tester, find.text('Device microphone input'));
      await tester.tap(find.text('Device microphone input'));
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
            tester.element(find.byType(WaveWorkspace)),
          ),
          mic = container.read(liveMicrophoneProvider);
      await show(tester, find.byKey(const Key('start-microphone')));
      await tester.tap(find.byKey(const Key('start-microphone')));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(seconds: 3)),
      );
      await tester.pump();
      if (!allow) {
        expect(mic.active, isFalse);
        expect(mic.status.toLowerCase(), contains('denied'));
        await capture(tester, binding, 'phase4-microphone-denied');
        await show(tester, find.text('Device microphone input'));
        await tester.tap(find.text('Device microphone input'));
        await tester.pumpAndSettle();
        await show(tester, find.byKey(const Key('record-waves')));
        await tester.tap(find.byKey(const Key('record-waves')));
        await tester.pumpAndSettle();
        final store = LocalNotebook();
        await store.initialize();
        expect(store.trials.last.configuration['input'], 'generated/model');
        binding.reportData!['phase4MicrophoneDenied'] = {
          'permissionDeniedVerified': true,
          'generatedFallbackVerified': true,
          'nativeCaptureTest': false,
        };
      } else {
        expect(mic.active, isTrue, reason: mic.status);
        expect(mic.frames, greaterThan(0), reason: mic.status);
        expect(mic.frame.length, 2048);
        expect(mic.spectrum!.sampleRate, mic.rate);
        expect(mic.frame.every((x) => x.isFinite && x >= -1 && x <= 1), isTrue);
        final frames = mic.frames,
            rate = mic.rate,
            rms = mic.spectrum!.rms,
            peak = mic.spectrum!.peakFrequency;
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        await mic.stop();
        await tester.pumpAndSettle();
        expect(mic.active, isFalse);
        await capture(tester, binding, 'phase4-microphone-captured-stopped');
        await show(tester, find.byKey(const Key('record-waves')));
        await tester.enterText(
          find.byType(TextField).last,
          'Actual Android PCM analysis; emulator input may be silence. No raw audio saved.',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('record-waves')));
        await tester.pumpAndSettle();
        final store = LocalNotebook();
        await store.initialize();
        final trial = store.trials.last;
        expect(trial.configuration['input'], 'microphone');
        expect(trial.configuration.containsKey('spatialProfile'), isFalse);
        expect(trial.configuration.containsKey('signal'), isFalse);
        expect(
          (trial.configuration['savedAnalysis']['bins'] as List).length,
          1025,
        );
        expect(trial.value, closeTo(peak, 1e-9));
        ScaffoldMessenger.of(tester.element(find.byType(Scaffold).last))
            .clearSnackBars();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Results').last);
        await tester.pumpAndSettle();
        await show(tester, find.text('Reopen configuration'));
        await tester.tap(find.text('Reopen configuration').first);
        await tester.pumpAndSettle();
        expect(mic.active, isFalse);
        await top(tester);
        await capture(tester, binding, 'phase4-microphone-analysis-restored');
        binding.reportData!['phase4Microphone'] = {
          'actualNativePcmCapture': true,
          'analyzedFrames': frames,
          'outputSampleRate': rate,
          'windowSamples': 2048,
          'rmsFullScale': rms,
          'peakBinHz': peak,
          'rawAudioSaved': false,
          'backgroundStopped': true,
          'explicitAnalysisRestore': true,
          'signalQualification': 'Emulator native PCM stream; no acoustic calibration or known physical test tone. Silence is a valid actual input.',
        };
      }
    },
  );
}
