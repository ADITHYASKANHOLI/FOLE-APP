import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class EngivaultAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogo;
  final Widget? leading;

  const EngivaultAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLogo = false,
    this.leading,
  });

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 64 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: showLogo
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/branding/fole-logo.png',
                  height: 28,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.school, color: AppColors.royalBlue),
                ),
                const SizedBox(width: 8),
                const Text.rich(
                  TextSpan(
                    text: 'ENGI',
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppColors.deepSlate,
                        fontSize: 18),
                    children: [
                      TextSpan(
                        text: 'VAULT',
                        style: TextStyle(color: AppColors.royalBlue),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : subtitle != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: AppTypography.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                )
              : Text(title, style: AppTypography.titleLarge),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: AppColors.borderLight,
          height: 1,
        ),
      ),
    );
  }
}
