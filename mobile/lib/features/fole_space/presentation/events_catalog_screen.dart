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

class EventsCatalogScreen extends ConsumerStatefulWidget {
  const EventsCatalogScreen({super.key});

  @override
  ConsumerState<EventsCatalogScreen> createState() =>
      _EventsCatalogScreenState();
}

class _EventsCatalogScreenState extends ConsumerState<EventsCatalogScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(spaceEventsProvider);

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Community Events',
        subtitle: 'Workshops, hackathons & technical cohorts',
      ),
      body: eventsAsync.when(
        loading: () => const LoadingView(message: 'Loading events...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(spaceEventsProvider),
        ),
        data: (events) {
          final filtered = events.where((e) {
            if (_selectedFilter == 'live') return e.isLive;
            if (_selectedFilter == 'upcoming') {
              return e.status.toLowerCase() == 'published';
            }
            if (_selectedFilter == 'registered') return e.isRegistered;
            return true;
          }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(spaceEventsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChip(
                        label: 'All Events',
                        isSelected: _selectedFilter == 'all',
                        onSelected: () =>
                            setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Live Now',
                        isSelected: _selectedFilter == 'live',
                        onSelected: () =>
                            setState(() => _selectedFilter = 'live'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'Upcoming',
                        isSelected: _selectedFilter == 'upcoming',
                        onSelected: () =>
                            setState(() => _selectedFilter = 'upcoming'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: 'My RSVPs',
                        isSelected: _selectedFilter == 'registered',
                        onSelected: () =>
                            setState(() => _selectedFilter = 'registered'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                if (filtered.isEmpty)
                  const EmptyView(
                    title: 'No Events Found',
                    message:
                        'No scheduled events match the current filter. Check back soon!',
                    icon: Icons.event_note_rounded,
                  )
                else
                  ...filtered.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _EventCard(event: e),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.slate700,
        ),
      ),
      selected: isSelected,
      selectedColor: AppColors.blue600,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.blue600 : AppColors.borderLight,
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _EventCard extends StatelessWidget {
  final SpaceEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/space/events/${event.id}'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(
                label: event.isLive ? 'LIVE NOW' : event.status.toUpperCase(),
                variant:
                    event.isLive ? StatusVariant.error : StatusVariant.info,
              ),
              if (event.isRegistered) ...[
                const SizedBox(width: 8),
                const StatusBadge(
                  label: 'REGISTERED',
                  variant: StatusVariant.success,
                ),
              ],
              const Spacer(),
              Text(
                '${event.availableSpots} spots left',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            event.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.navy950,
            ),
          ),
          if (event.description != null && event.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              event.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate600,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 14, color: AppColors.slate500),
              const SizedBox(width: 6),
              Text(
                DateFormatter.formatDate(event.startsAt),
                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
              const Spacer(),
              const Icon(Icons.place_outlined,
                  size: 14, color: AppColors.slate500),
              const SizedBox(width: 4),
              Text(
                event.venue,
                style: const TextStyle(fontSize: 12, color: AppColors.slate600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
