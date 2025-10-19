import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/core/profile/profile_providers.dart';
import 'package:quiz_new_app/core/profile/local_profile.dart';
import 'edit_profile_screen.dart';
import '../rewards/rewards_store.dart';
import '../auth/current_user.dart';
import '../rewards/poster_preview_screen.dart';
import '../../utils/assets_index.dart';
import '../../utils/rank_utils.dart';
// (import left below)
import 'widgets/country_stats_screen.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';
import '../progress/progress_store.dart';
import '../../data/categories_config.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(profileProvider);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).profile_title), actions: [
        IconButton(
          tooltip: 'Сбросить (гость)',
            onPressed: () => ref.read(profileProvider.notifier).reset(),
            icon: const Icon(Icons.refresh)),
      ]),
      body: st.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Ошибка: $e')),
        data: (p) => _Body(profile: p),
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  final LocalProfile profile;
  const _Body({required this.profile});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  bool _showCountryProgress = true;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider);
    final profile = widget.profile; // удобный алиас
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AvatarHeader(profile: profile),
        const SizedBox(height: 12),
        _DevActionsRow(userId: userId),
        const SizedBox(height: 24),
        Row(
          children: [
            Text(AppLocalizations.of(context).profile_progress_by_countries, style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _showCountryProgress = !_showCountryProgress),
              child: Text(_showCountryProgress ? _t(context, ru: 'Скрыть', en: 'Hide') : _t(context, ru: 'Показать', en: 'Show')),
            )
          ],
        ),
        const SizedBox(height: 8),
  if (_showCountryProgress) const CountryProgressList() else const SizedBox.shrink(),
        const SizedBox(height: 24),
        // Секция достижений скрыта по требованию
        RewardsByCountrySection(userId: userId),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _ChipStat extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ChipStat({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _AvatarHeader extends StatelessWidget {
  final LocalProfile profile;
  const _AvatarHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rank = RankUtils.byTotalStars(profile.totalStars);
    final colors = RankUtils.gradientFor(rank);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: colors),
              ),
              child: CircleAvatar(
                radius: 48,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 44,
                  backgroundImage: AssetImage(profile.avatarPath),
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.edit, size: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('${AppLocalizations.of(context).rank_title}: ${RankUtils.label(rank, context)}', style: const TextStyle(fontSize: 12, color: Colors.black87)),
              const SizedBox(height: 4),
              Text('ID: ${profile.id}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _ChipStat(icon: Icons.monetization_on, label: profile.coins.toString()),
                  _ChipStat(icon: Icons.star_rate, label: profile.totalStars.toString()),
                  _ChipStat(icon: Icons.videogame_asset, label: profile.gamesPlayed.toString()),
                ],
              )
            ],
          ),
        )
      ],
    );
  }
}

/// Вертикальный список мини-карт стран с прогресс-барами
class CountryProgressList extends ConsumerWidget {
  const CountryProgressList({super.key});

  int _expectedForSub(String key) => (key == 'classic' || key == 'hard') ? 10 : 5;

