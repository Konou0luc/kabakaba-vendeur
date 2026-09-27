import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/vendor_input.dart';
import '../../../../shared/widgets/vendeur_auth_scaffold.dart';
import '../../data/vendor_auth_provider.dart';

class VendorLoginPage extends ConsumerStatefulWidget {
  const VendorLoginPage({super.key});
  @override
  ConsumerState<VendorLoginPage> createState() => _VendorLoginPageState();
}

class _VendorLoginPageState extends ConsumerState<VendorLoginPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  int _otpTimer = 60;
  Timer? _timer;
  bool _otpSent = false;

  @override
  void dispose() {
    _timer?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String _phoneForApi() {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('228') ? '+$digits' : '+228$digits';
  }

  Future<void> _sendOtp() async {
    final localDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (localDigits.length < 8) {
      _showError('Saisis un numéro à 8 chiffres.');
      return;
    }
    final phone = _phoneForApi();
    final ok = await ref.read(vendorAuthProvider.notifier).sendOtp(phone);
    if (ok && mounted) {
      setState(() {
        _otpSent = true;
        _otpTimer = 60;
      });
      _startTimer();
    } else if (mounted) {
      final error = ref.read(vendorAuthProvider).error;
      _showError(
        error != null && error.isNotEmpty
            ? error
            : 'Impossible de joindre le serveur. Vérifie que le backend est lancé.',
      );
    }
  }

  Future<void> _verifyOtp() async {
    final code = _otpController.text;
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('Saisis les 6 chiffres du code reçu par SMS.');
      return;
    }
    FocusScope.of(context).unfocus();
    final phone = _phoneForApi();
    final ok = await ref
        .read(vendorAuthProvider.notifier)
        .verifyOtp(phone, code);
    if (ok && mounted) {
      context.go('/dashboard');
    } else if (mounted) {
      final error = ref.read(vendorAuthProvider).error;
      final message = error != null && error.contains('campus est obligatoire')
          ? 'Ce numéro n’est pas associé à un compte vendeur. Demande à un administrateur de créer le compte vendeur avant de te connecter.'
          : error != null && error.isNotEmpty
          ? error
          : 'Le code est invalide ou le serveur est indisponible.';
      _showError(message);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_otpTimer > 0) {
          _otpTimer--;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _goBackToPhone() {
    _timer?.cancel();
    _otpController.clear();
    setState(() {
      _otpSent = false;
      _otpTimer = 60;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(vendorAuthProvider);

    return VendeurAuthScaffold(
      currentStep: _otpSent ? 2 : 1,
      totalSteps: 2,
      heroIcon: Icons.storefront_rounded,
      heroTitle: _otpSent ? 'Vérification SMS' : 'Connexion vendeur',
      heroSubtitle: _otpSent
          ? 'Saisis le code à 6 chiffres reçu sur ton numéro.'
          : 'Saisis le numéro de téléphone associé à ton compte kabakaba.',
      showBackButton: _otpSent,
      onBack: _otpSent ? _goBackToPhone : null,
      body: _otpSent
          ? _OtpSection(
              controller: _otpController,
              timerSeconds: _otpTimer,
              onVerify: _verifyOtp,
              onResend: _sendOtp,
              isLoading: auth.isLoading,
            )
          : Column(
              children: [
                VendorInput(
                  label: 'NUMÉRO DE TÉLÉPHONE',
                  hintText: '90 12 34 56',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  maxLength: 11,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  autofocus: true,
                  onChanged: (v) {
                    final formatted = PhoneFormatter.formatDisplay(v);
                    if (formatted != _phoneController.text) {
                      _phoneController.value = TextEditingValue(
                        text: formatted,
                        selection: TextSelection.collapsed(
                          offset: formatted.length,
                        ),
                      );
                    }
                  },
                  prefixIcon: const Icon(Icons.phone_rounded),
                  prefixText: '+228',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.28),
                    ),
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
                          'kabakaba t\'enverra un code SMS à ce numéro pour te connecter.',
                          style: AppTextStyles.hintText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                KabaButton(
                  text: 'Envoyer le code',
                  icon: const Icon(
                    Icons.sms_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  isLoading: auth.isLoading,
                  onPressed: _sendOtp,
                ),
              ],
            ),
    );
  }
}

class _OtpSection extends StatefulWidget {
  final TextEditingController controller;
  final int timerSeconds;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final bool isLoading;

  const _OtpSection({
    required this.controller,
    required this.timerSeconds,
    required this.onVerify,
    required this.onResend,
    required this.isLoading,
  });

  @override
  State<_OtpSection> createState() => _OtpSectionState();
}

class _OtpSectionState extends State<_OtpSection> {
  static const _digitCount = 6;
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(_digitCount, (index) {
      final controller = TextEditingController();
      if (index < widget.controller.text.length) {
        controller.text = widget.controller.text[index];
      }
      return controller;
    });
    _focusNodes = List.generate(_digitCount, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _OtpSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timerSeconds == 0 && widget.timerSeconds > 0) {
      for (final controller in _digitControllers) {
        controller.clear();
      }
      widget.controller.clear();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes.first.requestFocus();
      });
      setState(() {});
    }
  }

  void _syncCode() {
    widget.controller.text = _digitControllers.map((item) => item.text).join();
  }

  void _handleInput(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      final count = (digits.length).clamp(0, _digitCount - index);
      for (var offset = 0; offset < count; offset++) {
        _digitControllers[index + offset].text = digits[offset];
      }
      for (var i = index + count; i < _digitCount; i++) {
        _digitControllers[i].clear();
      }
      _syncCode();
      if (index + count == _digitCount) {
        _focusNodes.last.unfocus();
      } else {
        _focusNodes[index + count].requestFocus();
      }
      setState(() {});
      return;
    }

    final digit = digits.isEmpty ? '' : digits;
    _digitControllers[index].value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
    _syncCode();

    if (digit.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    } else if (digit.isNotEmpty && index < _digitCount - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (digit.isNotEmpty) {
      _focusNodes[index].unfocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        Text('Code de vérification', style: AppTextStyles.flowTitle),
        const SizedBox(height: 10),
        AutofillGroup(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_digitCount, (i) {
              return Padding(
                padding: EdgeInsets.only(right: i < _digitCount - 1 ? 5 : 0),
                child: SizedBox(
                  width: 36,
                  height: 48,
                  child: TextField(
                    controller: _digitControllers[i],
                    focusNode: _focusNodes[i],
                    textAlign: TextAlign.center,
                    style: AppTextStyles.otpDigit,
                    keyboardType: TextInputType.number,
                    textInputAction: i < _digitCount - 1
                        ? TextInputAction.next
                        : TextInputAction.done,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofillHints: i == 0
                        ? const [AutofillHints.oneTimeCode]
                        : null,
                    enableSuggestions: false,
                    enabled: !widget.isLoading,
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: _digitControllers[i].text.isNotEmpty
                          ? AppColors.accent.withValues(alpha: 0.12)
                          : AppColors.field,
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(color: AppColors.line),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                        borderSide: BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) => _handleInput(i, value),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.timerSeconds > 0
              ? 'Renvoyer le code dans ${CurrencyFormatter.formatCountdown(widget.timerSeconds)}'
              : "Tu peux renvoyer le code.",
          style: AppTextStyles.timerText,
        ),
        if (widget.timerSeconds == 0)
          TextButton(
            onPressed: widget.isLoading ? null : widget.onResend,
            child: Text(
              'Renvoyer le code',
              style: AppTextStyles.resendText.copyWith(color: AppColors.accent),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onVerify,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Vérifier',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
        ),
      ],
    );
  }
}
