import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final weekly = ref.watch(weeklySummaryProvider);
    final breakdown = ref.watch(drinkBreakdownProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) => Scaffold(
        backgroundColor: context.pageBg,
        appBar: AppBar(title: const Text('History')),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Last 7 days',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),
                      _BarChart(
                          weekly: weekly,
                          goal: profile.effectiveGoalMl),
                    ]),
              ),
            ),
            const SizedBox(height: 16),
            _StatsRow(weekly: weekly, goal: profile.effectiveGoalMl),
            const SizedBox(height: 16),
            if (breakdown.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Today by drink type',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 16),
                        _DrinkBreakdown(breakdown: breakdown),
                      ]),
                ),
              ),
              const SizedBox(height: 16),
            ],
            _DailyDetail(weekly: weekly, profile: profile),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<Map<String, dynamic>> weekly;
  final int goal;

  const _BarChart({required this.weekly, required this.goal});

  @override
  Widget build(BuildContext context) {
    final maxVal = weekly.fold<int>(
        goal, (m, e) => (e['total'] as int) > m ? (e['total'] as int) : m);

    return SizedBox(
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: weekly.map((day) {
          final total = day['total'] as int;
          final date = day['date'] as DateTime;
          final ratio = maxVal > 0 ? total / maxVal : 0.0;
          final isToday = _isToday(date);
          final goalMet = total >= goal;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (total > 0)
                      Text(
                        _fmt(total),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: goalMet
                                ? AppTheme.success
                                : context.textSecondary),
                      ),
                    const SizedBox(height: 3),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOut,
                      height: 130 * ratio.clamp(0.03, 1.0),
                      decoration: BoxDecoration(
                        gradient: goalMet
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppTheme.primary,
                                  AppTheme.accent
                                ],
                              )
                            : null,
                        color: goalMet
                            ? null
                            : isToday
                                ? AppTheme.primary.withOpacity(0.3)
                                : context.divider,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dayLetter(date),
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: isToday
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isToday
                              ? AppTheme.primary
                              : context.textSecondary),
                    ),
                    if (isToday)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 2),
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primary),
                      ),
                  ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  String _fmt(int ml) =>
      ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)}L' : '${ml}ml';

  String _dayLetter(DateTime d) {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    return days[d.weekday - 1];
  }
}

class _StatsRow extends StatelessWidget {
  final List<Map<String, dynamic>> weekly;
  final int goal;

  const _StatsRow({required this.weekly, required this.goal});

  @override
  Widget build(BuildContext context) {
    final totals = weekly.map((e) => e['total'] as int).toList();
    final weekTotal = totals.fold(0, (a, b) => a + b);
    final avg = (weekTotal / 7).round();
    final daysGoalMet = totals.where((t) => t >= goal).length;
    final best = totals.isEmpty ? 0 : totals.reduce((a, b) => a > b ? a : b);

    String fmt(int ml) =>
        ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)}L' : '${ml}ml';

    return Row(children: [
      _StatCard(label: 'Week total', value: fmt(weekTotal), emoji: '📊'),
      const SizedBox(width: 10),
      _StatCard(label: 'Daily avg', value: fmt(avg), emoji: '📈'),
      const SizedBox(width: 10),
      _StatCard(label: 'Goals met', value: '$daysGoalMet/7', emoji: '🎯'),
      const SizedBox(width: 10),
      _StatCard(label: 'Best day', value: fmt(best), emoji: '🏆'),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, emoji;
  const _StatCard(
      {required this.label, required this.value, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          child: Column(children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 6),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 10,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

class _DrinkBreakdown extends StatelessWidget {
  final Map<DrinkType, int> breakdown;
  const _DrinkBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final total = breakdown.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();
    return Column(
      children: breakdown.entries.map((entry) {
        final pct = entry.value / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(children: [
            Text(entry.key.emoji,
                style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key.label,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                          Text(
                              '${entry.value}ml · ${(pct * 100).toInt()}%',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: context.textSecondary)),
                        ]),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: context.divider,
                        color: AppTheme.primary,
                      ),
                    ),
                  ]),
            ),
          ]),
        );
      }).toList(),
    );
  }
}

class _DailyDetail extends StatelessWidget {
  final List<Map<String, dynamic>> weekly;
  final UserProfile profile;

  const _DailyDetail(
      {required this.weekly, required this.profile});

  String _fmtFullDate(DateTime d) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Daily breakdown',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      ...weekly.reversed.map((day) {
        final date = day['date'] as DateTime;
        final total = day['total'] as int;
        final entries = day['entries'] as List<WaterEntry>;
        if (total == 0) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: total >= profile.effectiveGoalMl
                      ? AppTheme.success.withOpacity(0.1)
                      : AppTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  total >= profile.effectiveGoalMl
                      ? Icons.check_circle
                      : Icons.water_drop,
                  color: total >= profile.effectiveGoalMl
                      ? AppTheme.success
                      : AppTheme.primary,
                  size: 20,
                ),
              ),
              title: Text(_fmtFullDate(date),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: Text('${total}ml · ${entries.length} entries',
                  style: TextStyle(
                      fontSize: 12, color: context.textSecondary)),
              children: entries
                  .map((e) => ListTile(
                        dense: true,
                        leading:
                            Text(e.drinkType.emoji),
                        title: Text(
                            '${e.drinkType.label} · ${e.amountMl}ml',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                        trailing: Text(
                            TimeOfDay.fromDateTime(e.timestamp)
                                .format(context),
                            style: TextStyle(
                                fontSize: 12,
                                color: context.textSecondary)),
                      ))
                  .toList(),
            ),
          ),
        );
      }),
    ]);
  }
}