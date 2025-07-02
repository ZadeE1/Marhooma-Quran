import 'package:flutter/material.dart';
import '../../data/models/ayah.dart';
import '../../data/models/surah.dart';
import '../../app_theme.dart';

/// Displays the currently playing verse in the center of the screen.
///
/// Shows Arabic text prominently with English translation below.
/// This component focuses purely on presentation without any audio logic.
///
/// In focus mode, shows minimal UI with only Arabic text and translation
/// for distraction-free reading experience.
class CurrentVerseDisplay extends StatelessWidget {
  final Ayah? currentAyah;
  final Surah? currentSurah;
  final bool isPlaying;
  final bool focusMode;

  const CurrentVerseDisplay({super.key, this.currentAyah, this.currentSurah, this.isPlaying = false, this.focusMode = false});

  @override
  Widget build(BuildContext context) {
    // If no verse is selected or playing, show placeholder
    if (currentAyah == null || currentSurah == null) {
      // In focus mode, show nothing when no verse is available
      if (focusMode) {
        return Container(color: Theme.of(context).colorScheme.surface, child: const Center(child: Text('Tap to exit focus mode', style: TextStyle(fontSize: 16, color: Colors.grey))));
      }

      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.library_music_outlined, size: 80, color: Colors.grey), SizedBox(height: 16), Text('Select a reciter and surah to begin', style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center)]));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Focus mode: Minimal UI with just verse text and translation
    if (focusMode) {
      return Container(
        color: colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Arabic text - clean and prominent
              Container(margin: const EdgeInsets.symmetric(horizontal: 16), child: Text(currentAyah!.text, style: theme.textTheme.headlineLarge?.copyWith(fontSize: 30, height: 1.8, fontWeight: FontWeight.w400, color: colorScheme.onSurface), textAlign: TextAlign.center, textDirection: TextDirection.rtl)),
              const SizedBox(height: 32),
              // English translation - clean and readable with better spacing
              if (currentAyah!.englishTranslation != null) Container(margin: const EdgeInsets.symmetric(horizontal: 24), child: Text(currentAyah!.englishTranslation!, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.6, color: colorScheme.onSurface.withOpacity(0.85), fontWeight: FontWeight.w400), textAlign: TextAlign.center)),
            ],
          ),
        ),
      );
    }

    // Normal mode: Full UI with decorative elements
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Surah and verse information
            Container(padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS), decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)), child: Text('${currentSurah!.name} - Verse ${currentAyah!.numberInSurah}', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600))),

            const SizedBox(height: AppTheme.spaceXl),

            // Arabic text - main focus
            Container(width: double.infinity, padding: const EdgeInsets.all(AppTheme.spaceL), decoration: BoxDecoration(color: colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: colorScheme.outline.withOpacity(0.2)), boxShadow: [BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))]), child: Text(currentAyah!.text, style: theme.textTheme.headlineMedium?.copyWith(fontSize: 28, height: 1.8, fontWeight: FontWeight.w500), textAlign: TextAlign.center, textDirection: TextDirection.rtl)),

            const SizedBox(height: AppTheme.spaceL),

            // English translation
            if (currentAyah!.englishTranslation != null) Container(width: double.infinity, padding: const EdgeInsets.all(AppTheme.spaceM), decoration: BoxDecoration(color: colorScheme.secondaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)), child: Text(currentAyah!.englishTranslation!, style: theme.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.6, color: colorScheme.onSurface.withOpacity(0.8)), textAlign: TextAlign.center)),

            const SizedBox(height: AppTheme.spaceXl),

            // Playing indicator
            if (isPlaying) Container(padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS), decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.volume_up, color: colorScheme.primary, size: 20), const SizedBox(width: 8), Text('Now Playing', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600))])),
          ],
        ),
      ),
    );
  }
}
