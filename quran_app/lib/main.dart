import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'app_theme.dart';
import 'ui/screens/special_display_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(androidNotificationChannelId: 'com.example.quran_app.audio', androidNotificationChannelName: 'Audio Playback', androidNotificationChannelDescription: 'Quran recitation playback', androidNotificationOngoing: true);

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
