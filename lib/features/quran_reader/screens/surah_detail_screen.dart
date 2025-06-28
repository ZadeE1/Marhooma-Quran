import 'package:flutter/material.dart';

import '../../../data/models/surah.dart';
import '../../../data/repositories/quran_api.dart';
import '../../../data/models/ayah.dart';
import '../../../audio/audio_controller.dart';

/// Displays all ayahs of a given [Surah].
class SurahDetailScreen extends StatelessWidget {
  final Surah surahMeta;
  const SurahDetailScreen({super.key, required this.surahMeta});

  @override
  Widget build(BuildContext context) {
    final api = const QuranApi();
    return Scaffold(
      appBar: AppBar(title: Text('${surahMeta.englishName} (${surahMeta.arabicName})')),
      body: FutureBuilder(
        future: api.fetchAyahs(surahMeta.number),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final ayahs = snapshot.data as List<Ayah>;
          return ListView.builder(
            itemCount: ayahs.length,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(ayah.arabic, style: const TextStyle(fontSize: 20, fontFamily: 'ScheherazadeNew'), textAlign: TextAlign.right)), const SizedBox(width: 8), Text(ayah.numberInSurah.toString(), style: const TextStyle(color: Colors.grey, fontSize: 14))]),
                        const SizedBox(height: 8),
                        Text(ayah.translation, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: AudioController.instance,
        builder: (context, _) {
          final controller = AudioController.instance;
          final isCurrent = controller.currentSurah?.number == surahMeta.number;
          if (controller.isLoading && isCurrent) {
            return FloatingActionButton(onPressed: null, child: const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)));
          }
          final icon = (isCurrent && controller.isPlaying) ? Icons.pause : Icons.play_arrow;
          return FloatingActionButton(onPressed: () => controller.playSurah(surahMeta), child: Icon(icon));
        },
      ),
    );
  }
}
