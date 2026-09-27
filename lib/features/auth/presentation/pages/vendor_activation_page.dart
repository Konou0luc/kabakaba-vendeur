import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/system_pin_field.dart';
import '../../../../shared/widgets/vendeur_auth_scaffold.dart';
import '../../../../shared/widgets/vendor_input.dart';
import '../controllers/vendor_auth_controller.dart';
import '../widgets/otp_input.dart';

/// Activation d'un compte vendeur, en trois étapes dans un seul écran.
///
/// Les trois étapes partagent un état serveur (les jetons intermédiaires) qui
/// expire en dix minutes : les enchaîner dans des routes distinctes exposerait
/// au retour arrière matériel au milieu du parcours, avec un jeton d'étape
/// devenu invalide et aucun moyen de repartir proprement.
class VendorActivationPage extends ConsumerWidget {
  /// `true` quand la page est poussée au-dessus du tableau de bord (changement
  /// de PIN) : on referme la route au succès, au lieu de laisser go_router
  /// décider.
  final bool popOnSuccess;

  const VendorActivationPage({super.key, this.popOnSuccess = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorAuthControllerProvider);

    ref.listen<VendorAuthState>(vendorAuthControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage) {
        showAppSnackBar(context, message: message);
      }
      if (!popOnSuccess) return;
      if (next.activationStep == ActivationStep.done &&
          next.status == VendorAuthStatus.authenticated) {
        Navigator.of(context).pop();
      }
    });

    final (step, title, subtitle, body) = switch (state.activationStep) {
      ActivationStep.credentials => (
        1,
        'Connexion vendeur',
        'Saisis ton numéro et le mot de passe temporaire reçu de l’administration.',
        const _CredentialsStep(),
      ),
      ActivationStep.otp => (
        2,
        'Vérification SMS',
        'Saisis le code à 6 chiffres envoyé au ${state.phoneMasked ?? 'numéro indiqué'}.',
        const _OtpStep(),
      ),
      ActivationStep.pinSetup || ActivationStep.done => (
        3,
        'Crée ton code',
        'Ce code à ${state.pinLength} chiffres remplacera ton mot de passe temporaire.',
        const _PinSetupStep(),
      ),
    };

    final scaffold = VendeurAuthScaffold(
      currentStep: step,
      totalSteps: 3,
      heroIcon: Icons.storefront_rounded,
      heroTitle: title,
      heroSubtitle: subtitle,
      showBackButton:
          popOnSuccess || state.activationStep != ActivationStep.credentials,
      onBack: () {
        if (state.activationStep == ActivationStep.credentials) {
          if (popOnSuccess) {
            ref.read(vendorAuthControllerProvider.notifier).cancelPinChange();
            Navigator.of(context).pop();
          }
          return;
        }
        ref.read(vendorAuthControllerProvider.notifier).backToCredentials();
      },
      body: body,
    );

    if (!popOnSuccess) return scaffold;

    return PopScope(
      canPop: state.activationStep == ActivationStep.credentials,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(vendorAuthControllerProvider.notifier).cancelPinChange();
        } else {
          ref.read(vendorAuthControllerProvider.notifier).backToCredentials();
        }
      },
      child: scaffold,
    );
  }
}

class _CredentialsStep extends ConsumerStatefulWidget {
  const _CredentialsStep();

  @override
  ConsumerState<_CredentialsStep> createState() => _CredentialsStepState();
}

