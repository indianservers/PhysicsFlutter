import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart' show notebookProvider;
import '../../content/catalog.dart';
import '../../core/design_system/reference_style.dart';
import '../../core/design_system/theme.dart';
import '../home/home_screen.dart' show HomeArtwork;
import '../home/studio_registry.dart';
import '../workbench/lab_thumbnail.dart';
import '../workbench/exploration_workbench.dart';

class CompactStudio extends ConsumerStatefulWidget {
  final Studio studio;
  const CompactStudio({super.key, required this.studio});
  @override
  ConsumerState<CompactStudio> createState() => _CompactStudioState();
}

class _CompactStudioState extends ConsumerState<CompactStudio> {
  final search = TextEditingController(), scroll = ScrollController();
  String query = '', filter = 'All';
  Studio get studio => widget.studio;
  HomeStudio get presentation =>
      homeStudios.firstWhere((s) => s.studio.id == studio.id);
  void reset() {
    FocusScope.of(context).unfocus();
    search.clear();
    setState(() {
      query = '';
      filter = 'All';
    });
  }

  @override
  void didUpdateWidget(covariant CompactStudio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.studio.id != studio.id) {
      search.clear();
      query = '';
      filter = 'All';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.jumpTo(0);
        }
      });
    }
  }

  @override
  void dispose() {
    search.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final entries = studio.entries.where((e) {
          final matches = '${e.title} ${e.principle}'.toLowerCase().contains(
            query.trim().toLowerCase(),
          );
          return matches &&
              (filter == 'All' ||
                  filter == 'Saved' && store.favorites.contains(e.id) ||
                  filter == 'Completed' && store.completed.contains(e.id));
        }).toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(
              studio.title,
              maxLines: 2,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Studio guide',
                icon: const Icon(Icons.info_outline),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (sheetContext) => SafeArea(
                    child: SizedBox(
                      height: MediaQuery.sizeOf(sheetContext).height * .7,
                      child: ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Text(
                            'Explore ${studio.title}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 10),
                          Text(presentation.description),
                          const SizedBox(height: 12),
                          const Text(
                            'Choose a lab. Read its illustrated guide, manipulate the live apparatus, make a prediction and save your observations. Learning progress reflects your completed activities.',
                          ),
                          for (final e in studio.entries)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(e.title),
                              subtitle: Text(e.principle),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () {
                                Navigator.pop(sheetContext);
                                context.push('/lab/${e.id}');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: ReferenceNavigation(
            selected: 1,
            homeFirst: true,
            onLabs: reset,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, bounds) {
                final scale = MediaQuery.textScalerOf(context).scale(1);
                final cols = bounds.maxWidth < 360 || scale > 1.5
                    ? 1
                    : bounds.maxWidth > 1000
                    ? 4
                    : bounds.maxWidth > 700
                    ? 3
                    : 2;
                return CustomScrollView(
                  key: PageStorageKey('studio-${studio.id}'),
                  controller: scroll,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: OutlinedButton.icon(
                          key: const Key('studio-exploration-tools'),
                          onPressed: () =>
                              showStudioTools(context, studios.indexOf(studio)),
                          icon: const Icon(Icons.travel_explore),
                          label: const Text('10 studio tools'),
                        ),
                      ),
                    ),
                    if (query.trim().isEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                        sliver: SliverToBoxAdapter(
                          child: LayoutBuilder(
                            builder: (context, box) {
                              final description = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    presentation.description,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${studio.entries.length} ${studio.id == 's00' ? 'learning tools' : 'interactive labs'}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: cobalt,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              );
                              final art = SizedBox(
                                height: 112,
                                child: HomeArtwork(presentation.artwork),
                              );
                              return scale > 1.5
                                  ? Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [art, description],
                                    )
                                  : Row(
                                      children: [
                                        Expanded(flex: 5, child: description),
                                        const SizedBox(width: 10),
                                        Expanded(flex: 5, child: art),
                                      ],
                                    );
                            },
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 2),
                      sliver: SliverToBoxAdapter(
                        child: TextField(
                          key: const Key('studio-search'),
                          controller: search,
                          onChanged: (v) => setState(() => query = v),
                          textInputAction: TextInputAction.search,
                          decoration: InputDecoration(
                            hintText: studio.id == 's00'
                                ? 'Search learning tools'
                                : 'Search this studio',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear studio search',
                                    onPressed: reset,
                                    icon: const Icon(Icons.close),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverToBoxAdapter(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 2,
                          children: [
                            for (final name in [
                              'All',
                              if (studio.id != 's00') 'Saved',
                              'Completed',
                            ])
                              ChoiceChip(
                                key: Key('studio-filter-$name'),
                                label: Text(
                                  name == 'All'
                                      ? 'All ${studio.id == 's00' ? 'tools' : 'labs'}'
                                      : name,
                                ),
                                selected: filter == name,
                                showCheckmark: false,
                                onSelected: (_) {
                                  FocusScope.of(context).unfocus();
                                  setState(() => filter = name);
                                },
                                selectedColor: const Color(0xffe8f1ff),
                                side: const BorderSide(
                                  color: Color(0xffdae5f4),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (entries.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Text(
                                filter == 'Saved'
                                    ? 'No saved labs in this studio yet'
                                    : filter == 'Completed'
                                    ? 'Your next discovery starts here'
                                    : 'No matching labs',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Explore the catalogue or try another search.',
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: reset,
                                child: const Text('Show all labs'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          mainAxisExtent: math.max(202, 202 * scale),
                        ),
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final entry = entries[index],
                              saved = store.favorites.contains(
                                entries[index].id,
                              ),
                              done = store.completed.contains(
                                entries[index].id,
                              );
                          return Material(
                            color: Colors.white,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                              side: const BorderSide(color: Color(0xffdee7f2)),
                            ),
                            child: InkWell(
                              key: ValueKey('launch-${entry.id}'),
                              onTap: () {
                                FocusScope.of(context).unfocus();
                                context.push('/lab/${entry.id}');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          LabThumbnail(entry),
                                          Positioned(
                                            left: 0,
                                            top: 0,
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: .92,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                child: Text(
                                                  '${entry.index + 1}'.padLeft(
                                                    2,
                                                    '0',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: muted,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (entry.interactive)
                                            Positioned(
                                              right: 0,
                                              top: 0,
                                              child: IconButton(
                                                key: Key(
                                                  'studio-save-${entry.id}',
                                                ),
                                                tooltip: saved
                                                    ? 'Remove ${entry.title} from saved'
                                                    : 'Save ${entry.title}',
                                                onPressed: () => store
                                                    .toggleFavorite(entry.id),
                                                icon: Icon(
                                                  saved
                                                      ? Icons.bookmark
                                                      : Icons.bookmark_border,
                                                  color: cobalt,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.title,
                                      maxLines: 3,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.15,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      entry.principle,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        height: 1.25,
                                        color: muted,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      done
                                          ? 'Completed'
                                          : store.lastLab == entry.id
                                          ? 'Resume'
                                          : 'Explore ${entry.tool ? 'tool' : 'experiment'}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: cobalt,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }, childCount: entries.length),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}
