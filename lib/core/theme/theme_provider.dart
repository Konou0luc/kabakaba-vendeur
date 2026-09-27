import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final themeModeProvider = NotifierProvider<ThemeModeNotifier, AppThemeMode>(() {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  static const String _themePrefKey = 'theme_mode_vendeur';

  @override
  AppThemeMode build() {
    return _loadThemeMode();
  }

  AppThemeMode _loadThemeMode() {
    try {
      final prefs = ref.watch(sharedPreferencesProvider);
      final savedTheme = prefs.getString(_themePrefKey);
      if (savedTheme != null) {
        return AppThemeMode.values.firstWhere(
          (mode) => mode.name == savedTheme,
          orElse: () => AppThemeMode.light,
        );
      }
      return AppThemeMode.light;
    } catch (e) {
      return AppThemeMode.light;
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setString(_themePrefKey, mode.name);
      state = mode;
    } catch (e) {
      state = mode;
    }
  }
}
