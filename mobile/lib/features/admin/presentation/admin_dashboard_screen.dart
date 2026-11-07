import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/config/app_config.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/admin_repository.dart';
import '../domain/admin_models.dart';
import 'admin_auth_notifier.dart';

final adminDashboardProvider =
    FutureProvider.autoDispose<AdminDashboardStats>((ref) async {
  final tokenAsync = ref.watch(adminAuthNotifierProvider);
  final token = tokenAsync.valueOrNull;
  if (token == null || token.isEmpty) {
    throw Exception('Unauthorized administrator session.');
  }

  final repo = ref.watch(adminRepositoryProvider);
  return repo.getDashboard(token);
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  Future<void> _launchWebAdmin(BuildContext context) async {
    final uri = Uri.parse(
        '${AppConfig.apiBaseUrl.replaceAll('/api/mobile/v1', '')}/admin');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open web admin console')),
        );
      }
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit Administrator Mode?'),
        content: const Text(
          'Your active administrative token will be purged from secure device storage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(adminAuthNotifierProvider.notifier).logout();
              context.go('/home');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Exit Admin'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteLesson(
    BuildContext context,
    WidgetRef ref,
    String lessonId,
    String lessonTitle,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Lecture?'),
        content: Text(
          'Are you sure you want to permanently delete "$lessonTitle"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final token = ref.read(adminAuthNotifierProvider).valueOrNull ?? '';
      final repo = ref.read(adminRepositoryProvider);
      final success = await repo.deleteLesson(token, lessonId);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lecture deleted successfully.'),
              backgroundColor: AppColors.blue600,
            ),
          );
          ref.invalidate(adminDashboardProvider);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete lecture.'),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0B132B),
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            tooltip: 'Sign Out Admin Mode',
            onPressed: () => _showLogoutDialog(context, ref),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () =>
            const LoadingView(message: 'Compiling administrative metrics...'),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_clock_outlined,
                    color: AppColors.errorRed, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Administrative Session Expired',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/admin/login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: AppColors.navy950,
                  ),
                  child: const Text('Re-enter Access Code'),
                ),
              ],
            ),
          ),
        ),
        data: (stats) {
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(adminDashboardProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Quick Admin Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.push('/admin/lectures/create'),
                        icon: const Icon(Icons.video_call_rounded, size: 20),
                        label: const Text(
                          'Add Lecture',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: AppColors.navy950,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _launchWebAdmin(context),
                        icon:
                            const Icon(Icons.open_in_browser_rounded, size: 18),
                        label: const Text(
                          'Web Console',
                          style: TextStyle(color: Colors.white),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Metrics Grid
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: [
                    _MetricCard(
                      label: 'STUDENTS',
                      count: stats.studentsCount,
                      icon: Icons.school_outlined,
                      color: AppColors.cyan400,
                    ),
                    _MetricCard(
                      label: 'LECTURES',
                      count: stats.lessonsCount,
                      icon: Icons.ondemand_video_outlined,
                      color: const Color(0xFFF59E0B),
                    ),
                    _MetricCard(
                      label: 'SUBJECTS',
                      count: stats.subjectsCount,
                      icon: Icons.menu_book_outlined,
                      color: AppColors.blue400,
                    ),
                    _MetricCard(
                      label: 'MODULES',
                      count: stats.modulesCount,
                      icon: Icons.view_module_outlined,
                      color: AppColors.successGreen,
                    ),
                    _MetricCard(
                      label: 'MATERIALS',
                      count: stats.materialsCount,
                      icon: Icons.folder_open_outlined,
                      color: Colors.purpleAccent,
                    ),
                    _MetricCard(
                      label: 'ACTIVE SPACE',
                      count: stats.activeSpaceSessions,
                      icon: Icons.meeting_room_outlined,
                      color: Colors.tealAccent,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Lectures Section
                const Text(
                  'RECENT LECTURES',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 8),

                if (stats.recentLessons.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'No lectures published yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                else
                  ...stats.recentLessons.map((l) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.play_circle_outline_rounded,
                                color: Color(0xFFF59E0B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (l.youtubeVideoId != null) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'ID: ${l.youtubeVideoId}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 11,
                                        color:
                                            Colors.white.withValues(alpha: 0.5),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.errorRed, size: 20),
                              tooltip: 'Delete Lecture',
                              onPressed: () => _handleDeleteLesson(
                                context,
                                ref,
                                l.id,
                                l.title,
                              ),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
