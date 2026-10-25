import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../content/catalog.dart';
import '../core/design_system/theme.dart';
import '../core/persistence/notebook.dart';
import '../core/rendering/apparatus.dart';
import '../features/lab_workspace/workspace.dart';
import '../features/dynamics/workspace.dart';
import '../features/advanced/workspace.dart';
import '../features/waves/workspace.dart';

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
      builder: (c, s) => entryById(s.pathParameters['id']!).wavesOptics
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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeState();
}

class _HomeState extends ConsumerState<HomeScreen> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (c, _) => Scaffold(
        appBar: AppBar(
          title: const Row(
            children: [
              Icon(Icons.science_outlined, color: cobalt),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'PHYSICS ATELIER',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'Notebook',
              onPressed: () => context.push('/notebook'),
              icon: const Icon(Icons.auto_stories_outlined),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: SafeArea(
          child: PageBody(
            children: [
              const SizedBox(height: 16),
              const Eyebrow('A laboratory for curious minds'),
              const SizedBox(height: 12),
              Text(
                'Understand the world.\nOne experiment at a time.',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Explore the ideas. Handle the instruments.\nBuild an intuition for physics.',
                style: TextStyle(color: muted, height: 1.6),
              ),
              const SizedBox(height: 24),
              TextField(
                key: const Key('search'),
                onChanged: (v) => setState(() => query = v),
                decoration: const InputDecoration(
                  hintText: 'Search 17 studios & 102 entries',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 22),
              if (query.isNotEmpty) ...[
                Text(
                  'Search results',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                for (final s in studios.where(
                  (s) => s.title.toLowerCase().contains(query.toLowerCase()),
                ))
                  Panel(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.title),
                      subtitle: const Text('Studio · 6 entries'),
                      trailing: const Icon(Icons.arrow_forward),
                      onTap: () => context.push('/studio/${s.id}'),
                    ),
                  ),
                for (final e in allEntries.where(
                  (e) =>
                      e.title.toLowerCase().contains(query.toLowerCase()) ||
                      e.principle.toLowerCase().contains(query.toLowerCase()),
                ))
                  Panel(
                    child: ListTile(
                      key: Key('search-result-${e.id}'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(e.title),
                      subtitle: Text(
                        '${studios[e.studioIndex].title}\n${e.availability}',
                      ),
                      isThreeLine: true,
                      onTap: () => context.push('/lab/${e.id}'),
                    ),
                  ),
                if (!allEntries.any(
                      (e) =>
                          e.title.toLowerCase().contains(query.toLowerCase()) ||
                          e.principle.toLowerCase().contains(
                            query.toLowerCase(),
                          ),
                    ) &&
                    !studios.any(
                      (s) =>
                          s.title.toLowerCase().contains(query.toLowerCase()),
                    ))
                  const Panel(
                    child: Text(
                      'No matches. Try “Measurement”, “energy” or “orbits”.',
                    ),
                  ),
              ] else ...[
                Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('Your learning journey'),
                      const SizedBox(height: 10),
                      Text(
                        store.lastLab == null
                            ? 'Your first discovery starts here'
                            : 'Continue learning',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        store.lastLab == null
                            ? 'No activity yet. Begin with Measurement and learn to read a scale.'
                            : '${entryById(store.lastLab!).title} · ${studios[entryById(store.lastLab!).studioIndex].title}',
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => context.push(
                          store.lastLab == null
                              ? '/studio/s01'
                              : '/lab/${store.lastLab}',
                        ),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: Text(
                          store.lastLab == null
                              ? 'Explore Measurement'
                              : 'Resume activity',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 14,
                  children: [
                    Text(
                      'Explore the studios',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      '${store.completed.length}/102 activities completed',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  '17 studios · 96 labs · 6 learning tools',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, box) {
                    final columns = box.maxWidth > 800
                        ? 3
                        : box.maxWidth > 560
                        ? 2
                        : 1;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        for (int i = 0; i < studios.length; i++)
                          SizedBox(
                            width:
                                (box.maxWidth - 16 * (columns - 1)) / columns,
                            child: StudioCard(index: i, store: store),
                          ),
                      ],
                    );
                  },
                ),
              ],
              const SizedBox(height: 24),
              const Center(
                child: Text(
                  'DESIGNED FOR DISCOVERY · WORKS OFFLINE',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StudioCard extends StatelessWidget {
  final int index;
  final LocalNotebook store;
  const StudioCard({super.key, required this.index, required this.store});
  @override
  Widget build(BuildContext context) {
    final s = studios[index];
    final count = s.entries.where((e) => store.completed.contains(e.id)).length;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/studio/${s.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              label: '${s.title} scientific illustration, simplified model',
              image: true,
              child: SizedBox(
                height: 145,
                width: double.infinity,
                child: CustomPaint(painter: StudioIllustration(index)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${(index + 1).toString().padLeft(2, '0')}  /  ${index == 0 ? '6 TOOLS' : '6 LABS'}',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 10,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(s.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(
                    index >= 1 && index <= 9
                        ? '● Six interactive labs'
                        : index == 0
                        ? 'Introductory navigation tools'
                        : 'Learning content available',
                    style: TextStyle(
                      color: index >= 1 && index <= 9 ? teal : muted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 15),
                  LinearProgressIndicator(
                    value: count / 6,
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(5),
                    backgroundColor: const Color(0xffedf1f7),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$count of 6 completed',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudioScreen extends ConsumerWidget {
  final Studio studio;
  const StudioScreen({super.key, required this.studio});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final index = studios.indexOf(studio), store = ref.watch(notebookProvider);
    return Scaffold(
      appBar: AppBar(title: Text(studio.title)),
      body: SafeArea(
        child: PageBody(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 190,
                child: CustomPaint(painter: StudioIllustration(index)),
              ),
            ),
            const SizedBox(height: 24),
            Eyebrow(
              'Studio ${(index + 1).toString().padLeft(2, '0')} · Recommended order',
            ),
            const SizedBox(height: 10),
            Text(
              studio.title,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 10),
            Text(
              index == 1
                  ? 'Precision begins with observation. Learn six essential measurement techniques with instruments you can manipulate.'
                  : 'Explore ${studio.title.toLowerCase()} through six connected ideas. Read the theory and formulas in order, or follow your curiosity.',
            ),
            const SizedBox(height: 20),
            for (final e in studio.entries)
              Panel(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: const Color(0xffedf3ff),
                    child: Text(
                      '${e.index + 1}',
                      style: const TextStyle(color: cobalt),
                    ),
                  ),
                  title: Text(
                    e.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Text(
                      '${e.principle}\n${e.availability}${store.completed.contains(e.id) ? ' · Completed' : ''}',
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: cobalt),
                  onTap: () => context.push('/lab/${e.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
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
              const Panel(
                child: Paragraph(
                  'Private by design',
                  'No login, backend or network is needed. Experiments and preferences are stored on this device. Exported CSV files contain only your actual observations.',
                ),
              ),
              const Panel(
                child: Paragraph(
                  'Phase 4 of 9 · Waves, Sound & Optics',
                  '54 interactive labs across nine studios; 17 studios and 102 destinations. The remaining experiments follow the nine-phase roadmap. Illustrative apparatus and explicit model assumptions accompany calculated observations.',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
