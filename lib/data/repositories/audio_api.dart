import 'dart:convert';

import 'package:http/http.dart' as http;

class AudioApi {
  static const _base = 'https://api.quran.com/api/v4';
  static const _reciterId = 7; // Mishari Rashid al-Afasy 128kbps

  const AudioApi();

  /// Returns the mp3 URL for a complete surah recitation.
  Future<String> fetchSurahAudio(int surahNumber) async {
    final uri = Uri.parse('$_base/chapter_recitations/$_reciterId/$surahNumber');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load audio');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final audioFile = data['audio_file'] as Map<String, dynamic>;
    return audioFile['audio_url'] as String;
  }
}
