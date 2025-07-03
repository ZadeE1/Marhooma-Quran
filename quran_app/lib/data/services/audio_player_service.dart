import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
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
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: false,
      children: List.generate(totalAyahs, (i) {
        final ayahNumber = i + 1;
        final surahPadded = surah.number.toString().padLeft(3, '0');
        final ayahPadded = ayahNumber.toString().padLeft(3, '0');
        final url = 'https://everyayah.com/data/${reciter.subfolder}/$surahPadded$ayahPadded.mp3';

        developer.log('Adding to playlist: $url', name: 'QuranAudioPlayer');

        // Create audio source with metadata for Android media controls
        return LockCachingAudioSource(Uri.parse(url));
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

  /// Dispose of the audio player and clean up resources
  void dispose() {
    _audioPlayer.dispose();
    developer.log('Audio player disposed', name: 'QuranAudioPlayer');
  }
}
