import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/features/home/home_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/categories/category_screen.dart';
import 'features/levels/levels_screen.dart';
import 'features/quiz/ui/quiz_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/login_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/achievements/achievements_screen.dart';
import 'features/shop/shop_screen.dart';
// Rewards are shown inside Profile screen; achievements route remains stub for now.
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'core/app/locale_provider.dart';

void main() => runApp(const ProviderScope(child: App()));

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeControllerProvider);
    return MaterialApp(
      onGenerateTitle: (ctx) => AppLocalizations.of(ctx).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],
      locale: localeAsync.valueOrNull,
      localeResolutionCallback: (deviceLocale, supported) {
        if (deviceLocale == null) return const Locale('en');
        for (final l in supported) {
          if (l.languageCode == deviceLocale.languageCode) return l;
        }
        return supported.first;
      },
      // Gate: сначала логин, затем Home; при повторных запусках сразу Home.
      home: const StartGate(),
      initialRoute: '/home',
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/category': (_) => const CategoryScreen(),
        '/levels': (_) => const LevelsScreen(),
        SettingsScreen.route: (_) => const SettingsScreen(),
        '/season': (_) => const _StubScreen(title: 'Сезон'),
        AchievementsScreen.route: (_) => const AchievementsScreen(),
        '/shop': (_) => const ShopScreen(),
        // '/countriesFlow': (context) => const CountriesFlowScreen(), // удалён, файла нет
        // Опциональный прямой маршрут (если нужно вызовом Navigator.pushNamed):
        '/quiz': (c) => const QuizScreen(pack: 'demo', level: 1), // демо; обычно используйте push с параметрами
      },
    );
  }
}

class _StubScreen extends StatelessWidget {
  final String title;
  const _StubScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Center(
        child: Text('$title (в разработке)',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class StartGate extends StatelessWidget {
  const StartGate({super.key});

  Future<bool> _isLoginCompleted() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool('has_login_flow_completed') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoginCompleted(),
      builder: (c, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final completed = snap.data!;
        if (!completed) return const LoginScreen();
        return const HomeScreen();
      },
    );
  }
}
