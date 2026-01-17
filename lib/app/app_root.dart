import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../audio/audio_manager.dart';
import '../features/home/home_screen.dart';

class AppRoot extends ConsumerWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(audioManagerProvider, (prev, next) {
      next.whenOrNull(
        error: (e, _) {
          debugPrint('Audio error: $e');
        },
      );
    });

    return MaterialApp(
      // ...existing app config (theme/localizations/routes)...
      home: const HomeScreen(),
    );
  }
}