import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// CHANGED: не тащим core/profile типы (они у тебя расходятся с features)
import '../profile/profile_providers.dart';
import '../profile/local_profile.dart';

import '../../utils/sound_manager.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _emailValid = false;

  @override
  void initState() {
    super.initState();
    // фоновая мелодия для входа/hoмe
    SoundManager.playMusic('assets/sound/home.mp3');
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _validateEmail(String value) {
    setState(() {
      _emailValid = value.isNotEmpty && RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value);
    });
  }

  Future<void> _continueAsGuest() async {
    HapticFeedback.lightImpact();
    await SoundManager.playSfx('assets/sound/click.mp3');
    setState(() => _loading = true);
    try {
      final current = await ref.read(profileProvider.future); // CHANGED
      await _markLoginCompleted();
      if (!mounted) return;
      _goHome(current);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    await SoundManager.playSfx('assets/sound/click.mp3');
    setState(() => _loading = true);
    try {
      final notifier = ref.read(profileProvider.notifier);
      final loaded = await ref.read(profileProvider.future); // CHANGED

      // Псевдо «регистрация»: просто переименуем профиль
      final nextName = _email.text.trim();
      if (loaded.name != nextName) {
        await notifier.rename(nextName); // CHANGED: теперь метод есть
      }

      await _markLoginCompleted();
      if (!mounted) return;

      final after = ref.read(profileProvider).valueOrNull ?? loaded;
      _goHome(after);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
    HapticFeedback.lightImpact();
    await SoundManager.playSfx('assets/sound/click.mp3');
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('seen_onboarding', true);
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withOpacity(theme.brightness == Brightness.dark ? 0.45 : 0.9),
                    colorScheme.secondaryContainer.withOpacity(theme.brightness == Brightness.dark ? 0.32 : 0.8),
                    colorScheme.tertiary.withOpacity(theme.brightness == Brightness.dark ? 0.36 : 0.7),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.surface.withOpacity(theme.brightness == Brightness.dark ? 0.55 : 0.25),
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        children: [
                          Card(
                            elevation: 12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                            shadowColor: colorScheme.primary.withOpacity(0.25),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                              child: Form(
                                key: _formKey,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context).login_title,
                                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      AppLocalizations.of(context).login_hint,
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    const SizedBox(height: 24),
                                    TextFormField(
                                      controller: _email,
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      onChanged: _validateEmail,
                                      decoration: InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: const Icon(Icons.mail_outline),
                                        filled: true,
                                        fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
                                        suffixIcon: AnimatedOpacity(
                                          duration: const Duration(milliseconds: 200),
                                          opacity: _emailValid ? 1 : 0,
                                          child: Icon(Icons.check_circle, color: colorScheme.primary),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return AppLocalizations.of(context).login_enter_email;
                                        }
                                        return _emailValid ? null : AppLocalizations.of(context).login_enter_email;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    TextFormField(
                                      controller: _pass,
                                      obscureText: _obscure,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _signIn(),
                                      decoration: InputDecoration(
                                        labelText: 'Пароль (локально, без проверки)',
                                        prefixIcon: const Icon(Icons.lock_outline),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            SoundManager.playSfx('assets/sound/click.mp3');
                                            setState(() => _obscure = !_obscure);
                                          },
                                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                        ),
                                        filled: true,
                                        fillColor: colorScheme.surfaceVariant.withOpacity(0.35),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                      onPressed: _loading ? null : _signIn,
                                      icon: const Icon(Icons.login_rounded),
                                      label: Text(AppLocalizations.of(context).login_button),
                                      style: FilledButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        textStyle: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    OutlinedButton.icon(
                                      onPressed: _loading ? null : _continueAsGuest,
                                      icon: const Icon(Icons.person_outline),
                                      label: Text(AppLocalizations.of(context).login_guest),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        textStyle: theme.textTheme.titleMedium,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed: _loading ? null : _createNewUser,
                                      icon: const Icon(Icons.star_outline),
                                      label: Text(AppLocalizations.of(context).login_new_user),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_loading)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withOpacity(.08),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}