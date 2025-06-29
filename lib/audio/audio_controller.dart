import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../data/models/surah.dart';
import '../data/models/ayah.dart';
import '../data/repositories/audio_api.dart';
import '../data/repositories/quran_api.dart';
import 'stream_pipe.dart';

/// AudioController – low-level streaming implementation.
/// -----------------------------------------------------
/// ‑ Android only (for now)
/// ‑ 5-second RAM pre-buffer (~100 KB)
/// ‑ Uses two isolates: one for download, one for playback (libmpv via
///   media_kit).
///
/// Public API is identical to the previous controller so UI code remains
/// unchanged.
class AudioController with ChangeNotifier {
  // Singleton boiler-plate
  AudioController._() {
    // Listen to player state changes so we can notify widgets.
    _player.stream.playing.listen((_) => notifyListeners());
    _player.stream.buffering.listen((_) => notifyListeners());
    _player.stream.playlist.listen((_) => notifyListeners());
  }
  static final AudioController instance = AudioController._();

  // Internal fields ----------------------------------------------------------
  final Player _player = Player();

  int _selectedReciterId = 1;
  final List<Surah> _queuedSurahs = [];
  final List<Ayah> _queuedAyahs = [];

  File? _currentFile;
  StreamSubscription<Uint8List>? _pipeSub;
  Future<void>? _downloadTask;

  // Public getters -----------------------------------------------------------
  List<Surah> get queuedSurahs => List.unmodifiable(_queuedSurahs);
  int? get currentIndex => _player.state.playlist.index;
  bool get isPlaying => _player.state.playing;
  bool get isLoading => _player.state.buffering;
  Stream<Duration> get positionStream => _player.stream.position;
  Surah? get currentSurah {
    final idx = currentIndex;
    if (idx == null || idx < 0 || idx >= _queuedSurahs.length) return null;
    return _queuedSurahs[idx];
  }

  // Per-ayah tracking not implemented in this low-level prototype.
  Ayah? get currentAyah => null;

  int get selectedReciterId => _selectedReciterId;
  String get selectedReciterName => AudioApi.availableReciters[_selectedReciterId] ?? 'Unknown';

  // Playback helpers ---------------------------------------------------------

  /// Plays [surah] by progressively concatenating its ayah MP3s into a temp
  /// file and letting libmpv stream from the growing file.
  Future<void> playSurah(Surah surah) async {
    await _stopAndCleanup();

    final fullSurah = await _ensureAyahsLoaded(surah);
    _queuedSurahs
      ..clear()
      ..add(fullSurah);

    final tempFile = File('${Directory.systemTemp.path}/marhooma_stream_${DateTime.now().millisecondsSinceEpoch}.mp3');
    _currentFile = tempFile;

    // Spawn background task that downloads ayahs sequentially & writes.
    _downloadTask = _sequentialDownload(fullSurah, _currentFile!);
  }

  /// Adds [surah] to queue – not streamed yet (will play after current ends).
  Future<void> addToQueue(Surah surah) async {
    _queuedSurahs.add(surah);
    notifyListeners();
  }

  /// Replaces queue with [surahs] and starts streaming first immediately.
  Future<void> playPlaylist(List<Surah> surahs) async {
    if (surahs.isEmpty) return;
    await _stopAndCleanup();
    _queuedSurahs
      ..clear()
      ..addAll(surahs);
    await playSurah(surahs.first);
  }

  Future<void> toggle() async => _player.playOrPause();
  Future<void> seekToNext() async => _player.next();
  Future<void> seekToPrevious() async => _player.previous();
  Future<void> seekToIndex(int index) async => _player.jump(index);

  void disposeController() {
    _player.dispose();
    _stopAndCleanup();
  }

  void setReciter(int id) {
    _selectedReciterId = id;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Internal helpers
  // -------------------------------------------------------------------------

  Future<void> _stopAndCleanup() async {
    await _player.stop();
    await _pipeSub?.cancel();
    await _currentFile?.delete();
    _pipeSub = null;
    _currentFile = null;
  }

  Future<Surah> _ensureAyahsLoaded(Surah surah) async {
    if (surah.ayahs.isNotEmpty) return surah;
    final api = const QuranApi();
    final ayahs = await api.fetchAyahs(surah.number);
    return surah.copyWithAyahs(ayahs);
  }

  // Downloads each ayah one by one and appends to [dest].  Starts playback
  // once ~100 kB have been written (≈5 s @ 160 kbps).
  Future<void> _sequentialDownload(Surah surah, File file) async {
    int bytesWritten = 0;
    bool started = false;

    // IOSink handles back-pressure ensuring writes are ordered.
    final sink = file.openWrite(mode: FileMode.writeOnlyAppend);

    bool isFirstAyah = true;
    for (final ayah in surah.ayahs) {
      final url = AudioApi.buildAyahUrl(_selectedReciterId, surah.number, ayah.numberInSurah);
      final dl = await DownloaderStream.start(url);

      // State to skip initial ID3v2 tag (present at the start of most MP3s).
      int skipRemaining = isFirstAyah ? 0 : -1; // -1 indicates we haven't checked yet

      _pipeSub = dl.stream.listen((chunk) {
        int offset = 0;

        // Determine how many bytes (if any) to skip at the very beginning of this file.
        if (skipRemaining != 0) {
          if (skipRemaining == -1) {
            // First chunk for this ayah — inspect for ID3 tag.
            if (chunk.length >= 10 && chunk[0] == 0x49 /* I */ && chunk[1] == 0x44 /* D */ && chunk[2] == 0x33 /* 3 */ ) {
              // Size is stored as 4 sync-safe bytes.
              final size = ((chunk[6] & 0x7F) << 21) | ((chunk[7] & 0x7F) << 14) | ((chunk[8] & 0x7F) << 7) | (chunk[9] & 0x7F);
              skipRemaining = size + 10; // tag header (10) + payload
            } else {
              skipRemaining = 0; // no tag
            }
          }

          // Skip bytes if needed
          if (skipRemaining > 0) {
            final consume = skipRemaining < (chunk.length - offset) ? skipRemaining : (chunk.length - offset);
            offset += consume;
            skipRemaining -= consume;
          }
        }

        if (offset < chunk.length) {
          final data = chunk.sublist(offset);
          sink.add(data);
          bytesWritten += data.length;
          if (!started && bytesWritten > 100 * 1024) {
            started = true;
            _player.open(Media('appending://${file.path}'));
            _player.play();
          }
        }
      });
      await _pipeSub!.asFuture();
      isFirstAyah = false;
    }

    await sink.flush();
    await sink.close();
    if (_queuedSurahs.length > 1) {
      final next = _queuedSurahs[1];
      // Remove first and start next.
      _queuedSurahs.removeAt(0);
      await playSurah(next);
    }
  }
}
