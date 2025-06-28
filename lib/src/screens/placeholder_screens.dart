import 'package:flutter/material.dart';
import '../../features/quran_reader/screens/reciter_selection_screen.dart';
import '../../audio/audio_controller.dart';
import '../../data/repositories/quran_api.dart';
import '../../data/models/ayah.dart';

// ------------------------------------------------------------
// Dynamic home screen that shows currently recited verse
// ------------------------------------------------------------

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuranApi _api = const QuranApi();
  List<Ayah> _currentSurahAyahs = [];
  bool _isLoadingAyahs = false;
  int? _lastLoadedSurahNumber;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AudioController.instance,
      builder: (context, _) {
        final controller = AudioController.instance;
        final currentSurah = controller.currentSurah;

        // Load ayahs when surah changes
        if (currentSurah != null && currentSurah.number != _lastLoadedSurahNumber) {
          _loadAyahsForSurah(currentSurah.number);
        }

        if (currentSurah == null) {
          return _buildNoPlayingState();
        }

        return StreamBuilder<Duration>(
          stream: controller.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final currentAyah = _getCurrentAyah(position);

            return _buildPlayingState(currentSurah.englishName, currentAyah, controller.isPlaying);
          },
        );
      },
    );
  }

  /// Loads ayahs for the given surah number
  Future<void> _loadAyahsForSurah(int surahNumber) async {
    if (_isLoadingAyahs) return;

    setState(() {
      _isLoadingAyahs = true;
      _lastLoadedSurahNumber = surahNumber;
    });

    try {
      final ayahs = await _api.fetchAyahs(surahNumber);
      setState(() {
        _currentSurahAyahs = ayahs;
        _isLoadingAyahs = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAyahs = false;
        _currentSurahAyahs = [];
      });
    }
  }

  /// Calculates current ayah based on audio position
  /// Simple estimation: divide total duration by number of ayahs
  Ayah? _getCurrentAyah(Duration position) {
    // Use the AudioController's accurate mapping when available
    final controllerAyah = AudioController.instance.currentAyah;
    if (controllerAyah != null) return controllerAyah;

    // Fallback: estimation logic (in case currentAyah isn't ready yet)
    if (_currentSurahAyahs.isEmpty) return null;
    const averageSecondsPerAyah = 12;
    final estimatedIndex = (position.inSeconds / averageSecondsPerAyah).floor();
    final idx = estimatedIndex.clamp(0, _currentSurahAyahs.length - 1);
    return _currentSurahAyahs[idx];
  }

  /// Builds UI when nothing is playing
  Widget _buildNoPlayingState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.music_note_outlined, size: 80, color: Colors.grey.shade600), const SizedBox(height: 24), Text('No Surah Playing', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w500)), const SizedBox(height: 12), Text('Select a surah to start listening', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade500))]));
  }

  /// Builds UI when a surah is playing
  Widget _buildPlayingState(String surahName, Ayah? currentAyah, bool isPlaying) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Surah name and play state indicator
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(isPlaying ? Icons.play_circle_filled : Icons.pause_circle_filled, color: Colors.green, size: 28), const SizedBox(width: 8), Text(surahName, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.w600))]),

          const SizedBox(height: 40),

          // Current verse display
          if (_isLoadingAyahs) ...[
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))), child: Text('Verse ${AudioController.instance.currentAyah?.numberInSurah ?? ''}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.w600))),
          ] else if (currentAyah != null) ...[
            // Verse number
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.withOpacity(0.3))), child: Text('Verse ${currentAyah.numberInSurah}', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.green, fontWeight: FontWeight.w600))),

            const SizedBox(height: 32),

            // Arabic text - large and bold
            Text(currentAyah.arabic, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontFamily: 'ScheherazadeNew', fontSize: 32, fontWeight: FontWeight.bold, height: 1.8, color: Colors.white), textAlign: TextAlign.center, textDirection: TextDirection.rtl),

            const SizedBox(height: 24),

            // English translation - underneath
            Text(currentAyah.translation, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.6, color: Colors.grey.shade300, fontWeight: FontWeight.w400), textAlign: TextAlign.center),
          ] else ...[
            Icon(Icons.book_outlined, size: 60, color: Colors.grey.shade600),
            const SizedBox(height: 16),
            Text('Verses not available', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// Other placeholder screens remain the same
// ------------------------------------------------------------

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
