import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController();
});

const _prefsKey = 'app_locale';

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('ru')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved != null) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
    state = locale;
  }

  void toggleLocale() {
    final newLocale = state.languageCode == 'ru' ? const Locale('en') : const Locale('ru');
    setLocale(newLocale);
  }
}