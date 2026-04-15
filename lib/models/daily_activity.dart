import 'dart:convert';

/// ─────────────────────────────────────────────────────────────
/// DailyActivity — Registro consolidado de ações de um dia
///
/// Serve como a "Fonte da Verdade" para o que já foi premiado.
/// ─────────────────────────────────────────────────────────────
class DailyActivity {
  final String date; // yyyy-MM-dd
  final Set<String> rewardedSubtaskKeys;    // "habitId:index"
  final Set<String> rewardedHabitCompletions; // "habitId"
  final Set<String> activeTrails;            // "trailId"
  final int habitsCreated;

  const DailyActivity({
    required this.date,
    this.rewardedSubtaskKeys = const {},
    this.rewardedHabitCompletions = const {},
    this.activeTrails = const {},
    this.habitsCreated = 0,
  });

  // ── Helpers ───────────────────────────────────────────────
  
  bool isSubtaskRewarded(String habitId, int index) =>
      rewardedSubtaskKeys.contains('$habitId:$index');

  bool isHabitRewarded(String habitId) =>
      rewardedHabitCompletions.contains(habitId);

  bool isTrailActive(String trailId) =>
      activeTrails.contains(trailId);

  // ── copyWith ──────────────────────────────────────────────

  DailyActivity copyWith({
    String? date,
    Set<String>? rewardedSubtaskKeys,
    Set<String>? rewardedHabitCompletions,
    Set<String>? activeTrails,
    int? habitsCreated,
  }) {
    return DailyActivity(
      date: date ?? this.date,
      rewardedSubtaskKeys: rewardedSubtaskKeys ?? this.rewardedSubtaskKeys,
      rewardedHabitCompletions: rewardedHabitCompletions ?? this.rewardedHabitCompletions,
      activeTrails: activeTrails ?? this.activeTrails,
      habitsCreated: habitsCreated ?? this.habitsCreated,
    );
  }

  // ── Serialização ──────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'date': date,
    'rewardedSubtaskKeys': rewardedSubtaskKeys.toList(),
    'rewardedHabitCompletions': rewardedHabitCompletions.toList(),
    'activeTrails': activeTrails.toList(),
    'habitsCreated': habitsCreated,
  };

  factory DailyActivity.fromJson(Map<String, dynamic> json) {
    return DailyActivity(
      date: json['date'] as String,
      rewardedSubtaskKeys: Set<String>.from(json['rewardedSubtaskKeys'] as List? ?? []),
      rewardedHabitCompletions: Set<String>.from(json['rewardedHabitCompletions'] as List? ?? []),
      activeTrails: Set<String>.from(json['activeTrails'] as List? ?? []),
      habitsCreated: json['habitsCreated'] as int? ?? 0,
    );
  }
}
