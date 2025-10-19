import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';
import '../auth/current_user.dart';
import '../../core/profile/profile_providers.dart';
import 'currency_store.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});
  static const route = '/shop';

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  int _gems = 0;
  late DateTime _offerEndsAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _offerEndsAt = DateTime.now().add(const Duration(days: 5, hours: 1));
    // Отложенно загрузим баланс кристаллов
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = ref.read(currentUserProvider);
      final gems = await CurrencyStore.getGems(userId);
      if (mounted) setState(() => _gems = gems);
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
    if (days > 0) return '${days}д ${hours}ч';
    if (hours > 0) return '${hours}ч ${mins}м';
    return '${mins}м';
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
          // Плашки валют
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(children: [
              _CurrencyBadge(
                background: const Color(0xFF2ECC71),
                icon: Icons.diamond,
                valueText: _gems.toString(),
              ),
              const SizedBox(width: 8),
              profileAsync.when(
                loading: () => const _CurrencyBadge(background: Color(0xFF3498DB), icon: Icons.monetization_on, valueText: '…'),
                error: (_, __) => const _CurrencyBadge(background: Color(0xFF3498DB), icon: Icons.monetization_on, valueText: '0'),
                data: (p) => _CurrencyBadge(
                  background: const Color(0xFF3498DB),
                  icon: Icons.monetization_on,
                  valueText: p.coins.toString(),
                ),
              ),
            ]),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DailyOfferCard(
            endsAt: _offerEndsAt,
            leftTextBuilder: (d) => _formatLeft(d),
            onBuy: () async {
              // Покупка списывает кристаллы (для примера) и добавляет бонус
              final userId = ref.read(currentUserProvider);
              if (_gems >= 5000) {
                await CurrencyStore.addGems(userId, -5000);
                final newG = await CurrencyStore.getGems(userId);
                if (mounted) setState(() => _gems = newG);
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

class _CurrencyBadge extends StatelessWidget {
  final Color background;
  final IconData icon;
  final String valueText;
  const _CurrencyBadge({required this.background, required this.icon, required this.valueText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(valueText, style: const TextStyle(fontWeight: FontWeight.w700)),
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
