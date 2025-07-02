import 'package:quran/quran.dart' as quran;
import '../models/ayah.dart';

/// Retrieves Quranic verses for a surah from the locally bundled `quran` package.
///
/// This avoids any network dependency, ensuring the text is always available
/// offline while leaving the audio components untouched.
class QuranTextService {
  /// Returns a list of [Ayah]s for the given [surahNumber].
  ///
  /// The `quran` package provides helper functions to retrieve both the verse
  /// count and the actual text. We synthesise the remaining metadata that our
  /// existing [Ayah] model expects (global verse `number`, `juz`, and `page`)
  /// with placeholder values because they are currently unused elsewhere in
  /// the UI.  Refactor later if those fields become necessary.
  Future<List<Ayah>> getAyahs(int surahNumber) async {
    final verseCount = quran.getVerseCount(surahNumber);

    return List.generate(verseCount, (index) {
      final verseNumber = index + 1;
      return Ayah(
        number: verseNumber, // Global numbering not critical here.
        text: quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true),
        numberInSurah: verseNumber,
        juz: 0,
        page: 0,
        englishTranslation: quran.getVerseTranslation(surahNumber, verseNumber, translation: quran.Translation.enSaheeh),
      );
    });
  }

  /// Returns a single [Ayah] for the given [surahNumber] and [verseNumber].
  /// This is useful for getting specific verses during audio playback.
  Future<Ayah> getAyah(int surahNumber, int verseNumber) async {
    return Ayah(number: verseNumber, text: quran.getVerse(surahNumber, verseNumber, verseEndSymbol: true), numberInSurah: verseNumber, juz: 0, page: 0, englishTranslation: quran.getVerseTranslation(surahNumber, verseNumber, translation: quran.Translation.enSaheeh));
  }
}
