import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/space_repository.dart';
import '../domain/space_models.dart';
import 'qr_ticket_dialog.dart';

final singleEventProvider = FutureProvider.autoDispose
    .family<SpaceEvent?, String>((ref, eventId) async {
  final repo = ref.watch(spaceRepositoryProvider);
  final events = await repo.getEvents();
  try {
    return events.firstWhere((e) => e.id == eventId);
  } catch (_) {
    return null;
  }
});

class EventDetailScreen extends ConsumerStatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);
      final reg = await repo.registerEvent(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration confirmed! Your QR ticket is ready.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.invalidate(singleEventProvider(widget.eventId));
        ref.invalidate(spaceEventsProvider);
        ref.invalidate(mySpaceProvider);

        // Auto-show QR ticket dialog
        final event = ref.read(singleEventProvider(widget.eventId)).valueOrNull;
        if (event != null) {
          await showDialog(
            context: context,
            builder: (_) => QrTicketDialog(
              eventTitle: event.title,
              ticketCode: reg.ticketCode,
              startsAt: event.startsAt,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel RSVP?'),
        content: const Text(
          'Are you sure you want to cancel your registration? Your spot will be released to fellow students.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Pass'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel RSVP'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);
      await repo.cancelEvent(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration cancelled successfully.'),
            backgroundColor: AppColors.blue600,
          ),
        );
        ref.invalidate(singleEventProvider(widget.eventId));
        ref.invalidate(spaceEventsProvider);
        ref.invalidate(mySpaceProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVirtualCheckin() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);
      await repo.virtualCheckin(widget.eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Virtual check-in verified! Attendance logged.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.invalidate(singleEventProvider(widget.eventId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventAsync = ref.watch(singleEventProvider(widget.eventId));
    final userAsync = ref.watch(authNotifierProvider);
    final currentUser = userAsync.valueOrNull;

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Event Details',
      ),
      body: eventAsync.when(
        loading: () => const LoadingView(message: 'Loading event details...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(singleEventProvider(widget.eventId)),
        ),
        data: (event) {
          if (event == null) {
            return const ErrorView(message: 'Event not found or has expired.');
          }

          final isRegistered = event.isRegistered;
          final reg = event.userRegistration;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Flyer (if available)
                if (event.flyerUrl != null && event.flyerUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      color: AppColors.slate900,
                      child: Image.network(
                        event.flyerUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, _, __) => Container(
                          height: 180,
                          color: AppColors.slate100,
                          child: const Center(
                            child: Icon(Icons.image_not_supported_rounded,
                                color: AppColors.slate400, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Status & Availability Row
                Row(
                  children: [
                    StatusBadge(
                      label: event.isLive
                          ? 'LIVE NOW'
                          : event.status.toUpperCase(),
                      variant: event.isLive
                          ? StatusVariant.error
                          : StatusVariant.info,
                    ),
                    const SizedBox(width: 8),
                    if (isRegistered)
                      const StatusBadge(
                        label: 'REGISTERED',
                        variant: StatusVariant.success,
                      ),
                    const Spacer(),
                    Text(
                      '${event.availableSpots} / ${event.capacity} seats open',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title
                Text(
                  event.title,
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
                      _DetailMetaRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date & Time',
                        value:
                            '${DateFormatter.formatDateTime(event.startsAt)} – ${DateFormatter.formatDateTime(event.endsAt)} (IST)',
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _DetailMetaRow(
                        icon: Icons.place_outlined,
                        label: 'Venue',
                        value: event.venue,
                      ),
                      const Divider(height: 20, color: AppColors.borderLight),
                      _DetailMetaRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Attendance Mode',
                        value: event.allowVirtualCheckin
                            ? 'Hybrid (In-person & Virtual)'
                            : 'In-person at FOLE SPACE',
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
                  event.description ??
                      'No additional description provided for this session.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.slate700,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),

                // Registered Pass Area
                if (isRegistered && reg != null) ...[
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
                        Row(
                          children: [
                            const Icon(Icons.confirmation_number_outlined,
                                color: AppColors.blue600, size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Your Event Pass',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.navy950,
                              ),
                            ),
                            const Spacer(),
                            StatusBadge(
                              label: reg.status.toUpperCase(),
                              variant: reg.status == 'attended'
                                  ? StatusVariant.success
                                  : StatusVariant.info,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TICKET CODE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.slate500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                reg.ticketCode,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.navy950,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => QrTicketDialog(
                                      eventTitle: event.title,
                                      ticketCode: reg.ticketCode,
                                      startsAt: event.startsAt,
                                    ),
                                  );
                                },
                                icon:
                                    const Icon(Icons.qr_code_rounded, size: 18),
                                label: const Text('Show QR Pass'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.blue600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            if (event.isLive &&
                                event.allowVirtualCheckin &&
                                reg.status != 'attended') ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleVirtualCheckin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.successGreen,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Check In (Live)'),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: _isLoading ? null : _handleCancel,
                            child: const Text(
                              'Cancel Registration',
                              style: TextStyle(
                                color: AppColors.errorRed,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (currentUser == null) ...[
                  // Guest Call to Action
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => context.push('/auth/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Sign In to RSVP',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ] else ...[
                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isLoading || event.availableSpots <= 0)
                          ? null
                          : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue600,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.blue600.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              event.availableSpots > 0
                                  ? 'Register for Event'
                                  : 'Event Full (RSVP Closed)',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailMetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.slate500),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.slate500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy950,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
