import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/profile/profile_providers.dart';
import '../home/widgets/category_card.dart';
import '../../data/categories_config.dart';
import '../../l10n/app_localizations.dart';
// Background removed per request.
import '../../utils/ui_metrics.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final countryKey = args?['countryKey'] as String? ?? 'unknown';
    final title = args?['title'] as String? ?? countryKey;
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bg/category/category_$countryKey.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
            ),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      error: (e, _) => Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(title),
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bg/category/category_$countryKey.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
            ),
            Center(child: Text('${AppLocalizations.of(context).error_prefix}$e')),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      data: (profile) {
  // Прогресс визуально не показываем на этом экране
  final topPad = contentTopPadding(context);
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/bg/category/category_$countryKey.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
              ),
              ListView(
                padding: EdgeInsets.fromLTRB(16, topPad, 16, 16),
                children: [
                  ..._buildSubcats(countryKey).map((cfg) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left:4,bottom:8),
                          child: Text(_localizedSubcatLabel(context, cfg), style: const TextStyle(fontSize:16,fontWeight: FontWeight.w800,color: Colors.black87)),
                        ),
                        Stack(
                          children: [
                            CategoryCard(
                              imageAsset: cfg.imageAsset,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/levels',
                                  arguments: {
                                    'countryKey': countryKey,
                                    'subcategoryKey': cfg.key,
                                    'subcategoryLabel': _localizedSubcatLabel(context, cfg),
                                  },
                                );
                              },
                            ),
                            _SubcategoryStarsBadge(countryKey: countryKey, subKey: cfg.key),
                          ],
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ],
          ),
          backgroundColor: Colors.transparent,
        );
      },
    );
  }
}

// Удалены заголовочное изображение и бейджи прогресса по требованию UI

List<SubcategoryConfig> _buildSubcats(String countryKey) {
  final list = countrySubcategories[countryKey] ?? countrySubcategories['japan']!; // fallback
  // Ensure first two positions are classic + professional even if order changed externally.
  List<SubcategoryConfig> classic = list.where((e) => e.key == 'classic').toList();
  List<SubcategoryConfig> hard = list.where((e) => e.key == 'hard').toList();
  final others = list.where((e) => e.key != 'classic' && e.key != 'hard').toList();
  return [...classic, ...hard, ...others];
}

class _SubcategoryStarsBadge extends ConsumerWidget {
  final String countryKey;
  final String subKey;
  const _SubcategoryStarsBadge({required this.countryKey, required this.subKey});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(profileProvider);
    return Positioned(
      right: 12,
      top: 12,
      child: st.when(
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
        data: (p) {
          final sc = p.subcategories['$countryKey:$subKey'];
            if (sc == null) return const SizedBox.shrink();
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: .55),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text('${sc.totalStars}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.flag_outlined, color: Colors.white70, size: 14),
                const SizedBox(width: 2),
                Text('${sc.levelsPassed}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }
}

String _localizedSubcatLabel(BuildContext context, SubcategoryConfig cfg) {
  final l = AppLocalizations.of(context);
  switch (cfg.key) {
    case 'classic':
      return l.cat_classic;
    case 'hard':
      return l.cat_hard;
    case 'food':
      return l.cat_food_drinks;
    case 'games':
      return l.cat_games_entertainment;
    case 'cinema':
      return l.cat_cinema_animation;
    case 'architecture':
      return l.cat_architecture;
    case 'legends':
      return l.cat_legends_myths;
    case 'history_persons':
      return l.cat_history_personalities;
    case 'transport':
      return l.cat_transport_tech;
    case 'unexpected':
      return l.cat_unexpected;
    default:
      return cfg.label;
  }
}

