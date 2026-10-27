import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../content/catalog.dart';
import 'theme.dart';
import 'app_navigation.dart';

/// Global destinations share the exact same menu as the home screen.
/// Lab-specific learning and results live in the workspace toolbar.
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
    final configuration = GoRouter.maybeOf(context)
        ?.routerDelegate
        .currentConfiguration;
    final path = configuration == null || configuration.isEmpty
        ? ''
        : configuration.last.matchedLocation;
    return HomeNavigation(
      selected: path == '/settings'
          ? 3
          : path.startsWith('/studio') || path.startsWith('/lab')
          ? 1
          : -1,
      onSelect: (index) => context.push(switch (index) {
        1 => '/?tab=explore',
        2 => '/?tab=saved',
        3 => '/settings',
        _ => '/',
      }),
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
    final label = entry?.title ?? title;
    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: compact ? 3 : 2,
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
