import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import '../../core/physics/waves_optics.dart';

// Top-level callback avoids capturing a recorder/controller in an isolate closure.
Spectrum analyzePcm((List<double>, int) input) =>
    Spectrum.analyze(input.$1, input.$2);

/// No files, playback or network. PCM exists only in a bounded in-memory ring.
class LiveMicrophone extends ChangeNotifier {
  AudioRecorder? _recorder;
  StreamSubscription<Uint8List>? _bytes;
  StreamSubscription<RecordState>? _states;
  final buffer = PcmWindow();
  Spectrum? spectrum;
  List<double> frame = [];
  int rate = 48000, frames = 0, _generation = 0;
  bool active = false, requesting = false, analyzing = false, closed = false;
  String status = 'Microphone stopped. No input is generated or substituted.';
  final timer = Stopwatch()..start();
  int lastAnalysis = -100;
  double capturedSeconds = 0, frameEndTime = 0;
  Future<void> _stopping = Future<void>.value();
  Future<void> start() async {
    if (active || requesting || closed) return;
    final generation = ++_generation;
    requesting = true;
    status = 'Requesting microphone access…';
    notifyListeners();
    try {
      await _stopping;
      if (generation != _generation || closed) return;
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission()) {
        status = 'Microphone permission denied. Generated signal mode remains available offline.';
        return;
      }
      if (generation != _generation || closed) return;
      if (!await recorder.isEncoderSupported(AudioEncoder.pcm16bits)) {
        status = 'PCM16 streaming is unsupported on this device. Use generated mode.';
        return;
      }
      rate = 48000;
      buffer.channels = 1;
      buffer.clear();
      frame = [];
      spectrum = null;
      frames = 0;
      capturedSeconds = 0;
      frameEndTime = 0;
      await recorder.setOnConfigChanged((config) {
        rate = config.sampleRate;
        buffer.channels = config.numChannels;
        buffer.clear();
        status =
            'Listening · actual output $rate Hz, ${config.numChannels} channel(s), PCM16. No raw audio saved.';
      });
      _states ??= recorder.onStateChanged().listen(
        (state) {
          if (state != RecordState.record && active) {
            unawaited(stop());
          }
        },
        onError: (Object error) {
          status = 'Microphone interrupted. Generated mode is available.';
          unawaited(stop());
        },
      );
      final stream = await recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 48000,
          numChannels: 1,
          autoGain: false,
          echoCancel: false,
          noiseSuppress: false,
          streamBufferSize: 4096,
        ),
      );
      if (generation != _generation || closed) {
        await recorder.stop();
        return;
      }
      active = true;
      status = 'Listening · $rate Hz PCM16 · raw audio stays in memory.';
      _bytes = stream.listen(
        (bytes) {
          final before = buffer.receivedFrames;
          buffer.add(bytes);
          capturedSeconds += (buffer.receivedFrames - before) / rate;
          if (buffer.values.length >= 2048 &&
              !analyzing &&
              timer.elapsedMilliseconds - lastAnalysis >= 100) {
            lastAnalysis = timer.elapsedMilliseconds;
            analyzing = true;
            final captured = buffer.values.sublist(buffer.values.length - 2048),
                sampleRate = rate,
                endTime = capturedSeconds;
            compute(analyzePcm, (captured, sampleRate))
                .then((result) {
                  if (generation == _generation && active && !closed) {
                    frame = captured;
                    spectrum = result;
                    frameEndTime = endTime;
                    frames++;
                    notifyListeners();
                  }
                })
                .catchError((Object error) {
                  debugPrint('PCM analysis failed: $error');
                  if (!closed) {
                    status = 'Analysis failed; stop and retry.';
                    notifyListeners();
                  }
                })
                .whenComplete(() => analyzing = false);
          }
        },
        onError: (Object error) {
          status = 'Microphone stream failed. No generated data substituted.';
          unawaited(stop());
        },
      );
    } catch (_) {
      status = 'Microphone unavailable or permission blocked. Generated mode works without it.';
    } finally {
      requesting = false;
      if (!closed) notifyListeners();
    }
  }

  Future<void> stop() {
    _generation++;
    active = false;
    requesting = false;
    final subscription = _bytes;
    _bytes = null;
    _stopping = _stopping.then((_) async {
      await subscription?.cancel();
      try {
        await _recorder?.stop();
      } catch (_) {}
      buffer.clear();
      if (!status.contains('denied') &&
          !status.contains('failed') &&
          !status.contains('unavailable')) {
        status = 'Microphone stopped. Last analysis is held in memory; nothing saved automatically.';
      }
      if (!closed) notifyListeners();
    });
    return _stopping;
  }

  @override
  void dispose() {
    closed = true;
    _generation++;
    active = false;
    unawaited(_bytes?.cancel());
    unawaited(_states?.cancel());
    unawaited(_recorder?.dispose());
    buffer.clear();
    frame = [];
    super.dispose();
  }
}