  Future<(int completed, int expected)> _calcForCountry(BuildContext context, WidgetRef ref, String country) async {
    final userId = ref.read(currentUserProvider);
    final subs = countrySubcategories[country] ?? const <SubcategoryConfig>[];
    int expected = 0;
    int completed = 0;
    for (final sc in subs) {
      final exp = _expectedForSub(sc.key);
      expected += exp;
      final packKey = '${country}_${sc.key}';
      final (starsList, unlocked) = await ProgressStore.getLevelsProgress(userId, packKey, exp);
      // Считаем завершёнными уровни, где есть звёзды (>0) или уровень открыт (unlocked)
      int subCompleted = 0;
      for (var i = 0; i < exp; i++) {
        if (starsList[i] > 0 || unlocked[i]) subCompleted++;
      }
      completed += subCompleted;
    }
    return (completed, expected);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = countrySubcategories.keys.toList();
    return Column(
      children: [
        for (final c in countries) ...[
          FutureBuilder<(int, int)>(
            future: _calcForCountry(context, ref, c),
            builder: (context, snap) {
              final stats = snap.data ?? (0, (countrySubcategories[c]?.fold<int>(0, (p, sc) => p + _expectedForSub(sc.key)) ?? 0));
              return _CountryProgressTile(
                countryKey: c,
                label: _countryNameLocalized(context, c),
                stats: stats,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CountryStatsScreen(countryKey: c)),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ]
      ],
    );
  }
}

String _countryNameLocalized(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  switch (key) {
    case 'japan':
      return lang == 'ru' ? 'Япония' : 'Japan';
    case 'france':
      return lang == 'ru' ? 'Франция' : 'France';
    case 'brazil':
      return lang == 'ru' ? 'Бразилия' : 'Brazil';
    case 'norway':
      return lang == 'ru' ? 'Норвегия' : 'Norway';
    case 'egypt':
      return lang == 'ru' ? 'Египет' : 'Egypt';
    default:
      return key;
  }
}

class _CountryProgressTile extends StatelessWidget {
  final String countryKey;
  final String label;
  final (int completed, int expected) stats;
  final VoidCallback onTap;
  const _CountryProgressTile({
    required this.countryKey,
    required this.label,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (completed, expected) = stats;
    final pct = expected == 0 ? 0.0 : (completed / expected).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                child: Text(_flagEmoji(countryKey), style: const TextStyle(fontSize: 18)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label — ${(pct * 100).round()}%', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: Colors.black12,
                        color: Colors.deepPurpleAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _flagEmoji(String key) {
  switch (key) {
    case 'japan':
      return '🇯🇵';
    case 'france':
      return '🇫🇷';
    case 'brazil':
      return '🇧🇷';
    case 'norway':
      return '🇳🇴';
    case 'egypt':
      return '🇪🇬';
    default:
      return '🏳️';
  }
}

/// Кнопки для быстрой отладки/админ-действий: сброс и максимум
class _DevActionsRow extends ConsumerWidget {
  final String userId;
  const _DevActionsRow({required this.userId});

  Future<void> _confirm(BuildContext context, String title, Future<void> Function() action) async {
    final ok = await showDialog<bool>(context: context, builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(_t(context, ru: 'Действие нельзя отменить. Продолжить?', en: 'This action cannot be undone. Continue?')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_t(context, ru: 'Отмена', en: 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(_t(context, ru: 'Да', en: 'Yes'))),
      ],
    ));
    if (ok == true) {
      await action();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(context, ru: 'Готово', en: 'Done'))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.delete_forever),
            label: Text(_t(context, ru: 'Сбросить всё', en: 'Reset all')),
            onPressed: () => _confirm(context, _t(context, ru: 'Сбросить прогресс и коллекцию', en: 'Reset progress & collection'), () async {
              await ProgressStore.wipeUser(userId);
              await RewardsStore.clear(userId);
              // Профиль сбросим через провайдер (генерация нового гостя)
              await ref.read(profileProvider.notifier).reset();
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.star_rate),
            label: Text(_t(context, ru: 'Всё на 3★ + коллекция', en: 'All 3★ + collection')),
            onPressed: () => _confirm(context, _t(context, ru: 'Отметить все уровни как пройденные на 3★ и пополнить коллекцию', en: 'Mark all levels as 3★ and fill collection'), () async {
              // Для всех стран и их подкатегорий выставим 10 уровней (classic/hard) и 5 уровней (остальные) как пройденные на 3★
              // и добавим соответствующие постеры в коллекцию, если ассеты существуют.
              await AssetsIndex.ensureLoaded();
              for (final entry in countrySubcategories.entries) {
                final country = entry.key;
                for (final sc in entry.value) {
                  final packKey = '${country}_${sc.key}';
                  final limit = (sc.key == 'classic' || sc.key == 'hard') ? 10 : 5;
                  for (int level = 1; level <= limit; level++) {
                    await ProgressStore.setLevelStars(userId, packKey, level, 3);
                    if (level < limit) {
                      await ProgressStore.unlockLevel(userId, packKey, level + 1);
                    }
                    // Выдадим постер по новой схеме, как в LevelsScreen
                    final alias = _imageSubcatAlias(sc.key);
                    final found = AssetsIndex.rewardForLevel(country: country, alias: alias, level: level);
                    if (found != null && AssetsIndex.has(found)) {
                      await RewardsStore.addReward(userId, found);
                    }
                  }
                }
              }
              // Обновим локальный профиль (пересчитать totalStars грубо не будем; данные подтянутся при следующем запуске/игре)
              // Здесь просто уведомим UI
              ref.invalidate(profileProvider);
            }),
          ),
        ),
      ],
    );
  }
}

// Секции достижений временно нет на экране профиля

// Соответствие ключей подкатегорий к алиасам картинок (дублирует логику из LevelsScreen)
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

class RewardsByCountrySection extends StatefulWidget {
  final String userId;
  const RewardsByCountrySection({super.key, required this.userId});

