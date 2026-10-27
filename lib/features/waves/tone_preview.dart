import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../core/physics/waves_optics.dart';

/// Explicit playback of the generated educational signal, never recorded audio.
class TonePreview extends StatefulWidget {
  final Map<String, double> parameters;
  final int mode;
  const TonePreview({super.key, required this.parameters, required this.mode});
  @override
  State<TonePreview> createState() => _TonePreviewState();
}

class _TonePreviewState extends State<TonePreview> with WidgetsBindingObserver {
  static const channel = MethodChannel('physics_atelier/generated_audio');
  double volume = .08;
  bool busy = false;
  Timer? completion;
  String status =
      'Optional 2-second generated sound · microphone audio is never replayed.';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> stop() async {
    completion?.cancel();
    try {
      await channel.invokeMethod<void>('stop');
    } on PlatformException {
      /* Device cannot play this preview. */
    } on MissingPluginException {
      /* Unsupported platform. */
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) stop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stop();
    super.dispose();
  }

  Future<void> play() async {
    setState(() => busy = true);
    try {
      final p = widget.parameters;
      const rate = 16384;
      final samples = educationalSignal(
        rate * 2,
        rate,
        p['frequency']!,
        p['amplitude']!,
        p['frequency2']!,
        p['ratio']!,
        widget.mode,
      );
      final bytes = ByteData(samples.length * 2);
      for (var i = 0; i < samples.length; i++) {
        final envelope = math.min(
          1.0,
          math.min(i / 164, (samples.length - 1 - i) / 164),
        );
        bytes.setInt16(
          i * 2,
          (samples[i].clamp(-1, 1) * envelope * 32767).round(),
          Endian.little,
        );
      }
      await channel.invokeMethod<void>('play', {
        'pcm': bytes.buffer.asUint8List(),
        'rate': rate,
        'volume': volume,
      });
      if (mounted) {
        setState(
          () => status = 'Playing a 2-second generated preview. System media volume also applies.',
        );
        completion = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(
              () => status = 'Preview finished. Play again to compare the current settings.',
            );
          }
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(
          () => status = 'Audio preview is unavailable on this device. Waveform and spectrum remain available.',
        );
      }
    } on MissingPluginException {
      if (mounted) {
        setState(
          () => status = 'Audio preview is available in the Android app.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Listen to the generated signal',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(status),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              key: const Key('generated-audio-play'),
              onPressed: busy ? null : play,
              icon: const Icon(Icons.volume_up_outlined),
              label: const Text('Play 2 s'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                await stop();
                if (mounted) setState(() => status = 'Preview stopped.');
              },
              icon: const Icon(Icons.volume_off_outlined),
              label: const Text('Mute / stop'),
            ),
          ],
        ),
        Text('Preview volume: ${(volume * 100).round()}%'),
        Slider(
          value: volume,
          min: 0,
          max: .2,
          label: '${(volume * 100).round()}%',
          semanticFormatterCallback: (x) => '${(x * 100).round()} percent',
          onChanged: (x) async {
            await stop();
            if (mounted) {
              setState(() {
                volume = x;
                status = 'Volume changed. Play again to hear this level.';
              });
            }
          },
        ),
      ],
    );
  }
}
