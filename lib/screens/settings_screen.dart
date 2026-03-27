import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:auto_start_flutter/auto_start_flutter.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) => Scaffold(
        backgroundColor: context.pageBg,
        appBar: AppBar(title: const Text('Settings')),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            // ── Profile ─────────────────────────────────────────────────
            _Section('Profile'),
            Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Your name'),
                subtitle: Text(profile.name.isEmpty
                    ? 'Tap to set your name'
                    : profile.name),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _editName(context, ref, profile),
              ),
            ),

            const SizedBox(height: 16),

            // ── Daily goal ───────────────────────────────────────────────
            _Section('Daily goal'),
            Card(
              child: Column(children: [
                SwitchListTile(
                  secondary: const Icon(Icons.calculate_outlined),
                  title: const Text('Weight-based goal'),
                  subtitle: Text(profile.useWeightBasedGoal
                      ? 'Auto: ${profile.calculatedGoalMl}ml  (35ml × ${profile.weightKg.toInt()}kg)'
                      : 'Manual: ${profile.manualGoalMl}ml'),
                  value: profile.useWeightBasedGoal,
                  onChanged: (v) => _save(ref, profile.copyWith(useWeightBasedGoal: v)),
                ),
                if (profile.useWeightBasedGoal) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Weight: ${profile.weightKg.toStringAsFixed(0)} kg',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Slider(
                            value: profile.weightKg,
                            min: 30, max: 150, divisions: 120,
                            label: '${profile.weightKg.toStringAsFixed(0)} kg',
                            onChanged: (v) => _save(ref, profile.copyWith(weightKg: v)),
                          ),
                          const Text('Activity level',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          ...ActivityLevel.values.map((level) =>
                              RadioListTile<ActivityLevel>(
                                dense: true,
                                title: Text(level.label,
                                    style: const TextStyle(fontSize: 14)),
                                subtitle: Text(
                                    '${(profile.weightKg * 35 * level.factor).round()} ml/day',
                                    style: const TextStyle(fontSize: 12)),
                                value: level,
                                groupValue: profile.activityLevel,
                                onChanged: (v) {
                                  if (v != null) _save(ref, profile.copyWith(activityLevel: v));
                                },
                              )),
                        ]),
                  ),
                ] else ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Goal: ${profile.manualGoalMl} ml',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          Slider(
                            value: profile.manualGoalMl.toDouble(),
                            min: 1000, max: 5000, divisions: 40,
                            label: '${profile.manualGoalMl} ml',
                            onChanged: (v) => _save(ref, profile.copyWith(manualGoalMl: v.round())),
                          ),
                        ]),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 16),

            // ── Unit ─────────────────────────────────────────────────────
            _Section('Unit'),
            Card(
              child: Column(
                children: ['ml', 'oz'].map((unit) => RadioListTile<String>(
                      title: Text(unit == 'ml'
                          ? 'Millilitres (ml)'
                          : 'Fluid ounces (oz)'),
                      value: unit,
                      groupValue: profile.unit,
                      onChanged: (v) {
                        if (v != null) _save(ref, profile.copyWith(unit: v));
                      },
                    )).toList(),
              ),
            ),

            const SizedBox(height: 16),

            // ── Reminders ────────────────────────────────────────────────
            _Section('Reminders'),
            Card(
              child: Column(children: [
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_outlined),
                  title: const Text('Enable reminders'),
                  subtitle: const Text('Get nudged to drink water'),
                  value: profile.remindersEnabled,
                  onChanged: (v) async {
                    final updated = profile.copyWith(remindersEnabled: v);
                    await _save(ref, updated);
                    if (v) {
                      final granted =
                          await NotificationService().requestPermissions();
                      if (granted) {
                        // Request Unrestricted Battery
                        if (await Permission.ignoreBatteryOptimizations.isDenied) {
                          await Permission.ignoreBatteryOptimizations.request();
                        }
                        
                        // Request OEM Auto-Start (Vivo/Xiaomi/Oppo/etc)
                        try {
                          final isAvailable = await isAutoStartAvailable;
                          if (isAvailable == true) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('⚠️ Please enable Auto-Start to prevent your phone from killing your reminders!'),
                                  duration: Duration(seconds: 4),
                                ),
                              );
                            }
                            await getAutoStartPermission();
                          }
                        } catch (_) {}

                        await NotificationService().scheduleReminders(updated);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ Reminders scheduled!'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('⚠️ Permission denied. Enable in phone Settings > Apps > HydroQ > Notifications'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    } else {
                      await NotificationService().cancelAll();
                    }
                  },
                ),
                if (profile.remindersEnabled) ...[
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: Icon(profile.remindersMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined),
                    title: const Text('Mute reminders'),
                    subtitle: const Text('Deliver silently without sound or vibration'),
                    value: profile.remindersMuted,
                    onChanged: (v) async {
                      final updated = profile.copyWith(remindersMuted: v);
                      await _save(ref, updated);
                      await NotificationService().scheduleReminders(updated);
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.bolt_outlined),
                    title: const Text('Catch-up mode'),
                    subtitle: const Text(
                        'Auto-increase frequency when behind'),
                    value: profile.catchUpModeEnabled,
                    onChanged: (v) => _save(ref, profile.copyWith(catchUpModeEnabled: v)),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Every ${profile.reminderIntervalMinutes} minutes',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          Slider(
                            value: profile.reminderIntervalMinutes.toDouble(),
                            min: 1, max: 240, divisions: 239,
                            label: '${profile.reminderIntervalMinutes} min',
                            onChanged: (v) => _save(ref, profile.copyWith(reminderIntervalMinutes: v.round())),
                            onChangeEnd: (v) async {
                              // Reschedule when slider settles
                              final updated = profile.copyWith(
                                  reminderIntervalMinutes: v.round());
                              await NotificationService().scheduleReminders(updated);
                            },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('1 min', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                              Text('4 hrs', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                            ],
                          ),
                        ]),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Wake up time'),
                    trailing: Text(profile.wakeTime.format(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                    onTap: () => _pickTime(context, ref, profile, isWake: true),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bedtime_outlined),
                    title: const Text('Sleep time'),
                    trailing: Text(profile.sleepTime.format(context),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary)),
                    onTap: () =>
                        _pickTime(context, ref, profile, isWake: false),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 16),

            // ── Notification info box ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppTheme.primary.withOpacity(0.2), width: 0.5),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ℹ️ How reminders work',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: AppTheme.primary)),
                    const SizedBox(height: 6),
                    Text(
                      'Reminders are automatically scheduled between your wake and sleep times. '
                      'On Android 14+, grant "Exact alarms" permission in phone Settings if reminders don\'t fire.',
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary, height: 1.5),
                    ),
                  ]),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _save(WidgetRef ref, UserProfile profile) async {
    await ref.read(profileProvider.notifier).save(profile);
  }

  void _editName(BuildContext ctx, WidgetRef ref, UserProfile profile) {
    final c = TextEditingController(text: profile.name);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Your name'),
        content: TextField(
            controller: c,
            decoration: const InputDecoration(labelText: 'Name'),
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(_),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              _save(ref, profile.copyWith(name: c.text.trim()));
              Navigator.pop(_);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext ctx, WidgetRef ref, UserProfile profile,
      {required bool isWake}) async {
    final picked = await showTimePicker(
      context: ctx,
      initialTime: isWake ? profile.wakeTime : profile.sleepTime,
    );
    if (picked == null) return;
    final updated = isWake
        ? profile.copyWith(wakeTime: picked)
        : profile.copyWith(sleepTime: picked);
    await _save(ref, updated);
    // Reschedule with new times
    if (updated.remindersEnabled) {
      await NotificationService().scheduleReminders(updated);
    }
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4, left: 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
              letterSpacing: 0.5)),
    );
  }
}
