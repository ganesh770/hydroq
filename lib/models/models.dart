import 'package:flutter/material.dart';

// ── Drink types ───────────────────────────────────────────────────────────────

enum DrinkType {
  water(label: 'Water', emoji: '💧', hydrationFactor: 1.0, caffeineOffset: 0),
  coffee(label: 'Coffee', emoji: '☕', hydrationFactor: 0.5, caffeineOffset: 150),
  tea(label: 'Tea', emoji: '🍵', hydrationFactor: 0.8, caffeineOffset: 80),
  juice(label: 'Juice', emoji: '🧃', hydrationFactor: 0.9, caffeineOffset: 0),
  milk(label: 'Milk', emoji: '🥛', hydrationFactor: 0.9, caffeineOffset: 0),
  soda(label: 'Soda', emoji: '🥤', hydrationFactor: 0.6, caffeineOffset: 40),
  sports(label: 'Sports drink', emoji: '⚡', hydrationFactor: 1.0, caffeineOffset: 0),
  herbal(label: 'Herbal tea', emoji: '🌿', hydrationFactor: 1.0, caffeineOffset: 0);

  final String label;
  final String emoji;
  final double hydrationFactor;
  final int caffeineOffset;

  const DrinkType({
    required this.label,
    required this.emoji,
    required this.hydrationFactor,
    required this.caffeineOffset,
  });
}

// ── Water entry ───────────────────────────────────────────────────────────────

class WaterEntry {
  final String id;
  final int amountMl;
  final DrinkType drinkType;
  final DateTime timestamp;

  const WaterEntry({
    required this.id,
    required this.amountMl,
    required this.drinkType,
    required this.timestamp,
  });

