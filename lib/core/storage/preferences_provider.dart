import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Préférences non sensibles (affichage, derniers filtres…).
///
/// Surchargé dans `main()` : `SharedPreferences.getInstance()` est
/// asynchrone alors que la plupart des lectures sont synchrones.
/// Tout ce qui relève d'un secret passe par `SessionStore`, pas par ici.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider doit être surchargé dans main()',
  );
});
