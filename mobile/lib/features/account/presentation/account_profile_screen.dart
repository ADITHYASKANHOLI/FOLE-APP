import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_notifier.dart';

class AccountProfileScreen extends ConsumerWidget {
  const AccountProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of your ENGIVAULT student account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(authNotifierProvider.notifier).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Account & Settings',
      ),
      body: authState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (err, _) => Center(
          child: Text('Error loading account: $err'),
        ),
        data: (user) {
          final isLoggedIn = user != null;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User Header Card
              if (isLoggedIn)
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: AppColors.blue600,
                        child: Text(
                          user.username.isNotEmpty
                              ? user.username[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.username,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy950,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const StatusBadge(
                                  label: 'STUDENT',
                                  variant: StatusVariant.info,
                                ),
                                if (user.isOrganizer) ...[
                                  const SizedBox(width: 6),
                                  const StatusBadge(
                                    label: 'ORGANIZER',
                                    variant: StatusVariant.success,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Guest Prompt Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: AppColors.blue50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_circle_outlined,
                          size: 40,
                          color: AppColors.blue600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Guest Student',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy950,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to access FOLE SPACE walk-in passes, event tickets, and personalize your study history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.slate600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => context.push('/auth/register'),
                              style: OutlinedButton.styleFrom(
                                side:
                                    const BorderSide(color: AppColors.blue600),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => context.push('/auth/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text('Sign In'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Account Actions
              const Text(
                'ACCOUNT',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.slate500,
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    if (isLoggedIn) ...[
                      _SettingsTile(
                        icon: Icons.vpn_key_rounded,
                        title: 'Change Password',
                        subtitle: 'Update your account credentials',
                        onTap: () => context.push('/account/change-password'),
                      ),
                      const Divider(height: 1, color: AppColors.borderLight),
                    ],
                    _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      title: 'About ENGIVAULT',
                      subtitle: 'KTU engineering platform & FOLE team',
                      onTap: () => context.push('/about'),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _SettingsTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Contact & Support',
                      subtitle: 'Feedback, bug reports and inquiries',
                      onTap: () => context.push('/contact'),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _SettingsTile(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Administrator Portal',
                      subtitle: 'Access code verification & moderation',
                      onTap: () => context.push('/admin/login'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Student Communities & Quick Links
              const Text(
                'EXPLORE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.slate500,
                ),
              ),
              const SizedBox(height: 8),

              GlassCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsTile(
                      icon: Icons.handyman_rounded,
                      title: 'FOLE WORKS',
                      subtitle: 'Industrial cohorts and workshops',
                      onTap: () => context.push('/works'),
                    ),
                    const Divider(height: 1, color: AppColors.borderLight),
                    _SettingsTile(
                      icon: Icons.meeting_room_rounded,
                      title: 'FOLE SPACE',
                      subtitle: 'Co-learning space and community events',
                      onTap: () => context.push('/space'),
                    ),
                  ],
                ),
              ),

              if (isLoggedIn) ...[
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _showLogoutDialog(context, ref),
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.errorRed, size: 20),
                    label: const Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.errorRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.errorRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
              const Center(
                child: Text(
                  'ENGIVAULT Mobile v1.0.0\nCrafted for KTU Engineering Students',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.slate400,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.blue50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.blue600, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.navy950,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.slate500,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: AppColors.slate400,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
