import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../data/models/reciter.dart';
import '../../data/models/surah.dart';
import '../../data/services/quran_api_service.dart';
import 'reciter_tile.dart';
import 'surah_tile.dart';
import 'animated_verse_transition.dart';
import 'styled_dropdown.dart';

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
  late VerseTransitionStyle _selectedAnimationStyle;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedReciter = widget.selectedReciter;
    _selectedSurah = widget.selectedSurah;
    _selectedAnimationStyle = widget.animationStyle;
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

  /// Returns a user-friendly description for each animation style.
  /// This helps users understand what each animation style does.
  String _getAnimationStyleDescription(VerseTransitionStyle style) {
    switch (style) {
      case VerseTransitionStyle.fadeOnly:
        return 'Simple and clean transition with only fade effect. Best for minimal distraction.';
      case VerseTransitionStyle.fadeScale:
        return 'Smooth fade with subtle scaling effect. Provides gentle visual feedback.';
      case VerseTransitionStyle.fadeSlide:
        return 'Fade with gentle slide from below. Creates a flowing reading experience.';
      case VerseTransitionStyle.elegant:
        return 'Sophisticated combination of effects. Recommended for the most polished experience.';
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
              // Others Tab - Settings and Configuration
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceL),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Animation Style Section
                    Text('Animation Style', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: AppTheme.spaceM),

                    // Styled dropdown for animation style selection
                    StyledDropdown<VerseTransitionStyle>(
                      value: _selectedAnimationStyle,
                      hint: 'Select animation style',
                      items: const [DropdownMenuItem(value: VerseTransitionStyle.fadeOnly, child: Text('Simple Fade')), DropdownMenuItem(value: VerseTransitionStyle.fadeScale, child: Text('Fade & Scale')), DropdownMenuItem(value: VerseTransitionStyle.fadeSlide, child: Text('Fade & Slide')), DropdownMenuItem(value: VerseTransitionStyle.elegant, child: Text('Elegant'))],
                      onChanged: (style) {
                        if (style != null) {
                          setState(() {
                            _selectedAnimationStyle = style;
                          });
                          widget.onAnimationStyleChanged(style);
                        }
                      },
                    ),

                    const SizedBox(height: AppTheme.spaceL),

                    // Description text for the selected animation style
                    Container(padding: const EdgeInsets.all(AppTheme.spaceM), decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Text(_getAnimationStyleDescription(_selectedAnimationStyle), style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant))),
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
