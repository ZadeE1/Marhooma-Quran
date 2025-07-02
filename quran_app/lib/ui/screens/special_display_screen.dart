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
  Ayah? _currentDisplayAyah; // What's currently visible on screen
  Ayah? _nextDisplayAyah; // What will be shown next (pre-loaded)
  int? _lastAyahNumber; // Track the last ayah number we processed
  bool _isPlaying = false;
  bool _showingNextAyah = false; // Toggle between current and next display

  // Focus mode state and timer
  bool _isInFocusMode = false;
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(seconds: 10);

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
    _appBarAnimationController.dispose();
    _bottomNavAnimationController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onUserInteraction,
      onPanDown: (_) => _onUserInteraction(),
      behavior: HitTestBehavior.opaque,
      child: Scaffold(
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
                // Debug button to manually toggle focus mode
                IconButton(
                  icon: Icon(_isInFocusMode ? Icons.fullscreen_exit : Icons.fullscreen),
                  onPressed: () {
                    _onUserInteraction();
                    if (_isInFocusMode) {
                      _exitFocusModeWithAnimation();
                    } else {
                      _enterFocusMode();
                    }
                  },
                  tooltip: _isInFocusMode ? 'Exit Focus Mode' : 'Enter Focus Mode',
                ),
                IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsModal, tooltip: 'Select Reciter & Surah'),
              ],
            ),
          ),
        ),
        // Body content with smooth ayah cross-fade transitions using Stack
        body: SafeArea(
          child: Stack(
            children: [
              // Display A: Shows current or next ayah based on toggle
              AnimatedOpacity(opacity: _showingNextAyah ? 0.0 : 1.0, duration: const Duration(milliseconds: 400), child: CurrentVerseDisplay(currentAyah: _currentDisplayAyah, currentSurah: _selectedSurah, isPlaying: _isPlaying, focusMode: _isInFocusMode)),
              // Display B: Shows the alternate content for smooth transitions
              AnimatedOpacity(opacity: _showingNextAyah ? 1.0 : 0.0, duration: const Duration(milliseconds: 400), child: CurrentVerseDisplay(currentAyah: _nextDisplayAyah, currentSurah: _selectedSurah, isPlaying: _isPlaying, focusMode: _isInFocusMode)),
            ],
          ),
        ),
        // Bottom navigation - always present but slides down during focus mode
        bottomNavigationBar:
            _currentDisplayAyah != null && _selectedSurah != null
                ? SlideTransition(
                  position: _bottomNavSlideAnimation,
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
                : null, // Only null when no content is available, not based on focus mode
      ),
    );
  }
}
