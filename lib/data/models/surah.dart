import 'dart:convert';

import 'ayah.dart';

/// Model representing a Surah (chapter) and its Ayahs.
class Surah {
  final int number;
  final String englishName;
  final String arabicName;
  final List<Ayah> ayahs;

  const Surah({required this.number, required this.englishName, required this.arabicName, required this.ayahs});

  factory Surah.fromJson(Map<String, dynamic> json) => Surah(number: json['number'] as int, englishName: json['englishName'] as String, arabicName: json['arabicName'] as String, ayahs: (json['ayahs'] as List).map((e) => Ayah.fromJson(e as Map<String, dynamic>)).toList());

  Map<String, dynamic> toJson() => {'number': number, 'englishName': englishName, 'arabicName': arabicName, 'ayahs': ayahs.map((e) => e.toJson()).toList()};

  @override
  String toString() => jsonEncode(toJson());

  factory Surah.fromQuranComChapter(Map<String, dynamic> json) => Surah(number: json['id'] as int, englishName: json['name_simple'] as String, arabicName: json['name_arabic'] as String, ayahs: const []);

  /// Creates a new instance with [ayahs] filled while keeping meta.
  Surah copyWithAyahs(List<Ayah> ayahs) => Surah(number: number, englishName: englishName, arabicName: arabicName, ayahs: ayahs);
}
