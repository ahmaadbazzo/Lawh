class Surah {
  final int id;
  final String name;
  final String englishName;
  final int ayahsCount;
  final String revelationType; // مكية / مدنية
  final int startJuz;
  final int startPage;

  Surah({
    required this.id,
    required this.name,
    required this.englishName,
    required this.ayahsCount,
    required this.revelationType,
    required this.startJuz,
    required this.startPage,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'] as int,
      name: json['name'] as String,
      englishName: json['englishName'] as String,
      ayahsCount: json['ayahsCount'] as int,
      revelationType: json['revelationType'] as String,
      startJuz: json['startJuz'] as int,
      startPage: json['startPage'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'ayahsCount': ayahsCount,
      'revelationType': revelationType,
      'startJuz': startJuz,
      'startPage': startPage,
    };
  }

  bool get isMeccan => revelationType.contains('مكية') || revelationType == 'Meccan';
}
