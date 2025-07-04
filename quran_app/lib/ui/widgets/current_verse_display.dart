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
///
/// Features dynamic text scaling to ensure content always fits within available space.
class CurrentVerseDisplay extends StatelessWidget {
  final Ayah? currentAyah;
  final Surah? currentSurah;
  final bool isPlaying;
  final bool focusMode;

  const CurrentVerseDisplay({super.key, this.currentAyah, this.currentSurah, this.isPlaying = false, this.focusMode = false});

  /// Calculates appropriate text size based on available space and content length
  double _calculateArabicTextSize(double availableHeight, String text) {
    // Base size for Arabic text
    double baseSize = focusMode ? 30.0 : 28.0;

    // Reduce size based on text length
    if (text.length > 200) {
      baseSize *= 0.7; // Significantly smaller for very long verses
    } else if (text.length > 100) {
      baseSize *= 0.8; // Moderately smaller for long verses
    } else if (text.length > 50) {
      baseSize *= 0.9; // Slightly smaller for medium verses
    }

    // Ensure minimum readable size
    return baseSize.clamp(16.0, focusMode ? 30.0 : 28.0);
  }

  /// Calculates appropriate text size for English translation
  double _calculateEnglishTextSize(double availableHeight, String text) {
    // Base size for English text
    double baseSize = focusMode ? 17.0 : 16.0;

    // Reduce size based on text length
    if (text.length > 300) {
      baseSize *= 0.7;
    } else if (text.length > 150) {
      baseSize *= 0.8;
    } else if (text.length > 75) {
      baseSize *= 0.9;
    }

    // Ensure minimum readable size
    return baseSize.clamp(12.0, focusMode ? 17.0 : 16.0);
  }

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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final arabicSize = _calculateArabicTextSize(constraints.maxHeight, currentAyah!.text);
            final englishSize = _calculateEnglishTextSize(constraints.maxHeight, currentAyah!.englishTranslation ?? '');

            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Arabic text - clean and prominent with dynamic sizing
                    Center(child: Text(currentAyah!.text, style: theme.textTheme.headlineLarge?.copyWith(fontSize: arabicSize, height: 1.8, fontWeight: FontWeight.w400, color: colorScheme.onSurface), textAlign: TextAlign.center, textDirection: TextDirection.rtl)),
                    const SizedBox(height: AppTheme.spaceXl),
                    // English translation - clean and readable with dynamic sizing
                    if (currentAyah!.englishTranslation != null) Center(child: Text(currentAyah!.englishTranslation!, style: theme.textTheme.bodyLarge?.copyWith(fontSize: englishSize, height: 1.6, color: colorScheme.onSurface.withValues(alpha: 0.85), fontWeight: FontWeight.w400), textAlign: TextAlign.center)),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    // Normal mode: Full UI with decorative elements and dynamic sizing
    return LayoutBuilder(
      builder: (context, constraints) {
        final arabicSize = _calculateArabicTextSize(constraints.maxHeight, currentAyah!.text);
        final englishSize = _calculateEnglishTextSize(constraints.maxHeight, currentAyah!.englishTranslation ?? '');

        // Check if this is a very short verse (like الم) for special handling
        final isVeryShortVerse = currentAyah!.text.trim().length <= 10;

        return Container(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer to push content to center
              const Spacer(flex: 1),

              // Surah and verse information
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spaceM,
                    vertical: AppTheme.spaceS,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${currentSurah!.name} - Verse ${currentAyah!.numberInSurah}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              SizedBox(height: isVeryShortVerse ? AppTheme.spaceL : AppTheme.spaceXl),

              // Arabic text - clean and prominent with dynamic sizing
              Center(child: Container(width: double.infinity, child: Text(currentAyah!.text, style: theme.textTheme.headlineMedium?.copyWith(fontSize: arabicSize, height: 1.8, fontWeight: FontWeight.w500, color: colorScheme.onSurface), textAlign: TextAlign.center, textDirection: TextDirection.rtl))),

              SizedBox(height: isVeryShortVerse ? AppTheme.spaceM : AppTheme.spaceL),

              // English translation - clean and readable with dynamic sizing
              if (currentAyah!.englishTranslation != null) Center(child: Container(width: double.infinity, child: Text(currentAyah!.englishTranslation!, style: theme.textTheme.bodyLarge?.copyWith(fontSize: englishSize, height: 1.6, color: colorScheme.onSurface.withValues(alpha: 0.8)), textAlign: TextAlign.center))),

              // Spacer to push content to center
              const Spacer(flex: 1),

              // Playing indicator at bottom
              if (isPlaying) Container(padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS), decoration: BoxDecoration(color: colorScheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.volume_up, color: colorScheme.primary, size: 20), const SizedBox(width: 8), Text('Now Playing', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600))])),

              // Small spacer at bottom for playing indicator
              if (isPlaying) const SizedBox(height: AppTheme.spaceM),
            ],
          ),
        );
      },
    );
  }
}
