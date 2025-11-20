class SurahInfo {
  final int number;
  final String name;
  final String englishName;
  final String englishNameTranslation;
  final String revelationType;
  final int numberOfAyahs;

  SurahInfo({
    required this.number,
    required this.name,
    required this.englishName,
    required this.englishNameTranslation,
    required this.revelationType,
    required this.numberOfAyahs,
  });
}

class AyahBookmark {
  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final String ayahText;
  final DateTime timestamp;

  AyahBookmark({
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    required this.ayahText,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'surahName': surahName,
    'ayahText': ayahText,
    'timestamp': timestamp.toIso8601String(),
  };

  factory AyahBookmark.fromJson(Map<String, dynamic> json) => AyahBookmark(
    surahNumber: json['surahNumber'],
    ayahNumber: json['ayahNumber'],
    surahName: json['surahName'],
    ayahText: json['ayahText'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

class ReadingProgress {
  final int surahNumber;
  final int ayahNumber;
  final int juzNumber;
  final DateTime lastRead;

  ReadingProgress({
    required this.surahNumber,
    required this.ayahNumber,
    required this.juzNumber,
    required this.lastRead,
  });

  Map<String, dynamic> toJson() => {
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'juzNumber': juzNumber,
    'lastRead': lastRead.toIso8601String(),
  };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        surahNumber: json['surahNumber'],
        ayahNumber: json['ayahNumber'],
        juzNumber: json['juzNumber'],
        lastRead: DateTime.parse(json['lastRead']),
      );
}
