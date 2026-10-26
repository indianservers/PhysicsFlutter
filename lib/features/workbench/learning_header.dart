import 'package:flutter/material.dart';

import '../../content/catalog.dart';
import '../../core/design_system/theme.dart';
import 'lab_thumbnail.dart';

/// Reference artwork is separate from the student's computed live experiment.
class LabLearningHeader extends StatelessWidget {
  final Entry entry;
  final VoidCallback onExplore;
  const LabLearningHeader({
    super.key,
    required this.entry,
    required this.onExplore,
  });
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Material(
      color: const Color(0xfff7faff),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xffdfe8f4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 140 : 180,
            child: ColoredBox(color: Colors.white, child: LabThumbnail(entry)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studioIndex == 1 && entry.index == 5
                      ? 'Example visualization · simulated readings'
                      : entry.astronomy
                      ? 'Model reference'
                      : 'Apparatus reference',
                  style: const TextStyle(
                    fontSize: 11,
                    color: muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Change a control, observe the result and test your prediction.',
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  key: const Key('learn-explore-apparatus'),
                  onPressed: onExplore,
                  icon: const Icon(Icons.touch_app_outlined, size: 19),
                  label: Text(
                    entry.studioIndex == 1 && entry.index == 5
                        ? 'Explore readings'
                        : entry.astronomy
                        ? 'Explore the model'
                        : 'Explore apparatus',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
