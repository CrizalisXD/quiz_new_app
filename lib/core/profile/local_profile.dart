import 'dart:convert';

export '../../features/profile/local_profile.dart';

class LocalProfile {
  final String id; // например, 'guest-1234'
  final String name;
  final String avatarPath; // asset/file path
  final int coins;
  final int totalStars;
  final int gamesPlayed;
  final double avgScore; // 0..100
  final int bestStreak;
  final int avgAnswerMs; // хранить как int

  final Map<String, CountryProgress> countries; // 'japan','egypt',...
  // key format: "{countryKey}:{subcategoryKey}" e.g. "japan:classic"
  final Map<String, SubcategoryProgress> subcategories;
  final List<String> achievementsUnlocked;

  const LocalProfile({
    required this.id,
    required this.name,
    required this.avatarPath,
    required this.coins,
    required this.totalStars,
    required this.gamesPlayed,
    required this.avgScore,
    required this.bestStreak,
    required this.avgAnswerMs,
    required this.countries,
    required this.subcategories,
    required this.achievementsUnlocked,
  });

  LocalProfile copyWith({
    String? name,
    String? avatarPath,
    int? coins,
    int? totalStars,
    int? gamesPlayed,
    double? avgScore,
    int? bestStreak,
    int? avgAnswerMs,
    Map<String, CountryProgress>? countries,
    Map<String, SubcategoryProgress>? subcategories,
    List<String>? achievementsUnlocked,
  }) {
    return LocalProfile(
      id: id,
      name: name ?? this.name,
      avatarPath: avatarPath ?? this.avatarPath,
      coins: coins ?? this.coins,
      totalStars: totalStars ?? this.totalStars,
      gamesPlayed: gamesPlayed ?? this.gamesPlayed,
      avgScore: avgScore ?? this.avgScore,
      bestStreak: bestStreak ?? this.bestStreak,
      avgAnswerMs: avgAnswerMs ?? this.avgAnswerMs,
      countries: countries ?? this.countries,
      subcategories: subcategories ?? this.subcategories,
      achievementsUnlocked: achievementsUnlocked ?? this.achievementsUnlocked,
    );
  }

  factory LocalProfile.emptyGuest() => LocalProfile(
        id: 'guest-${DateTime.now().millisecondsSinceEpoch.remainder(10000)}',
        name: 'Гость',
        avatarPath: 'assets/images/profile/default.png',
        coins: 0,
        totalStars: 0,
        gamesPlayed: 0,
        avgScore: 0,
        bestStreak: 0,
        avgAnswerMs: 0,
        countries: const {},
        subcategories: const {},
        achievementsUnlocked: const [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'avatarPath': avatarPath,
        'coins': coins,
        'totalStars': totalStars,
        'gamesPlayed': gamesPlayed,
        'avgScore': avgScore,
        'bestStreak': bestStreak,
        'avgAnswerMs': avgAnswerMs,
        'countries': countries.map((k, v) => MapEntry(k, v.toMap())),
        'subcategories': subcategories.map((k, v) => MapEntry(k, v.toMap())),
        'achievementsUnlocked': achievementsUnlocked,
      };

  factory LocalProfile.fromMap(Map<String, dynamic> m) => LocalProfile(
        id: m['id'],
        name: m['name'],
        avatarPath: m['avatarPath'],
        coins: m['coins'],
        totalStars: m['totalStars'],
        gamesPlayed: m['gamesPlayed'],
        avgScore: (m['avgScore'] as num).toDouble(),
        bestStreak: m['bestStreak'],
        avgAnswerMs: m['avgAnswerMs'],
        countries: (m['countries'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, CountryProgress.fromMap(v)),
        ),
        subcategories: (m['subcategories'] as Map<String, dynamic>? ?? const {}).map(
          (k, v) => MapEntry(k, SubcategoryProgress.fromMap(v)),
        ),
        achievementsUnlocked:
            (m['achievementsUnlocked'] as List).map((e) => e.toString()).toList(),
      );

  String toJson() => jsonEncode(toMap());
  factory LocalProfile.fromJson(String s) => LocalProfile.fromMap(jsonDecode(s));
}

class CountryProgress {
  final int levelsPassed;
  final int stars;
  const CountryProgress({required this.levelsPassed, required this.stars});

  CountryProgress copyWith({int? levelsPassed, int? stars}) =>
      CountryProgress(levelsPassed: levelsPassed ?? this.levelsPassed, stars: stars ?? this.stars);

  Map<String, dynamic> toMap() => {'levelsPassed': levelsPassed, 'stars': stars};
  factory CountryProgress.fromMap(Map<String, dynamic> m) =>
      CountryProgress(levelsPassed: m['levelsPassed'], stars: m['stars']);
}

class SubcategoryProgress {
  final int levelsPassed; // Наивысший завершённый уровень (1-based)
  final int totalStars; // Сумма звёзд по уровням (кэш для быстрого доступа)
  final Map<String, int> levelStars; // ключ = номер уровня в строке, значение = 0..3

  const SubcategoryProgress({
    required this.levelsPassed,
    required this.totalStars,
    required this.levelStars,
  });

  SubcategoryProgress copyWith({
    int? levelsPassed,
    int? totalStars,
    Map<String, int>? levelStars,
  }) => SubcategoryProgress(
        levelsPassed: levelsPassed ?? this.levelsPassed,
        totalStars: totalStars ?? this.totalStars,
        levelStars: levelStars ?? this.levelStars,
      );

  Map<String, dynamic> toMap() => {
        'levelsPassed': levelsPassed,
        'totalStars': totalStars,
        'levelStars': levelStars,
      };

  factory SubcategoryProgress.fromMap(Map<String, dynamic> m) => SubcategoryProgress(
        levelsPassed: m['levelsPassed'],
        totalStars: m['totalStars'],
        levelStars: (m['levelStars'] as Map<String, dynamic>? ?? const {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      );
}
