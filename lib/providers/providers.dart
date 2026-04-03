import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/storage_service.dart';

final storageProvider = Provider<StorageService>((_) => StorageService());

// ── Profile ───────────────────────────────────────────────────────────────────

class ProfileNotifier extends AsyncNotifier<UserProfile> {
  @override
  Future<UserProfile> build() async {
    final p = await ref.read(storageProvider).loadProfile();
    return p;
  }

  Future<void> save(UserProfile p) async {
    await ref.read(storageProvider).saveProfile(p);
    state = AsyncData(p);
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

// ── Entries ───────────────────────────────────────────────────────────────────

class EntriesNotifier extends AsyncNotifier<List<WaterEntry>> {
  @override
  Future<List<WaterEntry>> build() =>
      ref.read(storageProvider).loadEntries();

  Future<void> addEntry({
    required int amountMl,
    required DrinkType drinkType,
  }) async {
    final entry = WaterEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      amountMl: amountMl,
      drinkType: drinkType,
      timestamp: DateTime.now(),
    );
    await ref.read(storageProvider).addEntry(entry);
    state = AsyncData([entry, ...state.value ?? []]);
  }

  Future<void> removeEntry(String id) async {
    await ref.read(storageProvider).removeEntry(id);
    state =
        AsyncData((state.value ?? []).where((e) => e.id != id).toList());
  }
}

final entriesProvider =
    AsyncNotifierProvider<EntriesNotifier, List<WaterEntry>>(
        EntriesNotifier.new);

// ── Derived providers ─────────────────────────────────────────────────────────

final todayEntriesProvider = Provider<List<WaterEntry>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? [];
  final now = DateTime.now();
  return entries
      .where((e) =>
          e.timestamp.year == now.year &&
          e.timestamp.month == now.month &&
          e.timestamp.day == now.day)
      .toList();
});

final todayEffectiveIntakeProvider = Provider<int>((ref) {
  final entries = ref.watch(todayEntriesProvider);
  final base = entries.fold(0, (s, e) => s + e.effectiveMl);
  final caffeineDebt =
      entries.fold(0, (s, e) => s + e.drinkType.caffeineOffset);
  return (base - caffeineDebt).clamp(0, 999999);
});

final hydrationScoreProvider = Provider<int>((ref) {
  final entries = ref.watch(todayEntriesProvider);
  final goal =
      ref.watch(profileProvider).value?.effectiveGoalMl ?? 2500;
  return HydrationScore.calculate(todayEntries: entries, goalMl: goal);
});



final weeklySummaryProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final entries = ref.watch(entriesProvider).value ?? [];
  final today = DateTime.now();
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    final dayEntries = entries.where((e) =>
        e.timestamp.year == day.year &&
        e.timestamp.month == day.month &&
        e.timestamp.day == day.day);
    final total = dayEntries.fold(0, (s, e) => s + e.effectiveMl);
    return {'date': day, 'total': total, 'entries': dayEntries.toList()};
  });
});

final drinkBreakdownProvider = Provider<Map<DrinkType, int>>((ref) {
  final entries = ref.watch(todayEntriesProvider);
  final map = <DrinkType, int>{};
  for (final e in entries) {
    map[e.drinkType] = (map[e.drinkType] ?? 0) + e.amountMl;
  }
  return map;
});
