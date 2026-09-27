import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../../../shared/widgets/vendor_input.dart';
import '../../../vendor/data/vendor_profile_repository.dart';
import '../../data/catalog_repository.dart';
import '../../domain/menu_item.dart';

class VendorMenuPage extends ConsumerWidget {
  const VendorMenuPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menu = ref.watch(vendorMenuProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Mon menu',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: menu.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Impossible de charger le menu.',
                  style: AppTextStyles.emptySub,
                ),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    title: 'Aucun plat pour l’instant',
                    subtitle:
                        'Ajoute tes articles pour que les étudiants puissent commander.',
                    icon: Icons.restaurant_menu_rounded,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(vendorMenuProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: page.items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: 10),
                    itemBuilder: (_, index) =>
                        _MenuTile(item: page.items[index]),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: KabaButton(
                text: 'Ajouter un plat',
                icon: const Icon(
                  Icons.add_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                onPressed: () => _openEditor(context, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends ConsumerWidget {
  final MenuItemModel item;
  const _MenuTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTextStyles.txTitle),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatTickets(item.priceTickets),
                  style: AppTextStyles.txMeta,
                ),
                if (item.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.emptySub,
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Switch.adaptive(
                value: item.isAvailable,
                activeThumbColor: AppColors.green,
                onChanged: (value) async {
                  try {
                    await ref
                        .read(catalogRepositoryProvider)
                        .setAvailable(item.id, value);
                    ref.invalidate(vendorMenuProvider);
                  } on ApiException catch (error) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error.message)));
                    }
                  }
                },
              ),
              Text(
                item.isAvailable ? 'Disponible' : 'Indisponible',
                style: AppTextStyles.txMeta,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
  final created = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _CreateItemSheet(),
  );
  if (created == true) ref.invalidate(vendorMenuProvider);
}

class _CreateItemSheet extends ConsumerStatefulWidget {
  const _CreateItemSheet();

  @override
  ConsumerState<_CreateItemSheet> createState() => _CreateItemSheetState();
}

class _CreateItemSheetState extends ConsumerState<_CreateItemSheet> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim());
    if (name.isEmpty || price == null || price < 0) {
      setState(
        () => _error = 'Indique un nom et un prix en tickets (nombre entier).',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final vendor = await ref.read(currentVendorProvider.future);
      await ref
          .read(catalogRepositoryProvider)
          .createItem(
            vendorId: vendor.id,
            name: name,
            description: _description.text.trim(),
            priceTickets: price,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      setState(() {
        _saving = false;
        _error = error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 18, 16, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Nouveau plat', style: AppTextStyles.promptTitle),
          const SizedBox(height: 16),
          VendorInput(
            label: 'NOM',
            hintText: 'Riz sauce arachide',
            controller: _name,
          ),
          const SizedBox(height: 12),
          VendorInput(
            label: 'PRIX (TICKETS)',
            hintText: '15',
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          VendorInput(
            label: 'DESCRIPTION (OPTIONNEL)',
            hintText: 'Ingrédients, portion…',
            controller: _description,
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: AppTextStyles.hintText.copyWith(color: AppColors.error)),
          ],
          const SizedBox(height: 18),
          KabaButton(
            text: 'Enregistrer',
            isLoading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
