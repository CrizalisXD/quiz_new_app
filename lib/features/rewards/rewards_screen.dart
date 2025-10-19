import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/current_user.dart';
import 'rewards_store.dart';
import '../../utils/ui_metrics.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});
  static const route = '/achievements';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserProvider);
    return FutureBuilder<List<String>>(
      future: RewardsStore.getRewards(userId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final items = snap.data!;
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).profile_rewards),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              // Можно добавить общий фон для наград в будущем
              Container(color: Colors.black.withOpacity(0.2)),
              Padding(
                padding: EdgeInsets.fromLTRB(16, contentTopPadding(context), 16, 16),
                child: items.isEmpty
                    ? Center(
                        child: Text(AppLocalizations.of(context).profile_no_rewards, style: const TextStyle(fontSize: 16)),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: items.length,
                        itemBuilder: (_, i) {
                          final p = items[i];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              p,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey.shade300,
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_not_supported_outlined),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}