class _CredentialsStepState extends ConsumerState<_CredentialsStep> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final knownPhone = ref.read(vendorAuthControllerProvider).phone;
    if (knownPhone != null) {
      _phoneController.text = PhoneFormatter.formatDisplay(knownPhone);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!PhoneFormatter.isValidLocal(_phoneController.text)) {
      showAppSnackBar(context, message: 'Saisis un numéro à 8 chiffres.');
      return;
    }
    if (_passwordController.text.isEmpty) {
      showAppSnackBar(
        context,
        message: 'Saisis ton mot de passe temporaire.',
      );
      return;
    }
    FocusScope.of(context).unfocus();

    await ref
        .read(vendorAuthControllerProvider.notifier)
        .startActivation(
          phone: PhoneFormatter.toE164(_phoneController.text),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorAuthControllerProvider);

    return Column(
      children: [
        VendorInput(
          label: 'NUMÉRO DE TÉLÉPHONE',
          hintText: '90 12 34 56',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: const [TogoPhoneInputFormatter()],
          autofocus: true,
          prefixIcon: const Icon(Icons.phone_rounded),
          prefixText: '+228',
        ),
        const SizedBox(height: 14),
        VendorInput(
          label: 'MOT DE PASSE TEMPORAIRE',
          hintText: '••••••••',
          controller: _passwordController,
          obscureText: _obscurePassword,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Icon(
              _obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 18,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Le mot de passe temporaire t’est remis par l’administration '
                  'kabakaba. Tu ne l’utiliseras qu’une fois : ensuite, ton code '
                  'à 4 chiffres suffira.',
                  style: AppTextStyles.hintText,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        KabaButton(
          text: 'Continuer',
          icon: const Icon(Icons.sms_rounded, color: Colors.white, size: 16),
          isLoading: state.isSubmitting,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _OtpStep extends ConsumerStatefulWidget {
  const _OtpStep();

  @override
  ConsumerState<_OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends ConsumerState<_OtpStep> {
  static const _resendDelay = Duration(seconds: 60);

  String _code = '';
  int _resetToken = 0;
  int _secondsLeft = _resendDelay.inSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _resendDelay.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _verify(String code) async {
    FocusScope.of(context).unfocus();
    final ok = await ref
        .read(vendorAuthControllerProvider.notifier)
        .verifyOtp(code);
    // Code refusé : on vide les cases, sinon le vendeur doit effacer six
    // chiffres à la main avant de pouvoir retenter.
    if (!ok && mounted) setState(() => _resetToken++);
  }

  Future<void> _resend() async {
    final ok = await ref.read(vendorAuthControllerProvider.notifier).resendOtp();
    if (!mounted) return;
    setState(() => _resetToken++);
    if (ok) _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorAuthControllerProvider);
    final canResend = _secondsLeft <= 0 && !state.isSubmitting;

    return Column(
      children: [
        const SizedBox(height: 6),
        Text('Code de vérification', style: AppTextStyles.flowTitle),
        const SizedBox(height: 10),
        OtpInput(
          enabled: !state.isSubmitting,
          resetToken: _resetToken,
          onChanged: (code) => setState(() => _code = code),
          onCompleted: _verify,
        ),
        const SizedBox(height: 12),
        Text(
          _secondsLeft > 0
              ? 'Renvoyer le code dans ${CurrencyFormatter.formatCountdown(_secondsLeft)}'
              : 'Tu peux demander un nouveau code.',
          style: AppTextStyles.timerText,
        ),
        if (_secondsLeft <= 0)
          TextButton(
            onPressed: canResend ? _resend : null,
            child: Text(
              'Renvoyer le code',
              style: AppTextStyles.resendText.copyWith(color: AppColors.accent),
            ),
          ),
        const SizedBox(height: 16),
        KabaButton(
          text: 'Vérifier',
          isLoading: state.isSubmitting,
          onPressed: _code.length == OtpInput.digitCount
              ? () => _verify(_code)
              : null,
        ),
      ],
    );
  }
}

class _PinSetupStep extends ConsumerStatefulWidget {
  const _PinSetupStep();

  @override
  ConsumerState<_PinSetupStep> createState() => _PinSetupStepState();
}

class _PinSetupStepState extends ConsumerState<_PinSetupStep> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String _pin = '';
  String _confirmation = '';
  bool _isConfirming = false;

  int get _pinLength => ref.read(vendorAuthControllerProvider).pinLength;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    if (ref.read(vendorAuthControllerProvider).isSubmitting) return;

    if (!_isConfirming) {
      setState(() => _pin = value);
      if (value.length == _pinLength) {
        setState(() => _isConfirming = true);
        _controller.clear();
        _focus.requestFocus();
      }
      return;
    }

    setState(() => _confirmation = value);
    if (value.length == _pinLength) _submit();
  }

  void _editFirstPin() {
    setState(() {
      _isConfirming = false;
      _confirmation = '';
      _controller.text = _pin;
      _controller.selection = TextSelection.collapsed(offset: _pin.length);
    });
    _focus.requestFocus();
  }

  Future<void> _submit() async {
    if (_pin != _confirmation) {
      setState(() => _confirmation = '');
      _controller.clear();
      _focus.requestFocus();
      showAppSnackBar(
        context,
        message: 'Les deux codes ne correspondent pas.',
      );
      return;
    }

    final ok = await ref
        .read(vendorAuthControllerProvider.notifier)
        .confirmPin(_pin);
    // PIN refusé par le serveur (trop simple) : on repart de la première
    // saisie, la confirmation n'a plus de sens.
    if (!ok && mounted) {
      setState(() {
        _pin = '';
        _confirmation = '';
        _isConfirming = false;
        _controller.clear();
      });
      _focus.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorAuthControllerProvider);

    return Column(
      children: [
        const SizedBox(height: 6),
        Text(
          _isConfirming ? 'Confirme ton code' : 'Choisis ton code',
          style: AppTextStyles.flowTitle,
        ),
        const SizedBox(height: 18),
        SystemPinField(
          controller: _controller,
          focusNode: _focus,
          length: state.pinLength,
          enabled: !state.isSubmitting,
          onChanged: _onChanged,
        ),
        const SizedBox(height: 10),
        Text(
          'Évite 0000, 1234 ou une suite de chiffres identiques.',
          textAlign: TextAlign.center,
          style: AppTextStyles.hintText,
        ),
        if (_isConfirming)
          TextButton(
            onPressed: state.isSubmitting ? null : _editFirstPin,
            child: Text(
              'Modifier le code',
              style: AppTextStyles.resendText.copyWith(color: AppColors.accent),
            ),
          ),
        if (state.isSubmitting) ...[
          const SizedBox(height: 12),
          const CircularProgressIndicator(color: AppColors.accent),
        ],
      ],
    );
  }
}
