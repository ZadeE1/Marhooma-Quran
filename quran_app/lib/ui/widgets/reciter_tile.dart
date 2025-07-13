import 'package:flutter/material.dart';
import '../../data/models/reciter.dart';
import '../../app_theme.dart';

/// A list tile representing a reciter. Shows a check mark when selected.
class ReciterTile extends StatelessWidget {
  final Reciter reciter;
  final bool selected;
  final VoidCallback onTap;

  const ReciterTile({super.key, required this.reciter, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: selected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
        borderRadius: BorderRadius.circular(AppTheme.spaceM),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.spaceM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Center(
            child: Text(
              reciter.name,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      ),
    );
  }
}
