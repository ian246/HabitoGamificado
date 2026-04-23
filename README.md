# 🌱 HabitFlow

> App Flutter gamificado de rastreamento de hábitos — offline-first com sincronização Firebase opcional.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%5E3.9.2-0175C2?logo=dart)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-RTDB-FFCA28?logo=firebase)](https://firebase.google.com)
[![Plataforma](https://img.shields.io/badge/Plataforma-Android%20%7C%20Web-green)](#)

---

## Sobre o Projeto

O **HabitFlow** é um aplicativo de criação e acompanhamento de hábitos com sistema de gamificação completo. O usuário cria hábitos com subtarefas, define períodos do dia e frequências, e é recompensado com XP, níveis, molduras e conquistas conforme mantém suas rotinas.

O app funciona **100% offline** usando SharedPreferences como fonte primária de dados. O Firebase (Auth + Realtime Database) é opcional e ativado somente via login com Google, realizando sync unidirecional na entrada.

---

## Funcionalidades

- Criação de hábitos com subtarefas, ícone, cor, período (manhã/tarde/noite) e frequência (diário, seg–sex ou dias customizados)
- Sistema de XP e níveis (15 níveis: Broto → Lendário)
- 6 ranks visuais com molduras de perfil: Prata, Ouro, Platina, Esmeralda, Diamante e Mestre
- 8 trilhas de conquistas com 6 tiers cada (O Constante, O Dedicado, O Perfeccionista, O Madrugador, O Vespertino, O Noturno, O Colecionador, O Guerreiro)
- Sistema anti-XP-farming com `DailyActivity` e timestamp de monotonia
- Notificações locais diárias agendadas por hábito
- Login com Google e sincronização com Firebase Realtime Database
- Suporte a tema claro e escuro
- Exportação e importação de backup local

---

## Sistema de XP e Gamificação

| Ação | XP |
|---|---|
| Subtarefa concluída | +5 |
| Hábito 100% completo | +20 |
| Dia perfeito | +50 |
| Streak semanal (a cada 7 dias) | +30 |
| Nova moldura desbloqueada | +100 |

### Níveis

| Nível | Nome | XP mínimo |
|---|---|---|
| 1 | Broto | 0 |
| 2 | Muda | 150 |
| 3 | Arbusto | 350 |
| 4 | Árvore | 700 |
| 5 | Floresta | 1.200 |
| 6 | Estrela | 2.000 |
| 8 | Cosmos | 5.000 |
| 10 | Galáxia | 12.000 |
| 15 | Supernova | 20.000 |
| 50 | Imortal | 100.000 |
| 80 | Lendário | 250.000 |

### Ranks

| Níveis | Rank |
|---|---|
| 1–4 | 🥈 Prata |
| 5–14 | 🥇 Ouro |
| 15–29 | 🪙 Platina |
| 30–49 | 💚 Esmeralda |
| 50–79 | 💎 Diamante |
| 80+ | 🏆 Mestre |

---

## Stack Tecnológico

| Categoria | Pacote / Versão |
|---|---|
| Armazenamento local | `shared_preferences ^2.5.5` |
| Autenticação | `firebase_auth ^6.3.0` |
| Banco de dados em nuvem | `firebase_database ^12.2.0` |
| Login Google | `google_sign_in 6.2.1` ⚠️ fixado |
| Notificações | `flutter_local_notifications ^21.0.0` |
| Foto de perfil | `image_picker ^1.2.1` |
| Tipografia | `google_fonts ^8.0.2` (Poppins) |
| IDs únicos | `uuid ^4.5.3` |
| Internacionalização | `intl ^0.20.2` |

> ⚠️ `google_sign_in` está fixado em `6.2.1` **sem** `^`. Versões mais novas podem causar breaking changes com `firebase_auth`. Não incrementar sem testar.

---

## Estrutura de Pastas

```
lib/
├── main.dart                     # Entry point, HabitFlowApp, _SplashScreen
├── firebase_options.dart         # Gerado pelo FlutterFire CLI — não editar
├── models/
│   ├── habit.dart
│   ├── subtask.dart
│   ├── user_profile.dart
│   ├── achievement.dart
│   ├── achievement_trail.dart
│   └── daily_activity.dart
├── services/
│   ├── auth_service.dart
│   ├── storage_service.dart
│   ├── xp_service.dart
│   └── notification_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── profile_screen.dart
│   ├── achievements_screen.dart
│   ├── progress_screen.dart
│   ├── habit_detail_screen.dart
│   └── habit_form_screen.dart
├── widgets/
│   ├── xp_header.dart
│   ├── habit_card.dart
│   ├── achievement_badge_widget.dart
│   ├── custom_nav_bar.dart
│   ├── rank_badge.dart
│   └── subtask_tile.dart
└── core/
    ├── theme/
    │   ├── app_colors.dart
    │   ├── app_text_styles.dart
    │   └── app_theme.dart
    ├── utils/
    │   ├── date_utils.dart
    │   └── xp_calculator.dart
    └── painters/
        ├── frame_painter.dart
        ├── progress_ring_painter.dart
        └── week_chart_painter.dart
```

---

## Assets

Os assets de rank e conquistas devem estar presentes com os nomes exatos abaixo:

```
assets/
├── frames/
│   ├── prata_frame.png
│   ├── ouro_frame.png
│   ├── platina_frame.png
│   ├── esmeralda_frame.png
│   ├── diamante_frame.png
│   └── mestre_frame.png
└── conquests/
    ├── conquista_prata.png
    ├── conquista_ouro.png
    ├── conquista_platina.png
    ├── conquista_esmeralda.png
    ├── conquista_diamante.png
    └── conquista_mestre.png
```

---

## Configuração e Instalação

### Pré-requisitos

- Flutter SDK `^3.x` com Dart `^3.9.2`
- Android Studio ou VS Code com extensão Flutter
- Conta Firebase com projeto configurado (opcional para modo offline)

### Passos

```bash
# 1. Clone o repositório
git clone https://github.com/ian246/HabitoGamificado.git
cd flutter_app_habitos

# 2. Instale as dependências
flutter pub get

# 3. Configure o Firebase (opcional)
# Execute o FlutterFire CLI e substitua o firebase_options.dart gerado
flutterfire configure

# 4. Execute o app
flutter run
```

> 📱 **Notificações locais funcionam apenas em dispositivo físico.** Não espere que funcionem no emulador.

---

## Arquitetura

O HabitFlow segue uma arquitetura de camadas com separação clara de responsabilidades:

- **Models** — imutáveis, toda alteração retorna nova instância via `copyWith()`
- **Services** — toda lógica de negócio (XP, streak, sync); padrão Singleton
- **Screens** — apenas orquestração de UI; nunca calculam XP nem salvam perfil diretamente
- **Widgets** — componentes reutilizáveis sem lógica de negócio

O roteamento é controlado por um `StreamBuilder<User?>` no `main.dart` que ouve `AuthService.authStateChanges`. **Nunca usar `Navigator.pushReplacement` para a transição Login → Home.**

### Fluxo de XP (Subtarefa)

```
Usuário marca subtarefa
  └─> XpService.onSubtaskChecked()
        ├─ Valida DailyActivity (anti-double-reward)
        ├─ Valida timestamp de monotonia
        ├─ Atualiza Habit (imutável, nova instância)
        ├─ Salva localmente via StorageService
        ├─ Calcula XP e verifica level-up
        ├─ Atualiza trilhas (guerreiro, dedicado, madrugador...)
        ├─ Dispara notificações se houver recompensa
        └─ Sync remoto se Firebase user
```

---

## Regras de Desenvolvimento

1. **Modelos são imutáveis** — use `copyWith()`, nunca modifique diretamente.
2. **Lógica de negócio nunca nas Screens** — pertence a `services/` ou aos próprios models.
3. **XpService é o único orquestrador de XP** — Screens chamam `XpService` e recebem `XpResult`.
4. **StorageService é o único que acessa SharedPreferences** — nenhuma outra classe importa `SharedPreferences`.
5. **StorageService NÃO importa AuthService** — dependência unidirecional obrigatória.
6. **Cores via `AppColors` ou `Theme`** — nunca hardcodar hex nas Screens/Widgets.
7. **Tipografia via `AppTextStyles`** — nunca criar `TextStyle` inline com `fontSize` ou `color` hardcoded.
8. **`RepaintBoundary` em CustomPainters** — todo painter animado deve ser envolvido.

---

## Design System

- **Tema:** Material 3, seed `#4A9E7C` (verde menta)
- **Fonte:** Poppins (via `google_fonts`)
- **Cor primária:** `#4A9E7C`
- **Cor de streak:** `#F0B86A` (âmbar)
- **Suporte a dark mode:** controlado pelo usuário via toggle no perfil

---

## Convenções de Commits

| Prefixo | Uso |
|---|---|
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `chore:` | Config, pubspec, estrutura |
| `style:` | Formatação, cores, sem lógica |
| `refactor:` | Melhoria sem mudar comportamento |
| `docs:` | Documentação |

---

## Licença

Projeto pessoal. Todos os direitos reservados ao autor.
