import 'package:flutter/material.dart';

// ------------------------------------------------------------
// Simple placeholder screens for Phase 0. Each one returns a
// distinct color + label so the navigation effect is obvious.
// ------------------------------------------------------------

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _BasePlaceholder(label: 'Home', icon: Icons.home, color: Colors.green.shade700);
  }
}

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
    return _BasePlaceholder(label: 'Settings', icon: Icons.settings, color: Colors.teal.shade700);
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
