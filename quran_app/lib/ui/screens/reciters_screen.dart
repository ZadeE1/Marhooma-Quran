import 'package:flutter/material.dart';

import '../../app_theme.dart';
import '../../data/models/reciter.dart';
import '../../data/services/quran_api_service.dart';
import '../widgets/reciter_tile.dart';

class RecitersScreen extends StatelessWidget {
  final Reciter? selectedReciter;
  final ValueChanged<Reciter> onReciterSelected;

  const RecitersScreen({super.key, required this.selectedReciter, required this.onReciterSelected});

  @override
  Widget build(BuildContext context) {
    final apiService = QuranApiService();

    return FutureBuilder<List<Reciter>>(
      future: apiService.getReciterList(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppTheme.spaceS),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3 / 2, crossAxisSpacing: AppTheme.spaceS, mainAxisSpacing: AppTheme.spaceS),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final reciter = snapshot.data![index];
              return ReciterTile(reciter: reciter, selected: selectedReciter?.id == reciter.id, onTap: () => onReciterSelected(reciter));
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        return const SizedBox.shrink();
      },
    );
  }
}
