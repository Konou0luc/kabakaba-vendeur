import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/vendor_model.dart';
import '../../../../shared/widgets/hint_box.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../../withdrawals/domain/withdrawal_models.dart';
import 'vendor_withdraw_confirm_page.dart';

class VendorWithdrawMethodPage extends ConsumerStatefulWidget {
  final VendorModel vendor;
  final int amount;

  const VendorWithdrawMethodPage({
    super.key,
    required this.vendor,
    required this.amount,
  });

  @override
  ConsumerState<VendorWithdrawMethodPage> createState() =>
      _VendorWithdrawMethodPageState();
}

class _VendorWithdrawMethodPageState
    extends ConsumerState<VendorWithdrawMethodPage> {
  WithdrawalOperator _selected = WithdrawalOperator.flooz;

  @override
  Widget build(BuildContext context) {
    final phone = widget.vendor.phone ?? 'Numéro non renseigné';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Moyen de retrait',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '${widget.amount} FCFA vers',
                    style: AppTextStyles.sectionLabel,
                  ),
                ),
                _MethodRow(
                  logo: 'Moov',
                  logoColor: const Color(0xFF0057B8),
                  name: WithdrawalOperator.flooz.label,
                  sub: phone,
                  selected: _selected == WithdrawalOperator.flooz,
                  onTap: () =>
                      setState(() => _selected = WithdrawalOperator.flooz),
                ),
                _MethodRow(
                  logo: 'T-M',
                  logoColor: const Color(0xFFFCC93B),
                  logoTextColor: AppColors.textPrimaryLight,
                  name: WithdrawalOperator.mixx.label,
                  sub: phone,
                  selected: _selected == WithdrawalOperator.mixx,
                  onTap: () =>
                      setState(() => _selected = WithdrawalOperator.mixx),
                ),
                const SizedBox(height: 8),
                const HintBox(
                  message:
                      'Le numéro affiché est celui renseigné à la création de ton compte. Contacte kabakaba pour le modifier.',
                  icon: Icons.info_outline_rounded,
                  isLight: true,
                ),
                const SizedBox(height: 24),
                KabaButton(
                  text: 'Continuer',
                  icon: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VendorWithdrawConfirmPage(
                          vendor: widget.vendor,
                          amount: widget.amount,
                          operator: _selected,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final String logo;
  final Color logoColor;
  final Color? logoTextColor;
  final String name;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  const _MethodRow({
    required this.logo,
    required this.logoColor,
    required this.name,
    required this.sub,
    required this.selected,
    required this.onTap,
    this.logoTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.indigoLight : Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x141B2A6B),
              blurRadius: 18,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: logoColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  logo,
                  style: TextStyle(
                    color: logoTextColor ?? Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTextStyles.methodRowName),
                  Text(sub, style: AppTextStyles.methodRowSub),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 19,
              height: 19,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primary : AppColors.borderLight,
                  width: 2,
                ),
              ),
              child: Center(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? AppColors.primary : Colors.transparent,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
