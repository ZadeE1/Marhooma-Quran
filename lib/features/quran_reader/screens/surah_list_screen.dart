import 'package:flutter/material.dart';

import '../../../data/models/surah.dart';
import '../../../data/repositories/quran_api.dart';
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
    return AnimatedBuilder(
      animation: AudioController.instance,
      builder: (context, _) {
        final controller = AudioController.instance;
        final currentSurah = controller.currentSurah;

        return ListView.separated(
          itemCount: surahs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final surah = surahs[index];
            final isCurrentlyPlaying = currentSurah?.number == surah.number;

            return ListTile(
              // Visual feedback for currently playing surah
              leading: isCurrentlyPlaying ? Icon(controller.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled, color: Colors.green, size: 32) : CircleAvatar(backgroundColor: Colors.grey.shade700, radius: 16, child: Text(surah.number.toString(), style: const TextStyle(color: Colors.white, fontSize: 12))),
              title: Text('${surah.englishName}', style: TextStyle(color: isCurrentlyPlaying ? Colors.green : null, fontWeight: isCurrentlyPlaying ? FontWeight.bold : null)),
              subtitle: Text(surah.arabicName, style: TextStyle(fontFamily: 'ScheherazadeNew', color: isCurrentlyPlaying ? Colors.green.shade300 : null)),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'queue':
                      AudioController.instance.addToQueue(surah);
                      // Show a snackbar to confirm the action
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${surah.englishName} added to queue'), duration: const Duration(seconds: 2)));
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(value: 'queue', child: Row(children: [Icon(Icons.queue_music), SizedBox(width: 8), Text('Add to Queue')])),
                    ],
              ),
              // Main tap action: Play the surah
              onTap: () {
                AudioController.instance.playSurah(surah);
              },
            );
          },
        );
      },
    );
  }
}
