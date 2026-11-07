import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/works_repository.dart';
import '../domain/works_models.dart';

final worksActivityDetailProvider = FutureProvider.autoDispose
    .family<WorksActivityItem?, String>((ref, slug) async {
  final repo = ref.watch(worksRepositoryProvider);
  return repo.getActivityBySlug(slug);
});

class WorksDetailScreen extends ConsumerWidget {
  final String slug;

  const WorksDetailScreen({super.key, required this.slug});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open registration link'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(worksActivityDetailProvider(slug));

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Activity Detail',
      ),
      body: activityAsync.when(
        loading: () =>
            const LoadingView(message: 'Loading activity details...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(worksActivityDetailProvider(slug)),
        ),
        data: (activity) {
          if (activity == null) {
            return const ErrorView(message: 'Activity not found');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flyer preserving original aspect ratio
                if (activity.flyerUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.slate900,
                      child: Image.network(
                        activity.flyerUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, _, __) => Container(
                          height: 200,
                          color: AppColors.slate100,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: AppColors.slate400, size: 40),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Category and Status
                Row(
                  children: [
                    StatusBadge(
                      label: activity.category.toUpperCase(),
                      variant: StatusVariant.info,
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(
                      label: activity.status.toUpperCase(),
                      variant: activity.status.toLowerCase() == 'upcoming'
                          ? StatusVariant.success
                          : StatusVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 16),

                // Meta Info Card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _MetaRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date & Time',
                        value: DateFormatter.formatDateTime(activity.startDate),
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _MetaRow(
                        icon: Icons.location_on_rounded,
                        label: 'Venue',
                        value: activity.venue,
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _MetaRow(
                        icon: Icons.payments_rounded,
                        label: 'Registration Fee',
                        value: activity.fee,
                        highlightValue: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Description
                const Text(
                  'About this Event',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  activity.description ??
                      activity.shortDescription ??
                      'No detailed description provided for this activity.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slate700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),

                // Register Button
                if (activity.registrationUrl != null &&
                    activity.registrationUrl!.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _launchUrl(context, activity.registrationUrl!),
                      icon: const Icon(Icons.open_in_new_rounded, size: 20),
                      label: const Text(
                        'Register for Activity',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlightValue;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlightValue = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slate500),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.slate500),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: highlightValue ? FontWeight.bold : FontWeight.w500,
                color: highlightValue ? AppColors.blue600 : AppColors.navy950,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
