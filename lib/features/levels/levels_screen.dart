import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../l10n/app_localizations.dart';
import '../quiz/ui/quiz_screen.dart';
// Background removed per request.
import '../auth/current_user.dart';
import '../progress/progress_store.dart';
import '../progress/star_utils.dart';
import '../home/widgets/category_card.dart';
import '../../data/categories_config.dart';
import '../../utils/assets_index.dart';
import '../rewards/rewards_store.dart';
import '../../utils/ui_metrics.dart';

// Simple model for a level tile; later can be replaced with data from repository
class LevelInfo {
  final int number; // sequential number
  final bool unlocked;
  final int stars; // 0..3
  const LevelInfo(this.number, this.unlocked, this.stars);
}

class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  static Future<_PackMeta> _resolvePackMeta(BuildContext context, String countryKey, String subcatKey) async {
    final cacheKey = '$countryKey:$subcatKey';
    final cached = _PackMeta.cache[cacheKey];
    if (cached != null) return cached;
    String manifest = '';
    try {
      // rootBundle быстрее, чем искать через DefaultAssetBundle + от нас не зависит контекст
      manifest = await rootBundle.loadString('AssetManifest.json');
    } catch (e) {
      debugPrint('[Levels] Не удалось загрузить AssetManifest: $e');
    }
  // Для JSON-файлов используем те же алиасы, что и для изображений: food->cuisine, history_persons->history_personalities
  final subcatAlias = _imageSubcatAlias(subcatKey);
  final base = 'assets/questions/ru/$countryKey/${countryKey}_${subcatAlias}';
    final has100 = manifest.contains('${base}_100.json');
    final has50 = manifest.contains('${base}_50.json');
    // Fallback: один общий файл country.json
    final countrySingleFile = manifest.contains('assets/questions/ru/$countryKey/$countryKey.json');
    _PackMeta meta;
    if (has100) {
      meta = _PackMeta(basePack: '${countryKey}_${subcatKey}', suffix: '_100', levelsCount: 10, usesCountryFile: false);
    } else if (has50) {
      meta = _PackMeta(basePack: '${countryKey}_${subcatKey}', suffix: '_50', levelsCount: 50, usesCountryFile: false);
    } else if (countrySingleFile) {
      // Попробуем прочитать файл и определить кол-во уровней по длине levels (map или list)
      int detectedLevels = 0;
      try {
        final raw = await rootBundle.loadString('assets/questions/ru/$countryKey/$countryKey.json');
        final data = jsonDecode(raw);
        final lv = data['levels'];
        if (lv is List) {
          detectedLevels = lv.length;
        } else if (lv is Map) {
          detectedLevels = lv.length;
        }
      } catch (e) {
        debugPrint('[Levels] Ошибка чтения country.json: $e');
      }
      meta = _PackMeta(basePack: countryKey, suffix: '', levelsCount: detectedLevels, usesCountryFile: true);
    } else {
      meta = _PackMeta(basePack: '${countryKey}_${subcatAlias}', suffix: '', levelsCount: 0, usesCountryFile: false);
    }
    _PackMeta.cache[cacheKey] = meta;
    return meta;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final countryKey = args?['countryKey'] as String? ?? 'unknown';
    final subcatKey = args?['subcategoryKey'] as String? ?? 'classic';
    final subcatLabel = args?['subcategoryLabel'] as String? ?? subcatKey;

    final userId = ref.watch(currentUserProvider);

