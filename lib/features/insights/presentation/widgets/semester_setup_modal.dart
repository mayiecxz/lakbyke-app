import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lakbyke_mobile/core/utils/colors.dart';
import 'package:lakbyke_mobile/features/insights/data/semester_config_storage.dart';
import 'package:lakbyke_mobile/features/insights/domain/cba_constants.dart';
import 'package:lakbyke_mobile/features/insights/providers/insights_providers.dart';

/// Modal to set custom semester start/end for insights projections.
/// Saves to SharedPreferences and invalidates insights so they refresh.
class SemesterSetupModal extends ConsumerStatefulWidget {
  const SemesterSetupModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SemesterSetupModal(),
    );
  }

  @override
  ConsumerState<SemesterSetupModal> createState() => _SemesterSetupModalState();
}

class _SemesterSetupModalState extends ConsumerState<SemesterSetupModal> {
  DateTime? _semesterStart;
  DateTime? _semesterEnd;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final start = await SemesterConfigStorage.loadSemesterStart();
    final end = await SemesterConfigStorage.loadSemesterEnd();
    if (mounted) {
      setState(() {
        _semesterStart = start ?? CBAConstants.semesterStart;
        _semesterEnd = end ?? CBAConstants.semesterEnd;
        _loading = false;
      });
    }
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _semesterStart ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) setState(() => _semesterStart = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _semesterEnd ?? DateTime.now(),
      firstDate: _semesterStart ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && mounted) setState(() => _semesterEnd = picked);
  }

  Future<void> _save() async {
    if (_semesterStart == null || _semesterEnd == null) return;
    setState(() => _saving = true);
    await SemesterConfigStorage.saveSemesterStart(_semesterStart!);
    await SemesterConfigStorage.saveSemesterEnd(_semesterEnd!);
    if (mounted) {
      ref.invalidate(effectiveSemesterEndProvider);
      ref.invalidate(insightsDataProvider);
      setState(() => _saving = false);
      Navigator.of(context).pop();
    }
  }

  Future<void> _resetToDefault() async {
    await SemesterConfigStorage.clearSemester();
    if (mounted) {
      ref.invalidate(effectiveSemesterEndProvider);
      ref.invalidate(insightsDataProvider);
      setState(() {
        _semesterStart = CBAConstants.semesterStart;
        _semesterEnd = CBAConstants.semesterEnd;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.paddingOf(context).bottom),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Semester dates',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.homePrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set start and end dates for semester projections and breakeven.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Semester start'),
                  subtitle: Text(
                    _semesterStart != null
                        ? '${_semesterStart!.day}/${_semesterStart!.month}/${_semesterStart!.year}'
                        : 'Not set',
                  ),
                  trailing: FilledButton.icon(
                    onPressed: _pickStart,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.homePrimary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Pick'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Semester end'),
                  subtitle: Text(
                    _semesterEnd != null
                        ? '${_semesterEnd!.day}/${_semesterEnd!.month}/${_semesterEnd!.year}'
                        : 'Not set',
                  ),
                  trailing: FilledButton.icon(
                    onPressed: _pickEnd,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.homePrimary,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.calendar_today_rounded, size: 18),
                    label: const Text('Pick'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _saving ? null : _resetToDefault,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.homePrimary,
                        side: const BorderSide(color: AppColors.homePrimary),
                      ),
                      child: const Text('Reset to default'),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.homePrimary,
                        foregroundColor: Colors.white,
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
