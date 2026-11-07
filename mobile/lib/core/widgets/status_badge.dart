import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

enum StatusVariant { success, info, warning, error, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusVariant variant;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.variant = StatusVariant.neutral,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.icon,
  });

  factory StatusBadge.success(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      variant: StatusVariant.success,
      icon: icon,
    );
  }

  factory StatusBadge.info(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      variant: StatusVariant.info,
      icon: icon,
    );
  }

  factory StatusBadge.warning(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      variant: StatusVariant.warning,
      icon: icon,
    );
  }

  factory StatusBadge.error(String label, {IconData? icon}) {
    return StatusBadge(
      label: label,
      variant: StatusVariant.error,
      icon: icon,
    );
  }

  factory StatusBadge.code(String label) {
    return StatusBadge(
      label: label,
      backgroundColor: const Color(0xFFF1F5F9),
      textColor: const Color(0xFF334155),
      borderColor: const Color(0xFFCBD5E1),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color bg = backgroundColor ?? AppColors.slate100;
    Color fg = textColor ?? AppColors.slate700;
    Color? border = borderColor;

    if (backgroundColor == null) {
      switch (variant) {
        case StatusVariant.success:
          bg = AppColors.statusSuccessBg;
          fg = AppColors.statusSuccess;
          border ??= AppColors.statusSuccess.withValues(alpha: 0.3);
          break;
        case StatusVariant.info:
          bg = AppColors.statusInfoBg;
          fg = AppColors.statusInfo;
          border ??= AppColors.statusInfo.withValues(alpha: 0.3);
          break;
        case StatusVariant.warning:
          bg = AppColors.statusWarningBg;
          fg = AppColors.statusWarning;
          border ??= AppColors.statusWarning.withValues(alpha: 0.3);
          break;
        case StatusVariant.error:
          bg = AppColors.statusErrorBg;
          fg = AppColors.statusError;
          border ??= AppColors.statusError.withValues(alpha: 0.3);
          break;
        case StatusVariant.neutral:
          bg = AppColors.slate100;
          fg = AppColors.slate700;
          border ??= AppColors.slate200;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border ?? Colors.transparent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.badge.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