    return FutureBuilder<_PackMeta>(
      future: _resolvePackMeta(context, countryKey, subcatKey),
      builder: (context, snapMeta) {
        if (!snapMeta.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
  final meta = snapMeta.data!;
  // Базовое кол-во из мета или 20 по умолчанию
  final baseTotal = meta.levelsCount == 0 ? 20 : meta.levelsCount;
  // Ограничение по требованию: classic/hard = 10 уровней, остальные = 5 уровней
  final limit = (subcatKey == 'classic' || subcatKey == 'hard') ? 10 : 5;
  final totalLevels = baseTotal < limit ? baseTotal : limit;
        return FutureBuilder<(List<int>, List<bool>)>(
          future: _loadProgressAndAssets(userId, meta.basePack, totalLevels),
          builder: (cProg, snapProg) {
            if (!snapProg.hasData) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final (starsList, unlockedList) = snapProg.data!;
            final levels = List<LevelInfo>.generate(totalLevels, (i) => LevelInfo(i + 1, unlockedList[i], starsList[i]));

            final levelBg = _pickLevelBackground(countryKey, subcatKey);
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text('$subcatLabel — ${AppLocalizations.of(context).levels_word} (${levels.length})'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              body: Stack(
                fit: StackFit.expand,
                children: [
                  if (levelBg != null)
                    Image.asset(
                      levelBg,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                    ),
                  Padding(
                padding: EdgeInsets.fromLTRB(16, contentTopPadding(context), 16, 16),
                child: ListView.separated(
                  itemCount: levels.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 18),
                  itemBuilder: (c, i) {
                    final l = levels[i];
                    // Найдём картинку подкатегории для фона карточки уровня
                    final subcats = countrySubcategories[countryKey] ?? countrySubcategories['japan'];
                    final cfg = subcats?.firstWhere(
                      (e) => e.key == subcatKey,
                      orElse: () => SubcategoryConfig(key: subcatKey, label: subcatLabel, imageAsset: 'assets/images/categories/$countryKey.png'),
                    );
                    final bgImage = cfg?.imageAsset ?? 'assets/images/categories/$countryKey.png';
                    // Картинка уровня по новой структуре: assets/images/ui/{country}_{subcategory}_lvl/{country}_{subcategory}_{level}.png
          final alias = _imageSubcatAlias(subcatKey);
          final levelImgAlias = 'assets/images/ui/${countryKey}_${alias}_lvl/${countryKey}_${alias}_${l.number}.png';
          final levelImgOrig  = 'assets/images/ui/${countryKey}_${subcatKey}_lvl/${countryKey}_${subcatKey}_${l.number}.png';
          final cardImage = AssetsIndex.has(levelImgAlias)
            ? levelImgAlias
            : (AssetsIndex.has(levelImgOrig) ? levelImgOrig : bgImage);

                    Future<void> handleTap() async {
                      if (!l.unlocked) return;
                      final pack = meta.basePack;
                      final result = await Navigator.push<Map<String, dynamic>?>(
                        c,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(pack: pack, level: l.number),
                        ),
                      );
                      if (result == null || !c.mounted) return;
                      final answered = (result['answered'] as int?) ?? 0;
                      final score = (result['score'] as int?) ?? 0;
                      if (answered == 0) return;
                      final starsEarned = result['starsEarned'] as int? ?? StarUtils.fromScore(score, answered);
                      await ProgressStore.setLevelStars(userId, meta.basePack, l.number, starsEarned);
                      if (starsEarned >= 1) {
                        // Не разблокируем уровни за пределом отображаемого лимита
                        final displayedTotal = levels.length;
                        if (l.number < displayedTotal) {
                          await ProgressStore.unlockLevel(userId, meta.basePack, l.number + 1);
                        }
                      }
                      // Награда за 3 звезды: добавим постер
                      if (starsEarned >= 3) {
                        // Определим страну из basePack (japan_classic -> japan)
                        final packParts = meta.basePack.split('_');
                        final country = packParts.isNotEmpty ? packParts.first : meta.basePack;
                        // Новая структура: assets/images/reward/{country}/{country}_{alias}_lvl/{country}_{alias}_{level}.png
                        final alias = _imageSubcatAlias(subcatKey);
                        await AssetsIndex.ensureLoaded();
                        final found = AssetsIndex.rewardForLevel(country: country, alias: alias, level: l.number);
                        if (found != null && AssetsIndex.has(found)) {
                          await RewardsStore.addReward(userId, found);
                          if (c.mounted) {
                            ScaffoldMessenger.of(c).showSnackBar(
                              SnackBar(
                                content: Text(AppLocalizations.of(c).reward_received),
                                action: SnackBarAction(
                                  label: AppLocalizations.of(c).open_rewards_action,
                                  onPressed: () => Navigator.pushNamed(c, '/profile'),
                                ),
                              ),
                            );
                          }
                        } else {
                          // Сообщим пользователю, что постер для этого уровня отсутствует в ассетах
                          debugPrint('[Levels] Reward asset not found for $country/$alias level ${l.number}. Folder must contain file with suffix _${l.number}.png');
                          if (c.mounted) {
                            ScaffoldMessenger.of(c).showSnackBar(
                              const SnackBar(content: Text('Постер для этого уровня пока не подготовлен')),
                            );
                          }
                        }
                      }
                      if (c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(
                          SnackBar(content: Text('${AppLocalizations.of(c).level_word} ${l.number}: ⭐$starsEarned')),
                        );
                      }
                      (context as Element).markNeedsBuild();
                    }

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Карточка как на экране категорий
                        CategoryCard(
                          imageAsset: cardImage,
                          onTap: handleTap,
                          title: '${AppLocalizations.of(context).level_word} ${l.number}',
                        ),
                        // Мягкий блюр в зависимости от звёзд (0★=100%, 1★=75%, 2★=50%, 3★=0%)
                        if (_blurSigmaForStars(l.stars) > 0)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: true,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(22),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: _blurSigmaForStars(l.stars),
                                    sigmaY: _blurSigmaForStars(l.stars),
                                  ),
                                  // Прозрачный child обязателен для отрисовки фильтра
                                  child: Container(color: Colors.transparent),
                                ),
                              ),
                            ),
                          ),
                        // Бейдж со звёздами справа сверху
                        Positioned(
                          right: 12,
                          top: 12,
                          child: _LevelStarsBadge(stars: l.stars),
                        ),
                        // Оверлей блокировки
                        if (!l.unlocked)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: const Center(
                                child: Icon(Icons.lock, size: 36, color: Colors.white70),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _PackMeta {
  final String basePack; // без суффикса
  final String suffix;   // '_100' | '_50' | ''
  final int levelsCount; // 10 | 50 | 0
  final bool usesCountryFile; // true если используем country.json формат
  static final Map<String, _PackMeta> cache = {};
  _PackMeta({required this.basePack, required this.suffix, required this.levelsCount, this.usesCountryFile = false});
}

/// Кеш наличия ассетов из AssetManifest.json
Future<(List<int>, List<bool>)> _loadProgressAndAssets(String userId, String basePack, int totalLevels) async {
  // Параллельно подтянем манифест ассетов и прогресс
  final results = await Future.wait([
    ProgressStore.getLevelsProgress(userId, basePack, totalLevels),
    AssetsIndex.ensureLoaded(),
  ]);
  return results.first as (List<int>, List<bool>);
}

/// Возвращает путь к фону для экрана уровней из assets/images/bg/level/
/// Новый приоритет по договорённости:
/// 1) level_{country}.png
/// Fallbacks для обратной совместимости:
/// 2) {country}_{subcat}.png
/// 3) {country}.png
/// 4) любой .png из папки
String? _pickLevelBackground(String countryKey, String subcatKey) {
  final byNewPattern = 'assets/images/bg/level/level_${countryKey}.png';
  if (AssetsIndex.has(byNewPattern)) return byNewPattern;
  final specific = 'assets/images/bg/level/${countryKey}_${subcatKey}.png';
  if (AssetsIndex.has(specific)) return specific;
  final byCountry = 'assets/images/bg/level/${countryKey}.png';
  if (AssetsIndex.has(byCountry)) return byCountry;
  // Возьмём любой png из папки как последний фоллбек
  return AssetsIndex.firstInDir('assets/images/bg/level/');
}

// Соответствие ключей подкатегорий к именам папок/файлов картинок
String _imageSubcatAlias(String subcatKey) {
  switch (subcatKey) {
    case 'food':
      return 'cuisine';
    case 'history_persons':
      return 'history_personalities';
    default:
      return subcatKey;
  }
}

class _LevelStarsBadge extends StatelessWidget {
  final int stars; // 0..3
  const _LevelStarsBadge({required this.stars});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final filled = stars > i;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              filled ? Icons.star_rounded : Icons.star_border_rounded,
              size: 16,
              color: filled ? Colors.amber : Colors.white70,
            ),
          );
        }),
      ),
    );
  }
}

// Возвращает sigma для эффекта blur в зависимости от количества звёзд
double _blurSigmaForStars(int stars) {
  const double maxSigma = 12.0; // 100%
  switch (stars) {
    case 0:
      return maxSigma * 0.50; // 50%
    case 1:
      return maxSigma * 0.35; // 35%
    case 2:
      return maxSigma * 0.15; // 15%
    default:
      return 0.0; // 3★ -> 0%
  }
}
