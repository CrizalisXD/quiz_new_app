import 'package:shared_preferences/shared_preferences.dart';

/// Ключи: u:<userId>|coins, u:<userId>|stars|<packKey>|<level>, u:<userId>|unlocked|<packKey>|<level>
/// Добавлен простой in-memory кэш + batch API для сокращения числа обращений/ FutureBuilder'ов.
class ProgressStore {
  static String _pfx(String userId) => 'u:$userId';

  // КЭШИ (очень простой; не потокобезопасен, но для Flutter UI достаточно).
  static final Map<String, int> _coinsCache = {};
  static final Map<String, Map<String, int>> _starsCache = {};     // user -> (pack|level -> stars)
  static final Map<String, Map<String, bool>> _unlockCache = {};   // user -> (pack|level -> unlocked)

  static String _starsKey(String packKey, int level) => '$packKey|$level';
  static String _unlockKey(String packKey, int level) => '$packKey|$level';

  /// ========== COINS ==========
  static Future<int> getCoins(String userId) async {
    final cached = _coinsCache[userId];
    if (cached != null) return cached;
    final p = await SharedPreferences.getInstance();
    final v = p.getInt('${_pfx(userId)}|coins') ?? 0;
    _coinsCache[userId] = v;
    return v;
  }

  static Future<void> addCoins(String userId, int delta) async {
    final current = await getCoins(userId);
    final next = (current + delta).clamp(0, 1 << 31);
    final p = await SharedPreferences.getInstance();
    await p.setInt('${_pfx(userId)}|coins', next);
    _coinsCache[userId] = next;
  }

  /// ========== STARS ==========
  static Future<int> getLevelStars(String userId, String packKey, int level) async {
    final packMap = _starsCache.putIfAbsent(userId, () => {});
    final composite = _starsKey(packKey, level);
    final cached = packMap[composite];
    if (cached != null) return cached;
    final p = await SharedPreferences.getInstance();
    final key = '${_pfx(userId)}|stars|$packKey|$level';
    final v = p.getInt(key) ?? 0;
    packMap[composite] = v;
    return v;
  }

  static Future<void> setLevelStars(String userId, String packKey, int level, int stars) async {
    final p = await SharedPreferences.getInstance();
    final key = '${_pfx(userId)}|stars|$packKey|$level';
    final prev = p.getInt(key) ?? 0;
    if (stars > prev) {
      final clamped = stars.clamp(0, 3);
      await p.setInt(key, clamped);
      _starsCache.putIfAbsent(userId, () => {})[_starsKey(packKey, level)] = clamped;
    }
  }

  /// ========== UNLOCK ==========
  static Future<bool> isLevelUnlocked(String userId, String packKey, int level) async {
    if (level == 1) return true; // первый уровень всегда доступен
    final userMap = _unlockCache.putIfAbsent(userId, () => {});
    final composite = _unlockKey(packKey, level);
    final cached = userMap[composite];
    if (cached != null) return cached;
    final p = await SharedPreferences.getInstance();
    final key = '${_pfx(userId)}|unlocked|$packKey|$level';
    final v = p.getBool(key) ?? false;
    userMap[composite] = v;
    return v;
  }

  static Future<void> unlockLevel(String userId, String packKey, int level) async {
    if (level <= 1) return; // первый и так открыт
    final p = await SharedPreferences.getInstance();
    final key = '${_pfx(userId)}|unlocked|$packKey|$level';
    await p.setBool(key, true);
    _unlockCache.putIfAbsent(userId, () => {})[_unlockKey(packKey, level)] = true;
  }

  /// Batch-загрузка звезд и unlock-флагов для 1..levelsCount.
  /// Возвращает tuple (stars[], unlocked[]).
  static Future<(List<int>, List<bool>)> getLevelsProgress(
    String userId,
    String packKey,
    int levelsCount,
  ) async {
    final p = await SharedPreferences.getInstance();
    final starsList = List<int>.filled(levelsCount, 0);
    final unlockedList = List<bool>.filled(levelsCount, false);

    final userStars = _starsCache.putIfAbsent(userId, () => {});
    final userUnlock = _unlockCache.putIfAbsent(userId, () => {});

    for (int i = 1; i <= levelsCount; i++) {
      // stars
      final starsComp = _starsKey(packKey, i);
      int stars;
      if (userStars.containsKey(starsComp)) {
        stars = userStars[starsComp]!;
      } else {
        final key = '${_pfx(userId)}|stars|$packKey|$i';
        stars = p.getInt(key) ?? 0;
        userStars[starsComp] = stars;
      }
      starsList[i - 1] = stars;

      // unlock
      bool unlocked;
      if (i == 1) {
        unlocked = true;
      } else {
        final unlockComp = _unlockKey(packKey, i);
        if (userUnlock.containsKey(unlockComp)) {
          unlocked = userUnlock[unlockComp]!;
        } else {
          final key = '${_pfx(userId)}|unlocked|$packKey|$i';
            unlocked = p.getBool(key) ?? false;
            userUnlock[unlockComp] = unlocked;
        }
      }
      unlockedList[i - 1] = unlocked;
    }
    return (starsList, unlockedList);
  }

  /// Удаляем ВСЕ записи для конкретного пользователя ("новая игра" для него)
  static Future<void> wipeUser(String userId) async {
    final p = await SharedPreferences.getInstance();
    final prefix = '${_pfx(userId)}|';
    final keys = p.getKeys().where((k) => k.startsWith(prefix)).toList();
    for (final k in keys) {
      await p.remove(k);
    }
    _coinsCache.remove(userId);
    _starsCache.remove(userId);
    _unlockCache.remove(userId);
  }
}