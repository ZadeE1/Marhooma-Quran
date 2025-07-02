class Ayah {
  final int number;
  final String text;
  final int numberInSurah;
  final int juz;
  final int page;
  final String? englishTranslation;

  Ayah({required this.number, required this.text, required this.numberInSurah, required this.juz, required this.page, this.englishTranslation});

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(number: json['number'], text: json['text'], numberInSurah: json['numberInSurah'], juz: json['juz'], page: json['page'], englishTranslation: json['englishTranslation']);
  }
}
