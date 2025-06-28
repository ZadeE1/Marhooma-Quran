import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/surah.dart';

/// Repository responsible for loading Qur'an data from bundled assets.
///
/// The JSON asset format is expected to be:
/// ```json
/// {
///   "translation": "en-saheeh",
///   "surahs": [
///     {
///       "number": 1,
///       "englishName": "Al-Fātiḥah",
///       "arabicName": "الفاتحة",
///       "ayahs": [
///         {
///           "number": 1,
///           "arabic": "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ",
///           "translation": "In the name of Allah, the Entirely Merciful, the Especially Merciful."
///         }
///       ]
///     }
///   ]
/// }
/// ```
class QuranRepository {
  QuranRepository._();

  /// Singleton instance
  static final QuranRepository instance = QuranRepository._();

  List<Surah>? _cached;

  /// Loads the requested [translationCode] from assets/quran/
  /// e.g., `en-saheeh` → assets/quran/en-saheeh.json
  Future<List<Surah>> loadTranslation(String translationCode) async {
    if (_cached != null) return _cached!;

    final path = 'assets/quran/$translationCode.json';
    final raw = await rootBundle.loadString(path);
    final map = jsonDecode(raw) as Map<String, dynamic>;

    _cached = (map['surahs'] as List).map((e) => Surah.fromJson(e as Map<String, dynamic>)).toList();
    return _cached!;
  }
}
