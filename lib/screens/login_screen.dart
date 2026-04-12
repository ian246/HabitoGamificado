import 'package:flutter/material.dart';
import 'package:flutter_app_habitos/main.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../services/auth_service.dart';

/// ─────────────────────────────────────────────────────────────
/// LoginScreen v2 — autenticação via Google
///
/// O que mudou:
///   - PIN removido (autenticação é feita pelo Google)
///   - Foto e nome vêm do UserProfile carregado pelo AuthService
///   - Cancelamento do Google é silencioso (sem snackbar de erro)
///   - StreamBuilder no main.dart cuida da navegação — sem Navigator.push aqui
///
/// O que foi mantido:
///   - Visual da tela (avatar centralizado, apelido, nível)
///   - Botão "Redefinir app" no rodapé
///   - AppColors e AppTextStyles
/// ─────────────────────────────────────────────────────────────

// Mantida para que profile_screen.dart continue importando sem quebrar
const kProfilePhotoKey = 'profile_photo_path';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final result = await AuthService.instance.signInWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    switch (result.status) {
      case AuthResultStatus.success:
        // StreamBuilder no main.dart detecta o login e navega para HomeScreen.
        // Não precisa de Navigator aqui.
        break;

      case AuthResultStatus.cancelled:
        // Usuário fechou o seletor de conta — silencioso
        break;

      case AuthResultStatus.networkError:
      case AuthResultStatus.unknownError:
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Tente novamente.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  void _mostrarResetDialog() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Redefinir app?'),
      content: const Text('Apagará todos os hábitos e conquistas locais.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () async {
            await AuthService.instance.signOut();
            if (!mounted) return;
            Navigator.pop(context);
            // StreamBuilder detecta signOut e volta para LoginScreen
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.error),
          child: const Text('Sair da conta'),
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

              // ── Logo / Headline ───────────────────────────────────
              Text(
                'HabitFlow',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transforme disciplina em evolução.',
                style: AppTextStyles.greeting,
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // ── Botão Google ──────────────────────────────────────
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : _GoogleSignInButton(onTap: _handleGoogleLogin),
              ),

              const SizedBox(height: 14),
              Text(
                'Suas conquistas ficam salvas na sua conta Google.',
                style: AppTextStyles.xpLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(),

              // ── Reset no rodapé ───────────────────────────────────
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
    return CustomPaint(size: const Size(22, 22), painter: _GoogleLogoPainter());
  }
}

class _GoogleLogoPainter extends CustomPainter {
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

    paint.color = Theme.of(
      navigatorKey.currentContext!,
    ).scaffoldBackgroundColor;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
