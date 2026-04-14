import 'package:flutter/material.dart';

/// ─────────────────────────────────────────────────────────────
/// AppColors — Design System HabitFlow
///
/// Organização:
///   • Paleta base (seed + neutros)
///   • Regra 60 / 30 / 10
///   • Cores semânticas (streak, sucesso, erro)
///   • Cores das molduras de conquista
///   • Cores dos níveis (tema por nível de XP)
/// ─────────────────────────────────────────────────────────────
abstract final class AppColors {
  // ── Seed color (Material 3 gera tudo a partir daqui) ────────
  static const Color seed = Color(0xFF4A9E7C);

  // ── 60% — Primário / Fundo ───────────────────────────────────
  static const Color background       = Color(0xFFF0F7F4); // fundo das telas
  static const Color surfaceCard      = Color(0xFFE3F0EA); // fundo dos cards
  static const Color surfaceHover     = Color(0xFFB8E0CE); // hover / borda suave

  // ── 30% — Secundário / Navegação ─────────────────────────────
  static const Color navBackground    = Color(0xFFEBF3FF); // drawer + nav bar
  static const Color navBorder        = Color(0xFFC8DDF5); // borda da nav
  static const Color blueAccent       = Color(0xFF3A6B9E); // azul de suporte

  // ── 10% — Destaque ───────────────────────────────────────────
  static const Color primary          = Color(0xFF4A9E7C); // FAB, checks, progresso
  static const Color primaryDark      = Color(0xFF2A5C4E); // texto título, AppBar

  // ── Texto ────────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFF2A5C4E);
  static const Color textSecondary    = Color(0xFF6B8880);
  static const Color textHint         = Color(0xFFA8C4BC);

  // ── Semânticas ───────────────────────────────────────────────
  static const Color streak           = Color(0xFFF0B86A); // âmbar — sequência de dias
  static const Color streakDark       = Color(0xFF8A5C00);
  static const Color success          = Color(0xFF4A9E7C);
  static const Color error            = Color(0xFFE57373);
  static const Color warning          = Color(0xFFF0B86A);

  // ── Dark mode ────────────────────────────────────────────────
  static const Color darkSurface      = Color(0xFF1A2821); // fundo escuro
  static const Color darkCard         = Color(0xFF243B31); // cards no dark
  static const Color darkBorder       = Color(0xFF2E5040); // bordas no dark

  // ─────────────────────────────────────────────────────────────
  // MOLDURAS — cores por raridade
  // Cada moldura tem: ring (cor principal), glow (brilho),
  // shine (reflexo interno), text (label da conquista)
  // ─────────────────────────────────────────────────────────────
  static const FrameColors silver = FrameColors(
    name:  'Prata',
    ring:  Color(0xFFC0C0C0),
    glow:  Color(0xFFE8E8E8),
    shine: Color(0xFFF5F5F5),
    text:  Color(0xFF707070),
    icon:  Color(0xFFB0B0B0),
  );

  static const FrameColors gold = FrameColors(
    name:  'Ouro',
    ring:  Color(0xFFD4AF37),
    glow:  Color(0xFFFFD700),
    shine: Color(0xFFFFF3B0),
    text:  Color(0xFF8A6800),
    icon:  Color(0xFFFFCC00),
  );

  static const FrameColors platinum = FrameColors(
    name:  'Platina',
    ring:  Color(0xFFA8A8B8),
    glow:  Color(0xFFE5E4E2),
    shine: Color(0xFFF0F0F5),
    text:  Color(0xFF5A5A6A),
    icon:  Color(0xFFD0D0E0),
  );

  static const FrameColors emerald = FrameColors(
    name:  'Esmeralda',
    ring:  Color(0xFF50C878),
    glow:  Color(0xFF7EEAA0),
    shine: Color(0xFFC8F5D8),
    text:  Color(0xFF1A6B3A),
    icon:  Color(0xFF2EAA5A),
  );

  static const FrameColors diamond = FrameColors(
    name:  'Diamante',
    ring:  Color(0xFF4FC3F7),
    glow:  Color(0xFF81D4FA),
    shine: Color(0xFFE1F5FE),
    text:  Color(0xFF0A5A7A),
    icon:  Color(0xFF29B6F6),
  );

  static const FrameColors master = FrameColors(
    name:  'Mestre',
    ring:  Color(0xFF9B59B6),
    glow:  Color(0xFFC39BD3),
    shine: Color(0xFFEDD6FF),
    text:  Color(0xFF5B0E8F),
    icon:  Color(0xFFA569BD),
  );

  /// Determina a moldura visual baseada no nível de XP
  static FrameColors frameForLevel(int level) {
    if (level >= 80) return master;
    if (level >= 50) return diamond;
    if (level >= 30) return emerald;
    if (level >= 15) return platinum;
    if (level >= 5)  return gold;
    return silver;
  }

