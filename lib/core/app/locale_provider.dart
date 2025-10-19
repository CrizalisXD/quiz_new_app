import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleController extends AsyncNotifier<Locale?> {
  static const _kLang = 'settings.language';

  @override
  Future<Locale?> build() async {
    final sp = await SharedPreferences.getInstance();
    final code = sp.getString(_kLang);
    if (code == null || code == 'system') return null; // null => системная локаль
    return Locale(code);
  }

  Future<void> setLanguage(String? code) async {
    final sp = await SharedPreferences.getInstance();
    if (code == null || code == 'system') {
      await sp.setString(_kLang, 'system');
      state = const AsyncData(null);
    } else {
      await sp.setString(_kLang, code);
      state = AsyncData(Locale(code));
    }
  }
}

final localeControllerProvider = AsyncNotifierProvider<LocaleController, Locale?>(
  () => LocaleController(),
);
