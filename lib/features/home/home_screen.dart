import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
// Legacy profile removed for coins/stars display; using per-user ProgressStore instead.
import 'widgets/category_card.dart';
import '../progress/progress_providers.dart';
import '../settings/settings_screen.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  static bool _assetSelfTestDone = false; // гарантируем один запуск

  @override
  void initState() {
    super.initState();
    _runAssetSelfTestOnce();
  }

  void _runAssetSelfTestOnce() {
    if (_assetSelfTestDone) return;
    _assetSelfTestDone = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final manifestStr = await rootBundle.loadString('AssetManifest.json');
  final contains = manifestStr.contains('assets/images/bg/home/home.png');
        debugPrint('[AssetSelfTest] length=${manifestStr.length}');
        // Для точного разбора:
        // final map = jsonDecode(manifestStr) as Map<String, dynamic>;
        // map.keys.where((k) => k.contains('bg/home')).forEach(debugPrint);

    debugPrint(contains
      ? '[AssetSelfTest] FOUND assets/images/bg/home/home.png'
      : '[AssetSelfTest] STILL NOT FOUND (assets/images/bg/home/home.png)');
      } catch (e) {
        debugPrint('[AssetSelfTest] error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref; // доступ к ref из ConsumerState
    final countryKeys = const ['japan', 'egypt', 'france', 'brazil', 'norway'];
  // userId доступен при необходимости: ref.watch(currentUserProvider);
    final coinsAsync = ref.watch(coinsProvider);

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
            child: Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    coinsAsync.when(
                      data: (v) => _CurrencyBadge(
                        colors: const [Color(0xFFE3D7FF), Color(0xFFFFFFFF)],
                        icon: Icons.monetization_on_outlined,
                        label: v.toString(),
                        semanticsLabel: 'Монеты',
                      ),
                      loading: () => const _CurrencyBadge(
                        colors: [Color(0xFFE3D7FF), Color(0xFFFFFFFF)],
                        icon: Icons.monetization_on_outlined,
                        label: '...',
                        semanticsLabel: 'Монеты',
                      ),
                      error: (_, __) => const _CurrencyBadge(
                        colors: [Color(0xFFE3D7FF), Color(0xFFFFFFFF)],
                        icon: Icons.monetization_on_outlined,
                        label: 'ERR',
                        semanticsLabel: 'Монеты',
                      ),
                    ),
                    const SizedBox(width: 8),
                    const _CurrencyBadge(
                      colors: [Color(0xFFFFF4CC), Color(0xFFFFFFFF)],
                      icon: Icons.star_border_rounded,
                      label: '?',
                      semanticsLabel: 'Звёзды',
                    ),
                    const SizedBox(width: 8),
                    const _CurrencyBadge(
                      colors: [Color(0xFFD7F9FF), Color(0xFFFFFFFF)],
                      icon: Icons.confirmation_number_outlined,
                      label: '—',
                      semanticsLabel: 'Билеты',
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pushNamed(context, SettingsScreen.route),
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
                    final key = countryKeys[i]; // countryKey
                    final title = _countryNameLocalized(context, key);
                    // progress not displayed now (stars/level removed per request)
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
                          imageAsset: 'assets/images/categories/$key.png',
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/category',
                            arguments: {
                              'countryKey': key,
                              'title': title,
                              // будущий packId можно вычислять в CategoryScreen
                            },
                          ),
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
                onTap: () => Navigator.pushNamed(context, '/achievements'),
              ),
              _BottomItem(
                icon: Icons.person_outline,
                label: AppLocalizations.of(context).home_profile,
                onTap: () => Navigator.pushNamed(context, '/profile'),
              ),
              _BottomItem(
                icon: Icons.storefront_outlined,
                label: AppLocalizations.of(context).home_shop,
                onTap: () => Navigator.pushNamed(context, '/shop'),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Colors.black87),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w700),
            ),
          ],
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

