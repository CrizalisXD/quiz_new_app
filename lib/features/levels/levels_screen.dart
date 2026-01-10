import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import 'dart:ui' show ImageFilter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../l10n/app_localizations.dart';
import '../quiz/ui/quiz_screen.dart';
import '../auth/current_user.dart';
import '../progress/progress_store.dart';
import '../progress/star_utils.dart';
import '../home/widgets/category_card.dart';
import '../../data/categories_config.dart';
import '../../utils/assets_index.dart';
import '../rewards/rewards_store.dart';
import '../achievements/achievements_store.dart';
import '../../utils/sound_manager.dart';

// Простая модель уровня
class LevelInfo {
  final int number; // 1..N
  final bool unlocked;
  final int stars; // 0..3
  const LevelInfo(this.number, this.unlocked, this.stars);
}

class LevelsScreen extends ConsumerWidget {
  const LevelsScreen({super.key});

  // Определяем метаданные пакета (кол-во уровней, тип файла и т.п.)
  static Future<_PackMeta> _resolvePackMeta(
    BuildContext context,
    String countryKey,
    String subcatKey,
  ) async {
    final cacheKey = '$countryKey:$subcatKey';
    final cached = _PackMeta.cache[cacheKey];
    if (cached != null) return cached;

    String manifest = '';
    try {
      manifest = await rootBundle.loadString('AssetManifest.json');
    } catch (e) {
      debugPrint('[Levels] Не удалось загрузить AssetManifest: $e');
    }

    // Алиас подкатегории для файлов:
    // food -> cuisine
    // history_persons -> history_personalities
    final subcatAlias = _imageSubcatAlias(subcatKey);

    // JSON-паки:
    // assets/questions/ru/{country}/{country}_{alias}_100.json
    // assets/questions/ru/{country}/{country}_{alias}_50.json
    final base = 'assets/questions/ru/$countryKey/${countryKey}_${subcatAlias}';
    final has100 = manifest.contains('${base}_100.json');
    final has50 = manifest.contains('${base}_50.json');

    // Fallback: один общий файл country.json
    final countrySingleFile =
        manifest.contains('assets/questions/ru/$countryKey/$countryKey.json');

    _PackMeta meta;
    if (has100) {
      meta = _PackMeta(
        basePack: '${countryKey}_${subcatKey}',
        suffix: '_100',
        levelsCount: 10,
        usesCountryFile: false,
      );
    } else if (has50) {
      meta = _PackMeta(
        basePack: '${countryKey}_${subcatKey}',
        suffix: '_50',
        levelsCount: 50,
        usesCountryFile: false,
      );
    } else if (countrySingleFile) {
      int detectedLevels = 0;
      try {
        final raw = await rootBundle
            .loadString('assets/questions/ru/$countryKey/$countryKey.json');
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
      meta = _PackMeta(
        basePack: countryKey,
        suffix: '',
        levelsCount: detectedLevels,
        usesCountryFile: true,
      );
    } else {
      // Ничего не нашли — считаем 0 уровней
      meta = _PackMeta(
        basePack: '${countryKey}_${subcatAlias}',
        suffix: '',
        levelsCount: 0,
        usesCountryFile: false,
      );
    }

    _PackMeta.cache[cacheKey] = meta;
    return meta;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final countryKey = args?['countryKey'] as String? ?? 'unknown';
    final subcatKey = args?['subcategoryKey'] as String? ?? 'classic';
    final subcatLabel = args?['subcategoryLabel'] as String? ?? subcatKey;

    final userId = ref.watch(currentUserProvider);

    // Музыку НЕ переключаем здесь: она должна продолжать играть между экранами без рестарта/задержки.
    // (Музыка страны включается на Home при выборе страны.)

    return FutureBuilder<_PackMeta>(
      future: _resolvePackMeta(context, countryKey, subcatKey),
      builder: (context, snapMeta) {
        if (!snapMeta.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final meta = snapMeta.data!;
        // Базовое количество уровней из мета или 20 по умолчанию
        final baseTotal = meta.levelsCount == 0 ? 20 : meta.levelsCount;
        // Ограничение: classic/hard = 10, остальные = 5
        final limit =
            (subcatKey == 'classic' || subcatKey == 'hard') ? 10 : 5;
        final totalLevels = baseTotal < limit ? baseTotal : limit;

        return FutureBuilder<(List<int>, List<bool>)>(
          future: _loadProgressAndAssets(userId, meta.basePack, totalLevels),
          builder: (cProg, snapProg) {
            if (!snapProg.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final (starsList, unlockedList) = snapProg.data!;
            final levels = List<LevelInfo>.generate(
              totalLevels,
              (i) => LevelInfo(i + 1, unlockedList[i], starsList[i]),
            );

            final levelBg = _pickLevelBackground(countryKey);
            final subcatAlias = _imageSubcatAlias(subcatKey);

            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(
                  '$subcatLabel — '
                  '${AppLocalizations.of(context).levels_word} '
                  '(${levels.length})',
                ),
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
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Colors.black),
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: ListView.separated(
                          itemCount: levels.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 18),
                          itemBuilder: (c, i) {
                            final l = levels[i];

                            // Конфиг подкатегории для фонового изображения карточки
                            final subcats = countrySubcategories[countryKey] ??
                                countrySubcategories['japan'];
                            final cfg = subcats?.firstWhere(
                              (e) => e.key == subcatKey,
                              orElse: () => SubcategoryConfig(
                                key: subcatKey,
                                label: subcatLabel,
                                imageAsset:
                                    'assets/images/categories/$countryKey.png',
                              ),
                            );
                            final bgImage = cfg?.imageAsset ??
                                'assets/images/categories/$countryKey.png';

                            // Кнопка уровня:
                            // assets/images/ui/{country}_{alias}_lvl/{country}_{alias}_{level}.png
                            final levelImg = _levelButtonPath(
                              countryKey: countryKey,
                              subcatAlias: subcatAlias,
                              level: l.number,
                            );

                            final cardImage = levelImg;

                            Future<void> handleTap() async {
                              if (!l.unlocked) return;

                              await SoundManager.playSfx('assets/sound/click.mp3');

                              final pack = meta.basePack;
                              final result =
                                  await Navigator.push<Map<String, dynamic>?>(
                                c,
                                MaterialPageRoute(
                                  builder: (_) => QuizScreen(
                                    pack: pack,
                                    level: l.number,
                                  ),
                                ),
                              );

                              if (result == null || !c.mounted) return;

                              // ВАЖНО: счётчики questions_answered / levels_completed / perfect_levels
                              // инкрементятся внутри QuizScreen, чтобы не было дублей.

                              final answered = (result['answered'] as int?) ?? 0;
                              final score = (result['score'] as int?) ?? 0;
                              if (answered == 0) return;

                              // ❌ убираем: answered/progress должен учитываться в QuizScreen через event counters
                              // await AchievementsStore.addAnswered(userId, answered);

                              final starsEarned =
                                  result['starsEarned'] as int? ??
                                      StarUtils.fromScore(score, answered);

                              await ProgressStore.setLevelStars(
                                userId,
                                meta.basePack,
                                l.number,
                                starsEarned,
                              );

                              if (starsEarned >= 1) {
                                // Не разблокируем уровни за пределом отображаемого лимита
                                final displayedTotal = levels.length;
                                if (l.number < displayedTotal) {
                                  await ProgressStore.unlockLevel(
                                    userId,
                                    meta.basePack,
                                    l.number + 1,
                                  );
                                }
                              }

                              // Награда за 3 звезды: добавим постер
                              if (starsEarned >= 3) {
                                final packParts = meta.basePack.split('_');
                                final country = packParts.isNotEmpty
                                    ? packParts.first
                                    : meta.basePack;
                                final alias = _imageSubcatAlias(subcatKey);
                                final rewardAsset = _levelRewardPath(
                                  country: country,
                                  subcatAlias: alias,
                                  level: l.number,
                                );
                                await RewardsStore.addReward(userId, rewardAsset);
                                await SoundManager.playSfx('assets/sound/rewards.mp3');
                                if (c.mounted) {
                                  await showDialog<void>(
                                    context: c,
                                    barrierDismissible: true,
                                    builder: (_) => Dialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Lottie.asset(
                                              'assets/animations/achievement_badge.json',
                                              repeat: false,
                                              width: 180,
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              AppLocalizations.of(c).reward_received,
                                              textAlign: TextAlign.center,
                                              style: Theme.of(c).textTheme.titleMedium,
                                            ),
                                            const SizedBox(height: 16),
                                            FilledButton(
                                              onPressed: () => Navigator.of(c).pop(),
                                              child: Text(AppLocalizations.of(c).ok),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                  await SoundManager.playSfx('assets/sound/finish.mp3');
                                  if (!c.mounted) return;

                                  // ❌ убрать нижний попап "reward_received"
                                  // ScaffoldMessenger.of(c).showSnackBar(
                                  //   SnackBar(
                                  //     content: Text(
                                  //       AppLocalizations.of(c).reward_received,
                                  //     ),
                                  //     action: SnackBarAction(
                                  //       label: AppLocalizations.of(c).open_rewards_action,
                                  //       onPressed: () => Navigator.pushNamed(c, '/profile'),
                                  //     ),
                                  //   ),
                                  // );
                                }
                              }

                              if (c.mounted) {
                                // ❌ убрать нижний попап "Level X: ⭐Y"
                                // ScaffoldMessenger.of(c).showSnackBar(
                                //   SnackBar(
                                //     content: Text(
                                //       '${AppLocalizations.of(c).level_word} '
                                //       '${l.number}: ⭐$starsEarned',
                                //     ),
                                //   ),
                                // );
                              }

                              (context as Element).markNeedsBuild();
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // ✅ убрать фикс высоты — размер как на Home (задаётся CategoryCard)
                                CategoryCard(
                                  imageAsset: cardImage,
                                  onTap: handleTap,
                                  title: '${AppLocalizations.of(context).level_word} ${l.number}',
                                ),

                                // Мягкий блюр в зависимости от звёзд (0★=макс, 3★=0)
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
                                          child:
                                              Container(color: Colors.transparent),
                                        ),
                                      ),
                                    ),
                                  ),

                                // Бейдж со звёздами
                                Positioned(
                                  right: 12,
                                  top: 12,
                                  child: _LevelStarsBadge(stars: l.stars),
                                ),

                                // Лок
                                if (!l.unlocked)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black38,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.lock,
                                          size: 36,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
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
  final String suffix; // '_100' | '_50' | ''
  final int levelsCount; // 10 | 50 | 0
  final bool usesCountryFile; // true если используем country.json формат

  static final Map<String, _PackMeta> cache = {};

  _PackMeta({
    required this.basePack,
    required this.suffix,
    required this.levelsCount,
    this.usesCountryFile = false,
  });
}

/// Кеш наличия ассетов + прогресс уровней
Future<(List<int>, List<bool>)> _loadProgressAndAssets(
  String userId,
  String basePack,
  int totalLevels,
) async {
  final results = await Future.wait([
    ProgressStore.getLevelsProgress(userId, basePack, totalLevels),
    AssetsIndex.ensureLoaded(),
  ]);
  return results.first as (List<int>, List<bool>);
}

/// Фон уровней:
/// assets/images/bg/level/level_{country}.png
String? _pickLevelBackground(String countryKey) {
  return 'assets/images/bg/level/level_$countryKey.png';
}

/// Путь к кнопке уровня:
/// assets/images/ui/{country}_{alias}_lvl/{country}_{alias}_{level}.png
String _levelButtonPath({
  required String countryKey,
  required String subcatAlias,
  required int level,
}) {
  return 'assets/images/ui/'
      '${countryKey}_${subcatAlias}_lvl/'
      '${countryKey}_${subcatAlias}_$level.png';
}

/// Соответствие ключей подкатегорий к алиасам для файлов/папок
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

// Blur в зависимости от количества звёзд
double _blurSigmaForStars(int stars) {
  const double maxSigma = 12.0;
  switch (stars) {
    case 0:
      return maxSigma * 0.50;
    case 1:
      return maxSigma * 0.35;
    case 2:
      return maxSigma * 0.15;
    default:
      return 0.0; // 3★
  }
}

String _levelRewardPath({
  required String country,
  required String subcatAlias,
  required int level,
}) {
  return 'assets/images/reward/$country/'
      '${country}_${subcatAlias}_lvl/'
      '${country}_${subcatAlias}_$level.png';
}
