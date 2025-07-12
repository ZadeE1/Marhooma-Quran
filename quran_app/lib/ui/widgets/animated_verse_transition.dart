import 'package:flutter/material.dart';
import '../../data/models/ayah.dart';
import '../../data/models/surah.dart';
import 'current_verse_display.dart';

/// Enhanced verse transition widget that provides smooth fade animations
/// between verses using Flutter's implicit animation widgets.
///
/// Uses AnimatedOpacity and related widgets that handle their own timing
/// and work well with rapid state changes.
class AnimatedVerseTransition extends StatelessWidget {
  final Ayah? currentAyah;
  final Ayah? nextAyah;
  final Surah? currentSurah;
  final bool isPlaying;
  final bool showingNext;
  final VerseTransitionStyle transitionStyle;

  const AnimatedVerseTransition({super.key, this.currentAyah, this.nextAyah, this.currentSurah, this.isPlaying = false, this.showingNext = false, this.transitionStyle = VerseTransitionStyle.fadeOnly});

  /// Build the appropriate verse display with the selected transition style
  Widget _buildVerseDisplay(Ayah? ayah, {required bool isVisible}) {
    final display = CurrentVerseDisplay(currentAyah: ayah, currentSurah: currentSurah, isPlaying: isPlaying);

    return _applyTransitionStyle(display, isVisible: isVisible);
  }

  /// Apply the selected transition style using implicit animations
  Widget _applyTransitionStyle(Widget child, {required bool isVisible}) {
    const duration = Duration(milliseconds: 400);
    const curve = Curves.easeInOut;

    switch (transitionStyle) {
      case VerseTransitionStyle.fadeOnly:
        return AnimatedOpacity(opacity: isVisible ? 1.0 : 0.0, duration: duration, curve: curve, child: child);

      case VerseTransitionStyle.fadeScale:
        return AnimatedScale(scale: isVisible ? 1.0 : 0.98, duration: duration, curve: Curves.easeOutBack, child: AnimatedOpacity(opacity: isVisible ? 1.0 : 0.0, duration: duration, curve: curve, child: child));

      case VerseTransitionStyle.fadeSlide:
        return AnimatedSlide(offset: isVisible ? Offset.zero : const Offset(0, 0.02), duration: duration, curve: Curves.easeOut, child: AnimatedOpacity(opacity: isVisible ? 1.0 : 0.0, duration: duration, curve: curve, child: child));

      case VerseTransitionStyle.elegant:
        // Elegant: Subtle combination of fade, scale, and slide
        return AnimatedSlide(offset: isVisible ? Offset.zero : const Offset(0, 0.015), duration: duration, curve: Curves.easeOut, child: AnimatedScale(scale: isVisible ? 1.0 : 0.99, duration: duration, curve: Curves.easeOutBack, child: AnimatedOpacity(opacity: isVisible ? 1.0 : 0.0, duration: duration, curve: curve, child: child)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Current verse display
        _buildVerseDisplay(currentAyah, isVisible: !showingNext),
        // Next verse display
        _buildVerseDisplay(nextAyah, isVisible: showingNext),
      ],
    );
  }
}

/// Different animation styles for verse transitions
enum VerseTransitionStyle {
  /// Simple fade in/out
  fadeOnly,

  /// Fade with subtle scale effect
  fadeScale,

  /// Fade with gentle slide from below
  fadeSlide,

  /// Elegant combination of fade, scale, and slide
  elegant,
}
