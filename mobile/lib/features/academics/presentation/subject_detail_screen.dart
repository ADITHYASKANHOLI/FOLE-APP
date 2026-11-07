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
import '../data/academics_repository.dart';
import '../domain/academic_models.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String slug;

  const SubjectDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectAsync = ref.watch(subjectDetailProvider(slug));

    return Scaffold(
      appBar: const EngivaultAppBar(title: 'Subject Curriculum'),
      body: subjectAsync.when(
        data: (subject) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSubjectBanner(context, subject),
            const SizedBox(height: 24),
            _buildModulesSection(context, subject.modules),
            if (subject.materials.isNotEmpty) ...[
              const SizedBox(height: 28),
              _buildMaterialsSection(context, subject.materials),
            ],
            const SizedBox(height: 32),
          ],
        ),
        loading: () => const LoadingView(message: 'Loading subject modules...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(subjectDetailProvider(slug)),
        ),
      ),
    );
  }

  Widget _buildSubjectBanner(BuildContext context, SubjectDetail subject) {
    final totalLessons =
        subject.modules.fold<int>(0, (sum, m) => sum + m.lessons.length);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF163B8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (subject.code != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    subject.code!,
                    style: AppTypography.monoCode
                        .copyWith(color: AppColors.cyanLight, fontSize: 11),
                  ),
                ),
              const Spacer(),
              if (subject.semesterNumber != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.royalBlueLight.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Semester ${subject.semesterNumber}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subject.title,
            style: AppTypography.heroTitle
                .copyWith(color: Colors.white, fontSize: 22),
          ),
          if (subject.description != null) ...[
            const SizedBox(height: 8),
            Text(
              subject.description!,
              style: const TextStyle(
                  color: Color(0xFFE2E8F0), fontSize: 13, height: 1.4),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBannerStat(
                  Icons.layers_outlined, '${subject.modules.length} Modules'),
              const SizedBox(width: 16),
              _buildBannerStat(
                  Icons.play_circle_outline, '$totalLessons Lectures'),
              const SizedBox(width: 16),
              _buildBannerStat(Icons.description_outlined,
                  '${subject.materials.length} Notes'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStat(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.cyanLight),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildModulesSection(
      BuildContext context, List<AcademicModule> modules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Syllabus Modules', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: modules.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final mod = modules[index];
            return GlassCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: index == 0,
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.royalBlue.withValues(alpha: 0.1),
                    child: Text(
                      '${mod.moduleNumber}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.royalBlue,
                          fontSize: 13),
                    ),
                  ),
                  title: Text(mod.title,
                      style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                  subtitle: Text('${mod.lessons.length} Recorded Lectures',
                      style: AppTypography.bodySmall),
                  children: [
                    const Divider(height: 1),
                    if (mod.description != null && mod.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                        child: Text(
                          mod.description!,
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: mod.lessons.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, indent: 56),
                      itemBuilder: (context, lIdx) {
                        final l = mod.lessons[lIdx];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 2),
                          leading: const Icon(Icons.play_circle_filled,
                              color: Colors.red, size: 24),
                          title: Text(l.title,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: l.instructor != null
                              ? Text(l.instructor!,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textMuted))
                              : null,
                          trailing: l.durationSeconds != null
                              ? Text(
                                  DateFormatter.formatDuration(
                                      l.durationSeconds),
                                  style: AppTypography.monoCode.copyWith(
                                      fontSize: 11, color: AppColors.textMuted),
                                )
                              : null,
                          onTap: () => context
                              .push('/lessons/${l.slug}?module_id=${mod.id}'),
                        );
                      },
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMaterialsSection(
      BuildContext context, List<MaterialRef> materials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Subject Study Materials', style: AppTypography.titleLarge),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: materials.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final m = materials[index];
            return GlassCard(
              onTap: () => context.push('/materials?subject_id=${m.id}'),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.statusSuccessBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.description,
                        color: AppColors.statusSuccess, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(
                          m.originalFilename,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.download_outlined,
                      color: AppColors.royalBlue, size: 20),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
