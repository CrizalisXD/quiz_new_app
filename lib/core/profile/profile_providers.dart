import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_profile.dart';
import 'profile_repository.dart';

final profileRepoProvider = Provider<ProfileRepository>((_) => ProfileRepository());

class ProfileNotifier extends AsyncNotifier<LocalProfile> {
  @override
  Future<LocalProfile> build() async {
    final repo = ref.read(profileRepoProvider);
    return repo.loadOrCreate();
  }

  Future<void> rename(String name) async {
    final current = state.valueOrNull ?? LocalProfile.emptyGuest();
    final updated = current.copyWith(name: name);
    state = AsyncData(updated);
    await ref.read(profileRepoProvider).save(updated);
  }

  Future<void> addCoins(int delta) async {
    final c = state.valueOrNull;
    if (c == null) return;
    final u = c.copyWith(coins: (c.coins + delta).clamp(0, 999999));
    state = AsyncData(u);
    await ref.read(profileRepoProvider).save(u);
  }

  Future<void> applyGameResult({
    required String countryKey,
    required int starsEarned, // 0..3
    required int levelPassedInc, // 0/1
    required double scorePercent,
    required int avgAnswerMs,
  }) async {
    // Legacy country-wide aggregation; new per-subcategory method below.
    final c = state.valueOrNull;
    if (c == null) return;
    final map = Map<String, CountryProgress>.from(c.countries);
    final cp = map[countryKey] ?? const CountryProgress(levelsPassed: 0, stars: 0);
    final newCP = cp.copyWith(
      levelsPassed: cp.levelsPassed + levelPassedInc,
      stars: cp.stars + starsEarned,
    );
    map[countryKey] = newCP;

    final newAvg = c.gamesPlayed == 0
        ? scorePercent
        : ((c.avgScore * c.gamesPlayed) + scorePercent) / (c.gamesPlayed + 1);

    final u = c.copyWith(
      totalStars: c.totalStars + starsEarned,
      gamesPlayed: c.gamesPlayed + 1,
      avgScore: newAvg,
      avgAnswerMs: avgAnswerMs,
      countries: map,
    );
    state = AsyncData(u);
    await ref.read(profileRepoProvider).save(u);
  }

  /// New granular progress: country + subcategory.
  Future<void> applyLevelResult({
    required String countryKey,
    required String subcategoryKey,
    required int levelNumber, // 1-based
    required int starsEarned, // 0..3
    required double scorePercent,
    required int avgAnswerMs,
  }) async {
    final c = state.valueOrNull;
    if (c == null) return;

    // Update country aggregate (increment levelsPassed only if this is a new highest)
    final countryMap = Map<String, CountryProgress>.from(c.countries);
    final countryProg = countryMap[countryKey] ?? const CountryProgress(levelsPassed: 0, stars: 0);
    final isNewLevel = levelNumber > countryProg.levelsPassed;
    final updatedCountry = countryProg.copyWith(
      levelsPassed: isNewLevel ? levelNumber : countryProg.levelsPassed,
      stars: countryProg.stars + starsEarned,
    );
    countryMap[countryKey] = updatedCountry;

    // Update subcategory key
    final scKey = '$countryKey:$subcategoryKey';
    final scMap = Map<String, SubcategoryProgress>.from(c.subcategories);
    final sc = scMap[scKey] ?? const SubcategoryProgress(levelsPassed: 0, totalStars: 0, levelStars: {});
    final isNewSubLevel = levelNumber > sc.levelsPassed;
    // Перезаписываем звёзды уровня только если улучшение (большее количество)
    final currentLevelStars = sc.levelStars['$levelNumber'] ?? 0;
    final improvedStars = starsEarned > currentLevelStars ? starsEarned : currentLevelStars;
    final newLevelStarsMap = Map<String, int>.from(sc.levelStars)..['$levelNumber'] = improvedStars;
    // Пересчитать totalStars (сумма всех значений levelStars)
    final recalculatedTotal = newLevelStarsMap.values.fold<int>(0, (a, b) => a + b);
    final updatedSub = sc.copyWith(
      levelsPassed: isNewSubLevel ? levelNumber : sc.levelsPassed,
      totalStars: recalculatedTotal,
      levelStars: newLevelStarsMap,
    );
    scMap[scKey] = updatedSub;

    // Разница звёзд для глобального totalStars (добавляем только прирост)
    final deltaStars = improvedStars - currentLevelStars;

    // Recompute global stats
    final newAvg = c.gamesPlayed == 0
        ? scorePercent
        : ((c.avgScore * c.gamesPlayed) + scorePercent) / (c.gamesPlayed + 1);

    final u = c.copyWith(
      countries: countryMap,
      subcategories: scMap,
      totalStars: c.totalStars + deltaStars,
      gamesPlayed: c.gamesPlayed + 1,
      avgScore: newAvg,
      avgAnswerMs: avgAnswerMs,
    );
    state = AsyncData(u);
    await ref.read(profileRepoProvider).save(u);
  }

  Future<void> reset() async {
    await ref.read(profileRepoProvider).reset();
    state = AsyncData(LocalProfile.emptyGuest());
  }

  Future<void> changeAvatar(String path) async {
    final c = state.valueOrNull;
    if (c == null) return;
    final u = c.copyWith(avatarPath: path);
    state = AsyncData(u);
    await ref.read(profileRepoProvider).save(u);
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, LocalProfile>(
  () => ProfileNotifier(),
);
