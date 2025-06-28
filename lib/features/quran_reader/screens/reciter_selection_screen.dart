import 'package:flutter/material.dart';

import '../../../audio/audio_controller.dart';
import '../../../data/repositories/audio_api.dart';

/// Screen for selecting different reciters
class ReciterSelectionScreen extends StatelessWidget {
  const ReciterSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Reciter')),
      body: AnimatedBuilder(
        animation: AudioController.instance,
        builder: (context, _) {
          final controller = AudioController.instance;
          return ListView.builder(
            itemCount: AudioApi.availableReciters.length,
            itemBuilder: (context, index) {
              final entry = AudioApi.availableReciters.entries.elementAt(index);
              final reciterId = entry.key;
              final reciterName = entry.value;
              final isSelected = controller.selectedReciterId == reciterId;

              return ListTile(
                title: Text(reciterName),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  controller.setReciter(reciterId);
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    );
  }
}
