import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:marhooma_quran/app.dart';

/// Entry point of the Marhooma Quran application.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}
