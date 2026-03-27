import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import 'urine_checker_sheet.dart';
import 'add_drink_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final score = ref.watch(hydrationScoreProvider);
    final intake = ref.watch(todayEffectiveIntakeProvider);
    final catchUpInterval = ref.watch(catchUpIntervalProvider);
    final todayEntries = ref.watch(todayEntriesProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        final goal = profile.effectiveGoalMl;
        final progress = (intake / goal).clamp(0.0, 1.0);
        final remaining = (goal - intake).clamp(0, goal);

        return Scaffold(
          backgroundColor: context.pageBg,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                snap: true,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.isNotEmpty
                          ? 'Hi, ${profile.name} 👋'
                          : 'HydroQ 💧',
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                    ),
                    Text(
                      _subtitle(intake, goal),
                      style: TextStyle(
                          fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.colorize_outlined),
                    tooltip: 'Urine color check',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => const UrineCheckerSheet(),
                    ),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 12),
                    _ProgressCard(
                      progress: progress,
                      intake: intake,
                      goal: goal,
                      remaining: remaining,
                      score: score,
                      profile: profile,
                    ),
                    const SizedBox(height: 16),
                    if (profile.catchUpModeEnabled &&
                        catchUpInterval < profile.reminderIntervalMinutes &&
                        progress < 1.0)
                      _CatchUpBanner(interval: catchUpInterval),
                    const SizedBox(height: 16),
                    _QuickAddRow(profile: profile),
                    const SizedBox(height: 20),
                    const _UrineCheckPromo(),
                    const SizedBox(height: 20),
                    _ScoreCard(score: score),
                    const SizedBox(height: 20),
                    _TodayLog(entries: todayEntries, profile: profile),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => AddDrinkSheet(ref: ref),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add drink',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  String _subtitle(int intake, int goal) {
    final pct = (intake / goal * 100).round();
    if (pct == 0) return 'Start hydrating today!';
    if (pct < 30) return 'Just getting started — keep going!';
    if (pct < 60) return 'Halfway there, great job!';
    if (pct < 100) return 'Almost at your goal!';
    return 'Goal achieved! Amazing 🎉';
  }
}

// ── Progress card ─────────────────────────────────────────────────────────────

class _ProgressCard extends StatelessWidget {
  final double progress;
  final int intake, goal, remaining, score;
  final UserProfile profile;

  const _ProgressCard({
    required this.progress,
    required this.intake,
    required this.goal,
    required this.remaining,
    required this.score,
    required this.profile,
  });

  String _fmt(int ml) {
    if (profile.unit == 'oz') return '${(ml / 29.574).toStringAsFixed(0)}';
    return ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)}L' : '$ml';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(200, 200),
                  painter: _RingPainter(
                    progress: progress,
                    trackColor: scheme.surfaceVariant,
                  ),
                ),
                Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_fmt(intake),
                      style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary)),
                  Text(profile.unit,
                      style: TextStyle(
                          fontSize: 13,
                          color: context.textSecondary)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: progress >= 1.0
                          ? AppTheme.success.withOpacity(0.15)
                          : AppTheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      progress >= 1.0
                          ? '🎉 Done!'
                          : '${(progress * 100).toInt()}%',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: progress >= 1.0
                              ? AppTheme.success
                              : AppTheme.primary),
                    ),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(children: [
            _Chip(label: 'Goal',
                value: '${_fmt(goal)}${profile.unit}',
                icon: Icons.flag_outlined),
            const SizedBox(width: 10),
            _Chip(
                label: 'Remaining',
                value: remaining > 0
                    ? '${_fmt(remaining)}${profile.unit}'
                    : 'Done ✓',
                icon: Icons.water_outlined,
                highlight: true),
            const SizedBox(width: 10),
            _Chip(
                label: 'Score',
                value: '$score/100',
                icon: Icons.insights,
                highlight: true,
                color: HydrationScore.color(score)),
          ]),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool highlight;
  final Color? color;

  const _Chip({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (highlight ? AppTheme.primary : context.textSecondary);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 13, color: c),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          color: c,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 3),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: c)),
            ]),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;

  const _RingPainter({required this.progress, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 16.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth);

    if (progress <= 0) return;

    final gradient = SweepGradient(
      startAngle: -math.pi / 2,
      endAngle: -math.pi / 2 + 2 * math.pi,
      colors: const [
        Color(0xFF2979FF),
        Color(0xFF00BCD4),
        Color(0xFF00C896)
      ],
    );

    canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}

