import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart' show notebookProvider;
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart' show muted;
import '../../core/persistence/notebook.dart';
import '../../core/design_system/app_navigation.dart';
export '../../core/design_system/app_navigation.dart'
    show HomeNavigation, HomeGlyph, HomeSymbol;
import 'studio_registry.dart';

const _ink = Color(0xff071746), _quiet = muted, _blue = Color(0xff0064ff);

class CompactHome extends ConsumerStatefulWidget {
  final int initialDestination;
  const CompactHome({super.key, this.initialDestination = 0});
  @override
  ConsumerState<CompactHome> createState() => _CompactHomeState();
}

class _CompactHomeState extends ConsumerState<CompactHome> {
  final scroll = ScrollController(), search = TextEditingController();
  final searchFocus = FocusNode();
  final catalogueHeading = GlobalKey();
  String query = '', category = 'All studios';
  int destination = 0;
  @override
  void initState() {
    super.initState();
    destination = widget.initialDestination;
    if (destination == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = catalogueHeading.currentContext;
        if (target != null) Scrollable.ensureVisible(target);
      });
    }
  }

  void reset() {
    searchFocus.unfocus();
    setState(() {
      query = '';
      search.clear();
      category = 'All studios';
    });
  }

  void open(String route) {
    searchFocus.unfocus();
    context.push(route);
  }

  void moveTo(double value, LocalNotebook store) {
    if (!scroll.hasClients) return;
    final target = value.clamp(0.0, scroll.position.maxScrollExtent);
    if (store.reducedMotion || MediaQuery.disableAnimationsOf(context)) {
      scroll.jumpTo(target);
    } else {
      scroll.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    scroll.dispose();
    search.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = ref.watch(notebookProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final matches = query.trim().isNotEmpty;
        final filtered = homeStudios
            .where(
              (s) =>
                  category == 'All studios' || s.categories.contains(category),
            )
            .toList();
        final studioResults = matches
            ? searchHomeStudios(query)
            : <HomeStudio>[];
        final labResults = matches ? searchHomeLabs(query) : <Entry>[];
        final saved = allEntries
            .where((e) => store.favorites.contains(e.id))
            .toList();
        final worksheets = allEntries
            .where(
              (e) =>
                  e.interactive &&
                  store.preferences.containsKey('lab-research:${e.id}'),
            )
            .toList();
        return Theme(
          data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme
                .apply(fontFamily: 'HomeManrope'),
          ),
          child: Scaffold(
            backgroundColor: Colors.white,
            bottomNavigationBar: HomeNavigation(
              selected: destination,
              onSelect: (i) {
                if (i == 3) {
                  open('/settings');
                  return;
                }
                setState(() => destination = i);
                if (i == 0) moveTo(0, store);
                if (i == 1) {
                  reset();
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    final target = catalogueHeading.currentContext;
                    if (mounted && target != null) {
                      Scrollable.ensureVisible(
                        target,
                        duration:
                            store.reducedMotion ||
                                MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 250),
                      );
                    }
                  });
                }
                if (i == 2) {
                  searchFocus.unfocus();
                  moveTo(0, store);
                }
              },
            ),
            body: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, bounds) {
                  final scale = MediaQuery.textScalerOf(context).scale(1);
                  final horizontal = bounds.maxWidth >= 700 ? 32.0 : 20.0;
                  final cols = scale > 1.5 || bounds.maxWidth < 340
                      ? 1
                      : bounds.maxWidth >= 1000
                      ? 4
                      : bounds.maxWidth >= 700
                      ? 3
                      : 2;
                  final tileWidth =
                      (bounds.maxWidth - 2 * horizontal - (cols - 1) * 8) /
                      cols;
                  final tileHeight = cols == 1
                      ? math.max(130.0, 100 * scale)
                      : math.max(74.0, tileWidth * .435);
                  return CustomScrollView(
                    key: const PageStorageKey('home-catalogue'),
                    controller: scroll,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          5,
                          horizontal,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 23,
                                height: 27,
                                child: CustomPaint(painter: AtomMark()),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Physics',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 20,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -.8,
                                    color: _ink,
                                  ),
                                ),
                              ),

                              IconButton(
                                tooltip: 'Settings',
                                onPressed: () => open('/settings'),
                                icon: const HomeGlyph(
                                  HomeSymbol.settings,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (destination != 2) ...[
                        if (!matches)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontal,
                            ),
                            sliver: SliverToBoxAdapter(child: _hero(scale)),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            7,
                            horizontal,
                            0,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: TextField(
                              key: const Key('search'),
                              controller: search,
                              focusNode: searchFocus,
                              style: const TextStyle(fontSize: 14, color: _ink),
                              textInputAction: TextInputAction.search,
                              onChanged: (value) =>
                                  setState(() => query = value),
                              decoration: InputDecoration(
                                hintText: 'What will you discover?',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: _quiet,
                                ),
                                prefixIcon: const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: HomeGlyph(HomeSymbol.search, size: 20),
                                ),
                                suffixIcon: matches
                                    ? IconButton(
                                        key: const Key('home-clear-search'),
                                        tooltip: 'Clear search',
                                        onPressed: reset,
                                        icon: const Icon(Icons.close, size: 19),
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 12,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: const BorderSide(
                                    color: Color(0xffdce5f2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: const BorderSide(
                                    color: _blue,
                                    width: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!matches)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              7,
                              horizontal,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Wrap(
                                spacing: 7,
                                runSpacing: 4,
                                children: [
                                  for (final label in [
                                    'All studios',
                                    'Matter',
                                    'Energy',
                                    'Waves',
                                  ])
                                    ChoiceChip(
                                      key: Key('home-filter-$label'),
                                      label: Text(label),
                                      selected: category == label,
                                      onSelected: (_) =>
                                          setState(() => category = label),
                                      showCheckmark: false,
                                      selectedColor: _ink,
                                      backgroundColor: const Color(0xfff5f7fb),
                                      side: BorderSide(
                                        color: category == label
                                            ? _ink
                                            : const Color(0xffe5ebf4),
                                      ),
                                      shape: const StadiumBorder(),
                                      visualDensity: VisualDensity.standard,
                                      labelStyle: TextStyle(
                                        color: category == label
                                            ? Colors.white
                                            : const Color(0xff516181),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (!matches && store.lastLab != null)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal,
                              5,
                              horizontal,
                              0,
                            ),
                            sliver: SliverToBoxAdapter(child: _resume(store)),
                          ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            8,
                            horizontal,
                            7,
                          ),
                          sliver: SliverToBoxAdapter(
                            child: Wrap(
                              key: catalogueHeading,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12,
                              children: [
                                Text(
                                  matches
                                      ? 'Search results'
                                      : 'Explore studios',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    height: 1.15,
                                    letterSpacing: -.7,
                                    fontWeight: FontWeight.w800,
                                    color: _ink,
                                  ),
                                ),
                                Text(
                                  matches
                                      ? '${studioResults.length + labResults.length} results'
                                      : '${filtered.length} studios',
                                  style: const TextStyle(
                                    color: _quiet,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!matches)
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              horizontal - 3,
                              0,
                              horizontal - 3,
                              16,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: cols,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 7,
                                    mainAxisExtent: tileHeight,
                                  ),
                              delegate: SliverChildBuilderDelegate(
                                (context, i) => HomeStudioCard(
                                  studio: filtered[i],
                                  number: homeStudios.indexOf(filtered[i]) + 1,
                                  large: cols == 1,
                                  onTap: () => open(filtered[i].route),
                                ),
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                        if (matches &&
                            studioResults.isEmpty &&
                            labResults.isEmpty)
                          SliverToBoxAdapter(
                            child: _empty(
                              'No discoveries found',
                              'Try a studio, experiment or physics principle.',
                              reset,
                            ),
                          ),
                        if (matches)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontal,
                            ),
                            sliver: SliverList.builder(
                              itemCount:
                                  studioResults.length + labResults.length,
                              itemBuilder: (context, i) {
                                if (i < studioResults.length) {
                                  final s = studioResults[i];
                                  return ListTile(
                                    key: Key('home-search-${s.studio.id}'),
                                    title: Text(s.studio.title),
                                    subtitle: Text(
                                      '${s.count} activities · ${s.description}',
                                    ),
                                    trailing: const HomeGlyph(
                                      HomeSymbol.arrow,
                                      size: 17,
                                    ),
                                    onTap: () => open(s.route),
                                  );
                                }
                                return _labTile(
                                  labResults[i - studioResults.length],
                                  store,
                                );
                              },
                            ),
                          ),
                      ] else ...[
                        SliverPadding(
                          padding: EdgeInsets.all(horizontal),
                          sliver: const SliverToBoxAdapter(
                            child: Text(
                              'Saved discoveries',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                          ),
                        ),
                        if (saved.isEmpty && worksheets.isEmpty)
                          SliverToBoxAdapter(
                            child: _empty('Your collection starts here', 'Favorite a lab to keep it close. Your saved labs stay available offline.', () {
                              reset();
                              setState(() => destination = 1);
                            }),
                          ),
                        if (worksheets.isNotEmpty) ...[
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontal,
                              vertical: 8,
                            ),
                            sliver: const SliverToBoxAdapter(
                              child: Text(
                                'Investigation worksheets',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SliverPadding(
                            padding: EdgeInsets.symmetric(
                              horizontal: horizontal,
                            ),
                            sliver: SliverList.builder(
                              itemCount: worksheets.length,
                              itemBuilder: (context, i) {
                                final entry = worksheets[i];
                                return ListTile(
                                  key: Key('saved-worksheet-${entry.id}'),
                                  leading: const Icon(
                                    Icons.description_outlined,
                                  ),
                                  title: Text(entry.title),
                                  subtitle: const Text(
                                    'Open saved investigation worksheet',
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () =>
                                      open('/lab/${entry.id}?worksheet=open'),
                                );
                              },
                            ),
                          ),
                        ],
                        SliverPadding(
                          padding: EdgeInsets.symmetric(horizontal: horizontal),
                          sliver: SliverList.builder(
                            itemCount: saved.length,
                            itemBuilder: (context, i) =>
                                _labTile(saved[i], store, saved: true),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _hero(double scale) => scale > 1.5
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'YOUR POCKET SCIENCE LAB',
              style: TextStyle(
                fontSize: 7.4,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w700,
                color: _quiet,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'A world of\ndiscovery.',
              style: TextStyle(
                fontSize: 28,
                height: 1,
                letterSpacing: -1.3,
                color: _ink,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(
              height: 105,
              width: double.infinity,
              child: Align(
                alignment: Alignment.centerRight,
                child: HomeArtwork('assets/home/hero.webp'),
              ),
            ),
          ],
        )
      : SizedBox(
          height: scale > 1.5 ? 165 * scale / 1.5 : 103,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                right: -7,
                bottom: -5,
                top: -8,
                width: MediaQuery.sizeOf(context).width * .54,
                child: _heroArtwork(),
              ),
              Positioned(
                left: 0,
                top: 10,
                right: 0,
                child: Text(
                  'YOUR POCKET SCIENCE LAB',
                  style: TextStyle(
                    fontSize: 7.4,
                    letterSpacing: 2.2,
                    fontWeight: FontWeight.w700,
                    color: _quiet.withValues(alpha: .95),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    'A world of\ndiscovery.',
                    style: TextStyle(
                      fontSize: scale > 1.5 ? 25 : 29,
                      letterSpacing: -1.3,
                      height: .97,
                      color: _ink,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );

  Widget _heroArtwork() => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (bounds) => const LinearGradient(
      colors: [
        Colors.transparent,
        Colors.white,
        Colors.white,
        Colors.transparent,
      ],
      stops: [0, .06, .94, 1],
    ).createShader(bounds),
    child: ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (bounds) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.white,
          Colors.white,
          Colors.transparent,
        ],
        stops: [0, .08, .9, 1],
      ).createShader(bounds),
      child: const HomeArtwork('assets/home/hero.webp'),
    ),
  );

  Widget _resume(LocalNotebook store) {
    final entry = entryById(store.lastLab!);
    return InkWell(
      key: const Key('home-resume'),
      borderRadius: BorderRadius.circular(9),
      onTap: () => open('/lab/${entry.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 43,
              height: 33,
              child: HomeArtwork(homeStudios[entry.studioIndex].artwork),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Continue learning',
                    style: TextStyle(
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    '${studios[entry.studioIndex].title} · ${entry.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 10, color: _quiet),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Resume',
              style: TextStyle(
                color: _blue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Icon(Icons.chevron_right, size: 16, color: _blue),
          ],
        ),
      ),
    );
  }

  Widget _labTile(Entry entry, LocalNotebook store, {bool saved = false}) =>
      ListTile(
        key: Key('search-result-${entry.id}'),
        leading: SizedBox(
          width: 48,
          height: 43,
          child: HomeArtwork(homeStudios[entry.studioIndex].artwork),
        ),
        title: Text(entry.title),
        subtitle: Text(studios[entry.studioIndex].title),
        trailing: saved
            ? IconButton(
                tooltip: 'Remove ${entry.title} from saved',
                onPressed: () => store.toggleFavorite(entry.id),
                icon: const Icon(Icons.bookmark_remove_outlined),
              )
            : const HomeGlyph(HomeSymbol.arrow, size: 17),
        onTap: () => open('/lab/${entry.id}'),
      );
  Widget _empty(String title, String description, VoidCallback action) =>
      Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(description, textAlign: TextAlign.center),
            TextButton(
              onPressed: action,
              child: const Text('Explore all studios'),
            ),
          ],
        ),
      );
}

class HomeStudioCard extends StatelessWidget {
  final HomeStudio studio;
  final int number;
  final bool large;
  final VoidCallback onTap;
  const HomeStudioCard({
    super.key,
    required this.studio,
    required this.number,
    required this.large,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${studio.studio.title}. ${studio.description} ${studio.count} ${studio.studio.id == 's00' ? 'learning tools' : 'labs'}. Open studio.',
    child: Tooltip(
      message: '${studio.description}\n${studio.count} activities',
      child: Material(
        color: Colors.white,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xffe0e7f1), width: .8),
        ),
        child: InkWell(
          key: Key('home-studio-${studio.studio.id}'),
          onTap: onTap,
          splashColor: _blue.withValues(alpha: .08),
          focusColor: _blue.withValues(alpha: .13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              HomeArtwork(studio.artwork, fit: BoxFit.contain),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xd9ffffff),
                      Color(0x00ffffff),
                    ],
                    stops: [0, .27, .62],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 9,
                right: 8,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            number.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              fontSize: 9,
                              color: _quiet,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          FractionallySizedBox(
                            widthFactor:
                                large || !studio.studio.title.contains(' ')
                                ? 1
                                : .62,
                            child: Text(
                              studio.studio.title,
                              maxLines: large ? 5 : 3,
                              style: TextStyle(
                                fontSize: large ? 16 : 11.8,
                                height: 1.05,
                                letterSpacing: -.35,
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const HomeGlyph(HomeSymbol.arrow, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class HomeArtwork extends StatelessWidget {
  final String path;
  final BoxFit fit;
  const HomeArtwork(this.path, {super.key, this.fit = BoxFit.contain});
  @override
  Widget build(BuildContext context) => Image.asset(
    path,
    fit: fit,
    cacheWidth: 768,
    excludeFromSemantics: true,
    errorBuilder: (_, error, stack) => const ColoredBox(
      color: Color(0xfff8faff),
      child: Center(child: Icon(Icons.science_outlined, color: _quiet)),
    ),
  );
}

class AtomMark extends CustomPainter {
  const AtomMark();
  @override
  void paint(Canvas c, Size s) {
    c.translate(s.width / 2, s.height / 2);
    final p = Paint()
      ..color = _blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 0; i < 3; i++) {
      c.save();
      c.rotate(i * math.pi / 3);
      c.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: s.width * .45,
          height: s.height * .96,
        ),
        p,
      );
      c.restore();
    }
    c.drawCircle(Offset.zero, 1.5, p..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant AtomMark old) => false;
}
