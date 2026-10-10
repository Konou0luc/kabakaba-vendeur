import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/models/vendor_model.dart';
import '../../../../shared/widgets/remote_photo.dart';
import '../../../../shared/widgets/vendor_header.dart';
import '../../../auth/presentation/controllers/vendor_auth_controller.dart';
import '../../../auth/presentation/pages/vendor_activation_page.dart';
import '../../../catalog/presentation/pages/vendor_menu_page.dart';
import '../../../notifications/data/notifications_repository.dart';
import '../../../notifications/presentation/pages/vendor_notifications_page.dart';
import '../../../schedules/presentation/pages/vendor_schedules_page.dart';
import '../../data/vendor_profile_repository.dart';

class VendorProfilePage extends ConsumerWidget {
  const VendorProfilePage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorAsync = ref.watch(currentVendorProvider);
    return Column(
      children: [
        VendorHeader(
          vendor: vendorAsync.value,
          showNotification: true,
          hasUnreadNotifications:
              ref.watch(unreadNotificationsCountProvider) > 0,
          onNotificationTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const VendorNotificationsPage(),
              ),
            );
          },
        ),
        Expanded(
          child: vendorAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Profil indisponible')),
            data: (v) => _LoadedProfile(vendor: v),
          ),
        ),
      ],
    );
  }
}

class _LoadedProfile extends ConsumerWidget {
  final VendorModel vendor;
  const _LoadedProfile({required this.vendor});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F1B2A6B),
                blurRadius: 18,
                offset: Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              RemotePhoto(
                url: vendor.bannerUrl,
                width: double.infinity,
                height: 120,
                radius: 0,
                fallback: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.primary, AppColors.indigoDark],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -18),
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: RemotePhoto(
                          url: vendor.logoUrl,
                          width: 64,
                          height: 64,
                          radius: 15,
                          fallback: Center(
                            child: Text(
                              vendor.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vendor.canteenName,
                              style: AppTextStyles.profileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.indigoLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    vendor.campusName.isNotEmpty
                                        ? vendor.campusName
                                        : 'Campus UCAO',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Vendeur actif',
                                  style: AppTextStyles.profileMeta,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Disponibilité'),
        _SettingsCard(
          children: [
            _ToggleRow(
              title: 'Cantine ouverte',
              sub: 'Visible et commandable par les étudiants',
              value: vendor.isOpen,
              onChanged: (open) async {
                try {
                  await ref
                      .read(vendorProfileRepositoryProvider)
                      .setOpen(open);
                  ref.invalidate(currentVendorProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Modification impossible.')),
                    );
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Carte'),
        _SettingsCard(
          children: [
            _NavRow(
              icon: Icons.restaurant_menu_rounded,
              title: 'Gérer mon menu',
              sub: 'Plats, prix, disponibilité',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const VendorMenuPage()),
                );
              },
            ),
            _NavRow(
              icon: Icons.schedule_rounded,
              title: 'Horaires d’ouverture',
              sub: 'Jours et plages affichés aux étudiants',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendorSchedulesPage(),
                  ),
                );
              },
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Établissement'),
        _SettingsCard(
          children: [
            _FieldRow(
              label: 'Géré par kabakaba',
              value: vendor.canteenName,
              icon: Icons.lock_rounded,
            ),
            _FieldRow(
              label: 'Campus affilié',
              value: vendor.campusName.isNotEmpty ? vendor.campusName : '—',
            ),
            _FieldRow(
              label: 'Numéro de contact',
              value: vendor.phone ?? '—',
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Sécurité'),
        _SettingsCard(
          children: [
            _NavRow(
              icon: Icons.shield_rounded,
              title: 'Modifier mon code PIN',
              sub: 'Mot de passe temporaire, puis nouveau code',
              onTap: () {
                ref.read(vendorAuthControllerProvider.notifier).startPinChange();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const VendorActivationPage(popOnSuccess: true),
                  ),
                );
              },
            ),
            _NavRow(
              icon: Icons.notifications_rounded,
              title: 'Notifications',
              sub: 'Nouvelles commandes, créance, retraits',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const VendorNotificationsPage(),
                  ),
                );
              },
              isLast: true,
            ),
          ],
        ),
        const SizedBox(height: 18),
        const _SectionTitle('Compte'),
        _SettingsCard(
          children: [
            _NavRow(
              icon: Icons.power_settings_new_rounded,
              title: 'Se déconnecter',
              iconColor: AppColors.red,
              iconBg: AppColors.redLight,
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => _LogoutDialog(),
                );
                if (ok == true) {
                  await ref.read(vendorAuthControllerProvider.notifier).logout();
                  if (context.mounted) context.go('/pin');
                }
              },
              isLast: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle(this.label);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9, left: 4),
      child: Text(label, style: AppTextStyles.sectionTitle),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 18,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String sub;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({
    required this.title,
    required this.sub,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.toggleTitle),
                const SizedBox(height: 1),
                Text(sub, style: AppTextStyles.toggleSub),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 23,
              decoration: BoxDecoration(
                color: value ? AppColors.accent : AppColors.borderLight,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    alignment: value
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      width: 17,
                      height: 17,
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isLast;
  const _FieldRow({
    required this.label,
    required this.value,
    this.icon,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: AppTextStyles.fieldLabelLight),
              if (icon != null) ...[
                const SizedBox(width: 6),
                Icon(icon, color: AppColors.textSecondaryLight, size: 11),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(value, style: AppTextStyles.fieldStatic),
        ],
      ),
    );
  }
}

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? sub;
  final Color? iconColor;
  final Color? iconBg;
  final VoidCallback onTap;
  final bool isLast;
  const _NavRow({
    required this.icon,
    required this.title,
    this.sub,
    this.iconColor,
    this.iconBg,
    required this.onTap,
    this.isLast = false,
  });
  @override
  Widget build(BuildContext context) {
    final isDestructive = iconColor == AppColors.red;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(bottom: BorderSide(color: AppColors.borderLight)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg ?? AppColors.indigoLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.navRowTitle.copyWith(
                      color: isDestructive
                          ? AppColors.red
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                  if (sub != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(sub!, style: AppTextStyles.navRowSub),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondaryLight,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.redLight,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: AppColors.red,
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Se déconnecter ?',
              style: AppTextStyles.promptTitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu devras saisir ton code PIN pour revenir. Les commandes en cours resteront actives.',
              style: AppTextStyles.promptSub,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderLight),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: AppColors.textPrimaryLight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.red,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Se déconnecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
