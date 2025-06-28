import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:audio_session/audio_session.dart';

import '../data/repositories/audio_api.dart';
import '../data/models/surah.dart';

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

  List<Surah> get queuedSurahs => _queuedSurahs;
  Surah? get currentSurah => _player.currentIndex != null && _player.currentIndex! < _queuedSurahs.length ? _queuedSurahs[_player.currentIndex!] : null;
  int get selectedReciterId => _selectedReciterId;
  String get selectedReciterName => AudioApi.availableReciters[_selectedReciterId] ?? 'Unknown';

  bool get isPlaying => _player.playing;
  bool get isLoading => _player.processingState == ProcessingState.loading || _player.processingState == ProcessingState.buffering;

  Stream<Duration> get positionStream => _player.positionStream;
  int? get currentIndex => _player.currentIndex;

  /// Plays a single surah (clears queue and starts fresh)
  Future<void> playSurah(Surah surah) async {
    await _createPlaylistWithSurah(surah);
    await _player.play();
  }

  /// Adds a surah to the current queue
  Future<void> addToQueue(Surah surah) async {
    if (_playlist == null) {
      await playSurah(surah);
      return;
    }

    final url = await _api.fetchSurahAudio(surah.number, reciterId: _selectedReciterId);
    await _playlist!.add(AudioSource.uri(Uri.parse(url)));
    _queuedSurahs.add(surah);
    notifyListeners();
  }

  /// Plays multiple surahs as a gapless playlist
  Future<void> playPlaylist(List<Surah> surahs) async {
    if (surahs.isEmpty) return;

    _queuedSurahs = List.from(surahs);
    notifyListeners();

    // Fetch all URLs and create playlist
    final sources = <AudioSource>[];
    for (final surah in surahs) {
      final url = await _api.fetchSurahAudio(surah.number, reciterId: _selectedReciterId);
      sources.add(AudioSource.uri(Uri.parse(url)));
    }

    _playlist = ConcatenatingAudioSource(useLazyPreparation: false, shuffleOrder: DefaultShuffleOrder(), children: sources);

    await _player.setAudioSource(_playlist!);
    await _player.play();
  }

  /// Creates a new playlist with just one surah
  Future<void> _createPlaylistWithSurah(Surah surah) async {
    _queuedSurahs = [surah];
    notifyListeners();

    final url = await _api.fetchSurahAudio(surah.number, reciterId: _selectedReciterId);
    _playlist = ConcatenatingAudioSource(useLazyPreparation: false, children: [AudioSource.uri(Uri.parse(url))]);

    await _player.setAudioSource(_playlist!);
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
