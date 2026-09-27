import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/json_reader.dart';
import '../../../../core/storage/session_store.dart';
import '../../data/vendor_auth_repository.dart';

/// Écran d'entrée à présenter au lancement.
enum VendorAuthStatus {
  /// Aucun vendeur connu sur cet appareil : activation complète requise.
  needsActivation,

  /// Un PIN a déjà été posé : connexion au code PIN.
  needsPin,

  authenticated,
}

/// Étape courante du parcours d'activation.
enum ActivationStep { credentials, otp, pinSetup, done }

@immutable
class VendorAuthState {
  final VendorAuthStatus status;
  final ActivationStep activationStep;

  /// Numéro mémorisé sur l'appareil, pré-rempli à la reconnexion.
  final String? phone;
  final String? phoneMasked;
  final int pinLength;

  final bool isSubmitting;

  /// Message d'erreur prêt à afficher, issu de l'API quand elle en fournit un
  /// (« Il te reste 2 essais », « Réessaie dans 12 minutes »…).
  final String? errorMessage;

  /// Le PIN est verrouillé côté serveur : inutile de laisser saisir.
  final bool pinLocked;

  const VendorAuthState({
    required this.status,
    this.activationStep = ActivationStep.credentials,
    this.phone,
    this.phoneMasked,
    this.pinLength = 4,
    this.isSubmitting = false,
    this.errorMessage,
    this.pinLocked = false,
  });

  bool get isAuthenticated => status == VendorAuthStatus.authenticated;

