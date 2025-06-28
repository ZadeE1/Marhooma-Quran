import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

import '../data/repositories/audio_api.dart';
import '../data/models/surah.dart';
import '../data/models/ayah.dart';
import '../data/repositories/quran_api.dart';

/// Singleton that manages audio playback for surah recitations using gapless playlists.
class AudioController with ChangeNotifier {
  AudioController._() {
    _initAudioSession();
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
  }

  static final AudioController instance = AudioController._();

  final _player = AudioPlayer();
  final _api = const AudioApi();
  int _selectedReciterId = 1; // Default to Mishary Rashid Al Afasy
  ConcatenatingAudioSource? _playlist;
  List<Surah> _queuedSurahs = [];
  List<Ayah> _queuedAyahs = []; // Flat list of ayahs matching the playlist order

  List<Surah> get queuedSurahs => _queuedSurahs;
  Surah? get currentSurah {
    if (_player.currentIndex == null) return null;
    var index = _player.currentIndex!;
    var offset = 0;
    for (final surah in _queuedSurahs) {
      final ayahCount = surah.ayahs.length;
      if (index < offset + ayahCount) {
        return surah;
      }
      offset += ayahCount;
    }
    return null;
  }

  int get selectedReciterId => _selectedReciterId;
  String get selectedReciterName => AudioApi.availableReciters[_selectedReciterId] ?? 'Unknown';

  bool get isPlaying => _player.playing;
  bool get isLoading => _player.processingState == ProcessingState.loading || _player.processingState == ProcessingState.buffering;

  Stream<Duration> get positionStream => _player.positionStream;
  int? get currentIndex => _player.currentIndex;

  Ayah? get currentAyah => _player.currentIndex != null && _player.currentIndex! < _queuedAyahs.length ? _queuedAyahs[_player.currentIndex!] : null;

  /// Plays a single surah (clears queue and starts fresh). Each ayah becomes its own
  /// track so we can keep accurate verse indices.
  Future<void> playSurah(Surah surah) async {
    await _createPlaylistForSurah(surah);
    await _player.play();
  }

  /// Adds a surah to the current queue
  Future<void> addToQueue(Surah surah) async {
    if (_playlist == null) {
      await playSurah(surah);
      return;
    }

    final fullSurah = await _ensureAyahsLoaded(surah);
    _queuedSurahs.add(fullSurah);

    for (final ayah in fullSurah.ayahs) {
      _queuedAyahs.add(ayah);
      final url = AudioApi.buildAyahUrl(_selectedReciterId, fullSurah.number, ayah.numberInSurah);
      await _playlist!.add(AudioSource.uri(Uri.parse(url)));
    }

    notifyListeners();
  }

  /// Plays multiple surahs as a gapless playlist (verse-by-verse)
  Future<void> playPlaylist(List<Surah> surahs) async {
    if (surahs.isEmpty) return;

    _queuedSurahs = [];
    _queuedAyahs = [];
    final children = <AudioSource>[];

    for (final surah in surahs) {
      final fullSurah = await _ensureAyahsLoaded(surah);
      _queuedSurahs.add(fullSurah);
      for (final ayah in fullSurah.ayahs) {
        _queuedAyahs.add(ayah);
        final url = AudioApi.buildAyahUrl(_selectedReciterId, fullSurah.number, ayah.numberInSurah);
        children.add(AudioSource.uri(Uri.parse(url)));
      }
    }

    _playlist = ConcatenatingAudioSource(useLazyPreparation: false, shuffleOrder: DefaultShuffleOrder(), children: children);

    await _player.setAudioSource(_playlist!);
    notifyListeners();
    await _player.play();
  }

  /// Creates a new playlist for a single surah (verse-by-verse)
  Future<void> _createPlaylistForSurah(Surah surah) async {
    final fullSurah = await _ensureAyahsLoaded(surah);

    _queuedSurahs = [fullSurah];
    _queuedAyahs = [];

    final children = <AudioSource>[];
    for (final ayah in fullSurah.ayahs) {
      _queuedAyahs.add(ayah);
      final url = AudioApi.buildAyahUrl(_selectedReciterId, fullSurah.number, ayah.numberInSurah);
      children.add(AudioSource.uri(Uri.parse(url)));
    }

    _playlist = ConcatenatingAudioSource(useLazyPreparation: false, children: children);

    await _player.setAudioSource(_playlist!);
    notifyListeners();
  }

  /// Ensures we have ayah data for a surah (fetches from API if missing)
  Future<Surah> _ensureAyahsLoaded(Surah surah) async {
    if (surah.ayahs.isNotEmpty) return surah;
    final api = const QuranApi();
    final ayahs = await api.fetchAyahs(surah.number);
    return surah.copyWithAyahs(ayahs);
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> seekToNext() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> seekToPrevious() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> seekToIndex(int index) async {
    await _player.seek(Duration.zero, index: index);
  }

  void disposeController() {
    _player.dispose();
  }

  /// Changes the reciter for future playback
  void setReciter(int reciterId) {
    if (AudioApi.availableReciters.containsKey(reciterId)) {
      _selectedReciterId = reciterId;
      notifyListeners();
    }
  }

  /// Initialize audio session for consistent playback
  Future<void> _initAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Set audio player to handle sample rate differences gracefully
    await _player.setVolume(1.0);
    await _player.setSpeed(1.0);
  }
}
