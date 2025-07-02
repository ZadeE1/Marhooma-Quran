import 'package:flutter/material.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/models/ayah.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/quran_text_service.dart';

class SurahScreen extends StatefulWidget {
  final Surah surah;
  final Reciter reciter;

  const SurahScreen({super.key, required this.surah, required this.reciter});

  @override
  _SurahScreenState createState() => _SurahScreenState();
}

class _SurahScreenState extends State<SurahScreen> {
  final QuranAudioPlayer _audioService = QuranAudioPlayer();
  final QuranTextService _textService = QuranTextService();
  late Future<List<Ayah>> _ayahs;
  int? _playingAyah;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ayahs = _textService.getAyahs(widget.surah.number);

    _audioService.currentAyahStream.listen((ayah) {
      setState(() => _playingAyah = ayah);
    });

    _audioService.playingStream.listen((playing) {
      setState(() => _isPlaying = playing);
    });
  }

  Future<void> _playSurah({int? fromAyah}) async {
    await _audioService.playSurah(surah: widget.surah, reciter: widget.reciter, fromAyah: fromAyah);
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.surah.name)),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahs,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final ayah = snapshot.data![index];
                final isPlaying = _isPlaying && _playingAyah == ayah.numberInSurah;

                return ListTile(
                  title: Text(ayah.text, textAlign: TextAlign.right, style: Theme.of(context).textTheme.bodyLarge),
                  trailing: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      if (isPlaying) {
                        _audioService.pause();
                      } else {
                        if (_playingAyah == ayah.numberInSurah) {
                          _audioService.play();
                        } else {
                          _playSurah(fromAyah: ayah.numberInSurah);
                        }
                      }
                    },
                  ),
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar:
          _playingAyah != null
              ? BottomAppBar(
                child: ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.stop),
                    onPressed: () {
                      _audioService.stop();
                      setState(() => _playingAyah = null);
                    },
                  ),
                  title: Text('Playing ayah $_playingAyah'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          if (_isPlaying) {
                            _audioService.pause();
                          } else {
                            _audioService.play();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _audioService.stop();
                          setState(() => _playingAyah = null);
                        },
                      ),
                    ],
                  ),
                ),
              )
              : null,
    );
  }
}
