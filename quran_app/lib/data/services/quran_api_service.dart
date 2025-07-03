import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/reciter.dart';
import '../models/surah.dart';

class QuranApiService {
  // Singleton instance
  static final QuranApiService _instance = QuranApiService._internal();

  // Private constructor
  QuranApiService._internal();

  // Factory constructor to return the singleton instance
  factory QuranApiService() {
    return _instance;
  }

  // Cached data
  Map<String, dynamic>? _quranData;
  List<Surah>? _surahListCache;
  List<Reciter>? _reciterListCache;

  Future<Map<String, dynamic>> _loadQuranData() async {
    if (_quranData == null) {
      final String jsonString = await rootBundle.loadString('assets/data/quranApiRef.json');
      _quranData = json.decode(jsonString);
    }
    return _quranData!;
  }

  Future<List<Surah>> getSurahList() async {
    // Return the cached list if we've already generated it
    if (_surahListCache != null) return _surahListCache!;

    final data = await _loadQuranData();
    final List<dynamic> ayahCounts = data['ayahCount'];
    // Hard-coded surah names list.
    final List<String> surahNames = [
      "Al-Fatihah",
      "Al-Baqarah",
      "Aal-E-Imran",
      "An-Nisa",
      "Al-Ma'idah",
      "Al-An'am",
      "Al-A'raf",
      "Al-Anfal",
      "At-Tawbah",
      "Yunus",
      "Hud",
      "Yusuf",
      "Ar-Ra'd",
      "Ibrahim",
      "Al-Hijr",
      "An-Nahl",
      "Al-Isra",
      "Al-Kahf",
      "Maryam",
      "Taha",
      "Al-Anbiya",
      "Al-Hajj",
      "Al-Muminun",
      "An-Nur",
      "Al-Furqan",
      "Ash-Shu'ara",
      "An-Naml",
      "Al-Qasas",
      "Al-Ankabut",
      "Ar-Rum",
      "Luqman",
      "As-Sajdah",
      "Al-Ahzab",
      "Saba",
      "Fatir",
      "Ya-Sin",
      "As-Saffat",
      "Sad",
      "Az-Zumar",
      "Ghafir",
      "Fussilat",
      "Ash-Shura",
      "Az-Zukhruf",
      "Ad-Dukhan",
      "Al-Jathiyah",
      "Al-Ahqaf",
      "Muhammad",
      "Al-Fath",
      "Al-Hujurat",
      "Qaf",
      "Adh-Dhariyat",
      "At-Tur",
      "An-Najm",
      "Al-Qamar",
      "Ar-Rahman",
      "Al-Waqi'ah",
      "Al-Hadid",
      "Al-Mujadilah",
      "Al-Hashr",
      "Al-Mumtahanah",
      "As-Saff",
      "Al-Jumu'ah",
      "Al-Munafiqun",
      "At-Taghabun",
      "At-Talaq",
      "At-Tahrim",
      "Al-Mulk",
      "Al-Qalam",
      "Al-Haaqqah",
      "Al-Ma'arij",
      "Nuh",
      "Al-Jinn",
      "Al-Muzzammil",
      "Al-Muddaththir",
      "Al-Qiyamah",
      "Al-Insan",
      "Al-Mursalat",
      "An-Naba",
      "An-Nazi'at",
      "Abasa",
      "At-Takwir",
      "Al-Infitar",
      "Al-Mutaffifin",
      "Al-Inshiqaq",
      "Al-Buruj",
      "At-Tariq",
      "Al-A'la",
      "Al-Ghashiyah",
      "Al-Fajr",
      "Al-Balad",
      "Ash-Shams",
      "Al-Layl",
      "Ad-Duha",
      "Ash-Sharh",
      "At-Tin",
      "Al-Alaq",
      "Al-Qadr",
      "Al-Bayyinah",
      "Az-Zalzalah",
      "Al-Adiyat",
      "Al-Qari'ah",
      "At-Takathur",
      "Al-Asr",
      "Al-Humazah",
      "Al-Fil",
      "Quraysh",
      "Al-Ma'un",
      "Al-Kawthar",
      "Al-Kafirun",
      "An-Nasr",
      "Al-Masad",
      "Al-Ikhlas",
      "Al-Falaq",
      "An-Nas",
    ];

    _surahListCache = List.generate(ayahCounts.length, (i) => Surah(number: i + 1, name: surahNames.length > i ? surahNames[i] : 'Surah ${i + 1}', ayahCount: ayahCounts[i]));

    return _surahListCache!;
  }

  Future<List<Reciter>> getReciterList() async {
    if (_reciterListCache != null) return _reciterListCache!;

    final data = await _loadQuranData();
    _reciterListCache = [];
    data.forEach((key, value) {
      if (int.tryParse(key) != null && value is Map<String, dynamic>) {
        _reciterListCache!.add(Reciter.fromJson(int.parse(key), value));
      }
    });
    return _reciterListCache!;
  }
}
