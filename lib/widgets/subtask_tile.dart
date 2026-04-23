import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text_styles.dart';
import '../models/subtask.dart';

class SubtaskTile extends StatelessWidget {
  final Subtask subtask;
  final VoidCallback? onToggle;
  final bool interactive;

  const SubtaskTile({
    super.key,
    required this.subtask,
    this.onToggle,
    this.interactive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: interactive ? onToggle : null,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            // ── Checkbox customizado ──────────────────────
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: subtask.feita ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: subtask.feita
                      ? AppColors.primary
                      : AppColors.surfaceHover,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: subtask.feita
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 10),

            // ── Label ─────────────────────────────────────
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: subtask.feita
                    ? AppTextStyles.subtaskDone
                    : AppTextStyles.subtaskLabel,
                child: Text(
                  subtask.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
