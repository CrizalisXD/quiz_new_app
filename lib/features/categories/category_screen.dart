import 'package:flutter/material.dart';
import '../home/widgets/category_card.dart';
import '../../data/categories_config.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/ui_metrics.dart';
import '../../utils/sound_manager.dart';
import '../levels/levels_screen.dart';

class CategoryScreen extends StatelessWidget { // CHANGED: было ConsumerWidget
  const CategoryScreen({super.key});

  String _subcatAlias(String subcatKey) {
    switch (subcatKey) {
      case 'food':
        return 'cuisine';
      case 'history_persons':
        return 'history_personalities';
      default:
        return subcatKey;
    }
  }

  String _subcatImageForCountry(String countryKey, String subcatKey) { // CHANGED: убрали fallback
    final alias = _subcatAlias(subcatKey);
    return 'assets/images/ui/$countryKey/${countryKey}_cat/${countryKey}_$alias.png';
  }

  @override
  Widget build(BuildContext context) { // CHANGED: убрали WidgetRef ref
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final countryKey = args?['countryKey'] as String? ?? 'unknown';
    final title = args?['title'] as String? ?? countryKey;
    final imageAsset = args?['imageAsset'] as String? ?? 'assets/images/categories/$countryKey.png';

    PreferredSizeWidget _buildAppBar() {
      return AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: BackButton(
          color: Colors.white,
          onPressed: () {
            SoundManager.playSfx('assets/sound/click.mp3');
            Navigator.of(context).maybePop();
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            // Мини-кнопка страны вместо текста
            SizedBox(
              height: 40,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imageAsset,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                      ),
                      Container(
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.0),  // CHANGED
                              Colors.black.withValues(alpha: 0.45), // CHANGED
                            ],
                          ),
                        ),
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Музыку НЕ переключаем здесь: она должна продолжать играть между экранами без рестарта/задержки.
    // (Музыка страны включается на Home при выборе страны.)

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/bg/category/category_$countryKey.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
          ListView(
            padding: EdgeInsets.fromLTRB(16, contentTopPadding(context), 16, 16),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    children: [
                      ..._buildSubcats(countryKey).map(
                        (cfg) => Padding(
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
                                  // ✅ убрать фикс высоты — размер как на Home (задаётся CategoryCard)
                                  CategoryCard(
                                    imageAsset: _subcatImageForCountry( // CHANGED
                                      countryKey,
                                      cfg.key,
                                    ),
                                    onTap: () {
                                      SoundManager.playSfx('assets/sound/click.mp3');
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const LevelsScreen(),
                                          settings: RouteSettings(
                                            arguments: {
                                              'countryKey': countryKey,
                                              'subcategoryKey': cfg.key,
                                              'subcategoryLabel': _localizedSubcatLabel(context, cfg),
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  _SubcategoryStarsBadge(countryKey: countryKey, subKey: cfg.key),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.transparent,
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

class _SubcategoryStarsBadge extends StatelessWidget { // CHANGED: было ConsumerWidget
  final String countryKey;
  final String subKey;
  const _SubcategoryStarsBadge({required this.countryKey, required this.subKey});

  @override
  Widget build(BuildContext context) { // CHANGED: убрали WidgetRef
    // FIX: бейдж пока отключён, чтобы не тянуть Riverpod/поля профиля и не ломать сборку
    return const SizedBox.shrink();
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

