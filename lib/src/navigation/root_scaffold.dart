import 'package:flutter/material.dart';
import '../screens/placeholder_screens.dart';
import '../../features/quran_reader/screens/surah_list_screen.dart';
import '../../audio/audio_controller.dart';

/// Stateful scaffold that holds bottom navigation & a mini-player placeholder.
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _currentIndex = 0;

  // Screens associated with each tab.
  static final _screens = [
    const HomeScreen(),
    SurahListScreen(), // actual Qur'an explore screen
    const LibraryScreen(),
    const SettingsScreen(),
  ];

  void _onTabSelected(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Expanded so the active screen takes all remaining space.
          Expanded(child: _screens[_currentIndex]),

          // Mini-player placeholder – will become functional in Phase 2.
          AnimatedBuilder(
            animation: AudioController.instance,
            builder: (context, _) {
              final controller = AudioController.instance;
              final surah = controller.currentSurah;
              final isPlaying = controller.isPlaying;
              return Container(height: 64, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey.shade900, border: const Border(top: BorderSide(color: Colors.black54, width: 0.5))), child: Row(children: [const Icon(Icons.graphic_eq, color: Colors.grey), const SizedBox(width: 12), Expanded(child: Text(surah != null ? surah.englishName : 'Nothing playing', style: const TextStyle(color: Colors.grey), overflow: TextOverflow.ellipsis)), if (controller.isBusy) const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) else IconButton(icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: surah == null ? null : () => controller.toggle())]));
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(currentIndex: _currentIndex, type: BottomNavigationBarType.fixed, onTap: _onTabSelected, items: const [BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'), BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'), BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'), BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings')]),
    );
  }
}
