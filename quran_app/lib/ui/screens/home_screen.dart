// import '../../data/models/surah.dart';
// import '../../app_theme.dart';
import 'reciters_screen.dart';
import 'surah_list_screen.dart';
import 'special_display_screen.dart';

import 'package:flutter/material.dart';
import '../../data/models/reciter.dart';
import '../../data/services/quran_api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuranApiService _apiService = QuranApiService();

  Reciter? _selectedReciter;
  // Start with Special tab (index 2) as the default homepage
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    // Prefetch reciters and set default.
    _apiService.getReciterList().then((reciters) {
      if (reciters.isNotEmpty) {
        setState(() => _selectedReciter = reciters.first);
      }
    });
  }

  void _onReciterSelected(Reciter reciter) {
    setState(() => _selectedReciter = reciter);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [SurahListScreen(selectedReciter: _selectedReciter), RecitersScreen(selectedReciter: _selectedReciter, onReciterSelected: _onReciterSelected), const SpecialDisplayScreen()];

    return Scaffold(appBar: AppBar(title: const Text('Quran App')), body: IndexedStack(index: _currentIndex, children: pages), bottomNavigationBar: NavigationBar(selectedIndex: _currentIndex, onDestinationSelected: (index) => setState(() => _currentIndex = index), destinations: const [NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Surahs'), NavigationDestination(icon: Icon(Icons.record_voice_over_outlined), selectedIcon: Icon(Icons.record_voice_over), label: 'Reciters'), NavigationDestination(icon: Icon(Icons.star_border), selectedIcon: Icon(Icons.star), label: 'Special')]));
  }
}
