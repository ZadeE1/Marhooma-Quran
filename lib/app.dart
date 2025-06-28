import 'package:flutter/material.dart';
import 'src/navigation/root_scaffold.dart';

/// Top-level widget that configures global theme & routing.
/// Keep this file short (<500 lines) so it remains readable.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Spotify-inspired green accent.
  static const _spotifyGreen = Color(0xFF1DB954);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marhooma Quran',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        // Dark theme with Spotify green seed color.
        colorScheme: ColorScheme.fromSeed(seedColor: _spotifyGreen, brightness: Brightness.dark),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: true,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(selectedItemColor: _spotifyGreen, unselectedItemColor: Colors.grey),
      ),
      home: const RootScaffold(),
    );
  }
}
