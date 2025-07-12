import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:wakelock_plus/wakelock_plus.dart';

/// The main and only screen of the app - displays the current verse
/// with settings to select reciter and surah.
///
/// This screen replaces the previous tab-based navigation structure
/// and focuses on a single, centered verse display experience.
///
/// Features focus mode that activates after inactivity to provide
/// distraction-free reading with only Arabic text and translation visible.
/// In focus mode, both the app UI elements and Android system UI bars
/// (status bar and navigation bar) are hidden for a fully immersive experience.
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
  late AnimationController _skipWidgetAnimationController;
  late Animation<Offset> _appBarSlideAnimation;
  late Animation<Offset> _bottomNavSlideAnimation;
  late Animation<Offset> _skipWidgetSlideAnimation;

  // Indicates if the audio player is preparing the surah (building playlist / initial buffering)
  bool _isPreparingAudio = false;

  // Skip to ayah floating widget state
  bool _showSkipToAyahWidget = false;
  final TextEditingController _skipToAyahController = TextEditingController();

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

    _skipWidgetAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Quick, smooth animation
      vsync: this,
    );

    // App bar slides up and out
    _appBarSlideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, -1)).animate(CurvedAnimation(parent: _appBarAnimationController, curve: Curves.easeInOut));

    // Bottom navigation slides down and out
    _bottomNavSlideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(0, 1)).animate(CurvedAnimation(parent: _bottomNavAnimationController, curve: Curves.easeInOut));

    // Skip widget slides right and out - using much larger offset to ensure it fully disappears
    _skipWidgetSlideAnimation = Tween<Offset>(begin: const Offset(0, 0), end: const Offset(3, 0)).animate(CurvedAnimation(parent: _skipWidgetAnimationController, curve: Curves.easeInOut));
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

  /// Hides Android system UI bars (status bar and navigation bar) for immersive experience.
  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky, overlays: []);
  }

  /// Shows Android system UI bars back to normal state.
  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
  }

  /// Smoothly enters focus mode with fade animation and hides system UI.
  void _enterFocusMode() {
    setState(() {
      _isInFocusMode = true;
    });
    _appBarAnimationController.forward();
    _skipWidgetAnimationController.forward();
    _bottomNavAnimationController.forward();
    print('🎯 Skip widget animation started: ${_skipWidgetAnimationController.value}');

    // Hide Android system UI bars for truly immersive experience
    _hideSystemUI();
    // Keep the screen awake while in focus mode
    WakelockPlus.enable();
  }

  /// Smoothly exits focus mode with fade animation and restores system UI.
  void _exitFocusModeWithAnimation() {
    // Restore Android system UI bars immediately when exiting focus mode
    _showSystemUI();
    // Allow the screen to sleep again
    WakelockPlus.disable();

    // Build list of animations to reverse
    List<Future<void>> animations = [_appBarAnimationController.reverse(), _skipWidgetAnimationController.reverse(), _bottomNavAnimationController.reverse()];

    // Use Future.wait to ensure all animations complete before updating state
    Future.wait(animations).then((_) {
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
      // Show loading overlay while preparing audio
      setState(() {
        _isPreparingAudio = true;
      });

      await _audioService.playSurah(surah: _selectedSurah!, reciter: _selectedReciter!);

      // Hide loading overlay once preparation is done
      if (mounted) {
        setState(() {
          _isPreparingAudio = false;
        });
      }
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

  /// Handles skipping to a specific ayah number
  Future<void> _handleSkipToAyah() async {
    // Check if widget is still mounted
    if (!mounted) return;

    final ayahNumberText = _skipToAyahController.text.trim();
    if (ayahNumberText.isEmpty) {
      return;
    }

    final ayahNumber = int.tryParse(ayahNumberText);
    if (ayahNumber == null || ayahNumber < 1) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid ayah number'), duration: Duration(seconds: 2)));
      }
      return;
    }

    // Store surah reference to avoid null issues during async operations
    final currentSurah = _selectedSurah;
    if (currentSurah == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a surah first'), duration: Duration(seconds: 2)));
      }
      return;
    }

    if (ayahNumber > currentSurah.ayahCount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ayah number must be between 1 and ${currentSurah.ayahCount}'), duration: const Duration(seconds: 2)));
      }
      return;
    }

    try {
      final success = await _audioService.skipToAyah(ayahNumber);

      // Check if widget is still mounted after async operation
      if (!mounted) return;

      if (success) {
        setState(() {
          _showSkipToAyahWidget = false;
        });
        _skipToAyahController.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Skipped to ayah $ayahNumber'), duration: const Duration(seconds: 1)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to skip to ayah'), duration: Duration(seconds: 2)));
      }
    } catch (e) {
      // Handle any unexpected errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error skipping to ayah: ${e.toString()}'), duration: const Duration(seconds: 2)));
      }
    }
  }

  /// Toggles the skip to ayah widget visibility
  void _toggleSkipToAyahWidget() {
    if (!mounted) return;

    setState(() {
      _showSkipToAyahWidget = !_showSkipToAyahWidget;
      if (!_showSkipToAyahWidget) {
        _skipToAyahController.clear();
      }
    });
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
    _skipWidgetAnimationController.dispose();
    _skipToAyahController.dispose();
    _audioService.dispose();
    // Ensure system UI is restored when disposing the screen
    _showSystemUI();
    // Ensure wakelock is disabled when the screen is disposed
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      // App bar that slides up and out during focus mode - hidden in landscape orientation
      appBar:
          MediaQuery.of(context).orientation == Orientation.landscape
              ? null
              : PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: SlideTransition(
                  position: _appBarSlideAnimation,
                  child: AppBar(
                    title:
                        _selectedSurah != null && _currentDisplayAyah != null
                            ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('${_selectedSurah!.name} - Verse ${_currentDisplayAyah!.numberInSurah}', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                                Row(mainAxisSize: MainAxisSize.min, children: [Icon(_isPlaying ? Icons.volume_up : Icons.volume_off, size: 14, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)), const SizedBox(width: 4), Text(_isPlaying ? 'Now Playing' : 'Paused', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)))]),
                              ],
                            )
                            : const Text('Quran'),
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
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                return Column(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            _isInFocusMode
                                ? () {
                                  _exitFocusModeWithAnimation();
                                }
                                : () {
                                  _enterFocusMode();
                                },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedVerseTransition(currentAyah: _currentDisplayAyah, nextAyah: _nextDisplayAyah, currentSurah: _selectedSurah, isPlaying: _isPlaying, showingNext: _showingNextAyah, transitionStyle: _transitionStyle),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          // Loading overlay removed

          // Skip to ayah floating widget
          if (_currentDisplayAyah != null && _selectedSurah != null)
            Positioned(
              bottom: 20,
              right: 16,
              child: SlideTransition(
                position: _skipWidgetSlideAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Skip to ayah input field - shows when widget is expanded
                    if (_showSkipToAyahWidget)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3))),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(width: 80, child: TextField(controller: _skipToAyahController, keyboardType: TextInputType.number, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium, decoration: InputDecoration(hintText: _selectedSurah != null ? '1-${_selectedSurah!.ayahCount}' : '1-10', hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 4)), onSubmitted: (_) => _handleSkipToAyah())),
                                const SizedBox(width: 8),
                                IconButton(icon: const Icon(Icons.arrow_forward, size: 20), onPressed: _handleSkipToAyah, padding: const EdgeInsets.all(4), constraints: const BoxConstraints(minWidth: 28, minHeight: 28)),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Skip to ayah toggle button
                    FloatingActionButton.small(
                      onPressed: () {
                        _onUserInteraction();
                        _toggleSkipToAyahWidget();
                      },
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      child: Icon(_showSkipToAyahWidget ? Icons.close : Icons.skip_next),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      // Bottom navigation - always present, animation state controls visibility
      bottomNavigationBar: SlideTransition(
        position: _bottomNavSlideAnimation,
        child: SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Restart button - disabled when no content
                IconButton(
                  icon: const Icon(Icons.restart_alt),
                  iconSize: 32,
                  onPressed:
                      (_currentDisplayAyah != null && _selectedSurah != null)
                          ? () async {
                            _onUserInteraction();
                            await _audioService.playSurah(surah: _selectedSurah!, reciter: _selectedReciter!);
                          }
                          : null,
                ),
                // Center button - Play/Pause when content available
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
