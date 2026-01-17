import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ADD: эти импорты нужны, потому что ниже используются CategoryCard/coinsProvider/diamondsProvider
import 'widgets/category_card.dart';
import '../progress/progress_providers.dart';

import '../settings/settings_screen.dart';
import '../achievements/achievements_screen.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';
import '../auth/current_user.dart';
import '../achievements/achievements_store.dart';

import '../../audio/audio_keys.dart'; // ADD
import '../../audio/audio_ref_ext.dart'; // ADD

BgmKey _bgmForCountryKey(String countryKey) {
  switch (countryKey) {
    case 'japan':
      return BgmKey.japan;
    case 'egypt':
      return BgmKey.egypt;
    case 'france':
      return BgmKey.france;
    case 'brazil':
      return BgmKey.brazil;
    case 'norway':
      return BgmKey.norway;
    default:
      return BgmKey.home;
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // FIX: был removeObserver без addObserver

    // BGM главного меню (через единый AudioManager)
    // ignore: discarded_futures
    ref.playBgm(BgmKey.home);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _categoryImageForCountry(String countryKey) {
    // В папке assets/images/ui/{country}_cat/ теперь лежат картинки ПОДКАТЕГОРИЙ,
    // поэтому на Home не выбираем "первую попавшуюся" из этой папки.
    return 'assets/images/categories/$countryKey.png';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // При заходе/возврате на Home принудительно подтягиваем актуальные валюты.
    ref.invalidate(coinsProvider);
    ref.invalidate(diamondsProvider);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Возврат в приложение — обновим валюты (чтобы “в реальном времени” догоняло изменения).
      ref.invalidate(coinsProvider);
      ref.invalidate(diamondsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final countryKeys = const ['japan', 'egypt', 'france', 'brazil', 'norway'];

    final coinsAsync = ref.watch(coinsProvider);
    final diamondsAsync = ref.watch(diamondsProvider);
    final userId = ref.watch(currentUserProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Единственный фон для Home экрана
          Image.asset(
            'assets/images/bg/home/home.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          coinsAsync.when(
                            data: (v) => const SizedBox.shrink(), // значение ниже, через _CurrencyAssetBadge
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                          coinsAsync.when(
                            data: (v) => _CurrencyAssetBadge(
                              colors: const [Color(0xFFFFE08A), Color(0xFFFFFFFF)],
                              assetPath: 'assets/images/ui/currency/gold.png',
                              label: v.toString(),
                              semanticsLabel: 'Gold',
                            ),
                            loading: () => const _CurrencyAssetBadge(
                              colors: [Color(0xFFFFE08A), Color(0xFFFFFFFF)],
                              assetPath: 'assets/images/ui/currency/gold.png',
                              label: '...',
                              semanticsLabel: 'Gold',
                            ),
                            error: (_, __) => const _CurrencyAssetBadge(
                              colors: [Color(0xFFFFE08A), Color(0xFFFFFFFF)],
                              assetPath: 'assets/images/ui/currency/gold.png',
                              label: 'ERR',
                              semanticsLabel: 'Gold',
                            ),
                          ),
                          const SizedBox(width: 8),
                          diamondsAsync.when(
                            data: (v) => _CurrencyAssetBadge(
                              colors: const [Color(0xFFFFD1EE), Color(0xFFFFFFFF)],
                              assetPath: 'assets/images/ui/currency/diamond.png',
                              label: v.toString(),
                              semanticsLabel: 'Diamond',
                            ),
                            loading: () => const _CurrencyAssetBadge(
                              colors: [Color(0xFFFFD1EE), Color(0xFFFFFFFF)],
                              assetPath: 'assets/images/ui/currency/diamond.png',
                              label: '...',
                              semanticsLabel: 'Diamond',
                            ),
                            error: (_, __) => const _CurrencyAssetBadge(
                              colors: [Color(0xFFFFD1EE), Color(0xFFFFFFFF)],
                              assetPath: 'assets/images/ui/currency/diamond.png',
                              label: 'ERR',
                              semanticsLabel: 'Diamond',
                            ),
                          ),

                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              // ignore: discarded_futures
                              ref.playSfx(SfxKey.click);
                              Navigator.pushNamed(context, SettingsScreen.route);
                            },
                            icon: const Icon(Icons.settings, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: countryKeys.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (c, i) {
                          final key = countryKeys[i];
                          final title = _countryNameLocalized(context, key);
                          final imageAsset = _categoryImageForCountry(key);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4, bottom: 8),
                                child: Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              CategoryCard(
                                imageAsset: imageAsset,
                                onTap: () async {
                                  // ignore: discarded_futures
                                  ref.playSfx(SfxKey.click);
                                  // ignore: discarded_futures
                                  ref.playBgm(_bgmForCountryKey(key));

                                  await AchievementsStore.markCountryOpenedOnce(userId, key);

                                  if (!context.mounted) return;
                                  Navigator.pushNamed(
                                    context,
                                    '/category',
                                    arguments: {
                                      'countryKey': key,
                                      'title': title,
                                      'imageAsset': imageAsset,
                                    },
                                  ).then((_) {
                                    // ignore: discarded_futures
                                    ref.playBgm(BgmKey.home);
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container
          (
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _BottomItem(
                icon: Icons.emoji_events_outlined,
                label: AppLocalizations.of(context).home_achievements,
                onTap: () {
                  // ignore: discarded_futures
                  ref.playSfx(SfxKey.click);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AchievementsScreen()),
                  );
                },
              ),
              _BottomItem(
                icon: Icons.person_outline,
                label: AppLocalizations.of(context).home_profile,
                onTap: () {
                  // ignore: discarded_futures
                  ref.playSfx(SfxKey.click);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              _BottomItem(
                icon: Icons.storefront_outlined,
                label: AppLocalizations.of(context).home_shop,
                onTap: () {
                  // ignore: discarded_futures
                  ref.playSfx(SfxKey.click);
                  Navigator.pushNamed(context, '/shop');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Кнопка «ледяная/прозрачная»
// Removed frost buttons - replaced by CurvyBottomBar

class _CurrencyBadge extends StatelessWidget {
  final List<Color> colors;
  final IconData icon;
  final String label;
  final String? semanticsLabel;
  const _CurrencyBadge({required this.colors, required this.icon, required this.label, this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 34, // ✅ фикс высоты, чтобы не "плясало"
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.black87),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()], // ✅ стабильная ширина цифр
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyAssetBadge extends StatelessWidget {
  final List<Color> colors;
  final String assetPath;
  final String label;
  final String? semanticsLabel;

  const _CurrencyAssetBadge({
    required this.colors,
    required this.assetPath,
    required this.label,
    this.semanticsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        height: 34, // ✅ фикс высоты
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                assetPath,
                width: 18,
                height: 18,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.monetization_on_outlined, size: 18, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BottomItem({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final color = Colors.white;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

String _countryNameLocalized(BuildContext context, String key) {
  final lang = Localizations.localeOf(context).languageCode;
  switch (key) {
    case 'japan':
      return lang == 'ru' ? 'Япония' : 'Japan';
    case 'egypt':
      return lang == 'ru' ? 'Египет' : 'Egypt';
    case 'france':
      return lang == 'ru' ? 'Франция' : 'France';
    case 'brazil':
      return lang == 'ru' ? 'Бразилия' : 'Brazil';
    case 'norway':
      return lang == 'ru' ? 'Норвегия' : 'Norway';
    default:
      return key;
  }
}

