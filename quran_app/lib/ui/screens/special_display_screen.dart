import 'package:flutter/material.dart';
import 'dart:async';
import '../../data/models/ayah.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/quran_text_service.dart';
import '../widgets/settings_modal.dart';
import '../widgets/current_verse_display.dart';

/// The main and only screen of the app - displays the current verse
/// with settings to select reciter and surah.
///
/// This screen replaces the previous tab-based navigation structure
/// and focuses on a single, centered verse display experience.
///
/// Features focus mode that activates after inactivity to provide
/// distraction-free reading with only Arabic text and translation visible.
class SpecialDisplayScreen extends StatefulWidget {
  const SpecialDisplayScreen({super.key});

  @override
  State<SpecialDisplayScreen> createState() => _SpecialDisplayScreenState();
}

class _SpecialDisplayScreenState extends State<SpecialDisplayScreen> with TickerProviderStateMixin {
  // Services for audio and text functionality
  final QuranAudioPlayer _audioService = QuranAudioPlayer();
  final QuranTextService _textService = QuranTextService();

  // Current state
  Reciter? _selectedReciter;
  Surah? _selectedSurah;
  Ayah? _currentAyah;
  bool _isPlaying = false;

  // Focus mode state and timer
  bool _isInFocusMode = false;
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(seconds: 10);

  // Animation controller for focus mode transitions
  late AnimationController _focusModeAnimationController;
  late Animation<double> _appBarSlideAnimation;
  late Animation<double> _bottomNavSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAudioListeners();
  }

  /// Initializes animation controllers and animations for smooth transitions.
  void _initializeAnimations() {
    _focusModeAnimationController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    // App bar slides up and out
    _appBarSlideAnimation = Tween<double>(begin: 0.0, end: -1.0).animate(CurvedAnimation(parent: _focusModeAnimationController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)));

    // Bottom navigation slides down and out
    _bottomNavSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _focusModeAnimationController, curve: const Interval(0.0, 0.6, curve: Curves.easeInOut)));

    // Content transitions to focus mode
    _contentFadeAnimation = CurvedAnimation(parent: _focusModeAnimationController, curve: const Interval(0.3, 1.0, curve: Curves.easeInOut));
  }

  /// Starts or restarts the inactivity timer for focus mode.
  /// Only call this for actual user interactions, not automatic events.
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted && _currentAyah != null) {
        _enterFocusMode();
      }
    });
  }

  /// Smoothly enters focus mode with fade animation.
  void _enterFocusMode() {
    setState(() {
      _isInFocusMode = true;
    });
    _focusModeAnimationController.forward();
  }

  /// Smoothly exits focus mode with fade animation.
  void _exitFocusModeWithAnimation() {
    _focusModeAnimationController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _isInFocusMode = false;
        });
      }
    });
    _startInactivityTimer();
  }

  /// Exits focus mode and restarts the inactivity timer.
  void _exitFocusMode() {
    if (_isInFocusMode) {
      _exitFocusModeWithAnimation();
    } else {
      _startInactivityTimer();
    }
  }

  /// Handles user interactions that should reset the inactivity timer.
  void _onUserInteraction() {
    _exitFocusMode();
  }

  /// Sets up stream listeners for audio playback state.
  void _setupAudioListeners() {
    // Listen for current ayah changes
    _audioService.currentAyahStream.listen((ayahNumber) async {
      if (ayahNumber != null && _selectedSurah != null) {
        // Fetch the current ayah with translation
        final ayah = await _textService.getAyah(_selectedSurah!.number, ayahNumber);
        setState(() {
          _currentAyah = ayah;
        });
        // Start timer only if this is the first verse (user just started playback)
        if (ayahNumber == 1) {
          _startInactivityTimer();
        }
      } else {
        setState(() {
          _currentAyah = null;
        });
      }
    });

    // Listen for playing state changes
    _audioService.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });
  }

  /// Handles the completion of reciter and surah selection from the modal.
  void _onSelectionComplete(Reciter reciter, Surah surah) {
    setState(() {
      _selectedReciter = reciter;
      _selectedSurah = surah;
    });

    // Start playing the surah from the beginning
    _startPlayback();
    // This is a user interaction - start the timer
    _startInactivityTimer();
  }

  /// Starts audio playback of the selected surah.
  Future<void> _startPlayback() async {
    if (_selectedReciter != null && _selectedSurah != null) {
      await _audioService.playSurah(surah: _selectedSurah!, reciter: _selectedReciter!);
    }
  }

  /// Shows the settings modal for reciter and surah selection.
  void _showSettingsModal() {
    _onUserInteraction(); // This is a user interaction
    showDialog(context: context, builder: (context) => SettingsModal(selectedReciter: _selectedReciter, selectedSurah: _selectedSurah, onSelectionComplete: _onSelectionComplete));
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _focusModeAnimationController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _focusModeAnimationController,
      builder: (context, child) {
        return GestureDetector(
          onTap: _onUserInteraction,
          onPanDown: (_) => _onUserInteraction(),
          behavior: HitTestBehavior.opaque,
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            // App bar that slides up and out during focus mode
            appBar: _isInFocusMode ? null : PreferredSize(preferredSize: const Size.fromHeight(kToolbarHeight), child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -1)).animate(_appBarSlideAnimation), child: AppBar(title: const Text('Quran'), centerTitle: true, actions: [IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsModal, tooltip: 'Select Reciter & Surah')]))),
            body: SafeArea(child: FadeTransition(opacity: _isInFocusMode ? _contentFadeAnimation : Tween<double>(begin: 1.0, end: 0.0).animate(_contentFadeAnimation), child: CurrentVerseDisplay(currentAyah: _currentAyah, currentSurah: _selectedSurah, isPlaying: _isPlaying, focusMode: _isInFocusMode))),
            // Bottom navigation that slides down and out during focus mode
            bottomNavigationBar:
                _currentAyah != null && _selectedSurah != null && !_isInFocusMode
                    ? SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 1)).animate(_bottomNavSlideAnimation),
                      child: SafeArea(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Stop button
                              IconButton(
                                icon: const Icon(Icons.stop),
                                iconSize: 32,
                                onPressed: () async {
                                  _onUserInteraction();
                                  await _audioService.stop();
                                },
                              ),
                              // Play/Pause button
                              IconButton(
                                icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, size: 48),
                                onPressed: () async {
                                  _onUserInteraction();
                                  if (_isPlaying) {
                                    await _audioService.pause();
                                  } else {
                                    await _audioService.play();
                                  }
                                },
                              ),
                              // Settings button
                              IconButton(icon: const Icon(Icons.tune), iconSize: 32, onPressed: _showSettingsModal),
                            ],
                          ),
                        ),
                      ),
                    )
                    : null,
          ),
        );
      },
    );
  }
}
