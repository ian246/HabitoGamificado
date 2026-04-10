import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinCtrl = TextEditingController();
  UserProfile? _profile;
  bool _obscure = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _profile = StorageService.instance.loadProfile();
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  void _entrar() {
    final pin = _pinCtrl.text;
    if (_profile == null) return;

    if (pin == _profile!.pinHash) {
      // Atualiza último acesso
      StorageService.instance.saveProfile(_profile!.atualizarAcesso());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _erro = 'PIN incorreto. Tente novamente.');
      _pinCtrl.clear();
    }
  }

  void _resetar() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Redefinir app?'),
        content: const Text(
          'Isso apagará todos os seus hábitos e conquistas. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await StorageService.instance.clearAll();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
                (_) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Apagar tudo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const SignupScreen();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),

              // ── Avatar + saudação ──────────────────────
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.surfaceCard,
                child: Text(
                  _profile!.apelido.isNotEmpty
                      ? _profile!.apelido[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bem-vindo de volta,',
                style: AppTextStyles.greeting,
              ),
              const SizedBox(height: 4),
              Text(
                _profile!.apelido,
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nível ${_profile!.nivel} — ${_profile!.nomeDonivel}',
                  style: AppTextStyles.levelBadge,
                ),
              ),
              const SizedBox(height: 48),

              // ── PIN ────────────────────────────────────
              Text('Digite seu PIN', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              TextFormField(
                controller:   _pinCtrl,
                keyboardType: TextInputType.number,
                obscureText:  _obscure,
                maxLength:    4,
                textAlign:    TextAlign.center,
                style: const TextStyle(fontSize: 24, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '••••',
                  errorText: _erro,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                onChanged: (_) {
                  if (_erro != null) setState(() => _erro = null);
                  if (_pinCtrl.text.length == 4) _entrar();
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _entrar,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Entrar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const Spacer(),

              TextButton(
                onPressed: _resetar,
                child: Text('Redefinir app',
                    style: AppTextStyles.xpLabel
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
