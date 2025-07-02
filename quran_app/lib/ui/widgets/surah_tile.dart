import 'package:flutter/material.dart';
import '../../data/models/surah.dart';
import '../../app_theme.dart';

/// A reusable tile displaying a Surah with its number, name and ayah count.
/// Tapping the tile triggers [onTap].
class SurahTile extends StatelessWidget {
  final Surah surah;
  final VoidCallback onTap;

  const SurahTile({super.key, required this.surah, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS), elevation: 2, child: ListTile(onTap: onTap, leading: CircleAvatar(backgroundColor: colorScheme.secondaryContainer, foregroundColor: colorScheme.onSecondaryContainer, child: Text(surah.number.toString(), style: Theme.of(context).textTheme.labelLarge)), title: Text(surah.name, style: Theme.of(context).textTheme.titleMedium), subtitle: Text('Ayahs: ${surah.ayahCount}', style: Theme.of(context).textTheme.bodySmall), trailing: const Icon(Icons.chevron_right)));
  }
}
