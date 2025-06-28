import 'package:flutter/material.dart';
import '../../features/quran_reader/screens/reciter_selection_screen.dart';
import '../../audio/audio_controller.dart';

// ------------------------------------------------------------
// Simple placeholder screens for Phase 0. Each one returns a
// distinct color + label so the navigation effect is obvious.
// ------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _BasePlaceholder(label: 'Home', icon: Icons.home, color: Colors.green.shade700);
  }
}

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _BasePlaceholder(label: 'Explore', icon: Icons.explore, color: Colors.blueGrey.shade700);
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _BasePlaceholder(label: 'Library', icon: Icons.library_music, color: Colors.deepPurple.shade700);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AudioController.instance,
      builder: (context, _) {
        final controller = AudioController.instance;
        return ListView(children: [const Padding(padding: EdgeInsets.all(16), child: Text('Audio Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), ListTile(leading: const Icon(Icons.person), title: const Text('Reciter'), subtitle: Text(controller.selectedReciterName), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReciterSelectionScreen()))), const Divider(), const Padding(padding: EdgeInsets.all(16), child: Text('About', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))), const ListTile(leading: Icon(Icons.info), title: Text('Version'), subtitle: Text('1.0.0')), const ListTile(leading: Icon(Icons.book), title: Text('Audio Source'), subtitle: Text('quranapi.pages.dev'))]);
      },
    );
  }
}

/// Reusable internal widget so this file remains concise.
class _BasePlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _BasePlaceholder({required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 64, color: color), const SizedBox(height: 16), Text(label, style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: color))]));
  }
}
