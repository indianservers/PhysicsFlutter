import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app.dart' show notebookProvider;
import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import '../../core/design_system/reference_style.dart';
import 'lab_thumbnail.dart';

export '../home/home_screen.dart' show CompactHome;

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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
        bottomNavigationBar: ReferenceNavigation(
          selected: 1,
          homeFirst: true,
          onLabs: () => context.go('/studio/${studio.id}'),
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
