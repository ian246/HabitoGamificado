import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';

/// ─────────────────────────────────────────────────────────────
/// Chave SharedPreferences para o caminho da foto de perfil
/// ─────────────────────────────────────────────────────────────
const kProfilePhotoKey = 'profile_photo_path';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _pinCtrl  = TextEditingController();
  final _picker   = ImagePicker();

  UserProfile? _profile;
  String?      _photoPath;
  bool         _obscure = true;
  String?      _erro;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shake;

  @override
  void initState() {
    super.initState();
    _profile = StorageService.instance.loadProfile();
    _loadPhoto();

    _shakeCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 420),
    );
    _shake = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: _ShakeCurve()),
    );
  }

  Future<void> _loadPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final path  = prefs.getString(kProfilePhotoKey);
    if (path != null && File(path).existsSync()) {
      setState(() => _photoPath = path);
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                    color: AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title:   const Text('Câmera'),
              onTap:   () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title:   const Text('Galeria'),
              onTap:   () => Navigator.pop(context, ImageSource.gallery),
            ),
            if (_photoPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error),
                title: const Text('Remover foto'),
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove(kProfilePhotoKey);
                  setState(() => _photoPath = null);
                  if (!mounted) return;
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(
      source:    source,
      maxWidth:  400,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kProfilePhotoKey, picked.path);
    setState(() => _photoPath = picked.path);
  }

  @override
  void dispose() {
    _pinCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _entrar() {
    if (_profile == null) return;
    if (_pinCtrl.text == _profile!.pinHash) {
      StorageService.instance.saveProfile(_profile!.atualizarAcesso());
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      setState(() => _erro = 'PIN incorreto. Tente novamente.');
      _pinCtrl.clear();
      _shakeCtrl.forward(from: 0);
    }
  }

  void _resetar() => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title:   const Text('Redefinir app?'),
      content: const Text('Apagará todos os hábitos e conquistas.'),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child:     const Text('Cancelar')),
        TextButton(
            onPressed: () async {
              await StorageService.instance.clearAll();
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove(kProfilePhotoKey);
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignupScreen()),
                (_) => false,
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Apagar tudo')),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_profile == null) return const SignupScreen();
    final theme = AppColors.themeForXp(_profile!.xpTotal);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Avatar com botão de foto ──────────────
              GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius:          52,
                      backgroundColor: theme.surface,
                      backgroundImage: _photoPath != null
                          ? FileImage(File(_photoPath!))
                          : null,
                      child: _photoPath == null
                          ? Text(
                              _profile!.apelido.isNotEmpty
                                  ? _profile!.apelido[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize:   38,
                                fontWeight: FontWeight.w700,
                                color:      theme.primary,
                              ),
                            )
                          : null,
                    ),
                    Container(
                      width:  30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:  AppColors.primary,
                        shape:  BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          size: 15, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Toque para alterar foto',
                style: AppTextStyles.xpLabel,
              ),
              const SizedBox(height: 20),

              // ── Nome e nível ──────────────────────────
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color:        AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nível ${_profile!.nivel} — ${_profile!.nomeDonivel}',
                  style: AppTextStyles.levelBadge,
                ),
              ),

              const Spacer(flex: 2),

              // ── Campo de PIN com shake ─────────────────
              Text('Digite seu PIN', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 10),
              AnimatedBuilder(
                animation: _shake,
                builder: (_, child) => Transform.translate(
                  offset: Offset(_shake.value * 8, 0),
                  child: child,
                ),
                child: TextFormField(
                  controller:   _pinCtrl,
                  keyboardType: TextInputType.number,
                  obscureText:  _obscure,
                  maxLength:    4,
                  textAlign:    TextAlign.center,
                  style: const TextStyle(
                      fontSize: 26, letterSpacing: 14, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText:    '••••',
                    errorText:   _erro,
                    suffixIcon:  IconButton(
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
              ),
              const SizedBox(height: 20),
              SizedBox(
                width:  double.infinity,
                height: 52,
                child:  FilledButton(
                  onPressed: _entrar,
                  style:     FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Entrar',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),

              const Spacer(flex: 1),

              TextButton(
                onPressed: _resetar,
                child: Text('Redefinir app',
                    style: AppTextStyles.xpLabel
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// Curva de tremor para PIN errado
class _ShakeCurve extends Curve {
  @override
  double transform(double t) {
    return (t < 0.5 ? 2 * t : 2 * (1 - t)) * (1 - t) * 2;
  }
}
