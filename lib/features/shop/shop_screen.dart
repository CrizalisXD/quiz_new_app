import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';
import '../auth/current_user.dart';
import '../progress/progress_store.dart';
import 'currency_store.dart';
import '../../core/profile/profile_providers.dart'; // для avatarPath

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  static const route = '/shop';

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  int _gems = 0;
  int _coins = 0; // ADD
  late DateTime _offerEndsAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _offerEndsAt = DateTime.now().add(const Duration(days: 5, hours: 1));

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserProvider);

      final gems = await CurrencyStore.getGems(userId);
      final coins = await ProgressStore.getCoins(userId); // ADD

      if (!mounted) return;
      setState(() {
        _gems = gems;
        _coins = coins; // ADD
      });
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatLeft(Duration d) {
    if (d.isNegative || d == Duration.zero) return '0ч 0м';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final mins = d.inMinutes % 60;
    if (days > 0) return '$daysд $hoursч';      // CHANGED (убрали {})
    if (hours > 0) return '$hoursч $minsм';     // CHANGED
    return '$minsм';                             // CHANGED
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(AppLocalizations.of(context).home_shop),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                PillBadge(
                  colors: const [Color(0xFFB9F6CA), Color(0xFFFFFFFF)],
                  leading: const PillAssetIcon(
                    'assets/images/ui/currency/diamond.png',
                    bubbleGradient: [Color(0xFFFFD6F2), Color(0xFFFFFFFF)],
                  ),
                  label: _gems.toString(),
                ),
                const SizedBox(width: 8),
                PillBadge(
                  colors: const [Color(0xFFB3E5FC), Color(0xFFFFFFFF)],
                  leading: const PillAssetIcon(
                    'assets/images/ui/currency/gold.png',
                    bubbleGradient: [Color(0xFFFFE08A), Color(0xFFFFFFFF)],
                  ),
                  label: _coins.toString(),
                ),
              ],
            ),
          ),
        ],
      ),

      // ADD: нижняя панель с hub-элементом (в стиле золото/алмазы)
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
          child: _BottomHubPanel(
            coinsText: _coins.toString(),
            gemsText: _gems.toString(),
            onTapCoins: () async {
              final userId = ref.read(currentUserProvider);
              final coins = await ProgressStore.getCoins(userId);
              if (!mounted) return;
              setState(() => _coins = coins);
            },
            onTapGems: () async {
              final userId = ref.read(currentUserProvider);
              final gems = await CurrencyStore.getGems(userId);
              if (!mounted) return;
              setState(() => _gems = gems);
            },
            onTapHub: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (r) => false);
            },
          ),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ADD: "привет • Бронза I" в виде того же PillBadge
          Align(
            alignment: Alignment.centerLeft,
            child: profileAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (profile) => PillBadge(
                colors: const [Color(0xFFE6D8FF), Color(0xFFFFFFFF)],
                leading: CircleAvatar(
                  radius: 10, // 20px diameter -> идеально под leadingBox (20x20)
                  backgroundImage: AssetImage(profile.avatarPath),
                  onBackgroundImageError: (_, __) {},
                ),
                label: 'привет • Бронза I',
              ),
            ),
          ),
          const SizedBox(height: 12),

          _DailyOfferCard(
            endsAt: _offerEndsAt,
            leftTextBuilder: (d) => _formatLeft(d),
            onBuy: () async {
              final userId = ref.read(currentUserProvider);
              if (_gems >= 5000) {
                await CurrencyStore.addGems(userId, -5000);
                final newG = await CurrencyStore.getGems(userId);
                final newCoins = await ProgressStore.getCoins(userId); // ADD: на всякий случай обновим
                if (!mounted) return;
                setState(() {
                  _gems = newG;
                  _coins = newCoins;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Покупка применена')),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Недостаточно кристаллов')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// UI building block.
/// NOTE: это нужно переиспользовать в верхней панели Home (топбар), чтобы иконки валют были одинаковыми.
class PillAssetIcon extends StatelessWidget {
  final String asset;

  /// общий размер “баббла” (должен совпадать для всех иконок)
  final double bubbleSize;

  /// фактический размер контента внутри баббла
  final double contentSize;

  /// градиент/фон баббла (чтобы визуально было одинаково как на скрине)
  final List<Color>? bubbleGradient;

  const PillAssetIcon(
    this.asset, {
    super.key,
    this.bubbleSize = 22,
    this.contentSize = 16,
    this.bubbleGradient,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: bubbleSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: bubbleGradient == null ? null : LinearGradient(colors: bubbleGradient!),
          color: bubbleGradient == null ? Colors.transparent : null,
        ),
        child: Center(
          // КЛЮЧ: cover + фиксированный contentSize => одинаковая “визуальная” масса,
          // даже если в PNG разный прозрачный padding.
          child: SizedBox.square(
            dimension: contentSize,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: Image.asset(
                  asset,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.image_not_supported_outlined, size: contentSize),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// UI building block.
/// NOTE: это нужно переиспользовать в верхней панели Home (топбар), чтобы стиль “пилюль” был единый.
class PillBadge extends StatelessWidget {
  final Widget leading;
  final String label;
  final List<Color> colors;
  final VoidCallback? onTap;

  const PillBadge({
    super.key,
    required this.leading,
    required this.label,
    required this.colors,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // CHANGED: ведущий слот подогнали под bubbleSize=22
    final leadingBox = SizedBox.square(
      dimension: 22,
      child: Center(child: leading),
    );

    final child = Container(
      height: 34,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leadingBox,
          const SizedBox(width: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: child,
      ),
    );
  }
}

// CHANGED: нижняя панель теперь тоже на PillBadge (единый стиль)
class _BottomHubPanel extends StatelessWidget {
  final String coinsText;
  final String gemsText;
  final VoidCallback onTapHub;
  final VoidCallback? onTapCoins;
  final VoidCallback? onTapGems;

  const _BottomHubPanel({
    required this.coinsText,
    required this.gemsText,
    required this.onTapHub,
    this.onTapCoins,
    this.onTapGems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EEF9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          PillBadge(
            colors: const [Color(0xFFB3E5FC), Color(0xFFFFFFFF)],
            leading: const PillAssetIcon(
              'assets/images/ui/currency/gold.png',
              bubbleGradient: [Color(0xFFFFE08A), Color(0xFFFFFFFF)],
            ),
            label: coinsText,
            onTap: onTapCoins,
          ),
          const Spacer(),
          PillBadge(
            colors: const [Color(0xFF6C5CE7), Color(0xFFB8B2FF)],
            leading: const Icon(Icons.hub, size: 18, color: Colors.white),
            label: 'HUB',
            onTap: onTapHub,
          ),
          const Spacer(),
          PillBadge(
            colors: const [Color(0xFFB9F6CA), Color(0xFFFFFFFF)],
            leading: const PillAssetIcon(
              'assets/images/ui/currency/diamond.png',
              bubbleGradient: [Color(0xFFFFD6F2), Color(0xFFFFFFFF)],
            ),
            label: gemsText,
            onTap: onTapGems,
          ),
        ],
      ),
    );
  }
}

class _DailyOfferCard extends StatelessWidget {
  final DateTime endsAt;
  final String Function(Duration) leftTextBuilder;
  final VoidCallback onBuy;
  const _DailyOfferCard({required this.endsAt, required this.leftTextBuilder, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = endsAt.isAfter(now) ? endsAt.difference(now) : Duration.zero;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6FF), // нежно голубой фон
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('ПРЕДЛОЖЕНИЕ ДНЯ', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w800)),
              Row(
                children: [
                  const Icon(Icons.schedule, size: 16, color: Colors.black54),
                  const SizedBox(width: 4),
                  Text(leftTextBuilder(left), style: const TextStyle(color: Colors.black54)),
                ],
              )
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 84, // больше места, чтобы избежать переполнения
            child: Row(
              children: const [
                _OfferPill(icon: Icons.lightbulb, count: 45, color: Color(0xFFFFF4CC)),
                _OfferPill(icon: Icons.gavel_rounded, count: 15, color: Color(0xFFE8D7FF)),
                _OfferPill(icon: Icons.rocket_launch_rounded, count: 100, color: Color(0xFFD7F9FF)),
                _OfferPill(icon: Icons.token, count: 8, color: Color(0xFFD7E9FF)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.center,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DBB54),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: onBuy,
              icon: const Icon(Icons.diamond, size: 18),
              label: const Text('5000'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferPill extends StatelessWidget {
  final IconData icon;
  final int count;
  final Color color;
  const _OfferPill({required this.icon, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE0ECFF)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: color,
              child: Icon(icon, color: Colors.black87, size: 18),
            ),
            const SizedBox(height: 6),
            Text('x$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
