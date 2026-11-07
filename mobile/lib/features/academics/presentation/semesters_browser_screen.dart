import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/academics_repository.dart';

class SemestersBrowserScreen extends ConsumerWidget {
  final String? departmentSlug;

  const SemestersBrowserScreen({super.key, this.departmentSlug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final semsAsync = ref.watch(semestersProvider);

    return Scaffold(
      appBar: EngivaultAppBar(
        title: 'Select Semester',
        subtitle: departmentSlug != null
            ? 'Department: ${departmentSlug!.toUpperCase()}'
            : 'KTU B.Tech Semester Hierarchy',
      ),
      body: semsAsync.when(
        loading: () => const LoadingView(message: 'Loading semesters...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(semestersProvider),
        ),
        data: (semesters) {
          // If empty, generate standard KTU 1..8 semesters
          final semList = semesters.isNotEmpty
              ? semesters
              : List.generate(
                  8,
                  (i) => (
                    number: i + 1,
                    title: 'Semester ${i + 1}',
                    year: 'Year ${(i / 2).floor() + 1}',
                  ),
                );

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.15,
            ),
            itemCount: semList.length,
            itemBuilder: (context, index) {
              final sem = semList[index];
              final semNum = sem is Map ? sem['semester_number'] : (index + 1);
              final semYear = ((semNum - 1) / 2).floor() + 1;

              return GlassCard(
                onTap: () {
                  final deptParam =
                      departmentSlug != null ? 'dept=$departmentSlug&' : '';
                  context.push('/subjects?${deptParam}sem=$semNum');
                },
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'YEAR $semYear',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'S$semNum',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy950,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Semester $semNum',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
