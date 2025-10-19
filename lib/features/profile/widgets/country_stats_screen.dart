import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/features/auth/current_user.dart';
import 'package:quiz_new_app/features/progress/progress_store.dart';
import 'package:quiz_new_app/features/rewards/rewards_store.dart';
import 'package:quiz_new_app/utils/assets_index.dart';
import 'package:quiz_new_app/data/categories_config.dart';

class CountryStatsScreen extends ConsumerWidget {
  final String countryKey;
  const CountryStatsScreen({super.key, required this.countryKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Статистика: ${_countryName(countryKey)}')),
      body: FutureBuilder<_CountryStats>(
        future: _loadCountryStats(userId, countryKey),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = snap.data!;
          final completion = s.totalLevels == 0 ? 0.0 : s.completedLevels / s.totalLevels;
          final starsPct = s.maxStars == 0 ? 0.0 : s.totalStars / s.maxStars;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionCard(
                  title: 'Общий прогресс',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LabeledBar(label: 'Уровни: ${s.completedLevels}/${s.totalLevels}', value: completion),
                      const SizedBox(height: 12),
                      _LabeledBar(label: 'Звёзды: ${s.totalStars}/${s.maxStars}', value: starsPct, color: Colors.amber),
                      const SizedBox(height: 12),
                      Text('Идеальные уровни (3★): ${s.perfectLevels}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Коллекция постеров',
                  child: _LabeledBar(
                    label: 'Получено: ${s.postersOwned}/${s.postersTotal}',
                    value: s.postersTotal == 0 ? 0 : (s.postersOwned / s.postersTotal).clamp(0.0, 1.0),
                    color: Colors.purpleAccent,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Распределение звёзд',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _StarPill(count: s.starBuckets[3], label: '3★'),
                      _StarPill(count: s.starBuckets[2], label: '2★'),
                      _StarPill(count: s.starBuckets[1], label: '1★'),
                      _StarPill(count: s.starBuckets[0], label: '0★'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'По подкатегориям',
                  child: Column(
                    children: [
                      for (final sc in s.subcats) ...[
                        _SubcatRow(sc: sc),
                        const Divider(height: 16),
                      ]
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SubcatStat {
  final String key;
  final String label;
  final int totalLevels;
  final int completedLevels;
  final int perfectLevels;
  final int starsTotal;
  _SubcatStat({
    required this.key,
    required this.label,
    required this.totalLevels,
    required this.completedLevels,
    required this.perfectLevels,
    required this.starsTotal,
  });
}

class _CountryStats {
  final int totalLevels;
  final int completedLevels;
  final int totalStars;
  final int maxStars;
  final int perfectLevels;
  final List<int> starBuckets; // index: stars count -> levels
  final int postersOwned;
  final int postersTotal;
  final List<_SubcatStat> subcats;
  _CountryStats({
    required this.totalLevels,
    required this.completedLevels,
    required this.totalStars,
    required this.maxStars,
    required this.perfectLevels,
    required this.starBuckets,
    required this.postersOwned,
    required this.postersTotal,
    required this.subcats,
  });
}

Future<_CountryStats> _loadCountryStats(String userId, String countryKey) async {
  await AssetsIndex.ensureLoaded();
  final subs = countrySubcategories[countryKey] ?? const <SubcategoryConfig>[];
  int totalLevels = 0;
  int completedLevels = 0;
  int totalStars = 0;
  int perfectLevels = 0;
  final buckets = [0, 0, 0, 0];
  final subStats = <_SubcatStat>[];

  for (final sc in subs) {
    final limit = _expectedForSub(sc.key);
    totalLevels += limit;
    final packKey = '${countryKey}_${sc.key}';
    final (starsList, unlocked) = await ProgressStore.getLevelsProgress(userId, packKey, limit);
    int subCompleted = 0;
    int subPerfect = 0;
    int subStarsSum = 0;
    for (var i = 0; i < limit; i++) {
      final st = starsList[i];
      buckets[st] += 1;
      subStarsSum += st;
      if (st > 0 || unlocked[i]) {
        subCompleted += 1; // уровень виден/доступен — считаем как достигнутый чекпоинт
      }
      if (st == 3) subPerfect += 1;
    }
    completedLevels += subCompleted;
    totalStars += subStarsSum;
    perfectLevels += subPerfect;
    subStats.add(_SubcatStat(
      key: sc.key,
      label: sc.label,
      totalLevels: limit,
      completedLevels: subCompleted,
      perfectLevels: subPerfect,
      starsTotal: subStarsSum,
    ));
  }

  // Коллекция постеров по стране
  final postersTotal = AssetsIndex.countByPrefix('assets/images/reward/$countryKey/');
  final rewards = await RewardsStore.getRewards(userId);
  final postersOwned = rewards.where((p) => _countryFromRewardPath(p) == countryKey).length;

  return _CountryStats(
    totalLevels: totalLevels,
    completedLevels: completedLevels,
    totalStars: totalStars,
    maxStars: totalLevels * 3,
    perfectLevels: perfectLevels,
    starBuckets: buckets,
    postersOwned: postersOwned,
    postersTotal: postersTotal,
    subcats: subStats,
  );
}

int _expectedForSub(String key) => (key == 'classic' || key == 'hard') ? 10 : 5;

String _countryName(String key) {
  switch (key) {
    case 'japan':
      return 'Япония';
    case 'france':
      return 'Франция';
    case 'brazil':
      return 'Бразилия';
    case 'norway':
      return 'Норвегия';
    case 'egypt':
      return 'Египет';
    default:
      return key;
  }
}

String _countryFromRewardPath(String p) {
  final norm = p.replaceAll('\\', '/');
  final parts = norm.split('/');
  final idx = parts.indexOf('reward');
  if (idx != -1 && idx + 1 < parts.length && parts[idx + 1].isNotEmpty) {
    return parts[idx + 1];
  }
  final file = parts.isNotEmpty ? parts.last : '';
  final mFull = RegExp(r'^([A-Za-z]+)_[A-Za-z]+_\d+\.png').firstMatch(file);
  if (mFull != null) return mFull.group(1)!;
  final m = RegExp(r'^([A-Za-z]+)[_/]').firstMatch('$file/');
  return m != null ? m.group(1)! : 'other';
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.035),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LabeledBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _LabeledBar({required this.label, required this.value, this.color = Colors.green});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: Colors.black12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StarPill extends StatelessWidget {
  final int count;
  final String label;
  const _StarPill({required this.count, required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('$count'),
        ],
      ),
    );
  }
}

class _SubcatRow extends StatelessWidget {
  final _SubcatStat sc;
  const _SubcatRow({required this.sc});
  @override
  Widget build(BuildContext context) {
    final pct = sc.totalLevels == 0 ? 0.0 : sc.completedLevels / sc.totalLevels;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sc.label, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Text('3★: ${sc.perfectLevels} — уровни: ${sc.completedLevels}/${sc.totalLevels}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ],
          ),
        ),
      ],
    );
  }
}
