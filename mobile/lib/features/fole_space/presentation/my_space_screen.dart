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
import '../data/space_repository.dart';
import '../domain/space_models.dart';
import 'qr_ticket_dialog.dart';

class MySpaceScreen extends ConsumerWidget {
  const MySpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySpaceAsync = ref.watch(mySpaceProvider);

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'My Passes & Tickets',
        subtitle: 'FOLE SPACE active passes and event RSVPs',
      ),
      body: mySpaceAsync.when(
        loading: () =>
            const LoadingView(message: 'Loading your space passes...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(mySpaceProvider),
        ),
        data: (data) {
          final activeSession = data.activeSession;
          final upcoming = data.upcomingRegistrations;

          if (activeSession == null && upcoming.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(mySpaceProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 40),
                  const EmptyView(
                    title: 'No Active Passes',
                    message:
                        'You do not have any active study passes or upcoming event RSVPs.',
                    icon: Icons.confirmation_number_outlined,
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => context.push('/space/events'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Browse Upcoming Events'),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(mySpaceProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Active Walk-in Study Pass
                if (activeSession != null) ...[
                  const Text(
                    'ACTIVE STUDY PASS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.blue200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            StatusBadge(
                              label: 'WALK-IN PASS',
                              variant: StatusVariant.success,
                            ),
                            Spacer(),
                            Icon(Icons.meeting_room_outlined,
                                color: AppColors.blue600, size: 20),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Checked In to FOLE SPACE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy950,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expires: ${DateFormatter.formatDateTime(activeSession.expiresAt)} (IST)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.slate600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Upcoming Event Tickets
                if (upcoming.isNotEmpty) ...[
                  const Text(
                    'UPCOMING EVENT PASSES',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: AppColors.slate500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...upcoming.map((reg) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TicketCard(registration: reg),
                      )),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final MyRegistrationItem registration;

  const _TicketCard({required this.registration});

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
                label: registration.status.toUpperCase(),
                variant: registration.status == 'attended'
                    ? StatusVariant.success
                    : StatusVariant.info,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.qr_code_rounded,
                    color: AppColors.blue600, size: 22),
                tooltip: 'Show QR Code',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => QrTicketDialog(
                      eventTitle: registration.eventTitle,
                      ticketCode: registration.ticketCode,
                      startsAt: registration.startsAt,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            registration.eventTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 13, color: AppColors.slate500),
              const SizedBox(width: 6),
              Text(
                DateFormatter.formatDateTime(registration.startsAt),
                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tag_rounded,
                    size: 14, color: AppColors.slate500),
                const SizedBox(width: 4),
                Text(
                  registration.ticketCode,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      context.push('/space/events/${registration.eventId}'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: const BorderSide(color: AppColors.blue600),
                  ),
                  child: const Text('Event Details',
                      style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => QrTicketDialog(
                        eventTitle: registration.eventTitle,
                        ticketCode: registration.ticketCode,
                        startsAt: registration.startsAt,
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                  label:
                      const Text('Show Pass', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
