import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ré-exporté ici pour que les appelants n'aient qu'un seul import de stockage.
export 'preferences_provider.dart' show sharedPreferencesProvider;

/// État persisté de la session vendeur, tel que relu au démarrage.
@immutable
class SessionSnapshot {
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? vendorId;

  /// Numéro du dernier vendeur connecté : conservé après déconnexion pour
  /// pouvoir proposer directement l'écran de code PIN.
  final String? phone;

  /// Un PIN a déjà été posé sur cet appareil pour ce numéro.
  final bool pinConfigured;

  const SessionSnapshot({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.vendorId,
    this.phone,
    this.pinConfigured = false,
  });

  const SessionSnapshot.empty() : this();

  bool get hasTokens => accessToken != null && refreshToken != null;

  SessionSnapshot copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? vendorId,
    String? phone,
    bool? pinConfigured,
  }) {
    return SessionSnapshot(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      vendorId: vendorId ?? this.vendorId,
      phone: phone ?? this.phone,
      pinConfigured: pinConfigured ?? this.pinConfigured,
    );
  }
}

/// Stockage de la session vendeur.
///
/// Les jetons vivent dans le Keystore (Android) / Keychain (iOS) via
/// `flutter_secure_storage`, jamais dans `SharedPreferences` : un fichier de
/// préférences est lisible en clair sur un appareil rooté ou via une
/// sauvegarde ADB.
///
/// Un cache mémoire double ce stockage, pour deux raisons : l'intercepteur
/// Dio et la redirection du routeur ont besoin d'une lecture **synchrone**, et
/// chaque accès au Keystore est un aller-retour de canal de plateforme qu'on
/// ne veut pas payer à chaque requête HTTP.
class SessionStore {
  static const _accessTokenKey = 'kabakaba.vendor.accessToken';
  static const _refreshTokenKey = 'kabakaba.vendor.refreshToken';
  static const _userIdKey = 'kabakaba.vendor.userId';
  static const _vendorIdKey = 'kabakaba.vendor.vendorId';
  static const _phoneKey = 'kabakaba.vendor.phone';
  static const _pinConfiguredKey = 'kabakaba.vendor.pinConfigured';

  /// Clés de l'ancienne implémentation, qui écrivait les jetons en clair dans
  /// les préférences. Purgées au démarrage pour ne pas laisser traîner de
  /// jetons lisibles sur les appareils déjà utilisés en développement.
  static const _legacyPlaintextKeys = [
    'vendor_access_token',
    'vendor_refresh_token',
    'vendor_user_id',
    'vendor_id',
    'vendor_pin_set',
    'vendor_pin_hash',
    'vendor_last_phone',
  ];

  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _preferences;

  SessionSnapshot _snapshot = const SessionSnapshot.empty();

  SessionStore(this._secureStorage, this._preferences);

  /// Lecture synchrone, sûre après `restore()`.
  SessionSnapshot get snapshot => _snapshot;

  Future<void> restore() async {
    await _purgeLegacyPlaintextKeys();

    final values = await _secureStorage.readAll();
    _snapshot = SessionSnapshot(
      accessToken: values[_accessTokenKey],
      refreshToken: values[_refreshTokenKey],
      userId: values[_userIdKey],
      vendorId: values[_vendorIdKey],
      phone: values[_phoneKey],
      pinConfigured: values[_pinConfiguredKey] == 'true',
    );
  }

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? userId,
    String? vendorId,
  }) async {
    _snapshot = _snapshot.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      vendorId: vendorId,
    );
    await Future.wait([
      _secureStorage.write(key: _accessTokenKey, value: accessToken),
      _secureStorage.write(key: _refreshTokenKey, value: refreshToken),
      if (userId != null) _secureStorage.write(key: _userIdKey, value: userId),
      if (vendorId != null)
        _secureStorage.write(key: _vendorIdKey, value: vendorId),
    ]);
  }

  Future<void> rememberVendor({
    required String phone,
    required bool pinConfigured,
  }) async {
    _snapshot = _snapshot.copyWith(phone: phone, pinConfigured: pinConfigured);
    await Future.wait([
      _secureStorage.write(key: _phoneKey, value: phone),
      _secureStorage.write(
        key: _pinConfiguredKey,
        value: pinConfigured.toString(),
      ),
    ]);
  }

  /// Déconnexion « douce » : les jetons partent, le numéro et l'existence
  /// d'un PIN restent pour que la reconnexion se fasse au PIN seul.
  Future<void> clearTokens() async {
    _snapshot = SessionSnapshot(
      phone: _snapshot.phone,
      pinConfigured: _snapshot.pinConfigured,
    );
    await Future.wait([
      _secureStorage.delete(key: _accessTokenKey),
      _secureStorage.delete(key: _refreshTokenKey),
      _secureStorage.delete(key: _userIdKey),
      _secureStorage.delete(key: _vendorIdKey),
    ]);
  }

  /// Oubli complet de l'appareil : impose de repasser par l'activation
  /// (téléphone + mot de passe + OTP).
  Future<void> forgetVendor() async {
    _snapshot = const SessionSnapshot.empty();
    await _secureStorage.deleteAll();
  }

  Future<void> _purgeLegacyPlaintextKeys() async {
    for (final key in _legacyPlaintextKeys) {
      if (_preferences.containsKey(key)) {
        await _preferences.remove(key);
      }
    }
  }
}

/// Coffre de la plateforme, à créer une seule fois et à partager.
///
/// Android : AES-GCM avec clé dans le Keystore, défaut du plugin depuis la
/// v11. `resetOnError` purge le coffre si la clé devient illisible
/// (restauration d'une sauvegarde sur un autre appareil) : le vendeur se
/// reconnecte, plutôt que l'app plante à chaque démarrage.
///
/// iOS : lisible après le premier déverrouillage, nécessaire pour qu'une
/// notification de commande puisse rafraîchir en arrière-plan.
FlutterSecureStorage createSecureStorage() => const FlutterSecureStorage(
  aOptions: AndroidOptions(resetOnError: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return createSecureStorage();
});

/// Surchargé au démarrage dans `main()` avec une instance déjà restaurée, pour
/// que `snapshot` soit lisible synchroniquement dès le premier build.
final sessionStoreProvider = Provider<SessionStore>((ref) {
  throw UnimplementedError(
    'sessionStoreProvider doit être surchargé dans main() après restore()',
  );
});

Future<SessionStore> createRestoredSessionStore({
  required FlutterSecureStorage secureStorage,
  required SharedPreferences preferences,
}) async {
  final store = SessionStore(secureStorage, preferences);
  await store.restore();
  return store;
}
