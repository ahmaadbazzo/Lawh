class Ayah {
  final int surah;
  final int ayah;
  final String text; // Uthmani script with full diacritics
  final String normalized; // Stripped & unified for comparison
  final int juz;

  Ayah({
    required this.surah,
    required this.ayah,
    required this.text,
    required this.normalized,
    required this.juz,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      surah: json['surah'] as int,
      ayah: json['ayah'] as int,
      text: json['text'] as String,
      normalized: json['normalized'] as String,
      juz: (json['juz'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'surah': surah,
      'ayah': ayah,
      'text': text,
      'normalized': normalized,
      'juz': juz,
    };
  }

  // Returns first word for hint
  String get firstWord {
    final words = text.split(' ');
    return words.isNotEmpty ? words.first : '';
  }
}
