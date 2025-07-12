import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:http/http.dart' as http;
import '../models/surah.dart';
import '../models/reciter.dart';
import 'dart:developer' as developer;

/// A lightweight wrapper around [AudioPlayer] that prepares and plays
/// an entire surah for a given reciter. The class exposes minimal
/// functionality required by the UI so the complex audio logic is
/// isolated from widget code.
///
/// This service also integrates with Android's media controls, allowing
/// users to control playback from the notification panel, lock screen,
/// and other system-level media controls.
class QuranAudioPlayer {
  QuranAudioPlayer() : _audioPlayer = AudioPlayer(audioLoadConfiguration: const AudioLoadConfiguration(androidLoadControl: AndroidLoadControl(minBufferDuration: Duration(seconds: 8), maxBufferDuration: Duration(seconds: 15), bufferForPlaybackDuration: Duration(seconds: 4)))) {
    _initializeAudioSession();
  }

  final AudioPlayer _audioPlayer;

  // Current playback context for metadata
  Surah? _currentSurah;
  Reciter? _currentReciter;

  /// Initialize audio session for Android media controls integration
  Future<void> _initializeAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      developer.log('Audio session configured for media controls', name: 'QuranAudioPlayer');
    } catch (e) {
      developer.log('Failed to configure audio session: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Public getters to expose useful audio status information.
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  /// Emits the currently playing ayah number (1-based) or null if nothing is playing.
  Stream<int?> get currentAyahStream => _audioPlayer.currentIndexStream.map((index) => index != null ? index + 1 : null);

  /// Emits low-level player state events if the UI needs them for debugging or advanced UI.
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Get current position in the current ayah
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  /// Get duration of current ayah
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;

  /// Build an [AudioSource] appropriate for the current platform.
  ///
  /// `LockCachingAudioSource` offers on-device caching which is only
  /// supported on Android and iOS. On desktop and web, we fall back to a
  /// plain network stream using [AudioSource.uri] to avoid runtime issues
  /// where caching is not yet implemented (e.g. Windows).
  AudioSource _buildAudioSource(Uri uri, MediaItem tag) {
    final isMobile = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

    if (isMobile) {
      return LockCachingAudioSource(uri, tag: tag);
    }

    // Desktop/web fallback – streaming without caching.
    return AudioSource.uri(uri, tag: tag);
  }

  /// Start playing the given [surah] recited by [reciter].
  ///
  /// If [fromAyah] is provided, playback starts from that specific ayah
  /// (1-based index within the surah). Otherwise, playback starts from
  /// the beginning of the surah.
  Future<void> playSurah({required Surah surah, required Reciter reciter, int? fromAyah}) async {
    developer.log('Preparing to play surah ${surah.number} from ayah $fromAyah', name: 'QuranAudioPlayer');

    // Store current context for metadata
    _currentSurah = surah;
    _currentReciter = reciter;

    final int totalAyahs = surah.ayahCount;

    // Test first URL before creating full playlist
    final firstAyahUrl = _buildAyahUrl(surah.number, 1, reciter.subfolder);
    final isFirstUrlValid = await _validateUrl(firstAyahUrl);

    if (!isFirstUrlValid) {
      developer.log('First ayah URL is invalid: $firstAyahUrl', name: 'QuranAudioPlayer');
      return;
    }

    final playlist = ConcatenatingAudioSource(
      // Enable lazy preparation so that only the first ayah is prepared immediately.
      // This significantly decreases the time between pressing the "Done" button
      // in the surah-selecting modal and the audio actually starting, because the
      // player no longer issues network HEAD requests for every single ayah
      // before beginning playback. Subsequent ayahs will be prepared on demand
      // just before they are needed.
      useLazyPreparation: true,
      children: List.generate(totalAyahs, (i) {
        final ayahNumber = i + 1;
        final url = _buildAyahUrl(surah.number, ayahNumber, reciter.subfolder);

        developer.log('Adding to playlist: $url', name: 'QuranAudioPlayer');

        // Create an audio source suited for the current platform.
        return _buildAudioSource(
          Uri.parse(url),
          MediaItem(
            id: url, // Unique ID for the track
            album: surah.name,
            title: 'Ayah $ayahNumber',
            artist: reciter.name,
          ),
        );
      }),
    );

    try {
      await _audioPlayer.setAudioSource(playlist, initialIndex: fromAyah != null ? fromAyah - 1 : 0, initialPosition: Duration.zero, preload: true);

      // Pre-buffer to reduce stutter on first play.
      await _audioPlayer.load();
      await _audioPlayer.play();

      developer.log('Started playing ${surah.name} by ${reciter.name}', name: 'QuranAudioPlayer');
    } catch (e, st) {
      developer.log('Error during playSurah: $e', name: 'QuranAudioPlayer', error: e, stackTrace: st);
    }
  }

  /// Build the URL for a specific ayah
  String _buildAyahUrl(int surahNumber, int ayahNumber, String reciterSubfolder) {
    final surahPadded = surahNumber.toString().padLeft(3, '0');
    final ayahPadded = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterSubfolder/$surahPadded$ayahPadded.mp3';
  }

  /// Validate if a URL is accessible
  Future<bool> _validateUrl(String url) async {
    try {
      developer.log('Validating URL: $url', name: 'QuranAudioPlayer');
      final response = await http.head(Uri.parse(url));
      final isValid = response.statusCode == 200;
      developer.log('URL validation result: $isValid (status: ${response.statusCode})', name: 'QuranAudioPlayer');
      return isValid;
    } catch (e) {
      developer.log('URL validation failed: $e', name: 'QuranAudioPlayer');
      return false;
    }
  }

  /// Play audio - can be controlled from Android media controls
  Future<void> play() async {
    try {
      await _audioPlayer.play();
      developer.log('Playback resumed', name: 'QuranAudioPlayer');
    } catch (e) {
      developer.log('Error during play: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Pause audio - can be controlled from Android media controls
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      developer.log('Playback paused', name: 'QuranAudioPlayer');
    } catch (e) {
      developer.log('Error during pause: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Stop audio and clear the playlist
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _currentSurah = null;
      _currentReciter = null;
      developer.log('Playback stopped', name: 'QuranAudioPlayer');
    } catch (e) {
      developer.log('Error during stop: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Seek to next ayah - can be controlled from Android media controls
  Future<void> seekToNext() async {
    try {
      if (_audioPlayer.hasNext) {
        await _audioPlayer.seekToNext();
        developer.log('Skipped to next ayah', name: 'QuranAudioPlayer');
      }
    } catch (e) {
      developer.log('Error during seekToNext: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Seek to previous ayah - can be controlled from Android media controls
  Future<void> seekToPrevious() async {
    try {
      if (_audioPlayer.hasPrevious) {
        await _audioPlayer.seekToPrevious();
        developer.log('Skipped to previous ayah', name: 'QuranAudioPlayer');
      }
    } catch (e) {
      developer.log('Error during seekToPrevious: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Skip to a specific ayah index in the current playlist
  ///
  /// [ayahIndex] is 1-based (first ayah is 1, not 0)
  /// Returns true if successful, false if the index is out of range
  Future<bool> skipToAyah(int ayahIndex) async {
    try {
      if (_currentSurah == null) {
        developer.log('Cannot skip to ayah: no surah currently loaded', name: 'QuranAudioPlayer');
        return false;
      }

      // Convert 1-based ayah index to 0-based for the audio player
      final zeroBasedIndex = ayahIndex - 1;

      // Validate the index is within bounds
      if (zeroBasedIndex < 0 || zeroBasedIndex >= _currentSurah!.ayahCount) {
        developer.log('Cannot skip to ayah $ayahIndex: index out of range (1-${_currentSurah!.ayahCount})', name: 'QuranAudioPlayer');
        return false;
      }

      // Check if the audio player has a valid audio source
      if (_audioPlayer.audioSource == null) {
        developer.log('Cannot skip to ayah: no audio source loaded', name: 'QuranAudioPlayer');
        return false;
      }

      // Seek to the specific index with error handling
      await _audioPlayer.seek(Duration.zero, index: zeroBasedIndex);
      developer.log('Skipped to ayah $ayahIndex (index $zeroBasedIndex)', name: 'QuranAudioPlayer');
      return true;
    } catch (e, stackTrace) {
      developer.log('Error during skipToAyah: $e', name: 'QuranAudioPlayer', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Seek to specific position in current ayah
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      developer.log('Seeked to position: ${position.inSeconds}s', name: 'QuranAudioPlayer');
    } catch (e) {
      developer.log('Error during seek: $e', name: 'QuranAudioPlayer');
    }
  }

  /// Get current playing context
  String? get currentSurahName => _currentSurah?.name;
  String? get currentReciterName => _currentReciter?.name;
  int? get currentSurahNumber => _currentSurah?.number;

  /// Check if audio is currently playing
  bool get isPlaying => _audioPlayer.playing;

  /// Test method to verify URL construction - for debugging
  void testUrlConstruction() {
    developer.log('=== Testing URL Construction ===', name: 'QuranAudioPlayer');

    // Test Al-Fatiha (surah 1) with Abdul Basit
    final testUrl = _buildAyahUrl(1, 1, 'Abdul_Basit_Murattal_64kbps');
    developer.log('Test URL: $testUrl', name: 'QuranAudioPlayer');

    // Test with different padding
    final testUrl2 = _buildAyahUrl(2, 10, 'Abdul_Basit_Murattal_64kbps');
    developer.log('Test URL 2: $testUrl2', name: 'QuranAudioPlayer');

    final testUrl3 = _buildAyahUrl(114, 6, 'Abdul_Basit_Murattal_64kbps');
    developer.log('Test URL 3: $testUrl3', name: 'QuranAudioPlayer');
  }

  /// Test method to play a single audio file - for debugging Windows audio
  Future<void> testSingleAudio() async {
    developer.log('=== Testing Single Audio File ===', name: 'QuranAudioPlayer');

    try {
      final testUrl = 'https://everyayah.com/data/Abdul_Basit_Murattal_64kbps/001001.mp3';
      developer.log('Testing single URL: $testUrl', name: 'QuranAudioPlayer');

      final audioSource = _buildAudioSource(Uri.parse(testUrl), MediaItem(id: testUrl, album: 'Test', title: 'Test Ayah', artist: 'Test Reciter'));

      await _audioPlayer.setAudioSource(audioSource);
      await _audioPlayer.load();
      await _audioPlayer.play();

      developer.log('Single audio test started successfully', name: 'QuranAudioPlayer');
    } catch (e, st) {
      developer.log('Single audio test failed: $e', name: 'QuranAudioPlayer', error: e, stackTrace: st);
    }
  }

  /// Dispose of the audio player and clean up resources
  void dispose() {
    _audioPlayer.dispose();
    developer.log('Audio player disposed', name: 'QuranAudioPlayer');
  }
}
