/// Chemins de l'API, relatifs à `AppConfig.apiBaseUrl` (`.../api/v1`).
///
/// Centralisés pour que les noms de routes n'apparaissent jamais dans la
/// couche présentation.
class ApiEndpoints {
  const ApiEndpoints._();

  // --- Authentification vendeur ------------------------------------------
  // Parcours d'activation : téléphone + mot de passe → OTP → code PIN.
  static const String vendorActivateStart = '/auth/vendor/activate/start';
  static const String vendorActivateResendOtp =
      '/auth/vendor/activate/resend-otp';
  static const String vendorActivateVerifyOtp =
      '/auth/vendor/activate/verify-otp';
  static const String vendorActivateSetPin = '/auth/vendor/activate/set-pin';
  static const String vendorLoginPin = '/auth/vendor/login-pin';

  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authChangePassword = '/auth/change-password';

  /// Routes publiques d'authentification : exclues du rafraîchissement
  /// automatique de token, sans quoi un 401 de « mauvais PIN » déclencherait
  /// une tentative de refresh puis une déconnexion.
  static const Set<String> publicAuthPaths = {
    vendorActivateStart,
    vendorActivateResendOtp,
    vendorActivateVerifyOtp,
    vendorActivateSetPin,
    vendorLoginPin,
    authRefresh,
  };

  // --- Profil vendeur -----------------------------------------------------
  static const String vendorsMe = '/vendors/me';
  static const String usersMe = '/users/me';
  static String userById(String id) => '/users/$id';

  // --- Commandes ----------------------------------------------------------
  static const String orders = '/orders';
  static String orderById(String id) => '/orders/$id';
  static String orderRefund(String id) => '/orders/$id/refund';

  // --- Portefeuille -------------------------------------------------------
  static const String transactions = '/transactions';

  static const String withdrawals = '/withdrawals';
  static const String withdrawalsPreview = '/withdrawals/preview';
  static const String withdrawalsMine = '/withdrawals/me';
  static String withdrawalAppeal(String id) => '/withdrawals/$id/appeal';

  // --- Catalogue (menu de la cantine) -------------------------------------
  static const String menuItems = '/catalog/menu-items';
  static String menuItemById(String id) => '/catalog/menu-items/$id';
  static const String menuComponents = '/catalog/menu-components';
  static String menuComponentById(String id) => '/catalog/menu-components/$id';
  static const String packagingOptions = '/catalog/packaging-options';
  static String packagingOptionById(String id) =>
      '/catalog/packaging-options/$id';

  // --- Horaires d'ouverture ----------------------------------------------
  static String vendorSchedules(String vendorId) =>
      '/vendors/$vendorId/schedules';
  static String vendorScheduleById(String vendorId, String scheduleId) =>
      '/vendors/$vendorId/schedules/$scheduleId';

  // --- Notifications et appareils ----------------------------------------
  static const String notifications = '/notifications';
  static String notificationById(String id) => '/notifications/$id';
  static const String devices = '/devices';

  // --- Litiges ------------------------------------------------------------
  static const String disputes = '/disputes';
  static String disputeById(String id) => '/disputes/$id';
}
