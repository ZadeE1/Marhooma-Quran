import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/quran_api_service.dart';
import 'reciter_tile.dart';
import 'surah_tile.dart';
import 'animated_verse_transition.dart';

/// Modal dialog for selecting reciter and surah for audio playback.
///
/// This component encapsulates the selection logic so the main screen
/// remains focused on verse display functionality.
class SettingsModal extends StatefulWidget {
  final Reciter? selectedReciter;
  final Surah? selectedSurah;
  final Function(Reciter, Surah) onSelectionComplete;
  final VerseTransitionStyle animationStyle;
  final Function(VerseTransitionStyle) onAnimationStyleChanged;

  const SettingsModal({super.key, this.selectedReciter, this.selectedSurah, required this.onSelectionComplete, required this.animationStyle, required this.onAnimationStyleChanged});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> with TickerProviderStateMixin {
  final QuranApiService _apiService = QuranApiService();
  late TabController _tabController;
  Future<List<Reciter>>? _recitersFuture;
  Future<List<Surah>>? _surahsFuture;

  Reciter? _selectedReciter;
  Surah? _selectedSurah;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedReciter = widget.selectedReciter;
    _selectedSurah = widget.selectedSurah;
    _recitersFuture = _apiService.getReciterList();
    _surahsFuture = _apiService.getSurahList();
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
          bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Reciters', icon: Icon(Icons.record_voice_over)), Tab(text: 'Surahs', icon: Icon(Icons.menu_book)), Tab(text: 'Others', icon: Icon(Icons.more_horiz))]),
          actions: [
            // Show complete button only when both selections are made
            if (_selectedReciter != null && _selectedSurah != null) TextButton(onPressed: _handleSelectionComplete, child: const Text('Done')),
          ],
        ),
        body: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Reciters Tab
              FutureBuilder<List<Reciter>>(
                future: _recitersFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: AppTheme.spaceS),
                      itemCount: snapshot.data!.length,
                      itemExtent: 80.0, // Fixed height for better performance
                      cacheExtent: 400.0, // Cache more items for smoother scrolling
                      itemBuilder: (context, index) {
                        final reciter = snapshot.data![index];
                        return ReciterTile(
                          key: ValueKey(reciter.id), // Important for performance
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
                future: _surahsFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.builder(
                      padding: const EdgeInsets.only(top: AppTheme.spaceS),
                      itemCount: snapshot.data!.length,
                      itemExtent: 80.0, // Fixed height for better performance
                      cacheExtent: 10.0, // Cache more items for smoother scrolling
                      itemBuilder: (context, index) {
                        final surah = snapshot.data![index];
                        return SurahTile(
                          key: ValueKey(surah.number), // Important for performance
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
              // Others Tab
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Animation Style', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    DropdownButton<VerseTransitionStyle>(
                      value: widget.animationStyle,
                      items: [DropdownMenuItem(value: VerseTransitionStyle.fadeOnly, child: Text('Simple Fade')), DropdownMenuItem(value: VerseTransitionStyle.fadeScale, child: Text('Fade & Scale')), DropdownMenuItem(value: VerseTransitionStyle.fadeSlide, child: Text('Fade & Slide')), DropdownMenuItem(value: VerseTransitionStyle.elegant, child: Text('Elegant'))],
                      onChanged: (style) {
                        if (style != null) widget.onAnimationStyleChanged(style);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
