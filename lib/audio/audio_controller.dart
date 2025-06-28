import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../data/repositories/audio_api.dart';
import '../data/models/surah.dart';
import '../data/models/ayah.dart';

/// Singleton that manages audio playback for surah recitations using the
/// FFmpeg-powered `media_kit` player.  Keeping this class <500 lines makes it
/// easier to maintain.
class AudioController with ChangeNotifier {
  AudioController._() {
    // Listen to common player state streams and propagate to widgets.
    _player.stream.playing.listen((_) => notifyListeners());
    _player.stream.playlist.listen((_) => notifyListeners());
  }

  // --------- Singleton boiler-plate -----------------------------------------------------------
  static final AudioController instance = AudioController._();

  // --------- Internal fields ------------------------------------------------------------------
  final Player _player = Player();
  final _api = const AudioApi();

  int _selectedReciterId = 1; // Default: Mishary Rashid Al-Afasy
  List<Surah> _queuedSurahs = [];

  // --------- Public getters -------------------------------------------------------------------
  List<Surah> get queuedSurahs => _queuedSurahs;

  Surah? get currentSurah {
    final idx = currentIndex;
    if (idx == null || idx < 0 || idx >= _queuedSurahs.length) return null;
    return _queuedSurahs[idx];
  }

  int get selectedReciterId => _selectedReciterId;
  String get selectedReciterName => AudioApi.availableReciters[_selectedReciterId] ?? 'Unknown';

  bool get isPlaying => _player.state.playing;
  bool get isLoading => _player.state.buffering;

  Stream<Duration> get positionStream => _player.stream.position;
  int? get currentIndex => _player.state.playlist.index;

  /// Returns `null` now that per-ayah tracking is no longer supported with
  /// the FFmpeg migration. UI code relying on this can fall back to other
  /// heuristics already present in the placeholder screens.
  Ayah? get currentAyah => null;

  // --------- Core playback helpers ------------------------------------------------------------

  /// Plays a single surah. Clears any existing queue.
  Future<void> playSurah(Surah surah) async {
    final url = await _api.fetchSurahAudio(surah.number, reciterId: _selectedReciterId);
    _queuedSurahs = [surah];
    await _player.open(Media(url));
    await _player.play();
  }

  /// Appends a surah to the current queue. If nothing has been queued yet this
  /// simply behaves like [playSurah].
  Future<void> addToQueue(Surah surah) async {
    if (_queuedSurahs.isEmpty) {
      await playSurah(surah);
      return;
    }

    final url = await _api.fetchSurahAudio(surah.number, reciterId: _selectedReciterId);
    _queuedSurahs.add(surah);
    await _player.add(Media(url));
    notifyListeners();
  }

  /// Replaces the current queue with the supplied list and starts playback.
  Future<void> playPlaylist(List<Surah> surahs) async {
    if (surahs.isEmpty) return;

    final media = <Media>[];
    for (final s in surahs) {
      final url = await _api.fetchSurahAudio(s.number, reciterId: _selectedReciterId);
      media.add(Media(url));
    }

    _queuedSurahs = List.of(surahs);
    await _player.open(Playlist(media));
    await _player.play();
  }

  // ---------------- Misc controls -------------------------------------------------------------

  Future<void> toggle() async => isPlaying ? _player.pause() : _player.play();
  Future<void> seekToNext() async => _player.next();
  Future<void> seekToPrevious() async => _player.previous();
  Future<void> seekToIndex(int index) async => _player.jump(index);

  /// Clean-up – MUST be called from `dispose` of the top-level provider.
  void disposeController() => _player.dispose();

  /// Changes the reciter for future playback.
  void setReciter(int reciterId) {
    if (AudioApi.availableReciters.containsKey(reciterId)) {
      _selectedReciterId = reciterId;
      notifyListeners();
    }
  }
}
