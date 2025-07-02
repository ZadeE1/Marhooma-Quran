class Reciter {
  final int id;
  final String name;
  final String bitrate;
  final String subfolder;

  Reciter({required this.id, required this.name, required this.bitrate, required this.subfolder});

  factory Reciter.fromJson(int id, Map<String, dynamic> json) {
    return Reciter(id: id, name: json['name'], bitrate: json['bitrate'], subfolder: json['subfolder']);
  }
}
