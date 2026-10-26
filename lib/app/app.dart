import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../content/catalog.dart';
import '../features/workbench/launchers.dart';
import '../content/learning.dart';
import '../features/astronomy/workspace.dart';
import '../features/overview/workspace.dart';
import '../features/overview/compare_workspace.dart';
import '../core/design_system/theme.dart';
import '../core/persistence/notebook.dart';
import '../features/lab_workspace/workspace.dart';
import '../features/dynamics/workspace.dart';
import '../features/advanced/workspace.dart';
import '../features/waves/workspace.dart';
import '../features/electromagnetism/workspace.dart';
import '../features/electronics_thermal/workspace.dart';
import '../features/fluid_modern/workspace.dart';

final notebookProvider = Provider<LocalNotebook>(
  (ref) => throw UnimplementedError('Initialize notebook'),
);
final router = GoRouter(
  observers: [dynamicsRouteObserver],
  routes: [
    GoRoute(path: '/', builder: (c, s) => const HomeScreen()),
    GoRoute(
      path: '/studio/:id',
      builder: (c, s) => StudioScreen(
        studio: studios.firstWhere((x) => x.id == s.pathParameters['id']),
      ),
    ),
    GoRoute(
      path: '/lab/:id',
      builder: (c, s) => entryById(s.pathParameters['id']!).tool
          ? (entryById(s.pathParameters['id']!).index == 4
                ? const CompareWorkspace()
                : OverviewWorkspace(
                    key: ValueKey(s.pathParameters['id']),
                    entry: entryById(s.pathParameters['id']!),
                  ))
          : entryById(s.pathParameters['id']!).astronomy
          ? AstronomyWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : entryById(s.pathParameters['id']!).fluidModern
          ? FMWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : entryById(s.pathParameters['id']!).electronicsThermal
          ? ETWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : entryById(s.pathParameters['id']!).electromagnetism
          ? EMWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : entryById(s.pathParameters['id']!).wavesOptics
          ? WaveWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : entryById(s.pathParameters['id']!).advanced
          ? AdvancedWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : entryById(s.pathParameters['id']!).dynamics
          ? DynamicsWorkspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            )
          : Workspace(
              key: ValueKey(s.pathParameters['id']),
              entry: entryById(s.pathParameters['id']!),
            ),
    ),
    GoRoute(path: '/notebook', builder: (c, s) => const NotebookScreen()),
    GoRoute(path: '/settings', builder: (c, s) => const SettingsScreen()),
  ],
  errorBuilder: (c, s) => Scaffold(
    appBar: AppBar(title: const Text('Destination unavailable')),
    body: Center(
      child: FilledButton(
        onPressed: () => c.go('/'),
        child: const Text('Return home'),
      ),
    ),
  ),
);

final appCaptureKey = GlobalKey();

class PhysicsApp extends ConsumerWidget {
  const PhysicsApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => RepaintBoundary(
    key: appCaptureKey,
    child: MaterialApp.router(
      title: 'Physics Atelier',
      debugShowCheckedModeBanner: false,
      theme: physicsTheme(),
      routerConfig: router,
    ),
  );
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  final String? scrollId;
  const PageBody({super.key, required this.children, this.scrollId});
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 1100),
      child: ListView(
        key: scrollId == null ? null : PageStorageKey(scrollId),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: children,
      ),
    ),
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const CompactHome();
}

class StudioScreen extends ConsumerWidget {
  final Studio studio;
  const StudioScreen({super.key, required this.studio});
  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      CompactStudio(studio: studio);
}

Future<void> exportTrials(BuildContext context, List<Trial> trials) async {
  if (trials.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record a trial before exporting.')),
    );
    return;
  }
  try {
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            utf8.encode(csvEncode(trials)),
            mimeType: 'text/csv',
            name: 'physics-results.csv',
          ),
        ],
        fileNameOverrides: ['physics-results.csv'],
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export could not open: $e')));
    }
  }
}

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (c, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Your notebook'),
          actions: [
            IconButton(
              tooltip: 'Export all trials as CSV',
              onPressed: store.trials.isEmpty
                  ? null
                  : () => exportTrials(context, store.trials),
              icon: const Icon(Icons.ios_share),
            ),
          ],
        ),
        body: SafeArea(
          child: PageBody(
            children: [
              const Eyebrow('Observations, kept locally'),
              const SizedBox(height: 12),
              Text(
                '${store.trials.length} recorded trials',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              if (store.recoveryMessage != null)
                Panel(child: Text(store.recoveryMessage!)),
              if (store.trials.isEmpty)
                const Panel(
                  child: Paragraph(
                    'A clean page for your discoveries',
                    'Record your first trial in a Measurement lab. Your readings, units, notes and apparatus configuration will appear here.',
                  ),
                ),
              for (final t in store.trials.reversed)
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entryById(t.labId).title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${t.value.toStringAsPrecision(6)} ${t.unit} · ${t.quantity}',
                      ),
                      Text(
                        t.created,
                        style: const TextStyle(color: muted, fontSize: 11),
                      ),
                      if (t.note.isNotEmpty) Text(t.note),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: () async {
                          await store.saveSession(t.labId, t.configuration);
                          if (context.mounted) {
                            context.push('/lab/${t.labId}');
                          }
                        },
                        child: const Text('Reopen this configuration'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (c, _) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: SafeArea(
          child: PageBody(
            children: [
              const Eyebrow('Make room for curiosity'),
              const SizedBox(height: 18),
              Panel(
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reduced motion'),
                      subtitle: const Text(
                        'Measurement track stays static. Dynamics hides trails; physics playback remains explicit.',
                      ),
                      value: store.reducedMotion,
                      onChanged: (v) => store.settings(motion: v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Haptic feedback'),
                      subtitle: const Text(
                        'A gentle tap when recording trials.',
                      ),
                      value: store.haptics,
                      onChanged: (v) => store.settings(touch: v),
                    ),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Open-source licenses'),
                onTap: () => showLicensePage(
                  context: c,
                  applicationName: 'Physics Atelier',
                  applicationVersion: '1.8.2+11',
                ),
              ),
              const Panel(
                child: Paragraph(
                  'Private by design',
                  'No login, backend or network is needed. Experiments and preferences are stored on this device. Exported CSV files contain only your actual observations.',
                ),
              ),
              const Panel(
                child: Paragraph(
                  'Scientific workspaces',
                  'Explore 96 labs and six concept tools. Experiments use documented models and assumptions. Trials and notes stay on this device; progress reflects completed investigations.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget relatedLabs(String id) {
  final links = relatedDestinations[id] ?? const <String>[];
  if (links.isEmpty) return const SizedBox.shrink();
  return Builder(
    builder: (context) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow(
            'Connected learning — return retains your current state',
          ),
          for (final target in links)
            TextButton.icon(
              onPressed: () => context.push('/lab/$target'),
              icon: const Icon(Icons.link),
              label: Text(entryById(target).title),
            ),
        ],
      ),
    ),
  );
}
