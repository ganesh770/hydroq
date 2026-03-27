import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService {
  static const _entriesKey = 'hydroq_entries_v2';
  static const _profileKey = 'hydroq_profile_v2';

  // ── Entries ───────────────────────────────────────────────────────────────

  Future<List<WaterEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_entriesKey) ?? [];
    final entries = <WaterEntry>[];
    for (final e in raw) {
      try {
        entries.add(WaterEntry.fromJson(jsonDecode(e) as Map<String, dynamic>));
      } catch (_) {
        // Skip corrupted entries safely instead of crashing the provider
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  Future<void> saveEntries(List<WaterEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _entriesKey,
      entries.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> addEntry(WaterEntry entry) async {
    final entries = await loadEntries();
    entries.insert(0, entry);
    await saveEntries(entries);
  }

  Future<void> removeEntry(String id) async {
    final entries = await loadEntries();
    entries.removeWhere((e) => e.id == id);
    await saveEntries(entries);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<UserProfile> loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return const UserProfile();
    return UserProfile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
  }
}
