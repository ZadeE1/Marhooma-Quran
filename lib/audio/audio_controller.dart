import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:flutter/foundation.dart';

import '../data/repositories/audio_api.dart';
import '../data/models/surah.dart';

/// Singleton that manages audio playback for surah recitations.
class AudioController with ChangeNotifier {
  AudioController._() {
    _player.playerStateStream.listen((_) => notifyListeners());
  }
  static final AudioController instance = AudioController._();

  final _player = AudioPlayer();
  final _api = const AudioApi();

  Surah? _currentSurah;
  Surah? get currentSurah => _currentSurah;

  bool get isPlaying => _player.playing;

  Stream<Duration> get positionStream => _player.positionStream;

  bool get isLoading => _player.processingState == ProcessingState.loading || _player.processingState == ProcessingState.buffering;

  bool _downloading = false;
  double _progress = 0.0;

  bool get isDownloading => _downloading;
  double get downloadProgress => _progress;

  bool get isBusy => isDownloading || isLoading;

  Future<String> _getCachedPath(int surahNumber) async {
    final dir = await getTemporaryDirectory();
    final cacheDir = Directory('${dir.path}/audio_cache');
    if (!await cacheDir.exists()) {
      await cacheDir.create(recursive: true);
    }
    return '${cacheDir.path}/$surahNumber.mp3';
  }

  Future<String> _downloadIfNeeded(int surahNumber, String url) async {
    final filePath = await _getCachedPath(surahNumber);
    final file = File(filePath);
    if (await file.exists()) return filePath;

    _downloading = true;
    _progress = 0;
    notifyListeners();

    final request = await http.Client().send(http.Request('GET', Uri.parse(url)));
    final total = request.contentLength ?? 0;
    List<int> bytes = [];
    int received = 0;
    await for (final chunk in request.stream) {
      bytes.addAll(chunk);
      received += chunk.length;
      if (total > 0) {
        _progress = received / total;
        notifyListeners();
      }
    }
    await file.writeAsBytes(bytes);

    _downloading = false;
    _progress = 0;
    notifyListeners();

    return filePath;
  }

  Future<void> playSurah(Surah surah) async {
    if (_currentSurah?.number == surah.number && _player.playing) {
      await _player.pause();
      notifyListeners();
      return;
    }
    _currentSurah = surah;
    notifyListeners();

    final url = await _api.fetchSurahAudio(surah.number);
    final localPath = await _downloadIfNeeded(surah.number, url);
    await _player.setUrl(Uri.file(localPath).toString());
    await _player.play();
    notifyListeners();
  }

  Future<void> toggle() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      await _player.play();
    }
    notifyListeners();
  }

  void disposeController() {
    _player.dispose();
  }
}
