import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import 'signup_screen.dart';
import 'home_screen.dart';
import '../main.dart';

// Mantida para que profile_screen.dart continue importando sem quebrar.
const kProfilePhotoKey = 'profile_photo_path';

/// ─────────────────────────────────────────────────────────────
/// LoginScreen v3 — tela de boas-vindas
///
/// Fluxo:
///   - Botão Google → signInWithGoogle()
///     • Novo usuário (isNewUser = true)  → SignupScreen com perfil pré-preenchido
///     • Usuário retornando               → HomeScreen
///   - Link "Criar perfil offline"        → SignupScreen (sem Google)
///
/// O StreamBuilder no main.dart fica pausado (via setSigningIn) enquanto
/// o Google sign-in está em andamento, evitando conflito de navegação.
/// ─────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    // Pausa o StreamBuilder para não sobrepor a navegação
    HabitFlowApp.appKey.currentState?.setSigningIn(true);
    setState(() => _isLoading = true);

    try {
      final result = await AuthService.instance.signInWithGoogle();

      // Resetamos o flag SEMPRE, usando o GlobalKey para garantir que funcione
      // mesmo que esta tela (LoginScreen) tenha sido desmontada pelo StreamBuilder.
      HabitFlowApp.appKey.currentState?.setSigningIn(false);

      if (!mounted) return;
      setState(() => _isLoading = false);

      switch (result.status) {
        case AuthResultStatus.success:
          // O StreamBuilder no main.dart cuidará da navegação automaticamente
          // baseando-se no snapshot.data (Firebase) e no setupComplete (Storage).
          break;

        case AuthResultStatus.cancelled:
          break;

        case AuthResultStatus.networkError:
        case AuthResultStatus.unknownError:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Tente novamente.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
      }
    } catch (e) {
      HabitFlowApp.appKey.currentState?.setSigningIn(false);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToOfflineSignup() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SignupScreen()),
    );
  }

  void _mostrarResetDialog() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Redefinir app?'),
          content: const Text(
              'Isso encerrará sua sessão. Os dados locais são preservados.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await AuthService.instance.signOut();
                await StorageService.instance.deleteProfile();
                // StreamBuilder detecta e volta para LoginScreen
              },
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Redefinir'),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Ícone ─────────────────────────────────────────────
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  Icons.spa_rounded,
                  size: 42,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),

              // ── Título ────────────────────────────────────────────
              Text(
                'HabitFlow',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: -0.5,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Bem-vindo! 👋',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Transforme disciplina em evolução.\nAcompanhe hábitos e suba de nível.',
                style: AppTextStyles.greeting,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ── Botão Google ──────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const SizedBox(
                        height: 54,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _GoogleSignInButton(onTap: _handleGoogleLogin),
              ),

              const SizedBox(height: 16),

              // ── Opção offline ─────────────────────────────────────
              TextButton(
                onPressed: _isLoading ? null : _goToOfflineSignup,
                child: Text(
                  'Usar sem conta Google',
                  style: AppTextStyles.xpLabel.copyWith(
                    color: AppColors.textSecondary,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: 6),
              Text(
                'Com Google, suas conquistas ficam salvas na nuvem.',
                style: AppTextStyles.xpLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Rodapé ───────────────────────────────────────────
              TextButton(
                onPressed: _mostrarResetDialog,
                child: Text(
                  'Redefinir app',
                  style: AppTextStyles.xpLabel.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Botão estilizado de Sign In with Google
// ─────────────────────────────────────────────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _GoogleLogo(),
            const SizedBox(width: 12),
            Text(
              'Continuar com Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(22, 22),
      painter: _GoogleLogoPainter(
        bgColor: Theme.of(context).scaffoldBackgroundColor,
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  final Color bgColor;
  const _GoogleLogoPainter({required this.bgColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()..style = PaintingStyle.fill;

    const colors = [
      Color(0xFF4285F4),
      Color(0xFF34A853),
      Color(0xFFFBBC05),
      Color(0xFFEA4335),
    ];

    for (int i = 0; i < 4; i++) {
      paint.color = colors[i];
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        (i * 90 - 45) * 3.14159 / 180,
        90 * 3.14159 / 180,
        true,
        paint,
      );
    }

    // Círculo branco central para criar o "G" oco
    paint.color = bgColor;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter old) =>
      old.bgColor != bgColor;
}
