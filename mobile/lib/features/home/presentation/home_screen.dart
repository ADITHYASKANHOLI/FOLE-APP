import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/home_repository.dart';
import '../domain/home_models.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: EngivaultAppBar(
        title: 'ENGIVAULT',
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textPrimary),
            tooltip: 'Search Curriculum',
            onPressed: () => context.push('/search'),
          ),
        ],
      ),
      body: homeAsync.when(
        data: (feed) => RefreshIndicator(
          onRefresh: () => ref.refresh(homeFeedProvider.future),
          color: AppColors.royalBlue,
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: [
              _buildHeroSection(context, feed),
              const SizedBox(height: 20),
              _buildDepartmentGrid(context, feed.departments),
              const SizedBox(height: 28),
              if (feed.spaceStatus != null) ...[
                _buildSpaceHighlightCard(context, feed.spaceStatus!),
                const SizedBox(height: 28),
              ],
              _buildFeaturedSubjects(context, feed.featuredSubjects),
              const SizedBox(height: 28),
              _buildLatestLectures(context, feed.latestLectures),
              const SizedBox(height: 32),
            ],
          ),
        ),
        loading: () => const LoadingView(message: 'Loading curriculum...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(homeFeedProvider),
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, HomeFeedData feed) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.deepSlate, AppColors.deepNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge.info('KTU ACADEMIC REPOSITORY'),
              const Spacer(),
              const Icon(Icons.verified,
                  color: AppColors.electricCyan, size: 18),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            feed.tagline,
            style: AppTypography.heroTitle
                .copyWith(color: Colors.white, fontSize: 22),
          ),
          const SizedBox(height: 8),
          const Text(
            'Structured syllabus modules, recorded YouTube video lectures, and syllabus question notes.',
            style:
                TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => context.push('/search'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, size: 18, color: Colors.white70),
                  SizedBox(width: 10),
                  Text(
                    'Search subjects, lectures, or topics...',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentGrid(
      BuildContext context, List<DepartmentSummary> depts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Engineering Disciplines',
                  style: AppTypography.titleLarge),
              TextButton(
                onPressed: () => context.push('/lectures'),
                child: const Text('View All',
                    style: TextStyle(color: AppColors.royalBlue, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 85,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: depts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final dept = depts[index];
              return InkWell(
                onTap: () => context.push('/lectures?dept=${dept.slug}'),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 110,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dept.code,
                        style: AppTypography.monoCode.copyWith(
                          fontSize: 14,
                          color: AppColors.royalBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dept.name.replaceAll('Engineering', '').trim(),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpaceHighlightCard(BuildContext context, SpaceSummary space) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        backgroundColor: const Color(0xFFF0FDF4),
        borderColor: const Color(0xFFBBF7D0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFDCFCE7),
                shape: BoxShape.circle,
              ),
              child: Icon(
                space.isOpen ? Icons.meeting_room : Icons.no_meeting_room,
                color: AppColors.statusSuccess,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        space.isOpen ? 'FOLE SPACE Open' : 'FOLE SPACE Closed',
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF14532D)),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge.success('${space.availableSeats} Seats Left'),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${space.currentOccupancy} of ${space.capacity} desks currently occupied',
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF166534)),
          ],
        ),
        onTap: () => context.go('/space'),
      ),
    );
  }

  Widget _buildFeaturedSubjects(
      BuildContext context, List<SubjectSummary> subjects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Featured Subjects', style: AppTypography.titleLarge),
              TextButton(
                onPressed: () => context.push('/subjects'),
                child: const Text('All Subjects →',
                    style: TextStyle(color: AppColors.royalBlue, fontSize: 13)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: subjects.length > 4 ? 4 : subjects.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final s = subjects[index];
            return GlassCard(
              onTap: () => context.push('/subjects/${s.slug}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (s.code != null) StatusBadge.code(s.code!),
                      const Spacer(),
                      if (s.semesterNumber != null)
                        StatusBadge.info('S${s.semesterNumber}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(s.title, style: AppTypography.titleMedium),
                  if (s.shortDescription != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.shortDescription!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.layers_outlined,
                          size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text('${s.modulesCount} Modules',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.play_circle_outline,
                          size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text('${s.lessonsCount} Lectures',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                      const SizedBox(width: 12),
                      const Icon(Icons.description_outlined,
                          size: 14, color: AppColors.statusSuccess),
                      const SizedBox(width: 4),
                      Text('${s.materialsCount} Notes',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLatestLectures(
      BuildContext context, List<LectureSummary> lectures) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child:
              Text('Latest Recorded Lectures', style: AppTypography.titleLarge),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: lectures.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final lec = lectures[index];
            return GlassCard(
              onTap: () => context.push('/lessons/${lec.slug}'),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.play_arrow,
                        color: Colors.red, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lec.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lec.subjectTitle} • ${lec.moduleTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  if (lec.durationSeconds != null)
                    Text(
                      DateFormatter.formatDuration(lec.durationSeconds),
                      style: AppTypography.monoCode
                          .copyWith(fontSize: 11, color: AppColors.textMuted),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
