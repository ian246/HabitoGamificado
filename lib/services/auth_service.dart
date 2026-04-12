import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_profile.dart';
import 'storage_service.dart';

/// Resultado tipado do login — Screens não precisam de try/catch.
enum AuthResultStatus { success, cancelled, networkError, unknownError }

class AuthResult {
  final AuthResultStatus status;
  final UserProfile? profile;
  final String? errorMessage;

  const AuthResult._({required this.status, this.profile, this.errorMessage});

  factory AuthResult.success(UserProfile p) =>
      AuthResult._(status: AuthResultStatus.success, profile: p);
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

/// Orquestra google_sign_in + firebase_auth + Realtime Database.
///
/// REGRA do projeto: único lugar que toca FirebaseAuth e GoogleSignIn.
/// Nenhuma Screen chama essas libs diretamente.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // ── Stream de estado ──────────────────────────────────────
  /// Usado pelo StreamBuilder no main.dart.
  /// Emite null → LoginScreen, emite User → HomeScreen.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ── Login com Google ──────────────────────────────────────
  Future<AuthResult> signInWithGoogle() async {
    try {
      final googleAccount = await _googleSignIn.signIn();

      // Usuário fechou o seletor de conta — silencioso
      if (googleAccount == null) return AuthResult.cancelled();

      final googleAuth = await googleAccount.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Busca ou cria o perfil unificado (gamificação + Firebase)
      final profile = await _fetchOrCreateProfile(user);

      // Persiste localmente para acesso offline (mantém lógica do StorageService)
      await StorageService.instance.saveProfile(profile);

      return AuthResult.success(profile);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'network-request-failed') return AuthResult.networkError();
      return AuthResult.unknownError(e.message ?? 'Erro de autenticação.');
    } catch (_) {
      return AuthResult.unknownError('Algo deu errado. Tente novamente.');
    }
  }

  // ── Logout ────────────────────────────────────────────────
  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
    // NÃO limpa SharedPreferences — dados ficam para quando voltar
  }

  // ── Sync do perfil completo ───────────────────────────────

  /// Salva o perfil unificado:
  ///   1. Local (SharedPreferences) via StorageService — acesso offline
  ///   2. Remoto (Realtime Database) — backup em nuvem
  ///
  /// Chamado pelo XpService após ganho de XP (igual ao saveProfile original).
  Future<void> saveProfile(UserProfile profile) async {
    await StorageService.instance.saveProfile(profile);
    if (profile.isFirebaseUser) {
      await _db.child('users/${profile.uid}').update(profile.toFirebase());
    }
  }

  /// Atualiza apenas a foto de perfil no banco (chamado ao trocar foto).
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    await _db.child('users/$uid/photoUrl').set(photoUrl);
  }

  /// Registra o último login no nó history.
  Future<void> _updateHistory(String uid) async {
    await _db.child('history/$uid').update({
      'last_login': DateTime.now().toUtc().toIso8601String(),
    });
  }

  // ── Lógica de novo vs. retornando ────────────────────────
  Future<UserProfile> _fetchOrCreateProfile(User user) async {
    final ref = _db.child('users/${user.uid}');
    final snapshot = await ref.get();

    await _updateHistory(user.uid);

    if (snapshot.exists) {
      // Usuário retornando do Firebase — carrega o perfil completo do banco
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return UserProfile.fromFirebase(user.uid, data);
    } else {
      // É novo no Google. Mas já usava offline localmente?
      final currentLocal = StorageService.instance.loadProfile();
      
      late final UserProfile profileToSave;
      if (currentLocal != null) {
        // Upgrade da conta local para conta na nuvem (preserva XP, níveis e Trilhas)
        profileToSave = currentLocal.copyWith(
          uid: user.uid,
          email: user.email ?? currentLocal.email,
          photoUrl: currentLocal.photoUrl.isEmpty ? (user.photoURL ?? '') : currentLocal.photoUrl,
        );
      } else {
        // Obviamente, usuário completamente novo
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
      return profileToSave;
    }
  }
}
