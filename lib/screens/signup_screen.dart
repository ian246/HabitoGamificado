import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _apelidoCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  final _pinConfCtrl = TextEditingController();
  bool _obscurePin = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _apelidoCtrl.dispose();
    _pinCtrl.dispose();
    _pinConfCtrl.dispose();
    super.dispose();
  }

  Future<void> _criarPerfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final profile = UserProfile.create(
      nome: _nomeCtrl.text.trim(),
      apelido: _apelidoCtrl.text.trim(),
      pinHash: _pinCtrl.text, // v1: texto simples. v2: use crypto SHA-256
    );

    await AuthService.instance.saveProfile(profile);

    // Solicita permissão de notificação
    await NotificationService.instance.requestPermission();

    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  Future<void> _handleGoogleSignup() async {
    setState(() => _isGoogleLoading = true);
    try {
      final user = await AuthService.instance.signInWithGoogle();
      if (user != null) {
        // Sucesso! O AuthService já cuidou de criar/vincular o perfil.
        // O main.dart StreamBuilder vai redirecionar sozinho,
        // mas podemos forçar se necessário.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao entrar com Google: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // ── Cabeçalho ─────────────────────────────
                Text('🌱', style: const TextStyle(fontSize: 48)),
                const SizedBox(height: 12),
                Text(
                  'Crie seu perfil',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Seus dados ficam apenas neste dispositivo.',
                  style: AppTextStyles.greeting,
                ),
                const SizedBox(height: 36),

                // ── Campos ────────────────────────────────
                _label('Nome completo'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nomeCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex: João Silva',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe seu nome'
                      : null,
                ),
                const SizedBox(height: 16),

                _label('Apelido (exibido no app)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _apelidoCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex: João',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Informe um apelido'
                      : null,
                ),
                const SizedBox(height: 16),

                _label('PIN de 4 dígitos'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: _obscurePin,
                  maxLength: 4,
                  decoration: InputDecoration(
                    hintText: '••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePin
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePin = !_obscurePin),
                    ),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Informe um PIN';
                    if (v.length < 4) return 'PIN deve ter 4 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                _label('Confirmar PIN'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _pinConfCtrl,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 4,
                  decoration: const InputDecoration(
                    hintText: '••••',
                    prefixIcon: Icon(Icons.lock_outline_rounded),
                    counterText: '',
                  ),
                  validator: (v) {
                    if (v != _pinCtrl.text) return 'PINs não coincidem';
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // ── Botão ─────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: (_isLoading || _isGoogleLoading)
                        ? null
                        : _criarPerfil,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Criar meu perfil offline',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Divisor ───────────────────────────────
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OU',
                        style: AppTextStyles.xpLabel.copyWith(fontSize: 12),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Botão Google ──────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: (_isLoading || _isGoogleLoading)
                        ? null
                        : _handleGoogleSignup,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isGoogleLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.network(
                                'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_\"G\"_Logo.svg',
                                width: 20,
                                height: 20,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.account_circle_outlined,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Começar com Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Info ──────────────────────────────────
                Center(
                  child: Text(
                    'Dados salvos localmente · sem conta · sem internet',
                    style: AppTextStyles.xpLabel,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AppTextStyles.sectionLabel);
}
