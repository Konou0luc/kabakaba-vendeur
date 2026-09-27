import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/storage/session_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Échoue au démarrage plutôt qu'à la première requête si la configuration
  // de build est incohérente (URL relative, HTTP en production).
  AppConfig.assertValid();

  // Le HttpClient Dart n'atteint pas fonts.gstatic.com sur certains
  // téléphones (TECNO) : on n'essaie plus de télécharger la police au runtime.
  GoogleFonts.config.allowRuntimeFetching = false;

  final preferences = await SharedPreferences.getInstance();
  final secureStorage = createSecureStorage();

  // La session est relue avant le premier build : l'intercepteur Dio et la
  // redirection du routeur lisent le jeton de façon synchrone, ils ne peuvent
  // pas attendre un `Future`.
  final sessionStore = await createRestoredSessionStore(
    secureStorage: secureStorage,
    preferences: preferences,
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(preferences),
        secureStorageProvider.overrideWithValue(secureStorage),
        sessionStoreProvider.overrideWithValue(sessionStore),
      ],
      child: const VendorApp(),
    ),
  );
}
