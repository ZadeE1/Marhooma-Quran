import 'package:flutter/material.dart';
import '../../data/models/surah.dart';
import '../../app_theme.dart';

/// A reusable tile displaying a Surah with its number, name and ayah count.
/// Tapping the tile triggers [onTap]. Shows selection state when [selected] is true.
class SurahTile extends StatelessWidget {
  final Surah surah;
  final bool selected;
  final VoidCallback onTap;

  const SurahTile({super.key, required this.surah, this.selected = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
      elevation: 2,
      shape: RoundedRectangleBorder(
        side: selected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(AppTheme.spaceM),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.spaceM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  child: Text(
                    surah.number.toString(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Ayahs: ${surah.ayahCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
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
}
