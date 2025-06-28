import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ayah.dart';
import '../models/surah.dart';

class QuranApi {
  static const _base = 'https://api.quran.com/api/v4';
  static const _englishTranslationId = 20; // Sahih International

  const QuranApi();

  Future<List<Surah>> fetchSurahList() async {
    final uri = Uri.parse('$_base/chapters?language=en');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load chapters');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final chapters = data['chapters'] as List<dynamic>;
    return chapters.map((e) => Surah.fromQuranComChapter(e as Map<String, dynamic>)).toList();
  }

  Future<List<Ayah>> fetchAyahs(int surahNumber) async {
    final uri = Uri.parse('$_base/verses/by_chapter/$surahNumber?language=en&translations=$_englishTranslationId&fields=text_uthmani&page=1&per_page=all');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load verses');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final verses = data['verses'] as List<dynamic>;
    return verses.map((e) => Ayah.fromQuranCom(e as Map<String, dynamic>)).toList();
  }
}
