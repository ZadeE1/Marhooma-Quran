import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/quran_api_service.dart';
import 'reciter_tile.dart';
import 'surah_tile.dart';

/// Modal dialog for selecting reciter and surah for audio playback.
///
/// This component encapsulates the selection logic so the main screen
/// remains focused on verse display functionality.
class SettingsModal extends StatefulWidget {
  final Reciter? selectedReciter;
  final Surah? selectedSurah;
  final Function(Reciter, Surah) onSelectionComplete;

  const SettingsModal({super.key, this.selectedReciter, this.selectedSurah, required this.onSelectionComplete});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> with TickerProviderStateMixin {
  final QuranApiService _apiService = QuranApiService();
  late TabController _tabController;

  Reciter? _selectedReciter;
  Surah? _selectedSurah;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedReciter = widget.selectedReciter;
    _selectedSurah = widget.selectedSurah;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Handles the completion of selection when both reciter and surah are chosen.
  void _handleSelectionComplete() {
    if (_selectedReciter != null && _selectedSurah != null) {
      widget.onSelectionComplete(_selectedReciter!, _selectedSurah!);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Select Reciter & Surah'),
          bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Reciters', icon: Icon(Icons.record_voice_over)), Tab(text: 'Surahs', icon: Icon(Icons.menu_book))]),
          actions: [
            // Show complete button only when both selections are made
            if (_selectedReciter != null && _selectedSurah != null) TextButton(onPressed: _handleSelectionComplete, child: const Text('Done')),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            // Reciters Tab
            FutureBuilder<List<Reciter>>(
              future: _apiService.getReciterList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: AppTheme.spaceS),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final reciter = snapshot.data![index];
                      return ReciterTile(
                        reciter: reciter,
                        selected: _selectedReciter?.id == reciter.id,
                        onTap: () {
                          setState(() {
                            _selectedReciter = reciter;
                          });
                          // Auto-switch to surah tab if no surah selected yet
                          if (_selectedSurah == null) {
                            _tabController.animateTo(1);
                          }
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading reciters: ${snapshot.error}'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
            // Surahs Tab
            FutureBuilder<List<Surah>>(
              future: _apiService.getSurahList(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: AppTheme.spaceS),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final surah = snapshot.data![index];
                      return SurahTile(
                        surah: surah,
                        selected: _selectedSurah?.number == surah.number,
                        onTap: () {
                          setState(() {
                            _selectedSurah = surah;
                          });
                          // Auto-complete if both selections are made
                          if (_selectedReciter != null) {
                            _handleSelectionComplete();
                          }
                        },
                      );
                    },
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error loading surahs: ${snapshot.error}'));
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ],
        ),
      ),
    );
  }
}
