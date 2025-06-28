import 'package:flutter/material.dart';

import '../../../data/models/surah.dart';
import '../../../data/repositories/quran_api.dart';
import 'surah_detail_screen.dart';
import '../../../audio/audio_controller.dart';

/// Lists all 114 surahs for the chosen translation.
class SurahListScreen extends StatelessWidget {
  const SurahListScreen({super.key, this.translationCode = 'en-saheeh'});

  /// Code identifying the translation asset (e.g. `en-saheeh`).
  final String translationCode;

  @override
  Widget build(BuildContext context) {
    final api = const QuranApi();
    return FutureBuilder<List<Surah>>(
      future: api.fetchSurahList(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final surahs = snapshot.data ?? [];
        return Column(
          children: [
            // Play All button
            Padding(padding: const EdgeInsets.all(16), child: SizedBox(width: double.infinity, child: ElevatedButton.icon(icon: const Icon(Icons.play_arrow), label: const Text('Play All Surahs'), onPressed: surahs.isNotEmpty ? () => AudioController.instance.playPlaylist(surahs) : null))),
            // Surah list
            Expanded(child: _buildSurahList(surahs)),
          ],
        );
      },
    );
  }

  Widget _buildSurahList(List<Surah> surahs) {
    return ListView.separated(
      itemCount: surahs.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final surah = surahs[index];
        return ListTile(
          title: Text('${surah.number}. ${surah.englishName}'),
          subtitle: Text(surah.arabicName, style: const TextStyle(fontFamily: 'ScheherazadeNew')),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'play':
                  AudioController.instance.playSurah(surah);
                  break;
                case 'queue':
                  AudioController.instance.addToQueue(surah);
                  break;
              }
            },
            itemBuilder: (context) => [const PopupMenuItem(value: 'play', child: Text('Play Now')), const PopupMenuItem(value: 'queue', child: Text('Add to Queue'))],
          ),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SurahDetailScreen(surahMeta: surah))),
        );
      },
    );
  }
}
