import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// ─────────────────────────────────────────────────────────────
/// HabitNavBar — NavigationBar customizada com indicador animado
///
/// Uso em HomeScreen:
///   bottomNavigationBar: HabitNavBar(
///     currentIndex: _currentIndex,
///     onTap: (i) => setState(() => _currentIndex = i),
///   )
/// ─────────────────────────────────────────────────────────────
class HabitNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const HabitNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Início',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart_rounded,
      label: 'Progresso',
    ),
    _NavItem(
      icon: Icons.emoji_events_outlined,
      activeIcon: Icons.emoji_events_rounded,
      label: 'Conquistas',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Perfil',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E2E27) : Colors.white;
    final border = isDark ? const Color(0xFF2E5040) : const Color(0xFFE3F0EA);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 60 : 15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(_items.length, (i) {
              return Expanded(
                child: _NavButton(
                  item: _items[i],
                  selected: currentIndex == i,
                  onTap: () => onTap(i),
                  isDark: isDark,
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _indicator;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.88,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _indicator = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));

    if (widget.selected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(_NavButton old) {
    super.didUpdateWidget(old);
    if (widget.selected != old.selected) {
      widget.selected ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = widget.isDark
        ? const Color(0xFF6B8880)
        : const Color(0xFF9BBAB2);

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Pill indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              width: widget.selected ? 48 : 0,
              height: 4,
              decoration: BoxDecoration(
                color: activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 6),

            // Icon com scale
            Transform.scale(
              scale: _scale.value,
              child: Icon(
                widget.selected ? widget.item.activeIcon : widget.item.icon,
                size: widget.selected ? 24 : 22,
                color: widget.selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 3),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: widget.selected ? 10.5 : 10,
                fontWeight: widget.selected ? FontWeight.w700 : FontWeight.w400,
                color: widget.selected ? activeColor : inactiveColor,
                letterSpacing: widget.selected ? 0.2 : 0,
              ),
              child: Text(widget.item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