  VendorAuthState copyWith({
    VendorAuthStatus? status,
    ActivationStep? activationStep,
    String? phone,
    String? phoneMasked,
    int? pinLength,
    bool? isSubmitting,
    bool? pinLocked,
    // Sentinelle explicite : `copyWith(errorMessage: null)` doit effacer
    // l'erreur, ce qu'un `??` ne permet pas d'exprimer.
    Object? errorMessage = _unchanged,
  }) {
    return VendorAuthState(
      status: status ?? this.status,
      activationStep: activationStep ?? this.activationStep,
      phone: phone ?? this.phone,
      phoneMasked: phoneMasked ?? this.phoneMasked,
      pinLength: pinLength ?? this.pinLength,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pinLocked: pinLocked ?? this.pinLocked,
      errorMessage: errorMessage == _unchanged
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  static const _unchanged = Object();
}

class VendorAuthController extends Notifier<VendorAuthState> {
  /// Jetons d'étape, gardés en mémoire seulement : ils expirent en 10 minutes
  /// et ne doivent pas survivre à la fermeture de l'app.
  String? _onboardingToken;
  String? _pinSetupToken;

  VendorAuthRepository get _repository => ref.read(vendorAuthRepositoryProvider);

  @override
  VendorAuthState build() {
    // Une session rejetée par l'API (refresh token mort) ramène à l'écran de
    // connexion sans redémarrage de l'app.
    ref.listen(sessionExpiredProvider, (_, expired) {
      if (expired) _resetToEntryScreen();
    });

    final snapshot = ref.read(sessionStoreProvider).snapshot;
    return VendorAuthState(
      status: _statusFrom(snapshot),
      phone: snapshot.phone,
    );
  }

  VendorAuthStatus _statusFrom(SessionSnapshot snapshot) {
    if (snapshot.hasTokens) return VendorAuthStatus.authenticated;
    if (snapshot.phone != null && snapshot.pinConfigured) {
      return VendorAuthStatus.needsPin;
    }
    return VendorAuthStatus.needsActivation;
  }

  void clearError() => state = state.copyWith(errorMessage: null);

  /// Étape 1 : téléphone + mot de passe temporaire.
  Future<bool> startActivation({
    required String phone,
    required String password,
  }) {
    return _run(() async {
      final challenge = await _repository.startActivation(
        phone: phone,
        password: password,
      );
      _onboardingToken = challenge.onboardingToken;
      state = state.copyWith(
        activationStep: ActivationStep.otp,
        phone: phone,
        phoneMasked: challenge.phoneMasked,
        pinLength: challenge.pinLength,
        errorMessage: null,
      );
      return true;
    });
  }

  Future<bool> resendOtp() {
    final token = _onboardingToken;
    final phone = state.phone;
    if (token == null || phone == null) return Future.value(false);

    return _run(() async {
      final challenge = await _repository.resendActivationOtp(
        onboardingToken: token,
        phone: phone,
      );
      _onboardingToken = challenge.onboardingToken;
      state = state.copyWith(
        phoneMasked: challenge.phoneMasked,
        errorMessage: null,
      );
      return true;
    });
  }

  /// Étape 2 : code reçu par SMS.
  Future<bool> verifyOtp(String code) {
    final token = _onboardingToken;
    if (token == null) {
      state = state.copyWith(
        activationStep: ActivationStep.credentials,
        errorMessage: 'Session d’activation expirée. Recommence la connexion.',
      );
      return Future.value(false);
    }

    return _run(() async {
      final grant = await _repository.verifyActivationOtp(
        onboardingToken: token,
        code: code,
      );
      _pinSetupToken = grant.pinSetupToken;
      state = state.copyWith(
        activationStep: ActivationStep.pinSetup,
        pinLength: grant.pinLength,
        errorMessage: null,
      );
      return true;
    });
  }

  /// Étape 3 : pose du code PIN, qui ouvre la session.
  Future<bool> confirmPin(String pin) {
    final token = _pinSetupToken;
    final phone = state.phone;
    if (token == null || phone == null) {
      state = state.copyWith(
        activationStep: ActivationStep.credentials,
        errorMessage: 'Session d’activation expirée. Recommence la connexion.',
      );
      return Future.value(false);
    }

    return _run(() async {
      await _repository.completeActivation(
        pinSetupToken: token,
        pin: pin,
        phone: phone,
      );
      _clearStepTokens();
      ref.read(sessionExpiredProvider.notifier).state = false;
      state = state.copyWith(
        status: VendorAuthStatus.authenticated,
        activationStep: ActivationStep.done,
        errorMessage: null,
      );
      return true;
    });
  }

  /// Reconnexion au code PIN.
  Future<bool> loginWithPin(String pin) {
    final phone = state.phone;
    if (phone == null) {
      _resetToEntryScreen();
      return Future.value(false);
    }

    return _run(() async {
      await _repository.loginWithPin(phone: phone, pin: pin);
      ref.read(sessionExpiredProvider.notifier).state = false;
      state = state.copyWith(
        status: VendorAuthStatus.authenticated,
        errorMessage: null,
        pinLocked: false,
      );
      return true;
    });
  }

  Future<void> logout() async {
    await _repository.logout();
    _clearStepTokens();
    ref.read(sessionExpiredProvider.notifier).state = false;
    _resetToEntryScreen();
  }

  /// Relance le parcours d'activation sans déconnecter : le mot de passe
  /// temporaire reste le seul moyen de poser un nouveau PIN.
  ///
  /// On pousse `VendorActivationPage` via `Navigator`, pas via go_router :
  /// une route `/activate` alors que la session est encore valide renverrait
  /// immédiatement au tableau de bord.
  void startPinChange() {
    _clearStepTokens();
    state = state.copyWith(
      activationStep: ActivationStep.credentials,
      errorMessage: null,
      isSubmitting: false,
      pinLocked: false,
    );
  }

  /// Annule un changement de PIN en cours (fermeture de la feuille).
  void cancelPinChange() {
    _clearStepTokens();
    state = state.copyWith(
      activationStep: ActivationStep.credentials,
      errorMessage: null,
      isSubmitting: false,
    );
  }

  /// « Utiliser un autre compte » : impose de repasser par l'activation.
  Future<void> forgetDevice() async {
    await _repository.forgetDevice();
    _clearStepTokens();
    ref.read(sessionExpiredProvider.notifier).state = false;
    state = const VendorAuthState(status: VendorAuthStatus.needsActivation);
  }

  /// Revenir à l'écran du numéro depuis l'écran OTP.
  void backToCredentials() {
    _clearStepTokens();
    state = state.copyWith(
      activationStep: ActivationStep.credentials,
      errorMessage: null,
    );
  }

  void _resetToEntryScreen() {
    final snapshot = ref.read(sessionStoreProvider).snapshot;
    state = VendorAuthState(
      status: _statusFrom(snapshot),
      phone: snapshot.phone,
    );
  }

  void _clearStepTokens() {
    _onboardingToken = null;
    _pinSetupToken = null;
  }

  /// Enveloppe commune : drapeau de soumission, traduction de l'erreur,
  /// détection du verrouillage du PIN.
  Future<bool> _run(Future<bool> Function() action) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);
    try {
      final result = await action();
      state = state.copyWith(isSubmitting: false);
      return result;
    } on ApiException catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: error.message,
        // 403 sur ce parcours signifie compte bloqué ou PIN verrouillé : dans
        // les deux cas, réessayer tout de suite est inutile.
        pinLocked: error.kind == ApiErrorKind.forbidden,
      );
      return false;
    } on PayloadException catch (error) {
      assert(false, 'Réponse inattendue de l’API : $error');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Réponse inattendue du serveur. Réessaie.',
      );
      return false;
    }
  }
}

final vendorAuthControllerProvider =
    NotifierProvider<VendorAuthController, VendorAuthState>(
      VendorAuthController.new,
    );
