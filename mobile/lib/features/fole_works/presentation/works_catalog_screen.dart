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
import '../data/works_repository.dart';
import '../domain/works_models.dart';

final worksActivitiesProvider =
    FutureProvider.autoDispose<List<WorksActivityItem>>((ref) async {
  final repo = ref.watch(worksRepositoryProvider);
  return repo.getActivities();
});

class WorksCatalogScreen extends ConsumerStatefulWidget {
  const WorksCatalogScreen({super.key});

  @override
  ConsumerState<WorksCatalogScreen> createState() => _WorksCatalogScreenState();
}

class _WorksCatalogScreenState extends ConsumerState<WorksCatalogScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final activitiesAsync = ref.watch(worksActivitiesProvider);

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'FOLE WORKS',
        subtitle: 'Engineering initiatives, hackathons & workshops',
      ),
      body: activitiesAsync.when(
        loading: () =>
            const LoadingView(message: 'Loading FOLE WORKS activities...'),
        error: (err, stack) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(worksActivitiesProvider),
        ),
        data: (activities) {
          final categories = [
            'all',
            ...activities
                .map((a) => a.category)
                .toSet()
                .where((c) => c.isNotEmpty)
          ];

          final filtered = _selectedCategory == 'all'
              ? activities
              : activities
                  .where((a) =>
                      a.category.toLowerCase() ==
                      _selectedCategory.toLowerCase())
                  .toList();

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(worksActivitiesProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Banner
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.blue600.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: AppColors.blue400,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hands-On Engineering',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore workshops, industrial challenges, and cohort programs hosted by FOLE.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Category Chips
                if (categories.length > 2) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              cat == 'all' ? 'All Activities' : cat,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.slate700,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.blue600,
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.blue600
                                  : AppColors.borderLight,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCategory = cat);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // List of Activities
                if (filtered.isEmpty)
                  const EmptyView(
                    title: 'No Activities Found',
                    message: 'Check back soon for upcoming FOLE WORKS events.',
                    icon: Icons.event_busy_rounded,
                  )
                else
                  ...filtered.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ActivityCard(item: item),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final WorksActivityItem item;

  const _ActivityCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: () => context.push('/works/${item.slug}'),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flyer Image (Preserving ratio)
          if (item.flyerUrl.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.flyerUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, _, __) => Container(
                    color: AppColors.slate100,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: AppColors.slate400, size: 36),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    StatusBadge(
                      label: item.category.toUpperCase(),
                      variant: StatusVariant.info,
                    ),
                    const Spacer(),
                    StatusBadge(
                      label: item.status.toUpperCase(),
                      variant: item.status.toLowerCase() == 'upcoming'
                          ? StatusVariant.success
                          : StatusVariant.neutral,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.navy950,
                  ),
                ),
                if (item.shortDescription != null &&
                    item.shortDescription!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.shortDescription!,
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
                      DateFormatter.formatDate(item.startDate),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate600),
                    ),
                    const Spacer(),
                    const Icon(Icons.currency_rupee_rounded,
                        size: 14, color: AppColors.slate500),
                    Text(
                      item.fee,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
