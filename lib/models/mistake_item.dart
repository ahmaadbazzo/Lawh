class MistakeItem {
  final String id;
  final int surahId;
  final String surahName;
  final int ayahNum;
  final String targetUthmani;
  final String targetNormalized;
  final String userInput;
  final DateTime timestamp;
  final int mistakeCount;

  MistakeItem({
    required this.id,
    required this.surahId,
    required this.surahName,
    required this.ayahNum,
    required this.targetUthmani,
    required this.targetNormalized,
    required this.userInput,
    required this.timestamp,
    this.mistakeCount = 1,
  });

  factory MistakeItem.fromJson(Map<String, dynamic> json) {
    return MistakeItem(
      id: json['id'] as String,
      surahId: json['surahId'] as int,
      surahName: json['surahName'] as String,
      ayahNum: json['ayahNum'] as int,
      targetUthmani: json['targetUthmani'] as String,
      targetNormalized: json['targetNormalized'] as String,
      userInput: json['userInput'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mistakeCount: (json['mistakeCount'] as int?) ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'surahId': surahId,
      'surahName': surahName,
      'ayahNum': ayahNum,
      'targetUthmani': targetUthmani,
      'targetNormalized': targetNormalized,
      'userInput': userInput,
      'timestamp': timestamp.toIso8601String(),
      'mistakeCount': mistakeCount,
    };
  }
}
