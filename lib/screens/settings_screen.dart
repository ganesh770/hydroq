import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_theme.dart';

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
