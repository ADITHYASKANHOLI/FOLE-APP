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
import '../data/organizer_repository.dart';
import '../domain/organizer_models.dart';

class LiveDeskScreen extends ConsumerStatefulWidget {
  final String eventId;

  const LiveDeskScreen({super.key, required this.eventId});

  @override
  ConsumerState<LiveDeskScreen> createState() => _LiveDeskScreenState();
}

class _LiveDeskScreenState extends ConsumerState<LiveDeskScreen> {
  String _searchQuery = '';
  bool _isActionLoading = false;

  Future<void> _handleManualCheckin(String registrationId) async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(organizerRepositoryProvider);
      final res = await repo.manualCheckin(widget.eventId, registrationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.message),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.invalidate(organizerDeskProvider(widget.eventId));
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
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _handleRevoke(String checkinId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Check-In?'),
        content: const Text(
          'Are you sure you want to revoke this attendee\'s check-in status?',
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
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(organizerRepositoryProvider);
      await repo.revokeCheckin(widget.eventId, checkinId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-in status revoked.'),
            backgroundColor: AppColors.blue600,
          ),
        );
        ref.invalidate(organizerDeskProvider(widget.eventId));
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
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deskAsync = ref.watch(organizerDeskProvider(widget.eventId));

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Check-In Desk',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            context.push('/organizer/events/${widget.eventId}/scan'),
        icon: const Icon(Icons.qr_code_scanner_rounded),
        label: const Text('Scan QR Pass'),
        backgroundColor: AppColors.blue600,
        foregroundColor: Colors.white,
      ),
      body: deskAsync.when(
        loading: () =>
            const LoadingView(message: 'Loading live desk roster...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(organizerDeskProvider(widget.eventId)),
        ),
        data: (desk) {
          final stats = desk.stats;
          final attendees = desk.attendees.where((a) {
            if (_searchQuery.isEmpty) return true;
            final query = _searchQuery.toLowerCase();
            return a.username.toLowerCase().contains(query) ||
                a.displayName.toLowerCase().contains(query) ||
                a.ticketCode.toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.refresh(organizerDeskProvider(widget.eventId).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Event Header & Live Stats
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.navy950, AppColors.navy900],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(
                            label: desk.event.isLive
                                ? 'LIVE'
                                : desk.event.status.toUpperCase(),
                            variant: desk.event.isLive
                                ? StatusVariant.error
                                : StatusVariant.info,
                          ),
                          const Spacer(),
                          Text(
                            'Capacity: ${desk.event.capacity}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        desk.event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Grid
                      Row(
                        children: [
                          _StatColumn(
                            label: 'REGISTERED',
                            value: '${stats.registered}',
                          ),
                          _StatColumn(
                            label: 'CHECKED IN',
                            value: '${stats.checkedIn}',
                            highlight: true,
                          ),
                          _StatColumn(
                            label: 'REMAINING',
                            value: '${stats.remaining}',
                          ),
                          _StatColumn(
                            label: 'RATE',
                            value: '${(stats.checkinRate * 100).toInt()}%',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stats.checkinRate,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.cyan400),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search attendee by name or ticket code...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Attendee List
                Row(
                  children: [
                    Text(
                      'ROSTER (${attendees.length})',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (attendees.isEmpty)
                  const EmptyView(
                    title: 'No Attendees Found',
                    message:
                        'No registered attendees match the current search filter.',
                  )
                else
                  ...attendees.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AttendeeTile(
                          attendee: a,
                          isLoading: _isActionLoading,
                          onCheckin: () =>
                              _handleManualCheckin(a.registrationId),
                          onRevoke: a.checkinId != null
                              ? () => _handleRevoke(a.checkinId!)
                              : null,
                        ),
                      )),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatColumn({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: highlight ? AppColors.cyan400 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttendeeTile extends StatelessWidget {
  final OrganizerAttendee attendee;
  final bool isLoading;
  final VoidCallback onCheckin;
  final VoidCallback? onRevoke;

  const _AttendeeTile({
    required this.attendee,
    required this.isLoading,
    required this.onCheckin,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final checkedIn = attendee.isCheckedIn;

    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: checkedIn
                ? AppColors.successGreen.withValues(alpha: 0.15)
                : AppColors.slate100,
            child: Icon(
              checkedIn
                  ? Icons.check_circle_rounded
                  : Icons.person_outline_rounded,
              color: checkedIn ? AppColors.successGreen : AppColors.slate500,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attendee.displayName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${attendee.username} • ${attendee.ticketCode}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: AppColors.slate500,
                  ),
                ),
                if (checkedIn && attendee.checkedInAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Checked in: ${DateFormatter.formatDateTime(attendee.checkedInAt)} (${attendee.checkinMethod?.toUpperCase() ?? 'DESK'})',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.successGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (checkedIn) ...[
            if (onRevoke != null)
              IconButton(
                icon: const Icon(Icons.undo_rounded,
                    color: AppColors.slate400, size: 20),
                tooltip: 'Revoke check-in',
                onPressed: isLoading ? null : onRevoke,
              ),
          ] else ...[
            ElevatedButton(
              onPressed: isLoading ? null : onCheckin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue600,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Check In', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}
