import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/quran_api_service.dart';
import '../widgets/surah_tile.dart';
import 'surah_screen.dart';

class SurahListScreen extends StatelessWidget {
  final Reciter? selectedReciter;
  const SurahListScreen({super.key, required this.selectedReciter});

  void _openSurah(BuildContext context, Surah surah) {
    if (selectedReciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a reciter first.')));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => SurahScreen(surah: surah, reciter: selectedReciter!)));
  }

  @override
  Widget build(BuildContext context) {
    final apiService = QuranApiService();
    return FutureBuilder<List<Surah>>(
      future: apiService.getSurahList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            padding: const EdgeInsets.only(top: AppTheme.spaceS),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final surah = snapshot.data![index];
              return SurahTile(surah: surah, onTap: () => _openSurah(context, surah));
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        // Loading indicator removed - show empty container instead
        return const SizedBox.shrink();
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
