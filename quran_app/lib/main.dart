import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'ui/screens/special_display_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark, // Force dark mode always
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: const SpecialDisplayScreen(),
    );
  }
}