  int get effectiveMl => (amountMl * drinkType.hydrationFactor).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountMl': amountMl,
        'drinkType': drinkType.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WaterEntry.fromJson(Map<String, dynamic> json) => WaterEntry(
        id: json['id'] as String,
        amountMl: (json['amountMl'] as num).toInt(),
        drinkType: DrinkType.values.firstWhere(
          (e) => e.name == json['drinkType'],
          orElse: () => DrinkType.water,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

// ── Activity level ────────────────────────────────────────────────────────────

enum ActivityLevel {
  sedentary(label: 'Sedentary', factor: 1.0),
  light(label: 'Light activity', factor: 1.1),
  moderate(label: 'Moderate', factor: 1.2),
  active(label: 'Very active', factor: 1.35),
  athlete(label: 'Athlete', factor: 1.5);

  final String label;
  final double factor;
  const ActivityLevel({required this.label, required this.factor});
}

// ── User profile ──────────────────────────────────────────────────────────────

class UserProfile {
  final double weightKg;
  final ActivityLevel activityLevel;
  final bool useWeightBasedGoal;
  final int manualGoalMl;
  final String unit;
  final int reminderIntervalMinutes;
  final bool remindersEnabled;
  final bool remindersMuted;
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final bool catchUpModeEnabled;
  final String name;

  const UserProfile({
    this.weightKg = 70,
    this.activityLevel = ActivityLevel.moderate,
    this.useWeightBasedGoal = true,
    this.manualGoalMl = 2500,
    this.unit = 'ml',
    this.reminderIntervalMinutes = 90,
    this.remindersEnabled = false,
    this.remindersMuted = false,
    this.wakeTime = const TimeOfDay(hour: 7, minute: 0),
    this.sleepTime = const TimeOfDay(hour: 23, minute: 0),
    this.catchUpModeEnabled = true,
    this.name = '',
  });

  int get calculatedGoalMl =>
      (weightKg * 35 * activityLevel.factor).round();

  int get effectiveGoalMl =>
      useWeightBasedGoal ? calculatedGoalMl : manualGoalMl;

  UserProfile copyWith({
    double? weightKg,
    ActivityLevel? activityLevel,
    bool? useWeightBasedGoal,
    int? manualGoalMl,
    String? unit,
    int? reminderIntervalMinutes,
    bool? remindersEnabled,
    bool? remindersMuted,
    TimeOfDay? wakeTime,
    TimeOfDay? sleepTime,
    bool? catchUpModeEnabled,
    String? name,
  }) =>
      UserProfile(
        weightKg: weightKg ?? this.weightKg,
        activityLevel: activityLevel ?? this.activityLevel,
        useWeightBasedGoal: useWeightBasedGoal ?? this.useWeightBasedGoal,
        manualGoalMl: manualGoalMl ?? this.manualGoalMl,
        unit: unit ?? this.unit,
        reminderIntervalMinutes:
            reminderIntervalMinutes ?? this.reminderIntervalMinutes,
        remindersEnabled: remindersEnabled ?? this.remindersEnabled,
        remindersMuted: remindersMuted ?? this.remindersMuted,
        wakeTime: wakeTime ?? this.wakeTime,
        sleepTime: sleepTime ?? this.sleepTime,
        catchUpModeEnabled: catchUpModeEnabled ?? this.catchUpModeEnabled,
        name: name ?? this.name,
      );

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'activityLevel': activityLevel.name,
        'useWeightBasedGoal': useWeightBasedGoal,
        'manualGoalMl': manualGoalMl,
        'unit': unit,
        'reminderIntervalMinutes': reminderIntervalMinutes,
        'remindersEnabled': remindersEnabled,
        'remindersMuted': remindersMuted,
        'wakeHour': wakeTime.hour,
        'wakeMinute': wakeTime.minute,
        'sleepHour': sleepTime.hour,
        'sleepMinute': sleepTime.minute,
        'catchUpModeEnabled': catchUpModeEnabled,
        'name': name,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 70,
        activityLevel: ActivityLevel.values.firstWhere(
          (e) => e.name == json['activityLevel'],
          orElse: () => ActivityLevel.moderate,
        ),
        useWeightBasedGoal: json['useWeightBasedGoal'] as bool? ?? true,
        manualGoalMl: json['manualGoalMl'] as int? ?? 2500,
        unit: json['unit'] as String? ?? 'ml',
        reminderIntervalMinutes:
            json['reminderIntervalMinutes'] as int? ?? 90,
        remindersEnabled: json['remindersEnabled'] as bool? ?? false,
        remindersMuted: json['remindersMuted'] as bool? ?? false,
        wakeTime: TimeOfDay(
            hour: json['wakeHour'] as int? ?? 7,
            minute: json['wakeMinute'] as int? ?? 0),
        sleepTime: TimeOfDay(
            hour: json['sleepHour'] as int? ?? 23,
            minute: json['sleepMinute'] as int? ?? 0),
        catchUpModeEnabled: json['catchUpModeEnabled'] as bool? ?? true,
        name: json['name'] as String? ?? '',
      );
}

// ── Hydration score ───────────────────────────────────────────────────────────

class HydrationScore {
  static int calculate({
    required List<WaterEntry> todayEntries,
    required int goalMl,
  }) {
    if (todayEntries.isEmpty) return 0;
    final safeGoal = goalMl > 0 ? goalMl : 2500;
    final totalMl = todayEntries.fold(0, (s, e) => s + e.effectiveMl);
    final volumeScore = ((totalMl / safeGoal) * 50).clamp(0, 50).toInt();
    final hours = todayEntries.map((e) => e.timestamp.hour).toSet();
    final spreadScore = ((hours.length / 8) * 30).clamp(0, 30).toInt();
    int consistencyScore = 20;
    if (todayEntries.length >= 2) {
      final sorted = [...todayEntries]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      for (int i = 1; i < sorted.length; i++) {
        final gap =
            sorted[i].timestamp.difference(sorted[i - 1].timestamp).inHours;
        if (gap > 3) consistencyScore -= 5;
      }
      consistencyScore = consistencyScore.clamp(0, 20);
    }
    return (volumeScore + spreadScore + consistencyScore).clamp(0, 100);
  }

  static String label(int score) {
    if (score >= 90) return 'Excellent 🏆';
    if (score >= 75) return 'Great 🌟';
    if (score >= 55) return 'Good 👍';
    if (score >= 35) return 'Fair ⚠️';
    return 'Needs work 💤';
  }

  static Color color(int score) {
    if (score >= 75) return const Color(0xFF00C896);
    if (score >= 50) return const Color(0xFF2979FF);
    if (score >= 30) return const Color(0xFFFF9800);
    return const Color(0xFFFF5252);
  }
}

// ── Urine color scale ─────────────────────────────────────────────────────────

class UrineColor {
  final int index;
  final Color color;
  final String label;
  final String message;
  final bool needsWater;

  const UrineColor({
    required this.index,
    required this.color,
    required this.label,
    required this.message,
    required this.needsWater,
  });
}

const List<UrineColor> urineColorScale = [
  UrineColor(index: 1, color: Color(0xFFFFFDE7), label: 'Very pale', message: 'Well hydrated! Maybe slightly over-hydrated.', needsWater: false),
  UrineColor(index: 2, color: Color(0xFFFFF9C4), label: 'Pale yellow', message: 'Perfect! You\'re well hydrated.', needsWater: false),
  UrineColor(index: 3, color: Color(0xFFFFF176), label: 'Light yellow', message: 'Good hydration. Keep it up!', needsWater: false),
  UrineColor(index: 4, color: Color(0xFFFFEE58), label: 'Yellow', message: 'Acceptable. Drink a glass soon.', needsWater: true),
  UrineColor(index: 5, color: Color(0xFFFFCA28), label: 'Dark yellow', message: 'Mildly dehydrated. Drink water now!', needsWater: true),
  UrineColor(index: 6, color: Color(0xFFFFB300), label: 'Amber', message: 'Dehydrated. Drink 2 glasses immediately.', needsWater: true),
  UrineColor(index: 7, color: Color(0xFFFF8F00), label: 'Orange', message: 'Severely dehydrated! Rehydrate now.', needsWater: true),
  UrineColor(index: 8, color: Color(0xFFE65100), label: 'Brown', message: 'Very severely dehydrated. Seek help if this persists.', needsWater: true),
];
