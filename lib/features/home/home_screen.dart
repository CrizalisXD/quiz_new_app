import 'dart:io';
import 'dart:ui' show FontFeature;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart' show rootBundle; // ADD

import 'widgets/category_card.dart';
import '../progress/progress_providers.dart';
import '../profile/profile_providers.dart';
import '../profile/local_profile.dart'; // ADD: нужен для AsyncValue<LocalProfile>

import '../settings/settings_screen.dart';
import '../achievements/achievements_screen.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';
import '../auth/current_user.dart';
import '../achievements/achievements_store.dart';

import '../../audio/audio_keys.dart';
import '../../audio/audio_ref_ext.dart';

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

const _kAvatarDir = 'assets/images/profile/avatar';
const _kDefaultAvatarAsset = '$_kAvatarDir/avatar_classic_girl.png';

ImageProvider _resolveAvatarProvider(String avatarPathOrAsset) {
  final v = avatarPathOrAsset.trim();

  if (v.isEmpty) return const AssetImage(_kDefaultAvatarAsset);

  // ADD: legacy путь из старых версий
  if (v == 'assets/images/profile/default.png') return const AssetImage(_kDefaultAvatarAsset);

  // ассет-путь
  if (v.startsWith('assets/')) return AssetImage(v);

  // имя файла -> ассет-путь
  if (!v.contains('/')) return AssetImage('$_kAvatarDir/$v');

  // локальный файл (не web)
  if (!kIsWeb) {
    final f = File(v);
    if (f.existsSync()) return FileImage(f);
  }

  return const AssetImage(_kDefaultAvatarAsset);
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  // ADD: найденные реальные пути ассетов по ключу страны
  final Map<String, String> _countryAssetPath = <String, String>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ignore: discarded_futures
    ref.playBgm(BgmKey.home);

    // ADD: резолвим ассеты после первого кадра (чтобы не словить setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ignore: discarded_futures
      _primeCountryAssets(const ['japan', 'egypt', 'france', 'brazil', 'norway']);
    });
  }

  Future<void> _primeCountryAssets(List<String> keys) async { // ADD
    final next = <String, String>{};

    for (final key in keys) {
      final candidates = <String>[
        // текущий ожидаемый путь
        'assets/images/categories/$key.png',
        'assets/images/categories/$key.webp',
        'assets/images/categories/$key.jpg',
        'assets/images/categories/$key.jpeg',

        // частый вариант: подпапка countries
        'assets/images/categories/countries/$key.png',
        'assets/images/categories/countries/$key.webp',
        'assets/images/categories/countries/$key.jpg',
        'assets/images/categories/countries/$key.jpeg',
      ];

      for (final path in candidates) {
        try {
          await rootBundle.load(path);
          next[key] = path;
          break;
        } catch (_) {
          // asset не найден — пробуем следующий
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _countryAssetPath
        ..clear()
        ..addAll(next);
    });
  }

  String _categoryImageForCountry(String countryKey) {
    // CHANGED: если нашли реальный путь — используем его, иначе оставляем дефолтный ожидаемый
    return _countryAssetPath[countryKey] ?? 'assets/images/categories/$countryKey.png';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // CHANGED: чтобы не вызывать markNeedsBuild во время build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(coinsProvider);
      ref.invalidate(diamondsProvider);
    }); // FIX: важно закрыть addPostFrameCallback
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // CHANGED: то же самое — отложенно
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.invalidate(coinsProvider);
        ref.invalidate(diamondsProvider);
      }); // FIX: важно закрыть addPostFrameCallback
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final countryKeys = const ['japan', 'egypt', 'france', 'brazil', 'norway'];

    final coinsAsync = ref.watch(coinsProvider);
    final diamondsAsync = ref.watch(diamondsProvider);
    final userId = ref.watch(currentUserProvider);

    // ADD: профиль напрямую из profileProvider
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
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
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) => [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: _HomeTopHudRow(
                          profileAsync: profileAsync,
                          coinsAsync: coinsAsync,
                          diamondsAsync: diamondsAsync,
                          onOpenProfile: () {
                            // ignore: discarded_futures
                            ref.playSfx(SfxKey.click);
                            Navigator.pushNamed(context, '/profile');
                          },
                          onOpenSettings: () {
                            // ignore: discarded_futures
                            ref.playSfx(SfxKey.click);
                            Navigator.pushNamed(context, SettingsScreen.route);
                          },
                        ),
                      ),
                    ),
                  ],
                  body: _CountriesList(
                    countryKeys: countryKeys,
                    getTitle: (key) => _countryNameLocalized(context, key),
                    getImageAsset: _categoryImageForCountry,
                    onTapCountry: (key, title, imageAsset) async {
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
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
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

/// ✅ NEW: врезка профиля (как на референсе)
class _HudProfileChip extends StatelessWidget {
  const _HudProfileChip({
    required this.avatarProvider,
    required this.level,
    required this.name,
    required this.rankLabel,
    required this.onTap,
  });

  final ImageProvider avatarProvider; // CHANGED
  final int level;
  final String name;
  final String rankLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  // если есть отдельный ассет — используй его
                  'assets/ui/hud/hud_profile_bg.png',
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => Container(
                    color: Colors.black.withOpacity(0.18),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                mainAxisSize: MainAxisSize.max, // CHANGED: было min (даёт overflow)
                children: [
                  // avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
                    ),
                    child: ClipOval(
                      child: Image(
                        image: avatarProvider, // CHANGED
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // level capsule
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(
                      '$level',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // name + rank
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // временно — иконка щита системная, потом заменишь на asset ic_rank_bronze
                            Icon(Icons.shield_outlined, size: 14, color: Colors.white.withOpacity(0.9)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                rankLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        height: 34,
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.monetization_on_outlined,
                  size: 18,
                  color: Colors.black87,
                ),
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

/// ADD: верхняя строка HUD вынесена из SliverAppBar.title
class _HomeTopHudRow extends StatelessWidget {
  final AsyncValue<LocalProfile> profileAsync;
  final AsyncValue<int> coinsAsync;
  final AsyncValue<int> diamondsAsync;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenProfile;

  const _HomeTopHudRow({
    required this.profileAsync,
    required this.coinsAsync,
    required this.diamondsAsync,
    required this.onOpenSettings,
    required this.onOpenProfile,
  });

  int _levelFromStars(int stars) => 1 + (stars ~/ 10);

  String _rankLabelFromStars(int totalStars) {
    if (totalStars >= 200) return 'Мастер';
    if (totalStars >= 100) return 'Золото I';
    if (totalStars >= 50) return 'Серебро I';
    return 'Бронза I';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Профиль слева — занимает доступное место, поэтому overflow не будет.
        Expanded(
          child: profileAsync.when(
            loading: () => const SizedBox(height: 52),
            error: (_, __) => const SizedBox(height: 52),
            data: (p) => _HudProfileChip(
              avatarProvider: _resolveAvatarProvider(p.avatarPath),
              level: _levelFromStars(p.totalStars),
              name: p.name,
              rankLabel: _rankLabelFromStars(p.totalStars),
              onTap: onOpenProfile,
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Валюты справа — фиксированно по контенту.
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
        const SizedBox(width: 6),
        IconButton(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings, color: Colors.black87),
        ),
      ],
    );
  }
}

/// ADD: список стран вынесен в отдельный виджет (body NestedScrollView)
class _CountriesList extends StatelessWidget {
  final List<String> countryKeys;
  final String Function(String key) getTitle;
  final String Function(String key) getImageAsset;
  final Future<void> Function(String key, String title, String imageAsset) onTapCountry;

  const _CountriesList({
    required this.countryKeys,
    required this.getTitle,
    required this.getImageAsset,
    required this.onTapCountry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: countryKeys.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (c, i) {
        final key = countryKeys[i];
        final title = getTitle(key);
        final imageAsset = getImageAsset(key);

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
              onTap: () => onTapCountry(key, title, imageAsset),
            ),
          ],
        );
      },
    );
  }
}