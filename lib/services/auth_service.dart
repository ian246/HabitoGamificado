import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import '../models/habit.dart';
import 'storage_service.dart';

/// Resultado tipado do login — Screens não precisam de try/catch.
enum AuthResultStatus { success, cancelled, networkError, unknownError }

class AuthResult {
  final AuthResultStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  /// true = usuário nunca teve perfil no Firebase (novo ou upgrade de offline)
  final bool isNewUser;

  const AuthResult._({
    required this.status,
    this.profile,
    this.errorMessage,
    this.isNewUser = false,
  });

  factory AuthResult.success(UserProfile p, {bool isNewUser = false}) =>
      AuthResult._(
        status: AuthResultStatus.success,
        profile: p,
        isNewUser: isNewUser,
      );

  factory AuthResult.cancelled() =>
      AuthResult._(status: AuthResultStatus.cancelled);

  factory AuthResult.networkError() => AuthResult._(
    status: AuthResultStatus.networkError,
    errorMessage: 'Sem conexão. Tente novamente.',
  );

  factory AuthResult.unknownError(String msg) =>
      AuthResult._(status: AuthResultStatus.unknownError, errorMessage: msg);

  bool get isSuccess => status == AuthResultStatus.success;
  bool get isCancelled => status == AuthResultStatus.cancelled;
}

class _FetchResult {
  final UserProfile profile;
  final bool isNew;
  const _FetchResult(this.profile, {required this.isNew});
}

/// Orquestra google_sign_in + firebase_auth + Realtime Database.
///
/// REGRA: único lugar que toca FirebaseAuth e GoogleSignIn.
/// StorageService NÃO importa AuthService — dependência só em uma direção.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ── Stream de estado ──────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ── Login com Google ──────────────────────────────────────
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();
      if (googleAccount == null) return AuthResult.cancelled();

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // 1. Busca ou cria o perfil no Firebase
      final fetchResult = await _fetchOrCreateProfile(user);

      // 2. Persiste perfil localmente ANTES de retornar
      await StorageService.instance.saveProfile(fetchResult.profile);

      // 3. Baixa hábitos remotos e salva APENAS localmente.
      //    Só para usuários retornando — novos não têm hábitos no banco ainda.
      //    Usa saveAllHabitsLocal (sem re-sync para o Firebase — sem loop).
      if (!fetchResult.isNew) {
        final remoteHabits = await _fetchHabitsRemote(user.uid);
        if (remoteHabits.isNotEmpty) {
          await StorageService.instance.saveAllHabitsLocal(remoteHabits);
        }
      }

      return AuthResult.success(
        fetchResult.profile,
        isNewUser: fetchResult.isNew,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') return AuthResult.networkError();
      return AuthResult.unknownError(e.message ?? 'Erro de autenticação.');
    } catch (e) {
      debugPrint('AuthService.signInWithGoogle error: $e');
      return AuthResult.unknownError('Algo deu errado. Tente novamente.');
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  // ── Salvar perfil (local + remoto) ────────────────────────
  Future<void> saveProfile(UserProfile profile) async {
    await StorageService.instance.saveProfile(profile);
    if (profile.isFirebaseUser) {
      await _db.child('users/${profile.uid}').update(profile.toFirebase());
    }
  }

  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _db.child('users/$uid/photoUrl').set(photoUrl);
  }

  // ── Sincronização de hábitos ──────────────────────────────

  /// Salva um hábito no Firebase RTDB.
  /// Chamado por HomeScreen/HabitFormScreen APÓS saveHabitLocal.
  Future<void> saveHabitRemote(Habit habit) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.child('users/${user.uid}/habits/${habit.id}').set(habit.toJson());
    } catch (e) {
      debugPrint('saveHabitRemote error: $e');
    }
  }

  /// Remove um hábito do Firebase RTDB.
  Future<void> deleteHabitRemote(String habitId) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.child('users/${user.uid}/habits/$habitId').remove();
    } catch (e) {
      debugPrint('deleteHabitRemote error: $e');
    }
  }

  // ── Privados ──────────────────────────────────────────────

  Future<void> _updateHistory(String uid) async {
    try {
      await _db.child('history/$uid').update({
        'last_login': DateTime.now().toUtc().toIso8601String(),
      });
    } catch (e) {
      debugPrint('_updateHistory error: $e');
    }
  }

  Future<List<Habit>> _fetchHabitsRemote(String uid) async {
    try {
      final snapshot = await _db.child('users/$uid/habits').get();
      if (!snapshot.exists) return [];

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final habits = <Habit>[];
      data.forEach((key, value) {
        if (value is Map) {
          try {
            habits.add(Habit.fromJson(Map<String, dynamic>.from(value)));
          } catch (e) {
            debugPrint('Erro ao parsear hábito remoto $key: $e');
          }
        }
      });
      return habits;
    } catch (e) {
      debugPrint('_fetchHabitsRemote error: $e');
      return [];
    }
  }

  Future<_FetchResult> _fetchOrCreateProfile(User user) async {
    final ref = _db.child('users/${user.uid}');
    final snapshot = await ref.get();
    await _updateHistory(user.uid);

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return _FetchResult(
        UserProfile.fromFirebase(user.uid, data),
        isNew: false,
      );
    }

    // Novo no Firebase — já usava offline?
    final local = StorageService.instance.loadProfile();
    late final UserProfile profileToSave;

    if (local != null) {
      profileToSave = local.copyWith(
        uid: user.uid,
        email: user.email ?? local.email,
        photoUrl: local.photoUrl.isEmpty
            ? (user.photoURL ?? '')
            : local.photoUrl,
      );
    } else {
      profileToSave = UserProfile.newFromGoogle(
        uid: user.uid,
        displayName: user.displayName ?? 'Aventureiro',
        email: user.email ?? '',
        photoUrl: user.photoURL ?? '',
      );
    }

    await ref.set(profileToSave.toFirebase());
    await _db.child('history/${user.uid}').set({
      'last_login': DateTime.now().toUtc().toIso8601String(),
      'completed_tasks': 0,
    });

    return _FetchResult(profileToSave, isNew: true);
  }
}
