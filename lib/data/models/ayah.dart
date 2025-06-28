import 'dart:convert';

/// Model representing a single Ayah (verse) with Arabic text and a
/// translated text.
class Ayah {
  final int numberInSurah;
  final String arabic;
  final String translation;

  const Ayah({required this.numberInSurah, required this.arabic, required this.translation});

  factory Ayah.fromJson(Map<String, dynamic> json) => Ayah(numberInSurah: json['number'] as int, arabic: json['arabic'] as String, translation: json['translation'] as String);

  Map<String, dynamic> toJson() => {'number': numberInSurah, 'arabic': arabic, 'translation': translation};

  @override
  String toString() => jsonEncode(toJson());

  /// Removes simple HTML/XML tags like <sup> or any <...> from a string.
  static String _stripTags(String input) {
    // Remove specific sup footnote tags entirely along with their numeric content.
    var out = input.replaceAll(RegExp(r'<sup[^>]*>.*?<\/sup>', caseSensitive: false), '');
    // Remove any residual generic HTML tags.
    out = out.replaceAll(RegExp(r'<[^>]*>'), '');
    // Remove trailing standalone numbers that were footnotes, e.g., ",1" or " 2".
    out = out.replaceAll(RegExp(r'[ ,]?\d+'), '');
    return out.trim();
  }

  factory Ayah.fromQuranCom(Map<String, dynamic> json) => Ayah(numberInSurah: json['verse_number'] as int, arabic: json['text_uthmani'] as String, translation: ((json['translations'] as List).isNotEmpty) ? _stripTags(json['translations'][0]['text'] as String) : '');
}
