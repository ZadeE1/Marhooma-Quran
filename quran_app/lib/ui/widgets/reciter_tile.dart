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
    return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM), title: Text(reciter.name), trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null, selected: selected, onTap: onTap);
  }
}
