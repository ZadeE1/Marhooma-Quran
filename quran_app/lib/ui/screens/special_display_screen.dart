import 'package:flutter/material.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../../data/models/ayah.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/quran_text_service.dart';
import '../../data/services/quran_api_service.dart';
import '../widgets/settings_modal.dart';
import '../widgets/animated_verse_transition.dart';

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
  final QuranApiService _quranApiService = QuranApiService();

  // Current state
  Reciter? _selectedReciter;
  Surah? _selectedSurah;
  Ayah? _currentDisplayAyah; // What's currently visible on screen
  Ayah? _nextDisplayAyah; // What will be shown next (pre-loaded)
  int? _lastAyahNumber; // Track the last ayah number we processed
  bool _isPlaying = false;
  bool _showingNextAyah = false; // Toggle between current and next display

  // Auto-advance to next surah functionality
  List<Surah>? _allSurahs; // Cache of all surahs for navigation

  // Focus mode state and timer
  bool _isInFocusMode = false;
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(seconds: 10);

  // Animation style for verse transitions - configurable
  VerseTransitionStyle _transitionStyle = VerseTransitionStyle.elegant;

  // Efficient animation controllers for focus mode transitions
  late AnimationController _appBarAnimationController;
  late AnimationController _bottomNavAnimationController;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<Offset> _bottomNavSlideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupAudioListeners();
  }

  /// Initializes efficient animation controllers for smooth, fast transitions.
  void _initializeAnimations() {
    // Separate controllers for better performance and resource management
    _appBarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Quick, smooth animation
      vsync: this,
    );

    _bottomNavAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Quick, smooth animation
      vsync: this,
    );

    // App bar slides up and out
    _appBarSlideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -1)).animate(CurvedAnimation(parent: _appBarAnimationController, curve: Curves.easeInOut));

    // Bottom navigation slides down and out
    _bottomNavSlideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 1)).animate(CurvedAnimation(parent: _bottomNavAnimationController, curve: Curves.easeInOut));
  }

  /// Starts or restarts the inactivity timer for focus mode.
  /// Only call this for actual user interactions, not automatic events.
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityDuration, () {
      if (mounted && _currentDisplayAyah != null) {
        _enterFocusMode();
      }
    });
  }

  /// Smoothly enters focus mode with fade animation.
  void _enterFocusMode() {
    setState(() {
      _isInFocusMode = true;
    });
    _appBarAnimationController.forward();
    _bottomNavAnimationController.forward();
  }

  /// Smoothly exits focus mode with fade animation.
  void _exitFocusModeWithAnimation() {
    // Use Future.wait to ensure both animations complete before updating state
    Future.wait([_appBarAnimationController.reverse(), _bottomNavAnimationController.reverse()]).then((_) {
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
        // Check if this is actually a new ayah (avoid duplicate processing)
        if (_lastAyahNumber == ayahNumber) {
          return; // Skip if same ayah
        }

        // Load the new ayah content
        final newAyah = await _textService.getAyah(_selectedSurah!.number, ayahNumber);

        // If this is the first ayah, show it immediately
        if (_currentDisplayAyah == null) {
          setState(() {
            _currentDisplayAyah = newAyah;
            _nextDisplayAyah = null;
            _lastAyahNumber = ayahNumber;
            _showingNextAyah = false;
          });

          if (ayahNumber == 1) {
            _startInactivityTimer();
          }
          return;
        }

        // We have existing content, so perform smooth transition
        if (_showingNextAyah) {
          // Currently showing next display, so load new content into current display
          setState(() {
            _currentDisplayAyah = newAyah;
            _lastAyahNumber = ayahNumber;
          });
          // Small delay then cross-fade to current display
          await Future.delayed(const Duration(milliseconds: 50));
          setState(() {
            _showingNextAyah = false; // Cross-fade to current display
          });
        } else {
          // Currently showing current display, so load new content into next display
          setState(() {
            _nextDisplayAyah = newAyah;
            _lastAyahNumber = ayahNumber;
          });
          // Small delay then cross-fade to next display
          await Future.delayed(const Duration(milliseconds: 50));
          setState(() {
            _showingNextAyah = true; // Cross-fade to next display
          });
        }

        // Start timer only if this is the first verse (user just started playback)
        if (ayahNumber == 1) {
          _startInactivityTimer();
        }
      } else {
        // Clear everything when no content
        setState(() {
          _currentDisplayAyah = null;
          _nextDisplayAyah = null;
          _lastAyahNumber = null;
          _showingNextAyah = false;
        });
      }
    });

    // Listen for playing state changes
    _audioService.playingStream.listen((playing) {
      setState(() {
        _isPlaying = playing;
      });
    });

    // Listen for player state to detect surah completion
    _audioService.playerStateStream.listen((playerState) {
      print('🎵 Player state: ${playerState.processingState}, playing: ${playerState.playing}');

      // Check if the surah has completed (playlist finished)
      if (playerState.processingState == ProcessingState.completed && _selectedSurah != null && _selectedReciter != null) {
        print('🎯 Surah ${_selectedSurah!.name} completed, attempting auto-advance...');

        // Auto-advance to next surah after a brief delay
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleSurahCompletion();
        });
      }
    });
  }

  /// Handles the completion of reciter and surah selection from the modal.
  void _onSelectionComplete(Reciter reciter, Surah surah) {
    setState(() {
      _selectedReciter = reciter;
      _selectedSurah = surah;
    });

    // Load all surahs for potential auto-advance functionality
    _loadAllSurahs();

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

  /// Cycles through different animation styles for verse transitions
  void _cycleAnimationStyle() {
    setState(() {
      switch (_transitionStyle) {
        case VerseTransitionStyle.fadeOnly:
          _transitionStyle = VerseTransitionStyle.fadeScale;
          break;
        case VerseTransitionStyle.fadeScale:
          _transitionStyle = VerseTransitionStyle.fadeSlide;
          break;
        case VerseTransitionStyle.fadeSlide:
          _transitionStyle = VerseTransitionStyle.elegant;
          break;
        case VerseTransitionStyle.elegant:
          _transitionStyle = VerseTransitionStyle.fadeOnly;
          break;
      }
    });

    // Show a brief feedback to user about the new style
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Animation style: ${_getAnimationStyleName()}'), duration: const Duration(milliseconds: 1500), behavior: SnackBarBehavior.floating));
  }

  /// Get a user-friendly name for the current animation style
  String _getAnimationStyleName() {
    switch (_transitionStyle) {
      case VerseTransitionStyle.fadeOnly:
        return 'Simple Fade';
      case VerseTransitionStyle.fadeScale:
        return 'Fade & Scale';
      case VerseTransitionStyle.fadeSlide:
        return 'Fade & Slide';
      case VerseTransitionStyle.elegant:
        return 'Elegant';
    }
  }

  /// Shows the settings modal for reciter and surah selection.
  void _showSettingsModal() {
    _onUserInteraction(); // This is a user interaction
    showDialog(
      context: context,
      builder:
          (context) => SettingsModal(
            selectedReciter: _selectedReciter,
            selectedSurah: _selectedSurah,
            onSelectionComplete: _onSelectionComplete,
            animationStyle: _transitionStyle,
            onAnimationStyleChanged: (style) {
              setState(() {
                _transitionStyle = style;
              });
            },
          ),
    );
  }

  /// Loads and caches all surahs for navigation purposes
  Future<void> _loadAllSurahs() async {
    if (_allSurahs == null) {
      _allSurahs = await _quranApiService.getSurahList();
    }
  }

  /// Gets the next surah in sequence, or null if current is the last surah
  Surah? _getNextSurah() {
    if (_selectedSurah == null || _allSurahs == null) return null;

    // Quran has 114 surahs, so if we're at surah 114, there's no next surah
    if (_selectedSurah!.number >= 114) return null;

    // Find the next surah by number
    return _allSurahs!.firstWhere(
      (surah) => surah.number == _selectedSurah!.number + 1,
      orElse: () => _selectedSurah!, // Fallback to current if not found
    );
  }

  /// Automatically advances to the next surah when current surah completes
  Future<void> _handleSurahCompletion() async {
    final nextSurah = _getNextSurah();

    if (nextSurah != null && _selectedReciter != null) {
      // Update the selected surah to the next one
      setState(() {
        _selectedSurah = nextSurah;
      });

      // Start playing the next surah
      await _audioService.playSurah(surah: nextSurah, reciter: _selectedReciter!);
    }
    // Note: When reaching the end of the Quran (surah 114), playback simply stops
    // without any notification, providing a clean, uninterrupted experience
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    _appBarAnimationController.dispose();
    _bottomNavAnimationController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // App bar that slides up and out during focus mode - always present but animated
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: SlideTransition(
          position: _appBarSlideAnimation,
          child: AppBar(
            title: const Text('Quran'),
            centerTitle: true,
            actions: [
              // Animation style toggle button
              IconButton(
                icon: const Icon(Icons.auto_awesome),
                onPressed: () {
                  _onUserInteraction();
                  _cycleAnimationStyle();
                },
                tooltip: 'Change Animation Style',
              ),
            ],
          ),
        ),
      ),
      // Body content with enhanced verse transitions
      body: SafeArea(
        child: Column(
          children: [
            // Main verse content
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isInFocusMode) {
                    _exitFocusModeWithAnimation();
                  } else {
                    _enterFocusMode();
                  }
                },
                behavior: HitTestBehavior.opaque,
                child: AnimatedVerseTransition(currentAyah: _currentDisplayAyah, nextAyah: _nextDisplayAyah, currentSurah: _selectedSurah, isPlaying: _isPlaying, focusMode: _isInFocusMode, showingNext: _showingNextAyah, transitionStyle: _transitionStyle),
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation - always present but slides down during focus mode
      bottomNavigationBar: SlideTransition(
        position: _bottomNavSlideAnimation,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Stop button - disabled when no content
                IconButton(
                  icon: const Icon(Icons.stop),
                  iconSize: 32,
                  onPressed:
                      (_currentDisplayAyah != null && _selectedSurah != null)
                          ? () async {
                            _onUserInteraction();
                            await _audioService.stop();
                          }
                          : null, // Disabled when no content
                ),
                // Center button - Play/Pause when content available, nothing otherwise
                if (_currentDisplayAyah != null && _selectedSurah != null)
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
                // Settings button - always available
                IconButton(icon: const Icon(Icons.tune), iconSize: 32, onPressed: _showSettingsModal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