// ── Catch-up banner ───────────────────────────────────────────────────────────

class _CatchUpBanner extends StatelessWidget {
  final int interval;
  const _CatchUpBanner({required this.interval});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.warning.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppTheme.warning.withOpacity(0.3), width: 0.5),
      ),
      child: Row(children: [
        const Text('⚡', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Smart catch-up mode active',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppTheme.warning)),
                Text('Reminders every $interval min to help you catch up',
                    style: TextStyle(
                        fontSize: 12, color: context.textSecondary)),
              ]),
        ),
      ]),
    );
  }
}

// ── Quick add row ─────────────────────────────────────────────────────────────

class _QuickAddRow extends ConsumerWidget {
  final UserProfile profile;
  const _QuickAddRow({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amounts = [150, 250, 350, 500];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick add water',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: amounts.map((ml) {
              final label = profile.unit == 'ml'
                  ? '${ml}ml'
                  : '${(ml / 29.574).toStringAsFixed(0)}oz';
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ref.read(entriesProvider.notifier).addEntry(
                        amountMl: ml, drinkType: DrinkType.water);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Added $label 💧'),
                      duration: const Duration(milliseconds: 1200),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin:
                          const EdgeInsets.fromLTRB(16, 0, 16, 90),
                    ));
                  },
                  child: Container(
                    width: 76,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: context.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: context.divider, width: 0.5),
                    ),
                    child: Column(children: [
                      const Icon(Icons.water_drop,
                          color: AppTheme.primary, size: 22),
                      const SizedBox(height: 6),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Score card ────────────────────────────────────────────────────────────────

class _ScoreCard extends StatelessWidget {
  final int score;
  const _ScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = HydrationScore.color(score);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color, width: 2.5)),
            child: Center(
                child: Text('$score',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hydration score',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(HydrationScore.label(score),
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('Volume · timing · consistency',
                      style: TextStyle(
                          fontSize: 12,
                          color: context.textSecondary)),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ── Today's log ───────────────────────────────────────────────────────────────

class _TodayLog extends ConsumerWidget {
  final List<WaterEntry> entries;
  final UserProfile profile;

  const _TodayLog({required this.entries, required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(children: [
            Icon(Icons.water_drop_outlined,
                size: 40, color: context.textSecondary),
            const SizedBox(height: 8),
            Text('No drinks logged yet',
                style: TextStyle(color: context.textSecondary)),
          ]),
        ),
      );
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Today's log",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...entries.map((entry) {
            final display = profile.unit == 'ml'
                ? '${entry.amountMl} ml'
                : '${(entry.amountMl / 29.574).toStringAsFixed(1)} oz';
            final time =
                TimeOfDay.fromDateTime(entry.timestamp).format(context);
            final isDiff = entry.effectiveMl != entry.amountMl;

            return Dismissible(
              key: ValueKey(entry.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) =>
                  ref.read(entriesProvider.notifier).removeEntry(entry.id),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16)),
                child: const Icon(Icons.delete_outline,
                    color: AppTheme.danger),
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12)),
                    child: Center(
                        child: Text(entry.drinkType.emoji,
                            style: const TextStyle(fontSize: 20))),
                  ),
                  title: Text(
                      '${entry.drinkType.label} · $display',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(
                    isDiff
                        ? '$time · ${entry.effectiveMl}ml effective'
                        : time,
                    style: TextStyle(
                        fontSize: 12, color: context.textSecondary),
                  ),
                  trailing: isDiff
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                              color: AppTheme.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            '−${entry.drinkType.caffeineOffset}ml',
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.warning,
                                fontWeight: FontWeight.w600),
                          ),
                        )
                      : null,
                ),
              ),
            );
          }),
        ]);
  }
}

// ── Urine check promo ─────────────────────────────────────────────────────────

class _UrineCheckPromo extends StatelessWidget {
  const _UrineCheckPromo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppTheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withOpacity(0.2), width: 0.5),
      ),
      child: Row(children: [
        const Icon(Icons.colorize_outlined, size: 36, color: AppTheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Not sure about hydration?',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.primary)),
              const SizedBox(height: 4),
              Text('Check your urine color for a quick estimate.',
                  style: TextStyle(fontSize: 12, color: context.textSecondary)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const UrineCheckerSheet(),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Check now', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ),
      ]),
    );
  }
}