  /// Determina a moldura visual baseada em dias de streak (para conquistas específicas)
  static FrameColors frameForDays(int days) {
    if (days >= 300) return master;
    if (days >= 200) return diamond;
    if (days >= 150) return emerald;
    if (days >= 75)  return platinum;
    if (days >= 30)  return gold;
    return silver;
  }

  // ─────────────────────────────────────────────────────────────
  // NÍVEIS — cor de tema por nível de XP
  // ─────────────────────────────────────────────────────────────
  static const List<LevelTheme> levelThemes = [
    LevelTheme(level: 1,  name: 'Broto',     xp: 0,     primary: Color(0xFFA8D5B5), surface: Color(0xFFF0F7F4)),
    LevelTheme(level: 2,  name: 'Muda',      xp: 150,   primary: Color(0xFF7EC8A0), surface: Color(0xFFEAF5EE)),
    LevelTheme(level: 3,  name: 'Arbusto',   xp: 350,   primary: Color(0xFF4A9E7C), surface: Color(0xFFE3F0EA)),
    LevelTheme(level: 4,  name: 'Árvore',    xp: 700,   primary: Color(0xFF2E7D6B), surface: Color(0xFFDCEDE5)),
    LevelTheme(level: 5,  name: 'Floresta',  xp: 1200,  primary: Color(0xFF1B5E50), surface: Color(0xFFD5EAE0)),
    LevelTheme(level: 6,  name: 'Estrela',   xp: 2000,  primary: Color(0xFF3A6B9E), surface: Color(0xFFE8F0FA)),
    LevelTheme(level: 7,  name: 'Oceano',    xp: 3000,  primary: Color(0xFF1A4B7A), surface: Color(0xFFDEEAF5)),
    LevelTheme(level: 8,  name: 'Cosmos',    xp: 5000,  primary: Color(0xFF2D1B69), surface: Color(0xFFEAE5F5)),
    LevelTheme(level: 9,  name: 'Nebulosa',  xp: 8000,  primary: Color(0xFF4A0E8F), surface: Color(0xFFF0E8FA)),
    LevelTheme(level: 10, name: 'Galáxia',   xp: 12000, primary: Color(0xFF5B0E8F), surface: Color(0xFFF5E8FA)),
    LevelTheme(level: 15, name: 'Supernova', xp: 20000, primary: Color(0xFF7B1FA2), surface: Color(0xFFF3E5F5)),
    LevelTheme(level: 20, name: 'Quasar',    xp: 35000, primary: Color(0xFF6A1B9A), surface: Color(0xFFEDE7F6)),
    LevelTheme(level: 30, name: 'Zênite',    xp: 55000, primary: Color(0xFF4A148C), surface: Color(0xFFF3E5F5)),
    LevelTheme(level: 50, name: 'Imortal',   xp: 100000,primary: Color(0xFF311B92), surface: Color(0xFFEDE7F6)),
    LevelTheme(level: 80, name: 'Lendário',  xp: 250000,primary: Color(0xFF1A237E), surface: Color(0xFFE8EAF6)),
  ];

  /// Retorna o LevelTheme pelo XP atual do usuário
  static LevelTheme themeForXp(int xp) {
    LevelTheme current = levelThemes.first;
    for (final t in levelThemes) {
      if (xp >= t.xp) current = t;
    }
    return current;
  }
}

// ─────────────────────────────────────────────────────────────
// Data classes auxiliares
// ─────────────────────────────────────────────────────────────

/// Agrupa as cores de uma moldura de conquista
class FrameColors {
  final String name;
  final Color  ring;   // anel externo
  final Color  glow;   // brilho / anel tracejado
  final Color  shine;  // reflexo interno
  final Color  text;   // cor do label
  final Color  icon;   // ícone decorativo

  const FrameColors({
    required this.name,
    required this.ring,
    required this.glow,
    required this.shine,
    required this.text,
    required this.icon,
  });
}

/// Agrupa as cores de tema de um nível
class LevelTheme {
  final int    level;
  final String name;
  final int    xp;
  final Color  primary;
  final Color  surface;

  const LevelTheme({
    required this.level,
    required this.name,
    required this.xp,
    required this.primary,
    required this.surface,
  });

  /// XP necessário para o próximo nível
  int get xpForNext {
    final themes = AppColors.levelThemes;
    final idx    = themes.indexWhere((t) => t.level == level);
    if (idx == -1 || idx >= themes.length - 1) return xp;
    return themes[idx + 1].xp;
  }

  /// Progresso de 0.0 a 1.0 dentro do nível atual
  double progressTo(int currentXp) {
    final diff = xpForNext - xp;
    if (diff <= 0) return 1.0;
    return ((currentXp - xp) / diff).clamp(0.0, 1.0);
  }
}
