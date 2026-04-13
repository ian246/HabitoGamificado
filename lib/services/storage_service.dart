import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../models/user_profile.dart';

/// ─────────────────────────────────────────────────────────────
/// StorageService — CRUD completo via SharedPreferences
///
/// Padrão Singleton: StorageService.instance
///
/// IMPORTANTE: Este service NÃO importa AuthService para evitar
/// dependência circular. A sincronização remota é responsabilidade
/// de quem chama (HomeScreen, HabitFormScreen etc.), não daqui.
///
/// Chaves usadas no SharedPreferences:
///   'user_profile'       → JSON do UserProfile
///   'habit_ids'          → JSON de List<String> com IDs
///   'habit_{id}'         → JSON de cada Habit
///   'last_reset_date'    → 'yyyy-MM-dd' do último reset diário
/// ─────────────────────────────────────────────────────────────
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late SharedPreferences _prefs;
  bool _initialized = false;

  // ── Chaves ────────────────────────────────────────────────
  static const _keyProfile = 'user_profile';
  static const _keyHabitIds = 'habit_ids';
  static const _keyLastReset = 'last_reset_date';
  static const _prefixHabit = 'habit_';

  // ── Inicialização ─────────────────────────────────────────
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  void _assertInit() {
    assert(
      _initialized,
      'StorageService não foi inicializado. '
      'Chame await StorageService.instance.init() no main.dart',
    );
  }

  // ══════════════════════════════════════════════════════════
  // PERFIL DO USUÁRIO
  // ══════════════════════════════════════════════════════════

  bool get hasProfile {
    _assertInit();
    return _prefs.containsKey(_keyProfile);
  }

  UserProfile? loadProfile() {
    _assertInit();
    final raw = _prefs.getString(_keyProfile);
    if (raw == null) return null;
    try {
      return UserProfile.fromJsonString(raw);
    } catch (_) {
      _prefs.remove(_keyProfile);
      return null;
    }
  }

  Future<bool> saveProfile(UserProfile profile) {
    _assertInit();
    return _prefs.setString(_keyProfile, profile.toJsonString());
  }

  Future<bool> deleteProfile() {
    _assertInit();
    return _prefs.remove(_keyProfile);
  }

  // ══════════════════════════════════════════════════════════
  // HÁBITOS — apenas local (sem sync remoto aqui)
  // ══════════════════════════════════════════════════════════

  List<String> _loadIds() {
    final raw = _prefs.getString(_keyHabitIds);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw) as List);
  }

  Future<void> _saveIds(List<String> ids) async {
    await _prefs.setString(_keyHabitIds, jsonEncode(ids));
  }

  Future<List<Habit>> loadAllHabits() async {
    _assertInit();
    final ids = _loadIds();
    final habits = <Habit>[];
    for (final id in ids) {
      final raw = _prefs.getString('$_prefixHabit$id');
      if (raw == null) continue;
      try {
        habits.add(Habit.fromJsonString(raw));
      } catch (_) {
        // ignora entrada corrompida
      }
    }
    return habits;
  }

  Habit? loadHabit(String id) {
    _assertInit();
    final raw = _prefs.getString('$_prefixHabit$id');
    if (raw == null) return null;
    try {
      return Habit.fromJsonString(raw);
    } catch (_) {
      return null;
    }
  }

  /// Salva um hábito SOMENTE localmente.
  /// Quem precisar de sync remoto deve chamar AuthService separadamente.
  Future<void> saveHabitLocal(Habit habit) async {
    _assertInit();
    await _prefs.setString('$_prefixHabit${habit.id}', habit.toJsonString());
    final ids = _loadIds();
    if (!ids.contains(habit.id)) {
      ids.add(habit.id);
      await _saveIds(ids);
    }
  }

  /// Sobrescreve TODOS os hábitos localmente (usado no sync de login).
  /// Não dispara nenhum sync remoto — apenas grava no SharedPreferences.
  Future<void> saveAllHabitsLocal(List<Habit> habits) async {
    _assertInit();
    for (final h in habits) {
      await _prefs.setString('$_prefixHabit${h.id}', h.toJsonString());
    }
    await _saveIds(habits.map((h) => h.id).toList());
  }

  /// Remove um hábito SOMENTE localmente.
  Future<void> deleteHabitLocal(String id) async {
    _assertInit();
    await _prefs.remove('$_prefixHabit$id');
    final ids = _loadIds()..remove(id);
    await _saveIds(ids);
  }

  Future<void> reorderHabits(List<String> newOrder) async {
    _assertInit();
    await _saveIds(newOrder);
  }

  // ══════════════════════════════════════════════════════════
  // RESET DIÁRIO
  // ══════════════════════════════════════════════════════════

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  bool needsDailyReset() {
    _assertInit();
    return _prefs.getString(_keyLastReset) != _todayKey;
  }

  Future<void> performDailyReset() async {
    _assertInit();
    final hoje = _todayKey;
    final habits = await loadAllHabits();

    final resetados = habits.map((h) {
      return h.salvarProgressoHoje(hoje).resetarParaHoje();
    }).toList();

    // Reset é apenas local — não sobe para o Firebase aqui
    await saveAllHabitsLocal(resetados);
    await _prefs.setString(_keyLastReset, hoje);
  }

  // ══════════════════════════════════════════════════════════
  // UTILITÁRIOS
  // ══════════════════════════════════════════════════════════

  int get habitCount => _loadIds().length;

  Future<void> clearAll() async {
    _assertInit();
    await _prefs.clear();
  }

  Future<String> exportAll() async {
    _assertInit();
    final habits = await loadAllHabits();
    final profile = loadProfile();
    return jsonEncode({
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile?.toJson(),
      'habits': habits.map((h) => h.toJson()).toList(),
    });
  }

  Future<void> importAll(String jsonString) async {
    _assertInit();
    final data = jsonDecode(jsonString) as Map<String, dynamic>;
    final profile = data['profile'];
    final habits = data['habits'] as List? ?? [];

    if (profile != null) {
      await saveProfile(UserProfile.fromJson(profile as Map<String, dynamic>));
    }
    for (final h in habits) {
      await saveHabitLocal(Habit.fromJson(h as Map<String, dynamic>));
    }
  }
}
