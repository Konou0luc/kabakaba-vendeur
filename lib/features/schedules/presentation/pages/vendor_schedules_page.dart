import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/kaba_button.dart';
import '../../../../shared/widgets/light_app_bar.dart';
import '../../../vendor/data/vendor_profile_repository.dart';
import '../../data/schedules_repository.dart';
import '../../domain/vendor_schedule.dart';

class VendorSchedulesPage extends ConsumerWidget {
  const VendorSchedulesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedules = ref.watch(vendorSchedulesProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          LightTopNav(
            title: 'Horaires d’ouverture',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: schedules.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text(
                  error is ApiException
                      ? error.message
                      : 'Impossible de charger les horaires.',
                  style: AppTextStyles.emptySub,
                  textAlign: TextAlign.center,
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyState(
                    title: 'Aucune plage horaire',
                    subtitle:
                        'Ajoute les jours et heures où ta cantine est habituellement ouverte.',
                    icon: Icons.schedule_rounded,
                  );
                }
                final sorted = [...items]..sort(
                  (a, b) => a.day.index.compareTo(b.day.index),
                );
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(vendorSchedulesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (_, index) => _ScheduleTile(
                      schedule: sorted[index],
                      onDelete: () =>
                          _delete(context, ref, sorted[index]),
                    ),
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
                text: 'Ajouter une plage',
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

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    VendorSchedule schedule,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette plage ?'),
        content: Text(
          '${schedule.day.label} · ${schedule.rangeLabel}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final vendor = await ref.read(currentVendorProvider.future);
      await ref
          .read(schedulesRepositoryProvider)
          .delete(vendorId: vendor.id, scheduleId: schedule.id);
      ref.invalidate(vendorSchedulesProvider);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is ApiException
                ? error.message
                : 'Suppression impossible.',
          ),
        ),
      );
    }
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ScheduleEditorSheet(),
    );
    if (created == true) {
      ref.invalidate(vendorSchedulesProvider);
    }
  }
}

class _ScheduleTile extends StatelessWidget {
  final VendorSchedule schedule;
  final VoidCallback onDelete;

  const _ScheduleTile({required this.schedule, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1B2A6B),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.indigoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.day.label, style: AppTextStyles.navRowTitle),
                const SizedBox(height: 2),
                Text(schedule.rangeLabel, style: AppTextStyles.navRowSub),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleEditorSheet extends ConsumerStatefulWidget {
  const _ScheduleEditorSheet();

  @override
  ConsumerState<_ScheduleEditorSheet> createState() =>
      _ScheduleEditorSheetState();
}

class _ScheduleEditorSheetState extends ConsumerState<_ScheduleEditorSheet> {
  Weekday _day = Weekday.monday;
  TimeOfDay _start = const TimeOfDay(hour: 7, minute: 30);
  TimeOfDay _end = const TimeOfDay(hour: 15, minute: 0);
  bool _saving = false;
  String? _error;

  String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pick(bool start) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _start = picked;
      } else {
        _end = picked;
      }
      _error = null;
    });
  }

  Future<void> _save() async {
    final startMinutes = _start.hour * 60 + _start.minute;
    final endMinutes = _end.hour * 60 + _end.minute;
    if (endMinutes <= startMinutes) {
      setState(() => _error = 'L’heure de fin doit être après l’heure de début.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final vendor = await ref.read(currentVendorProvider.future);
      await ref.read(schedulesRepositoryProvider).create(
        vendorId: vendor.id,
        day: _day,
        startTime: _format(_start),
        endTime: _format(_end),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      setState(() {
        _saving = false;
        _error = error is ApiException
            ? error.message
            : 'Enregistrement impossible.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle plage', style: AppTextStyles.promptTitle),
            const SizedBox(height: 16),
            DropdownButtonFormField<Weekday>(
              initialValue: _day,
              decoration: const InputDecoration(
                labelText: 'Jour',
                border: OutlineInputBorder(),
              ),
              items: Weekday.values
                  .map(
                    (day) => DropdownMenuItem(
                      value: day,
                      child: Text(day.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _day = value);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeField(
                    label: 'Début',
                    value: _format(_start),
                    onTap: () => _pick(true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimeField(
                    label: 'Fin',
                    value: _format(_end),
                    onTap: () => _pick(false),
                  ),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: AppTextStyles.emptySub.copyWith(color: AppColors.red),
              ),
            ],
            const SizedBox(height: 18),
            KabaButton(
              text: 'Enregistrer',
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        child: Text(value, style: AppTextStyles.fieldStatic),
      ),
    );
  }
}