  @override
  State<RewardsByCountrySection> createState() => _RewardsByCountrySectionState();
}

class _RewardsByCountrySectionState extends State<RewardsByCountrySection> {
  final Map<String, bool> _expanded = {};

  String _countryFromPath(String p) {
    // Новая структура:
    // assets/images/reward/{country}/{country}_{alias}_lvl/{country}_{alias}_{level}.png
    // Также поддержка старых вариантов и путей с обратными слешами.
    final norm = p.replaceAll('\\', '/');
    final parts = norm.split('/');
    final idx = parts.indexOf('reward');
    if (idx != -1 && idx + 1 < parts.length && parts[idx + 1].isNotEmpty) {
      return parts[idx + 1];
    }
    // Фоллбек: пробуем извлечь страну из имени файла (префикс до первого '_' или '/')
    final file = parts.isNotEmpty ? parts.last : '';
    // Сначала пробуем по полному шаблону {country}_{alias}_{level}.png
    final mFull = RegExp(r'^([A-Za-z]+)_[A-Za-z]+_\d+\.png$').firstMatch(file);
    if (mFull != null) return mFull.group(1)!;
    // Затем общий префикс до '_' или '/'
    final m = RegExp(r'^([A-Za-z]+)[_/]').firstMatch('$file/');
    if (m != null) return m.group(1)!;
    return 'other';
  }

  String _countryLabel(BuildContext context, String key) {
    final lang = Localizations.localeOf(context).languageCode;
    switch (key) {
      case 'japan':
        return lang == 'ru' ? 'Япония' : 'Japan';
      case 'france':
        return lang == 'ru' ? 'Франция' : 'France';
      case 'brazil':
        return lang == 'ru' ? 'Бразилия' : 'Brazil';
      case 'norway':
        return lang == 'ru' ? 'Норвегия' : 'Norway';
      case 'egypt':
        return lang == 'ru' ? 'Египет' : 'Egypt';
      default:
        return lang == 'ru' ? 'Другое' : 'Other';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      // Гарантируем, что индекс ассетов загружен для корректной работы подсчёта total
      future: () async {
        await AssetsIndex.ensureLoaded();
        return RewardsStore.getRewards(widget.userId);
      }(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final rewards = snap.data!;
        if (rewards.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context).profile_rewards, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(AppLocalizations.of(context).profile_no_rewards, style: const TextStyle(color: Colors.black54)),
            ],
          );
        }

        // Группируем по стране
        final Map<String, List<String>> byCountry = {};
        for (final p in rewards) {
          final c = _countryFromPath(p);
          byCountry.putIfAbsent(c, () => []).add(p);
        }

        // Порядок: Япония первой, затем остальное по алфавиту
        final keys = byCountry.keys.toList();
        keys.sort();
        if (keys.contains('japan')) {
          keys.remove('japan');
          keys.insert(0, 'japan');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context).profile_rewards, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final key in keys) ...[
              _CountryRewardsBlock(
                countryKey: key,
                label: _countryLabel(context, key),
                items: byCountry[key]!,
                expanded: _expanded[key] ?? false,
                total: AssetsIndex.countByPrefix('assets/images/reward/$key/'),
                onToggle: () => setState(() => _expanded[key] = !(_expanded[key] ?? false)),
              ),
              const SizedBox(height: 16),
            ],
          ],
        );
      },
    );
  }
}

class _CountryRewardsBlock extends StatelessWidget {
  final String countryKey;
  final String label;
  final List<String> items;
  final bool expanded;
  final int total;
  final VoidCallback onToggle;

  const _CountryRewardsBlock({
    required this.countryKey,
    required this.label,
    required this.items,
    required this.expanded,
    required this.total,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final visibleItems = expanded ? items : items.take(4).toList();
    final countStr = total > 0 ? '$label — ${items.length}/$total' : '$label — ${items.length}/∞';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(countStr, style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            TextButton(
              onPressed: onToggle,
              child: Text(expanded ? _t(context, ru: 'Свернуть', en: 'Show less') : _t(context, ru: 'Показать больше', en: 'Show more')),
            )
          ],
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 16/9,
          ),
          itemCount: visibleItems.length,
          itemBuilder: (_, i) {
            final p = visibleItems[i];
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(PosterPreviewScreen.route(p)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        p,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade300,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

String _t(BuildContext context, {required String ru, required String en}) {
  return Localizations.localeOf(context).languageCode == 'ru' ? ru : en;
}
