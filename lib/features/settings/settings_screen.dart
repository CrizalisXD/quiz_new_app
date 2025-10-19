import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_new_app/core/app/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quiz_new_app/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  static const route = '/settings';
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = 0.7;        // 0..1
  bool _soundsEnabled = true;  // on/off
  String _language = 'ru';     // заглушка

  // ключи для SharedPreferences
  static const _kVolume = 'settings.volume';
  static const _kSounds = 'settings.sounds';
  static const _kLang   = 'settings.language';

  // ключи данных профиля/прогресса (очищаем при выходе)
  static const _kUserNick   = 'user.nick';
  static const _kUserAvatar = 'user.avatar';
  static const _kCoins      = 'user.coins';
  static const _kStars      = 'user.stars';
  static const _kEnergy     = 'user.energy';
  static const _kProgress   = 'progress.map'; // JSON со всем прогрессом

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _volume = p.getDouble(_kVolume) ?? 0.7;
      _soundsEnabled = p.getBool(_kSounds) ?? true;
      _language = p.getString(_kLang) ?? 'ru';
    });
  }

  Future<void> _saveVolume(double v) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_kVolume, v);
  }

  Future<void> _saveSounds(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kSounds, v);
  }

  Future<void> _saveLanguage(String code) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLang, code);
  }

  Future<void> _logoutAndClearLocal() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kUserNick);
    await p.remove(_kUserAvatar);
    await p.remove(_kCoins);
    await p.remove(_kStars);
    await p.remove(_kEnergy);
    await p.remove(_kProgress);
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scope = ProviderScope.containerOf(context, listen: false);
    final topPad = MediaQuery.of(context).padding.top + kToolbarHeight + 8;
    final l = AppLocalizations.of(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l.settings_title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, topPad, 16, 16),
        children: [
          Text(l.settings_section_basic, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Громкость
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up),
                      const SizedBox(width: 12),
                      Text(l.settings_volume),
                      const Spacer(),
                      Text('${(_volume * 100).round()}%'),
                    ],
                  ),
                  Slider(
                    value: _volume,
                    min: 0,
                    max: 1,
                    onChanged: (v) => setState(() => _volume = v),
                    onChangeEnd: _saveVolume,
                  ),
                ],
              ),
            ),
          ),

          // Звуки
          SwitchListTile(
            value: _soundsEnabled,
            onChanged: (v) {
              setState(() => _soundsEnabled = v);
              _saveSounds(v);
            },
            title: Text(l.settings_sounds),
            secondary: const Icon(Icons.music_note),
          ),

          // Язык
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(l.settings_language),
            subtitle: Text(_language == 'ru' ? 'Русский' : (_language == 'system' ? l.settings_language_system : 'English')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final selected = await showModalBottomSheet<String>(
                context: context,
                builder: (ctx) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: Text(l.settings_language_system),
                        onTap: () => Navigator.pop(ctx, 'system'),
                      ),
                      ListTile(
                        title: const Text('Русский'),
                        onTap: () => Navigator.pop(ctx, 'ru'),
                      ),
                      ListTile(
                        title: const Text('English'),
                        onTap: () => Navigator.pop(ctx, 'en'),
                      ),
                    ],
                  ),
                ),
              );
              if (selected != null) {
                setState(() => _language = selected);
                _saveLanguage(selected);
                // Обновляем провайдер локали
                scope.read(localeControllerProvider.notifier).setLanguage(selected);
              }
            },
          ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          Text(l.settings_account, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Выйти из аккаунта
          FilledButton.tonalIcon(
            onPressed: _logoutAndClearLocal,
            icon: const Icon(Icons.logout),
            label: Text(l.settings_sign_out),
          ),
        ],
      ),
    );
  }
}