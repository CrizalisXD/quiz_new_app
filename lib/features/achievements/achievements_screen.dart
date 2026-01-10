import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/current_user.dart';
import 'achievements_store.dart';
import '../../utils/sound_manager.dart';
import '../progress/progress_providers.dart';

enum AchievementState { locked, claimable, claimed }

class AchievementRewardLine {
  final String label; // "+200 coins" / "+50 gems"
  const AchievementRewardLine(this.label);
}

class AchievementDef {
  final String id;
  final String group;
  final IconData icon;
  final String titleRu;
  final String titleEn;
  final String descRu;
  final String descEn;

  // ✅ новый ключ прогресса
  final String eventKey;
  final int target;

  final List<AchievementRewardLine> rewards;

  const AchievementDef({
    required this.id,
    required this.group,
    required this.icon,
    required this.titleRu,
    required this.titleEn,
    required this.descRu,
    required this.descEn,
    required this.eventKey,
    required this.target,
    required this.rewards,
  });
}

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  static const route = '/achievements';

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  final Set<String> _claimed = <String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserProvider);
      final claimed = await AchievementsStore.getClaimed(userId);
      if (!mounted) return;
      setState(() {
        _claimed
          ..clear()
          ..addAll(claimed);
      });
    });
  }

  // ✅ 25 достижений по вашему списку (трофей пока как текст)
  static const _defs = <AchievementDef>[
    // A. База
    AchievementDef(
      id: 'a_answer_5',
      group: 'База',
      icon: Icons.emoji_events_outlined,
      titleRu: 'Первые шаги',
      titleEn: 'First steps',
      descRu: 'Ответьте на 5 вопросов.',
      descEn: 'Answer 5 questions.',
      eventKey: 'questions_answered',
      target: 5,
      rewards: [AchievementRewardLine('+100 gold')],
    ),
    AchievementDef(
      id: 'a_answer_25',
      group: 'База',
      icon: Icons.emoji_events_outlined,
      titleRu: 'Разогрев',
      titleEn: 'Warm-up',
      descRu: 'Ответьте на 25 вопросов.',
      descEn: 'Answer 25 questions.',
      eventKey: 'questions_answered',
      target: 25,
      rewards: [AchievementRewardLine('+250 gold')],
    ),
    AchievementDef(
      id: 'a_answer_100',
      group: 'База',
      icon: Icons.emoji_events_outlined,
      titleRu: 'В ритме',
      titleEn: 'In rhythm',
      descRu: 'Ответьте на 100 вопросов.',
      descEn: 'Answer 100 questions.',
      eventKey: 'questions_answered',
      target: 100,
      rewards: [AchievementRewardLine('+800 gold')],
    ),
    AchievementDef(
      id: 'a_levels_1',
      group: 'База',
      icon: Icons.flag_outlined,
      titleRu: 'Первый уровень',
      titleEn: 'First level',
      descRu: 'Пройдите 1 уровень.',
      descEn: 'Complete 1 level.',
      eventKey: 'levels_completed',
      target: 1,
      rewards: [AchievementRewardLine('+150 gold')],
    ),
    AchievementDef(
      id: 'a_levels_3',
      group: 'База',
      icon: Icons.flag_outlined,
      titleRu: 'Три подряд',
      titleEn: 'Three in a row',
      descRu: 'Пройдите 3 уровня.',
      descEn: 'Complete 3 levels.',
      eventKey: 'levels_completed',
      target: 3,
      rewards: [AchievementRewardLine('+350 gold')],
    ),
    AchievementDef(
      id: 'a_levels_10',
      group: 'База',
      icon: Icons.flag_outlined,
      titleRu: 'Десятка',
      titleEn: 'Ten',
      descRu: 'Пройдите 10 уровней.',
      descEn: 'Complete 10 levels.',
      eventKey: 'levels_completed',
      target: 10,
      rewards: [AchievementRewardLine('+1200 gold')],
    ),

    // B. Мастерство
    AchievementDef(
      id: 'a_perfect_1',
      group: 'Мастерство',
      icon: Icons.workspace_premium_outlined,
      titleRu: 'Идеальный уровень I',
      titleEn: 'Perfect level I',
      descRu: 'Пройдите уровень без ошибок (10/10).',
      descEn: 'Complete a level with 0 mistakes.',
      eventKey: 'perfect_levels',
      target: 1,
      rewards: [AchievementRewardLine('+200 gold')],
    ),
    AchievementDef(
      id: 'a_perfect_5',
      group: 'Мастерство',
      icon: Icons.workspace_premium_outlined,
      titleRu: 'Идеальный уровень II',
      titleEn: 'Perfect level II',
      descRu: 'Пройдите 5 уровней без ошибок.',
      descEn: 'Complete 5 perfect levels.',
      eventKey: 'perfect_levels',
      target: 5,
      rewards: [AchievementRewardLine('+700 gold')],
    ),
    AchievementDef(
      id: 'a_perfect_20',
      group: 'Мастерство',
      icon: Icons.workspace_premium_outlined,
      titleRu: 'Идеальный уровень III',
      titleEn: 'Perfect level III',
      descRu: 'Пройдите 20 уровней без ошибок.',
      descEn: 'Complete 20 perfect levels.',
      eventKey: 'perfect_levels',
      target: 20,
      rewards: [AchievementRewardLine('+2500 gold'), AchievementRewardLine('+50 diamond')],
    ),
    AchievementDef(
      id: 'a_perfect_streak_3',
      group: 'Мастерство',
      icon: Icons.local_fire_department_outlined,
      titleRu: 'Без ошибок серия I',
      titleEn: 'No-mistake streak I',
      descRu: '3 уровня подряд 10/10.',
      descEn: '3 perfect levels in a row.',
      eventKey: 'perfect_streak_best',
      target: 3,
      rewards: [AchievementRewardLine('+500 gold')],
    ),
    AchievementDef(
      id: 'a_perfect_streak_7',
      group: 'Мастерство',
      icon: Icons.local_fire_department_outlined,
      titleRu: 'Без ошибок серия II',
      titleEn: 'No-mistake streak II',
      descRu: '7 уровней подряд 10/10.',
      descEn: '7 perfect levels in a row.',
      eventKey: 'perfect_streak_best',
      target: 7,
      rewards: [AchievementRewardLine('+1500 gold'), AchievementRewardLine('+30 diamond')],
    ),

    // C. Контент
    AchievementDef(
      id: 'a_countries_open_1',
      group: 'Контент',
      icon: Icons.public_outlined,
      titleRu: 'Путешественник I',
      titleEn: 'Traveller I',
      descRu: 'Откройте 1 страну.',
      descEn: 'Open 1 country.',
      eventKey: 'countries_opened',
      target: 1,
      rewards: [AchievementRewardLine('+200 gold')],
    ),
    AchievementDef(
      id: 'a_countries_open_3',
      group: 'Контент',
      icon: Icons.public_outlined,
      titleRu: 'Путешественник II',
      titleEn: 'Traveller II',
      descRu: 'Откройте 3 страны.',
      descEn: 'Open 3 countries.',
      eventKey: 'countries_opened',
      target: 3,
      rewards: [AchievementRewardLine('+600 gold')],
    ),
    AchievementDef(
      id: 'a_countries_open_7',
      group: 'Контент',
      icon: Icons.public_outlined,
      titleRu: 'Путешественник III',
      titleEn: 'Traveller III',
      descRu: 'Откройте 7 стран.',
      descEn: 'Open 7 countries.',
      eventKey: 'countries_opened',
      target: 7,
      rewards: [AchievementRewardLine('+1800 gold')],
    ),
    AchievementDef(
      id: 'a_categories_complete_1',
      group: 'Контент',
      icon: Icons.grid_view_rounded,
      titleRu: 'Исследователь I',
      titleEn: 'Explorer I',
      descRu: 'Завершите 1 категорию (10 уровней).',
      descEn: 'Complete 1 category (10 levels).',
      eventKey: 'categories_completed',
      target: 1,
      rewards: [AchievementRewardLine('+1000 gold')],
    ),
    AchievementDef(
      id: 'a_categories_complete_3',
      group: 'Контент',
      icon: Icons.grid_view_rounded,
      titleRu: 'Исследователь II',
      titleEn: 'Explorer II',
      descRu: 'Завершите 3 категории.',
      descEn: 'Complete 3 categories.',
      eventKey: 'categories_completed',
      target: 3,
      rewards: [AchievementRewardLine('+2500 gold'), AchievementRewardLine('+40 diamond')],
    ),
    AchievementDef(
      id: 'a_countries_complete_1',
      group: 'Контент',
      icon: Icons.collections_bookmark_outlined,
      titleRu: 'Коллекционер I',
      titleEn: 'Collector I',
      descRu: 'Соберите 10 фрагментов (закройте страну).',
      descEn: 'Collect 10 fragments (complete a country).',
      eventKey: 'countries_completed',
      target: 1,
      rewards: [AchievementRewardLine('+1200 gold'), AchievementRewardLine('+трофей')],
    ),
    AchievementDef(
      id: 'a_countries_complete_3',
      group: 'Контент',
      icon: Icons.collections_bookmark_outlined,
      titleRu: 'Коллекционер II',
      titleEn: 'Collector II',
      descRu: 'Закройте 3 страны.',
      descEn: 'Complete 3 countries.',
      eventKey: 'countries_completed',
      target: 3,
      rewards: [AchievementRewardLine('+4000 gold'), AchievementRewardLine('+80 diamond')],
    ),

    // D. Серии дней (нужен трекинг логина/дней — пока eventKey заглушка)
    AchievementDef(
      id: 'a_days_streak_2',
      group: 'Серии',
      icon: Icons.calendar_month_outlined,
      titleRu: 'Серия дней I',
      titleEn: 'Daily streak I',
      descRu: 'Играйте 2 дня подряд.',
      descEn: 'Play 2 days in a row.',
      eventKey: 'days_streak_best',
      target: 2,
      rewards: [AchievementRewardLine('+200 gold')],
    ),
    AchievementDef(
      id: 'a_days_streak_7',
      group: 'Серии',
      icon: Icons.calendar_month_outlined,
      titleRu: 'Серия дней II',
      titleEn: 'Daily streak II',
      descRu: 'Играйте 7 дней подряд.',
      descEn: 'Play 7 days in a row.',
      eventKey: 'days_streak_best',
      target: 7,
      rewards: [AchievementRewardLine('+1200 gold'), AchievementRewardLine('+30 diamond')],
    ),
    AchievementDef(
      id: 'a_days_streak_30',
      group: 'Серии',
      icon: Icons.calendar_month_outlined,
      titleRu: 'Серия дней III',
      titleEn: 'Daily streak III',
      descRu: 'Играйте 30 дней подряд.',
      descEn: 'Play 30 days in a row.',
      eventKey: 'days_streak_best',
      target: 30,
      rewards: [AchievementRewardLine('+9000 gold'), AchievementRewardLine('+200 diamond')],
    ),

    // E. Магазин (eventKey заглушки до реализации магазина)
    AchievementDef(
      id: 'a_shop_first',
      group: 'Магазин',
      icon: Icons.storefront_outlined,
      titleRu: 'Первая покупка',
      titleEn: 'First purchase',
      descRu: 'Купите любой товар за coins.',
      descEn: 'Buy any item with coins.',
      eventKey: 'shop_purchases',
      target: 1,
      rewards: [AchievementRewardLine('+200 gold')],
    ),
    AchievementDef(
      id: 'a_shop_5',
      group: 'Магазин',
      icon: Icons.storefront_outlined,
      titleRu: 'Покупатель I',
      titleEn: 'Buyer I',
      descRu: 'Сделайте 5 покупок за coins.',
      descEn: 'Make 5 purchases with coins.',
      eventKey: 'shop_purchases',
      target: 5,
      rewards: [AchievementRewardLine('+800 gold')],
    ),
    AchievementDef(
      id: 'a_daily_deal_1',
      group: 'Магазин',
      icon: Icons.local_offer_outlined,
      titleRu: 'Сделка дня I',
      titleEn: 'Daily deal I',
      descRu: 'Купите предложение дня 1 раз.',
      descEn: 'Buy daily deal once.',
      eventKey: 'daily_deals_bought',
      target: 1,
      rewards: [AchievementRewardLine('+20 diamond')],
    ),
    AchievementDef(
      id: 'a_daily_deal_7',
      group: 'Магазин',
      icon: Icons.local_offer_outlined,
      titleRu: 'Сделка дня II',
      titleEn: 'Daily deal II',
      descRu: 'Купите предложение дня 7 раз.',
      descEn: 'Buy daily deal 7 times.',
      eventKey: 'daily_deals_bought',
      target: 7,
      rewards: [AchievementRewardLine('+120 diamond')],
    ),
  ];

  String _t(BuildContext context, {required String ru, required String en}) =>
      Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

  String _groupTitle(BuildContext context, String group) => _t(context, ru: group, en: group);

  (int current, AchievementState state) _calcState({
    required AchievementDef def,
    required Map<String, int> counters,
  }) {
    final current = counters[def.eventKey] ?? 0;
    if (_claimed.contains(def.id)) return (current, AchievementState.claimed);
    if (current >= def.target) return (current, AchievementState.claimable);
    return (current, AchievementState.locked);
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            SoundManager.playSfx('assets/sound/click.mp3');
            Navigator.of(context).maybePop();
          },
        ),
        title: Text(_t(context, ru: 'Достижения', en: 'Achievements')),
      ),
      body: FutureBuilder<Map<String, int>>(
        future: () async {
          // пытаемся читать универсальные счётчики, если в AchievementsStore это реализовано
          Future<int> c(String key) async {
            try {
              final v = await AchievementsStore.getCounter(userId, key);
              return v;
            } catch (_) {
              // fallback на старые методы (пока переходный период)
              if (key == 'questions_answered') return AchievementsStore.getAnsweredCount(userId);
              if (key == 'perfect_levels') return AchievementsStore.getPerfectLevelsCount(userId);
              return 0;
            }
          }

          final keys = _defs.map((d) => d.eventKey).toSet().toList();
          final vals = await Future.wait(keys.map(c));
          return {for (var i = 0; i < keys.length; i++) keys[i]: vals[i]};
        }(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final counters = snapshot.data!;

          final groups = <String, List<AchievementDef>>{};
          for (final d in _defs) {
            groups.putIfAbsent(d.group, () => []).add(d);
          }
          final groupKeys = groups.keys.toList();

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Text(
                    _t(
                      context,
                      ru: 'Забирайте награды за достижения. Награды выдаются только по кнопке «Забрать».',
                      en: 'Claim rewards for achievements. Rewards are granted only when you press “Claim”.',
                    ),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 14),
                  for (final g in groupKeys) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                      child: Text(
                        _groupTitle(context, g),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    for (final def in groups[g]!) ...[
                      Builder(
                        builder: (ctx) {
                          final (current, state) = _calcState(def: def, counters: counters);
                          return _AchievementCard(
                            def: def,
                            current: current,
                            state: state,
                            onClaim: state == AchievementState.claimable
                                ? () async {
                                    SoundManager.playSfx('assets/sound/click.mp3');

                                    await AchievementsStore.claimAchievement(
                                      userId: userId,
                                      achievementId: def.id,
                                      rewards: def.rewards.map((e) => e.label).toList(),
                                    );

                                    // ✅ обновляем валюты в UI
                                    ref.invalidate(coinsProvider);
                                    ref.invalidate(diamondsProvider);

                                    if (!mounted) return;
                                    setState(() => _claimed.add(def.id));

                                    // ❌ убрать нижний попап
                                    // final gold = await AchievementsStore.getGold(userId);
                                    // final diamond = await AchievementsStore.getDiamond(userId);
                                    // if (!mounted) return;
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   SnackBar(
                                    //     behavior: SnackBarBehavior.floating,
                                    //     content: Text(
                                    //       _t(
                                    //         context,
                                    //         ru: 'Награда получена: ${def.rewards.map((e) => e.label).join(', ')} • Баланс: $gold gold, $diamond diamond',
                                    //         en: 'Reward claimed: ${def.rewards.map((e) => e.label).join(', ')} • Balance: $gold gold, $diamond diamond',
                                    //       ),
                                    //     ),
                                    //   ),
                                    // );
                                  }
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementDef def;
  final int current;
  final AchievementState state;
  final VoidCallback? onClaim;

  const _AchievementCard({
    required this.def,
    required this.current,
    required this.state,
    required this.onClaim,
  });

  String _t(BuildContext context, {required String ru, required String en}) =>
      Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

  @override
  Widget build(BuildContext context) {
    final title = _t(context, ru: def.titleRu, en: def.titleEn);
    final desc = _t(context, ru: def.descRu, en: def.descEn);

    final target = def.target;
    final clamped = current.clamp(0, target);
    final progress = target == 0 ? 0.0 : (clamped / target).clamp(0.0, 1.0);

    final isClaimable = state == AchievementState.claimable;
    final isClaimed = state == AchievementState.claimed;

    final bg = Colors.white;
    final border = isClaimable ? Colors.deepPurpleAccent.withOpacity(0.55) : Colors.black12;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1),
        boxShadow: [
          BoxShadow(
            color: isClaimable ? Colors.deepPurpleAccent.withOpacity(0.16) : Colors.black.withOpacity(0.06),
            blurRadius: isClaimable ? 24 : 14,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isClaimable ? Colors.deepPurpleAccent : Colors.black12).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(def.icon, color: isClaimable ? Colors.deepPurple : Colors.black54),
            ),
            const SizedBox(width: 12),

            // main
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(desc, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        '$clamped/$target',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 10,
                            backgroundColor: Colors.black12,
                            valueColor: AlwaysStoppedAnimation(
                              isClaimable ? Colors.deepPurpleAccent : Colors.deepPurple.withOpacity(0.65),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: def.rewards
                        .map((r) => _RewardChip(label: r.label, highlighted: isClaimable))
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // right state
            if (isClaimed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _t(context, ru: 'Получено', en: 'Claimed'),
                  style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.green),
                ),
              )
            else if (isClaimable)
              GestureDetector(
                onTap: onClaim,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurpleAccent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _t(context, ru: 'Забрать награду', en: 'Claim reward'),
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _RewardChip({
    required this.label,
    required this.highlighted,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = highlighted ? Colors.deepPurpleAccent : Colors.black54;
    final bgColor = highlighted ? Colors.deepPurpleAccent.withOpacity(0.12) : Colors.black12;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}