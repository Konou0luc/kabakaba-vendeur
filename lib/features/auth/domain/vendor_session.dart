import 'package:flutter/foundation.dart';

/// Session vendeur ouverte.
@immutable
class VendorSession {
  final String userId;
  final String vendorId;
  final String canteenName;
  final String phone;

  const VendorSession({
    required this.userId,
    required this.vendorId,
    required this.canteenName,
    required this.phone,
  });
}

/// Étape 1 franchie : identifiants validés, OTP envoyé par SMS.
@immutable
class ActivationChallenge {
  /// Jeton d'étape à réutiliser tel quel. Portée limitée côté serveur : il ne
  /// donne accès à aucune donnée, il ne prouve que le passage de l'étape.
  final String onboardingToken;

  /// Numéro masqué, à afficher pour confirmer la destination du SMS.
  final String phoneMasked;

  final int pinLength;

  const ActivationChallenge({
    required this.onboardingToken,
    required this.phoneMasked,
    required this.pinLength,
  });
}

/// Étape 2 franchie : OTP vérifié, le PIN peut être posé.
@immutable
class PinSetupGrant {
  final String pinSetupToken;
  final int pinLength;

  const PinSetupGrant({required this.pinSetupToken, required this.pinLength});
}
