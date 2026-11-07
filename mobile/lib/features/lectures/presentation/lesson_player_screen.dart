import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/lectures_repository.dart';
import '../domain/lecture_models.dart';

class LessonPlayerScreen extends ConsumerWidget {
  final String idOrSlug;
  final String? subjectSlug;
  final String? moduleSlug;

  const LessonPlayerScreen({
    super.key,
    required this.idOrSlug,
    this.subjectSlug,
    this.moduleSlug,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonAsync = ref.watch(lessonDetailProvider(idOrSlug));

    return Scaffold(
      appBar: const EngivaultAppBar(title: 'Recorded Lecture'),
      body: lessonAsync.when(
        data: (lesson) => ListView(
          padding: EdgeInsets.zero,
          children: [
            // 16:9 Video Player Container
            _buildVideoPlayer(context, lesson),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Breadcrumb
                  _buildBreadcrumbs(context, lesson.hierarchy),
                  const SizedBox(height: 12),

                  // Title & Meta
                  Text(lesson.title,
                      style: AppTypography.heroTitle.copyWith(fontSize: 20)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      StatusBadge.info('Lecture #${lesson.lessonNumber}'),
                      if (lesson.durationSeconds != null) ...[
                        const SizedBox(width: 8),
                        StatusBadge.code(DateFormatter.formatDuration(
                            lesson.durationSeconds)),
                      ],
                      if (lesson.instructor != null) ...[
                        const SizedBox(width: 8),
                        StatusBadge.code(lesson.instructor!),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prominent Watch on YouTube Action
                  if (lesson.youtubeWatchUrl != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC0000),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.play_arrow, size: 22),
                        label: const Text('Watch on YouTube',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        onPressed: () => _launchUrl(lesson.youtubeWatchUrl!),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Previous & Next Navigation Buttons
                  _buildNavigationControls(context, lesson),
                  const SizedBox(height: 20),

                  // Description / Notes
                  if (lesson.description != null &&
                      lesson.description!.isNotEmpty) ...[
                    const Text('Lecture Overview',
                        style: AppTypography.titleLarge),
                    const SizedBox(height: 8),
                    GlassCard(
                      child: Text(
                        lesson.description!,
                        style: AppTypography.bodyMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Attached Study Materials
                  if (lesson.materials.isNotEmpty) ...[
                    const Text('Attached Study Notes',
                        style: AppTypography.titleLarge),
                    const SizedBox(height: 8),
                    ...lesson.materials.map((m) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            onTap: () => context.push('/materials?id=${m.id}'),
                            child: Row(
                              children: [
                                const Icon(Icons.description,
                                    color: AppColors.statusSuccess),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(m.title,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13)),
                                      Text(m.originalFilename,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.download,
                                    color: AppColors.royalBlue, size: 20),
                              ],
                            ),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingView(message: 'Loading lecture video...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(lessonDetailProvider(idOrSlug)),
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(BuildContext context, LessonDetail lesson) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (lesson.youtubeThumbnailUrl != null)
              Image.network(
                lesson.youtubeThumbnailUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.video_library,
                      color: Colors.white30, size: 48),
                ),
              ),
            Container(color: Colors.black.withValues(alpha: 0.35)),
            InkWell(
              onTap: () {
                if (lesson.youtubeWatchUrl != null) {
                  _launchUrl(lesson.youtubeWatchUrl!);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4)),
                  ],
                ),
                child:
                    const Icon(Icons.play_arrow, color: Colors.white, size: 40),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.hd, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text('1080p HD YouTube Stream',
                        style: TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, LessonHierarchy hier) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          InkWell(
            onTap: () => context.push('/subjects/${hier.subjectSlug}'),
            child: Text(
              hier.subjectCode ?? hier.subjectTitle,
              style: const TextStyle(
                  color: AppColors.royalBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child:
                Icon(Icons.chevron_right, size: 14, color: AppColors.textMuted),
          ),
          Text(
            hier.moduleTitle,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600),
          ),
          if (hier.topicTitle != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Icon(Icons.chevron_right,
                  size: 14, color: AppColors.textMuted),
            ),
            Text(
              hier.topicTitle!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavigationControls(BuildContext context, LessonDetail lesson) {
    return Row(
      children: [
        Expanded(
          child: lesson.prevLesson != null
              ? OutlinedButton.icon(
                  onPressed: () => context
                      .pushReplacement('/lessons/${lesson.prevLesson!.slug}'),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: Text(
                    lesson.prevLesson!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: lesson.nextLesson != null
              ? ElevatedButton.icon(
                  onPressed: () => context
                      .pushReplacement('/lessons/${lesson.nextLesson!.slug}'),
                  icon: const Icon(Icons.arrow_forward, size: 16),
                  label: Text(
                    lesson.nextLesson!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
