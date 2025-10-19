import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/core/profile/profile_providers.dart';
import 'package:quiz_new_app/core/profile/local_profile.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  // убран старый LocalProfileStore, используем ProfileNotifier

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    final notifier = ref.read(profileProvider.notifier);
    // Просто убеждаемся что профиль загружен (гостевой создаётся автоматически)
    final current = ref.read(profileProvider).valueOrNull ?? await notifier.build();
    await _markLoginCompleted();
    if (!mounted) return;
    _goHome(current);
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).login_enter_email)),
      );
      return;
    }
    setState(() => _loading = true);
    final notifier = ref.read(profileProvider.notifier);
    final loaded = ref.read(profileProvider).valueOrNull ?? await notifier.build();
    // Псевдо «регистрация»: просто переименуем профиль
    if (loaded.name != email) {
      await notifier.rename(email);
    }
    await _markLoginCompleted();
    if (!mounted) return;
    _goHome(ref.read(profileProvider).valueOrNull ?? loaded);
  }

  void _goHome(LocalProfile p) {
    setState(() => _loading = false);
    Navigator.of(context).pushReplacementNamed('/home');
  }

  Future<void> _markLoginCompleted() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('has_login_flow_completed', true);
  }

  Future<void> _createNewUser() async {
    // Простая «регистрация» локально: запомним, что показывали онбординг и очистим поля.
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('seen_onboarding', true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).login_local_profile_creates)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Image.asset(
                    'assets/images/logo/logo_game.png',
                    width: 72,
                    height: 72,
                  ),
                ),
                const SizedBox(height: 24),
                Text(AppLocalizations.of(context).login_title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
        Text(AppLocalizations.of(context).login_hint,
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54)),
                const SizedBox(height: 24),

                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Пароль (локально, без проверки)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                FilledButton(
                  onPressed: _loading ? null : _signIn,
                  child: Text(AppLocalizations.of(context).login_button),
                ),
                const SizedBox(height: 12),

                Center(
                  child: TextButton(
                    onPressed: _loading ? null : _continueAsGuest,
                    child: Text(AppLocalizations.of(context).login_guest),
                  ),
                ),

                const SizedBox(height: 28),
                const Divider(),
                const SizedBox(height: 8),

                // «Новый пользователь?» — в САМОМ НИЗУ как текст-кнопка
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: _loading ? null : _createNewUser,
                    child: Text(AppLocalizations.of(context).login_new_user),
                  ),
                ),
              ],
            ),

            if (_loading)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: .08),
                  child: const Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
