import 'package:just_audio/just_audio.dart';
import '../models/surah.dart';
import '../models/reciter.dart';
import 'dart:developer' as developer;

/// A lightweight wrapper around [AudioPlayer] that prepares and plays
/// an entire surah for a given reciter. The class exposes minimal
/// functionality required by the UI so the complex audio logic is
/// isolated from widget code.
class QuranAudioPlayer {
  QuranAudioPlayer() : _audioPlayer = AudioPlayer(audioLoadConfiguration: const AudioLoadConfiguration(androidLoadControl: AndroidLoadControl(minBufferDuration: Duration(seconds: 8), maxBufferDuration: Duration(seconds: 15), bufferForPlaybackDuration: Duration(seconds: 4))));

  final AudioPlayer _audioPlayer;

  /// Public getters to expose useful audio status information.
  Stream<bool> get playingStream => _audioPlayer.playingStream;

  /// Emits the currently playing ayah number (1-based) or null if nothing is playing.
  Stream<int?> get currentAyahStream => _audioPlayer.currentIndexStream.map((index) => index != null ? index + 1 : null);

  /// Emits low-level player state events if the UI needs them for debugging or advanced UI.
  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;

  /// Start playing the given [surah] recited by [reciter].
  ///
  /// If [fromAyah] is provided, playback starts from that specific ayah
  /// (1-based index within the surah). Otherwise, playback starts from
  /// the beginning of the surah.
  Future<void> playSurah({required Surah surah, required Reciter reciter, int? fromAyah}) async {
    developer.log('Preparing to play surah ${surah.number} from ayah $fromAyah', name: 'QuranAudioPlayer');

    final int totalAyahs = surah.ayahCount;
    final playlist = ConcatenatingAudioSource(
      useLazyPreparation: false,
      children: List.generate(totalAyahs, (i) {
        final ayahNumber = i + 1;
        final surahPadded = surah.number.toString().padLeft(3, '0');
        final ayahPadded = ayahNumber.toString().padLeft(3, '0');
        final url = 'https://everyayah.com/data/${reciter.subfolder}/$surahPadded$ayahPadded.mp3';
        developer.log('Adding to playlist: $url', name: 'QuranAudioPlayer');
        return LockCachingAudioSource(Uri.parse(url));
      }),
    );

    try {
      await _audioPlayer.setAudioSource(playlist, initialIndex: fromAyah != null ? fromAyah - 1 : 0, initialPosition: Duration.zero, preload: true);

      // Pre-buffer to reduce stutter on first play.
      await _audioPlayer.load();
      await _audioPlayer.play();
    } catch (e, st) {
      developer.log('Error during playSurah: $e', name: 'QuranAudioPlayer', error: e, stackTrace: st);
    }
  }

  Future<void> play() => _audioPlayer.play();
  Future<void> pause() => _audioPlayer.pause();
  Future<void> stop() => _audioPlayer.stop();

  void dispose() => _audioPlayer.dispose();
}
