import 'package:flutter/foundation.dart';

/// Stubbed `AudioApi` – the actual audio fetching has been removed to satisfy
/// the "remove backend" requirement.  It now only exposes a static list of
/// available reciters used by the UI.
@immutable
class AudioApi {
  const AudioApi();

  /// IDs & names of popular reciters.  This is consumed by the settings and
  /// selection screens to populate the list.
  static const Map<int, String> availableReciters = {1: 'Mishary Rashid Al Afasy', 2: 'Abu Bakr Al Shatri', 3: 'Nasser Al Qatami', 4: 'Yasser Al Dosari', 5: 'Hani Ar Rifai'};

  /// Builds direct URL for a single ayah MP3 using the pattern
  /// `https://the-quran-project.github.io/Quran-Audio/Data/<reciter>/<surah>_<ayah>.mp3`.
  static String buildAyahUrl(int reciterId, int surahNumber, int ayahNumber) {
    return 'https://the-quran-project.github.io/Quran-Audio/Data/$reciterId/${surahNumber}_${ayahNumber}.mp3';
  }
}
