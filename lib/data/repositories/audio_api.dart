import 'dart:convert';

import 'package:http/http.dart' as http;

class AudioApi {
  static const _base = 'https://quranapi.pages.dev/api';
  static const _reciterId = 1; // Mishary Rashid Al Afasy (default)

  const AudioApi();

  /// Returns the mp3 URL for a complete surah recitation using quranapi.pages.dev
  Future<String> fetchSurahAudio(int surahNumber, {int reciterId = _reciterId}) async {
    final uri = Uri.parse('$_base/audio/$surahNumber.json');
    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('Failed to load audio');

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final reciterData = data[reciterId.toString()] as Map<String, dynamic>?;

    if (reciterData == null) {
      throw Exception('Reciter $reciterId not found for surah $surahNumber');
    }

    // Prefer originalUrl for better performance, fallback to GitHub url
    return (reciterData['originalUrl'] as String?) ?? (reciterData['url'] as String);
  }

  /// Returns available reciters with their IDs and names
  static const Map<int, String> availableReciters = {1: 'Mishary Rashid Al Afasy', 2: 'Abu Bakr Al Shatri', 3: 'Nasser Al Qatami', 4: 'Yasser Al Dosari', 5: 'Hani Ar Rifai'};

  /// Builds the direct URL to a specific ayah audio file based on the pattern
  /// `/<reciterId>/<surahNo>_<ayahNo>.mp3` hosted on the-quran-project GitHub pages.
  /// Example: `https://the-quran-project.github.io/Quran-Audio/Data/2/1_2.mp3`
  static String buildAyahUrl(int reciterId, int surahNumber, int ayahNumber) {
    return 'https://the-quran-project.github.io/Quran-Audio/Data/$reciterId/${surahNumber}_${ayahNumber}.mp3';
  }
}
