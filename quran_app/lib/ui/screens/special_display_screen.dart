import 'package:flutter/material.dart';
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
class SpecialDisplayScreen extends StatefulWidget {
  const SpecialDisplayScreen({super.key});

  @override
  State<SpecialDisplayScreen> createState() => _SpecialDisplayScreenState();
}

class _SpecialDisplayScreenState extends State<SpecialDisplayScreen> {
  // Services for audio and text functionality
  final QuranAudioPlayer _audioService = QuranAudioPlayer();
  final QuranTextService _textService = QuranTextService();

  // Current state
  Reciter? _selectedReciter;
  Surah? _selectedSurah;
  Ayah? _currentAyah;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _setupAudioListeners();
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
  }

  /// Starts audio playback of the selected surah.
  Future<void> _startPlayback() async {
    if (_selectedReciter != null && _selectedSurah != null) {
      await _audioService.playSurah(surah: _selectedSurah!, reciter: _selectedReciter!);
    }
  }

  /// Shows the settings modal for reciter and surah selection.
  void _showSettingsModal() {
    showDialog(context: context, builder: (context) => SettingsModal(selectedReciter: _selectedReciter, selectedSurah: _selectedSurah, onSelectionComplete: _onSelectionComplete));
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran'),
        centerTitle: true,
        actions: [
          // Settings dial button to open the modal
          IconButton(icon: const Icon(Icons.settings), onPressed: _showSettingsModal, tooltip: 'Select Reciter & Surah'),
        ],
      ),
      body: CurrentVerseDisplay(currentAyah: _currentAyah, currentSurah: _selectedSurah, isPlaying: _isPlaying),
      // Audio controls when something is playing
      bottomNavigationBar:
          _currentAyah != null && _selectedSurah != null
              ? Container(
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
                        await _audioService.stop();
                      },
                    ),
                    // Play/Pause button
                    IconButton(
                      icon: Icon(_isPlaying ? Icons.pause_circle : Icons.play_circle, size: 48),
                      onPressed: () async {
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
              )
              : null,
    );
  }
}
