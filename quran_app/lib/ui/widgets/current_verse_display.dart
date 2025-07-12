import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
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

  const CurrentVerseDisplay({super.key, this.currentAyah, this.currentSurah, this.isPlaying = false});

  @override
  Widget build(BuildContext context) {
    // If no verse is selected or playing, show placeholder
    if (currentAyah == null || currentSurah == null) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.library_music_outlined, size: 80, color: Colors.grey), SizedBox(height: 16), Text('Select a reciter and surah to begin', style: TextStyle(fontSize: 18, color: Colors.grey), textAlign: TextAlign.center)]));
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Clean verse display with Arabic text and English translation
    return LayoutBuilder(
      builder: (context, constraints) {
        // Check if this is a very short verse (like الم) for special handling
        final isVeryShortVerse = currentAyah!.text.trim().length <= 10;

        return Container(
          height: constraints.maxHeight,
          width: constraints.maxWidth,
          // padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Minimal top spacer
              const Spacer(flex: 1),

              // Arabic text - clean and prominent with dynamic sizing
              Flexible(flex: 4, child: Container(alignment: Alignment.bottomCenter, child: AutoSizeText(currentAyah!.text, style: theme.textTheme.headlineMedium?.copyWith(height: 1.6, fontWeight: FontWeight.w500, color: colorScheme.onSurface), textAlign: TextAlign.center, textDirection: TextDirection.rtl, wrapWords: false, maxLines: 10))),

              SizedBox(height: isVeryShortVerse ? AppTheme.spaceS : AppTheme.spaceM),

              // English translation - clean and readable with dynamic sizing
              if (currentAyah!.englishTranslation != null) Flexible(flex: 4, child: Container(alignment: Alignment.topCenter, child: AutoSizeText(currentAyah!.englishTranslation!, style: theme.textTheme.bodyLarge?.copyWith(height: 1.4, color: colorScheme.onSurface.withValues(alpha: 0.8)), textAlign: TextAlign.center, wrapWords: true, maxLines: 8))),

              // Minimal bottom spacer
              const Spacer(flex: 1),
            ],
          ),
        );
      },
    );
  }
}
