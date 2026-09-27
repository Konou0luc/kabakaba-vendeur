import 'package:flutter/foundation.dart';

enum AppEnvironment { dev, staging, prod }

/// Configuration de compilation, fournie par `--dart-define`.
///
/// Volontairement en `const` : les valeurs sont figées dans le binaire au
/// build, donc un binaire de production ne peut pas être détourné vers une
/// autre API au lancement. À l'inverse d'un `.env` embarqué comme asset, rien
/// n'est lisible dans l'archive ni modifiable après signature.
///
/// Exemple :
/// ```sh
/// flutter run \
///   --dart-define=KABAKABA_ENV=dev \
///   --dart-define=KABAKABA_API_URL=http://192.168.1.10:3000/api/v1
/// ```
class AppConfig {
  const AppConfig._();

  static const String _environmentName = String.fromEnvironment(
    'KABAKABA_ENV',
    defaultValue: 'prod',
  );

  static const String apiBaseUrl = String.fromEnvironment(
    'KABAKABA_API_URL',
    defaultValue: 'https://kabakaba-backend.vercel.app/api/v1',
  );

  static AppEnvironment get environment => switch (_environmentName) {
    'dev' => AppEnvironment.dev,
    'staging' => AppEnvironment.staging,
    _ => AppEnvironment.prod,
  };

  static bool get isProduction => environment == AppEnvironment.prod;

  /// Les traces réseau contiennent les en-têtes `Authorization` et les corps
  /// de réponse : elles ne doivent jamais être compilées dans un binaire
  /// distribué.
  static bool get enableNetworkLogs => kDebugMode;

  /// Échoue au démarrage plutôt qu'au premier appel réseau si la
  /// configuration est inutilisable. Les messages visent le développeur.
  static void assertValid() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      throw StateError(
        'KABAKABA_API_URL invalide : "$apiBaseUrl". '
        'Attendu une URL absolue, par exemple https://api.kabakaba.com/api/v1',
      );
    }
    if (isProduction && uri.scheme != 'https') {
      throw StateError(
        'KABAKABA_API_URL doit être en HTTPS en production (reçu "$apiBaseUrl"). '
        'Les jetons de session ne doivent jamais circuler en clair.',
      );
    }
  }
}
