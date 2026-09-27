import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/system_pin_field.dart';
import '../controllers/vendor_auth_controller.dart';

/// Reconnexion d'un vendeur déjà activé sur cet appareil.
class VendorPinLoginPage extends ConsumerStatefulWidget {
  const VendorPinLoginPage({super.key});

  @override
  ConsumerState<VendorPinLoginPage> createState() => _VendorPinLoginPageState();
}

class _VendorPinLoginPageState extends ConsumerState<VendorPinLoginPage> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final state = ref.read(vendorAuthControllerProvider);
    if (state.isSubmitting || state.pinLocked) return;
    ref.read(vendorAuthControllerProvider.notifier).clearError();
    setState(() {});
    if (value.length == state.pinLength) _submit();
  }

  Future<void> _submit() async {
    final pin = _controller.text;
    final ok = await ref
        .read(vendorAuthControllerProvider.notifier)
        .loginWithPin(pin);
    if (!ok && mounted) {
      _controller.clear();
      _focus.requestFocus();
    }
  }

  Future<void> _useAnotherAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Utiliser un autre compte ?'),
        content: const Text(
          'Ton code sera oublié sur cet appareil. Tu devras te reconnecter '
          'avec ton numéro et ton mot de passe temporaire.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(vendorAuthControllerProvider.notifier).forgetDevice();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorAuthControllerProvider);

    ref.listen<VendorAuthState>(vendorAuthControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message != previous?.errorMessage) {
        showAppSnackBar(context, message: message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.indigoDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: AppColors.accent,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text('Bon retour', style: AppTextStyles.heroTitle),
              const SizedBox(height: 6),
              Text(
                state.phone == null
                    ? 'Saisis ton code à ${state.pinLength} chiffres.'
                    : '+228 ${PhoneFormatter.formatDisplay(state.phone!)}',
                style: AppTextStyles.heroSubtitle,
              ),
              const SizedBox(height: 28),
              SystemPinField(
                controller: _controller,
                focusNode: _focus,
                length: state.pinLength,
                enabled: !state.isSubmitting && !state.pinLocked,
                onChanged: _onChanged,
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: state.isSubmitting
                    ? const CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2,
                      )
                    : const SizedBox.shrink(),
              ),
              const Spacer(),
              TextButton(
                onPressed: state.isSubmitting ? null : _useAnotherAccount,
                child: Text(
                  'Utiliser un autre compte',
                  style: AppTextStyles.resendText.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
