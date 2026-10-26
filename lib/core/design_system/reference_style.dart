import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/catalog.dart';
import 'theme.dart';

/// The four contextual destinations shown by the supplied Target UI.
/// This is separate from the former five-section navigation bar.
class ReferenceNavigation extends StatelessWidget {
  final int selected;
  final VoidCallback? onFirst, onLabs, onResults;
  final bool homeFirst;
  final IconData? firstIcon;
  const ReferenceNavigation({
    super.key,
    required this.selected,
    this.onFirst,
    this.onLabs,
    this.onResults,
    this.homeFirst = false,
    this.firstIcon,
  });
  @override
  Widget build(BuildContext context) {
    final labels = [homeFirst ? 'Home' : 'Learn', 'Labs', 'Results', 'Profile'];
    final icons = [
      firstIcon ?? (homeFirst ? Icons.home_outlined : Icons.menu_book_outlined),
      Icons.science_outlined,
      Icons.bar_chart_outlined,
      Icons.person_outline,
    ];
    final height = (42 + MediaQuery.textScalerOf(context).scale(10)).clamp(
      56.0,
      84.0,
    );
    return Material(
      color: Colors.white,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xffdce7f1))),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: height,
            child: Row(
              children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                    child: Semantics(
                      selected: selected == i,
                      button: true,
                      label: labels[i],
                      child: InkWell(
                        key: Key('reference-nav-${labels[i].toLowerCase()}'),
                        onTap: () {
                          switch (i) {
                            case 0:
                              if (onFirst != null) {
                                onFirst!();
                              } else {
                                context.go('/');
                              }
                            case 1:
                              if (onLabs != null) {
                                onLabs!();
                              } else {
                                context.go('/studio/s01');
                              }
                            case 2:
                              if (onResults != null) {
                                onResults!();
                              } else {
                                context.push('/notebook');
                              }
                            case 3:
                              context.push('/profile');
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              icons[i],
                              size: 22,
                              color: selected == i ? cobalt : muted,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                fontWeight: selected == i
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected == i ? cobalt : navy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReferenceLabHeading extends StatelessWidget {
  final String id, title;
  const ReferenceLabHeading(this.id, this.title, {super.key});
  @override
  Widget build(BuildContext context) {
    final known = allEntries.where((e) => e.id == id);
    final entry = known.isEmpty ? null : known.first;
    final compact = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    final label = entry == null
        ? title
        : entry.studioIndex >= 10
        ? entry.title
        : '${entry.index + 1}. ${entry.title}';
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 15,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: navy,
            ),
          ),
        ],
      ),
    );
  }
}
