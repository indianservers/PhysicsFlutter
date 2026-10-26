import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart' show notebookProvider;
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/rendering/apparatus.dart' show StudioIllustration;
import 'lab_thumbnail.dart';

class CompactHome extends ConsumerStatefulWidget {
  const CompactHome({super.key});
  @override
  ConsumerState<CompactHome> createState() => _CompactHomeState();
}

class _CompactHomeState extends ConsumerState<CompactHome> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text(
            'Physics Atelier',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Your notebook',
              onPressed: () => context.push('/notebook'),
              icon: const Icon(Icons.menu_book_outlined),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: TextFormField(
                    key: const Key('search'),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search studios, labs and principles',
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => query = v),
                  ),
                ),
              ),
              if (query.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: store.lastLab == null
                        ? const ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Your first discovery starts here'),
                            subtitle: Text(
                              '17 studios · 96 labs · 6 learning tools',
                            ),
                          )
                        : ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.play_circle_outline,
                              color: cobalt,
                            ),
                            title: const Text('Continue Learning'),
                            subtitle: Text(
                              entryById(store.lastLab!).title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.push('/lab/${store.lastLab}'),
                          ),
                  ),
                ),
              if (query.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverLayoutBuilder(
                    builder: (context, b) {
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final cols = b.crossAxisExtent >= 700
                          ? 3
                          : b.crossAxisExtent < 300 || scale > 1.7
                          ? 1
                          : 2;
                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate((context, i) {
                          final studio = studios[i],
                              done = studio.entries
                                  .where((e) => store.completed.contains(e.id))
                                  .length;
                          return Card(
                            margin: const EdgeInsets.all(4),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () => context.push('/studio/${studio.id}'),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: CustomPaint(
                                        painter: StudioIllustration(i),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      10,
                                      4,
                                      10,
                                      10,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          studio.title,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          '$done/6 activities',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }, childCount: studios.length),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisExtent: cols == 1
                              ? 180 * math.max(1, scale)
                              : 170 * math.max(1, scale * .9),
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                      );
                    },
                  ),
                ),
              if (query.isNotEmpty)
                SliverList.list(
                  children: [
                    for (final studio in studios.where(
                      (s) =>
                          s.title.toLowerCase().contains(query.toLowerCase()),
                    ))
                      ListTile(
                        title: Text(studio.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/studio/${studio.id}'),
                      ),
                    for (final e in allEntries.where(
                      (e) => '${e.title} ${e.principle}'.toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                    ))
                      ListTile(
                        key: Key('search-result-${e.id}'),
                        title: Text(e.title),
                        subtitle: Text(studios[e.studioIndex].title),
                        leading: SizedBox(
                          width: 58,
                          height: 48,
                          child: LabThumbnail(e),
                        ),
                        onTap: () => context.push('/lab/${e.id}'),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompactStudio extends ConsumerWidget {
  final Studio studio;
  const CompactStudio({super.key, required this.studio});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text(
            studio.title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              tooltip: 'Studio guide',
              icon: const Icon(Icons.info_outline),
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Choose a lab to manipulate its apparatus. Learn, formulas, investigations and recorded results remain available from the workspace. Progress reflects completed activity.',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, b) {
              final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final cols = b.maxWidth < 330 || scale > 1.7
                  ? 1
                  : b.maxWidth > 900
                  ? 3
                  : 2;
              final tileHeight = cols == 1
                  ? 170 * math.max(1, scale)
                  : math.max(
                      170 * math.max(1, scale),
                      (b.maxHeight - 40) / 3 - 8,
                    );
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: 6,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisExtent: tileHeight.toDouble(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, i) {
                  final e = studio.entries[i],
                      done = store.completed.contains(e.id),
                      resume = store.lastLab == e.id;
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('launch-${e.id}'),
                      onTap: () => context.push('/lab/${e.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: LabThumbnail(e),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.title,
                              maxLines: 3,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              done
                                  ? 'Completed'
                                  : resume
                                  ? 'Resume'
                                  : 'Open ${e.tool ? 'tool' : 'experiment'}',
                              style: const TextStyle(fontSize: 12, color: teal),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
