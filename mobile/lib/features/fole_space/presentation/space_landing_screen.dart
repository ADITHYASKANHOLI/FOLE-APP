import 'dart:async';
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

class SpaceLandingScreen extends ConsumerStatefulWidget {
  const SpaceLandingScreen({super.key});

  @override
  ConsumerState<SpaceLandingScreen> createState() => _SpaceLandingScreenState();
}

class _SpaceLandingScreenState extends ConsumerState<SpaceLandingScreen> {
  Timer? _refreshTimer;
  bool _isActionLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-refresh space status every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidate(spaceStatusProvider);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleCheckin() async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);
      await repo.checkin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Checked in to FOLE SPACE! Enjoy your study session.'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.invalidate(spaceStatusProvider);
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

  Future<void> _handleCheckout() async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);
      await repo.checkout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checked out from FOLE SPACE. See you next time!'),
            backgroundColor: AppColors.blue600,
          ),
        );
        ref.invalidate(spaceStatusProvider);
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

  Future<void> _handleExtend() async {
    setState(() => _isActionLoading = true);
    try {
      final repo = ref.read(spaceRepositoryProvider);
      await repo.extend();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session extended by 30 minutes!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        ref.invalidate(spaceStatusProvider);
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
    final statusAsync = ref.watch(spaceStatusProvider);
    final userAsync = ref.watch(authNotifierProvider);
    final currentUser = userAsync.valueOrNull;

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'FOLE SPACE',
        subtitle: 'Co-learning space & engineering community',
      ),
      body: statusAsync.when(
        loading: () => const LoadingView(message: 'Checking space status...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(spaceStatusProvider),
        ),
        data: (status) {
          final occupancyRatio = status.capacity > 0
              ? (status.currentOccupancy / status.capacity).clamp(0.0, 1.0)
              : 0.0;
          final activeSession = status.userActiveSession;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(spaceStatusProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Top Status Card
                Container(
                  padding: const EdgeInsets.all(20),
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
                            label: status.isOpen ? 'OPEN NOW' : 'CLOSED',
                            variant: status.isOpen
                                ? StatusVariant.success
                                : StatusVariant.neutral,
                          ),
                          const Spacer(),
                          Text(
                            'Updated ${DateFormatter.formatDate(status.serverNow)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        status.isOpen
                            ? '${status.availableSeats} Seats Available'
                            : 'Currently Closed',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Capacity: ${status.currentOccupancy} / ${status.capacity} students studying',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: occupancyRatio,
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            occupancyRatio > 0.85
                                ? AppColors.errorRed
                                : AppColors.cyan400,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Walk-in Session Card
                const Text(
                  'WALK-IN STUDY PASS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    color: AppColors.slate500,
                  ),
                ),
                const SizedBox(height: 8),

                if (currentUser == null)
                  // Guest State
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign in for Walk-in Access',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy950,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Registered students can check into FOLE SPACE for study desks, high-speed Wi-Fi, and lab equipment.',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.slate600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.push('/auth/login'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue600,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Sign In to Check In'),
                        ),
                      ],
                    ),
                  )
                else if (activeSession != null)
                  // Active Study Session
                  _ActiveSessionCard(
                    session: activeSession,
                    isLoading: _isActionLoading,
                    onCheckout: _handleCheckout,
                    onExtend: _handleExtend,
                  )
                else
                  // Ready to Check In
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.blue50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.meeting_room_outlined,
                                color: AppColors.blue600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Ready to Study?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.navy950,
                                    ),
                                  ),
                                  Text(
                                    'Check in for an initial 45-minute session',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: (_isActionLoading || !status.isOpen)
                                ? null
                                : _handleCheckin,
                            icon: _isActionLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Icon(Icons.login_rounded, size: 20),
                            label: Text(
                              status.isOpen
                                  ? 'Check In to FOLE SPACE'
                                  : 'Space Currently Closed',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Community Quick Actions
                const Text(
                  'EXPLORE SPACE',
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
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.event_outlined,
                              color: AppColors.blue600, size: 20),
                        ),
                        title: const Text(
                          'Events & Workshops',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy950,
                          ),
                        ),
                        subtitle: const Text(
                          'Hackathons, expert talks, and cohort sessions',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.slate500),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.slate400),
                        onTap: () => context.push('/space/events'),
                      ),
                      if (currentUser != null) ...[
                        const Divider(height: 1, color: AppColors.borderLight),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blue50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code_rounded,
                                color: AppColors.blue600, size: 20),
                          ),
                          title: const Text(
                            'My Passes & Tickets',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy950,
                            ),
                          ),
                          subtitle: const Text(
                            'View active passes and event QR passes',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.slate500),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.slate400),
                          onTap: () => context.push('/space/my'),
                        ),
                      ],
                      if (currentUser?.isOrganizer == true) ...[
                        const Divider(height: 1, color: AppColors.borderLight),
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.successGreen.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code_scanner_rounded,
                                color: AppColors.successGreen, size: 20),
                          ),
                          title: const Text(
                            'Organizer Live Desk',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy950,
                            ),
                          ),
                          subtitle: const Text(
                            'Scan attendee tickets and verify check-ins',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.slate500),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.slate400),
                          onTap: () => context.push('/organizer'),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Space Info & Guidelines
                const GlassCard(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Space Guidelines',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy950,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Maintain academic silence in study pods.\n'
                        '• Check out when leaving so fellow students can access seats.\n'
                        '• Wi-Fi credentials available at the physical front desk.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.slate600,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActiveSessionCard extends StatelessWidget {
  final SpaceSession session;
  final bool isLoading;
  final VoidCallback onCheckout;
  final VoidCallback onExtend;

  const _ActiveSessionCard({
    required this.session,
    required this.isLoading,
    required this.onCheckout,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                label: 'ACTIVE PASS',
                variant: StatusVariant.success,
              ),
              Spacer(),
              Icon(Icons.timer_outlined, color: AppColors.blue600, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'You are checked in to FOLE SPACE',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pass expires: ${DateFormatter.formatDateTime(session.expiresAt)} (IST)',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slate600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : onCheckout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorRed,
                    side: const BorderSide(color: AppColors.errorRed),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Check Out'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isLoading ? null : onExtend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('+30 Mins'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
