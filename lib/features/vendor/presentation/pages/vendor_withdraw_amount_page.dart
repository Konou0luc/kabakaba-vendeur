import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/vendor_model.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import 'vendor_withdraw_method_page.dart';

class VendorWithdrawAmountPage extends ConsumerStatefulWidget {
  final VendorModel vendor;
  const VendorWithdrawAmountPage({super.key, required this.vendor});

  @override
  ConsumerState<VendorWithdrawAmountPage> createState() =>
      _VendorWithdrawAmountPageState();
}

class _VendorWithdrawAmountPageState
    extends ConsumerState<VendorWithdrawAmountPage> {
  late final TextEditingController _amountController =
      TextEditingController();
  int? _selectedPreset;
  String? _tier;

  @override
  void initState() {
    super.initState();
    _tier = _computeTier();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String? _computeTier() {
    final amount = int.tryParse(_amountController.text);
    if (amount == null) return null;
    if (amount < 10000) return 'low';
    if (amount < 30000) return 'mid';
    return 'high';
  }

  void _onAmountChange(String v) {
    setState(() {
      _selectedPreset = null;
      _tier = _computeTier();
    });
  }

  void _selectPreset(int amount) {
    setState(() {
      _amountController.text = amount.toString();
      _amountController.selection = TextSelection.collapsed(
          offset: _amountController.text.length);
      _selectedPreset = amount;
      _tier = _computeTier();
    });
  }

  void _selectAll() {
    setState(() {
      _amountController.text = widget.vendor.balanceFcfa.toInt().toString();
      _amountController.selection = TextSelection.collapsed(
          offset: _amountController.text.length);
      _selectedPreset = -1;
      _tier = _computeTier();
    });
  }

  bool get _isValid {
    final amount = int.tryParse(_amountController.text) ?? 0;
    return amount > 0 && amount <= widget.vendor.balanceFcfa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Retirer des fonds',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x141B2A6B),
                          blurRadius: 18,
                          offset: Offset(0, 4))
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('MONTANT À RETIRER',
                            style: AppTextStyles.fieldCardLabel),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        onChanged: _onAmountChange,
                        style: AppTextStyles.amountDisplay,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text('FCFA',
                          style: TextStyle(
                            color: AppColors.textSecondaryLight,
                            fontSize: 16,
                          )),                      const SizedBox(height: 4),
                      Text(
                        'Solde disponible : ${CurrencyFormatter.formatTickets(widget.vendor.balanceFcfa)}',
                        style: AppTextStyles.amountSub,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                              child: _Preset(
                                  label: '5 000',
                                  selected: _selectedPreset == 5000,
                                  onTap: () => _selectPreset(5000))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _Preset(
                                  label: '12 000',
                                  selected: _selectedPreset == 12000,
                                  onTap: () => _selectPreset(12000))),
                          const SizedBox(width: 8),
                          Expanded(
                              child: _Preset(
                                  label: 'Tout retirer',
                                  selected: _selectedPreset == -1,
                                  onTap: _selectAll)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _TierBox(activeTier: _tier),
                const SizedBox(height: 24),
                KabaButton(
                  text: 'Continuer',
                  icon: const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 16),
                  onPressed: _isValid
                      ? () {
                          final amount =
                              int.parse(_amountController.text);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => VendorWithdrawMethodPage(
                              vendor: widget.vendor,
                              amount: amount,
                            ),
                          ));
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Preset(
      {required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.borderLight,
              width: 1.5),
          color: selected ? AppColors.orangeLight : Colors.transparent,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.presetChip.copyWith(
              color: selected
                  ? AppColors.accent
                  : AppColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

class _TierBox extends StatelessWidget {
  final String? activeTier;
  const _TierBox({this.activeTier});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.indigoLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: _title(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const TextSpan(
                  text:
                      ' Les frais vers l\'opérateur mobile money sont pris en charge par kabakaba. Les frais de retrait de l\'opérateur restent à ta charge.',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _TierRow(
                label: '< 10 000 FCFA — tous frais à ta charge',
                active: activeTier == 'low',
              ),
              _TierRow(
                label:
                    '10 000 – 29 999 FCFA — frais plateforme couverts',
                active: activeTier == 'mid',
              ),
              _TierRow(
                label: '≥ 30 000 FCFA — tous frais couverts',
                active: activeTier == 'high',
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _title() {
    switch (activeTier) {
      case 'low':
        return 'Palier applicable : moins de 10 000 FCFA.';
      case 'mid':
        return 'Palier applicable : 10 000 FCFA et plus.';
      case 'high':
        return 'Palier applicable : 30 000 FCFA et plus.';
      default:
        return 'Palier applicable : en attente de saisie.';
    }
  }
}

class _TierRow extends StatelessWidget {
  final String label;
  final bool active;
  const _TierRow({required this.label, required this.active});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.white.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.primary
                  : AppColors.textSecondaryLight.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondaryLight,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
