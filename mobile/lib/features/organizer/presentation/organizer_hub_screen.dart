import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/organizer_repository.dart';
import '../domain/organizer_models.dart';

class OrganizerHubScreen extends ConsumerWidget {
  const OrganizerHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(authNotifierProvider);
    final user = userAsync.valueOrNull;

    // Strict Role Gate: Must be verified organizer
    if (user == null || !user.isOrganizer) {
      return Scaffold(
        appBar: const EngivaultAppBar(
          title: 'Organizer Hub',
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_outlined,
                      color: AppColors.errorRed, size: 48),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Organizer Access Restricted',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The live check-in desk and ticket scanner are restricted to verified event organizers and campus leads.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final eventsAsync = ref.watch(organizerEventsProvider);

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Organizer Hub',
        subtitle: 'Manage desk check-ins and attendee attendance',
      ),
      body: eventsAsync.when(
        loading: () =>
            const LoadingView(message: 'Loading organizer events...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(organizerEventsProvider),
        ),
        data: (events) {
          if (events.isEmpty) {
            return const EmptyView(
              title: 'No Assigned Events',
              message:
                  'You currently have no events assigned for desk coordination. Contact administrative staff if this is unexpected.',
              icon: Icons.event_available_rounded,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(organizerEventsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final event = events[index];
                return _OrganizerEventCard(event: event);
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrganizerEventCard extends StatelessWidget {
  final OrganizerEvent event;

  const _OrganizerEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: event.isLive
                    ? 'LIVE DESK ACTIVE'
                    : event.status.toUpperCase(),
                variant:
                    event.isLive ? StatusVariant.error : StatusVariant.info,
              ),
              const Spacer(),
              Text(
                'Capacity: ${event.capacity}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.schedule_rounded,
                  size: 14, color: AppColors.slate500),
              const SizedBox(width: 6),
              Text(
                '${DateFormatter.formatDateTime(event.startsAt)} (IST)',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () =>
                  context.push('/organizer/events/${event.id}/desk'),
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text(
                'Open Check-In Desk',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    event.isLive ? AppColors.blue600 : AppColors.navy900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
