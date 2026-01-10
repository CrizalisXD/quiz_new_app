import 'package:shared_preferences/shared_preferences.dart';
import '../progress/progress_store.dart';

class AchievementsStore {
  // Универсальные счётчики (если уже есть — используйте ваши ключи)
  static String _kCounter(String userId, String key) => 'ach_counter:$userId:$key';

  static String _kPerfect(String userId) => 'ach_perfect_levels:$userId';
  static String _kAnswered(String userId) => 'ach_answered:$userId';
  static String _kClaimed(String userId) => 'ach_claimed:$userId';
  static String _kGold(String userId) => 'wallet_gold:$userId';
  static String _kDiamond(String userId) => 'wallet_diamond:$userId';
  static String _kCountriesOpened(String userId) => 'ach_countries_opened:$userId';

  static Future<int> getAnsweredCount(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_kAnswered(userId)) ?? 0;
  }

  static Future<void> addAnswered(String userId, int delta) async {
    if (delta <= 0) return;
    final prefs = await SharedPreferences.getInstance();
    final key = _kAnswered(userId);
    final next = (prefs.getInt(key) ?? 0) + delta;
    await prefs.setInt(key, next);
  }

  static Future<void> setAnsweredCount(String userId, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAnswered(userId), value.clamp(0, value));
  }

  static Future<void> ensureAnsweredAtLeast(String userId, int minValue) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _kAnswered(userId);
    final current = prefs.getInt(key) ?? 0;
    if (current >= minValue) return;
    await prefs.setInt(key, minValue);
  }

  static Future<int> getPerfectLevelsCount(String userId) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kPerfect(userId)) ?? 0;
  }

  static Future<void> addPerfectLevel(String userId) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kPerfect(userId)) ?? 0;
    await sp.setInt(_kPerfect(userId), cur + 1);
  }

  static Future<Set<String>> getClaimed(String userId) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kClaimed(userId)) ?? const <String>[];
    return list.toSet();
  }

  static Future<void> _setClaimed(String userId, Set<String> ids) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setStringList(_kClaimed(userId), ids.toList()..sort());
  }

  static Future<int> getGold(String userId) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kGold(userId)) ?? 0;
  }

  static Future<int> getDiamond(String userId) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kDiamond(userId)) ?? 0;
  }

  static Future<void> addGold(String userId, int delta) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kGold(userId)) ?? 0;
    await sp.setInt(_kGold(userId), cur + delta);
  }

  static Future<void> addDiamond(String userId, int delta) async {
    final sp = await SharedPreferences.getInstance();
    final cur = sp.getInt(_kDiamond(userId)) ?? 0;
    await sp.setInt(_kDiamond(userId), cur + delta);
  }

  /// rewards: список строк вида "+2500 gold", "+50 diamond"
  static Future<void> claimAchievement({
    required String userId,
    required String achievementId,
    required List<String> rewards,
  }) async {
    final claimed = await getClaimed(userId);
    if (claimed.contains(achievementId)) return;

    for (final r in rewards) {
      final parsed = _parseReward(r);
      if (parsed == null) continue;
      final (amount, currency) = parsed;

      if (currency == 'gold') {
        // ✅ Источник истины для монет на Home: ProgressStore (coinsProvider -> ProgressStore.getCoins)
        await ProgressStore.addCoins(userId, amount);

        // (опционально) можно синхронизировать старый кошелёк, но лучше не использовать его дальше
        // await addGold(userId, amount);
      } else if (currency == 'diamond') {
        // пока diamonds живут здесь (на Home сейчас всё равно label=0)
        await addDiamond(userId, amount);
      }
    }

    claimed.add(achievementId);
    await _setClaimed(userId, claimed);
  }

  /// "+2500 gold" -> (2500, "gold")
  static (int amount, String currency)? _parseReward(String raw) {
    final s = raw.trim().toLowerCase();
    final m = RegExp(r'^\+?\s*(\d+)\s*(gold|diamond)s?$').firstMatch(s);
    if (m == null) return null;
    final amount = int.tryParse(m.group(1)!) ?? 0;
    final currency = m.group(2)!;
    if (amount <= 0) return null;
    return (amount, currency);
  }

  /// ✅ событие: страна открыта (один раз на страну)
  /// Возвращает true, если страна была добавлена впервые (т.е. это "первое открытие").
  static Future<bool> markCountryOpenedOnce(String userId, String countryKey) async {
    final sp = await SharedPreferences.getInstance();
    final key = _kCountriesOpened(userId);
    final list = sp.getStringList(key) ?? const <String>[];
    final set = list.toSet();

    final added = set.add(countryKey);
    if (!added) return false;

    await sp.setStringList(key, set.toList()..sort());

    // ✅ инкрементим счётчик для достижений "Путешественник"
    await incCounter(userId, 'countries_opened', 1);

    return true;
  }

  /// (опционально) Сколько уникальных стран открыто
  static Future<int> getOpenedCountriesCount(String userId) async {
    final sp = await SharedPreferences.getInstance();
    final list = sp.getStringList(_kCountriesOpened(userId)) ?? const <String>[];
    return list.toSet().length;
  }

  /// Универсальный инкремент счётчика (например: questions_answered / levels_completed / perfect_levels)
  static Future<int> incCounter(String userId, String name, int delta) async {
    if (delta == 0) return getCounter(userId, name);
    final sp = await SharedPreferences.getInstance();
    final key = _kCounter(userId, name);
    final cur = sp.getInt(key) ?? 0;
    final next = (cur + delta).clamp(0, 1 << 31);
    await sp.setInt(key, next);
    return next;
  }

  /// Прочитать счётчик (0 если не установлен)
  static Future<int> getCounter(String userId, String name) async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kCounter(userId, name)) ?? 0;
  }

  static Future<void> wipeUser(String userId) async {
    final sp = await SharedPreferences.getInstance();

    // старые/точечные ключи
    await sp.remove(_kAnswered(userId));
    await sp.remove(_kPerfect(userId));
    await sp.remove(_kClaimed(userId));
    await sp.remove(_kGold(userId));
    await sp.remove(_kDiamond(userId));
    await sp.remove(_kCountriesOpened(userId));

    // универсальные counters: удаляем известные eventKey (минимум под текущие точки)
    for (final k in const <String>[
      'questions_answered',
      'levels_completed',
      'perfect_levels',
      'countries_opened',
      'categories_completed',
      'countries_completed',
      'daily_deals_bought',
      'shop_purchases',
    ]) {
      await sp.remove(_kCounter(userId, k));
    }

    // NOTE: настройки звука/громкости хранятся в ProgressStore и очищаются через ProgressStore.wipeUser(userId)
  }

  /// DEV: выдать максимум прогресса/наград (для теста UI)
  static Future<void> grantAllDev(String userId) async {
    final sp = await SharedPreferences.getInstance();

    // 1) Счётчики под достижения/статистику
    await sp.setInt(_kCounter(userId, 'questions_answered'), 9999);
    await sp.setInt(_kCounter(userId, 'levels_completed'), 9999);
    await sp.setInt(_kCounter(userId, 'perfect_levels'), 9999);

    // 2) Валюта
    await ProgressStore.addCoins(userId, 999999);
    await sp.setInt(_kDiamond(userId), 9999);

    // 3) Claim все ачивки, которые есть в вашей витрине
    // (список должен совпадать с ids в achievements_screen.dart)
    await _setClaimed(userId, <String>{
      'a_answer_5',
      'a_answer_25',
      'a_answer_100',
      'a_levels_1',
      'a_levels_3',
      'a_levels_10',
      'a_perfect_1',
      'a_perfect_5',
      'a_perfect_20',
      'a_perfect_streak_3',
      'a_perfect_streak_7',
      'a_countries_open_1',
      'a_countries_open_3',
      'a_countries_open_7',
      'a_categories_complete_1',
      'a_categories_complete_3',
      'a_countries_complete_1',
      'a_countries_complete_3',
      'a_days_streak_2',
      'a_days_streak_7',
      'a_days_streak_30',
      'a_shop_first',
      'a_shop_5',
      'a_daily_deal_1',
      'a_daily_deal_7',
    });
  }
}