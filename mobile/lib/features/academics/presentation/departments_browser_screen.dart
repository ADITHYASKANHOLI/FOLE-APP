import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../data/academics_repository.dart';

class DepartmentsBrowserScreen extends ConsumerWidget {
  const DepartmentsBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deptsAsync = ref.watch(departmentsProvider);

    return Scaffold(
      appBar: const EngivaultAppBar(
        title: 'Departments & Branches',
        subtitle: 'Select an engineering discipline',
      ),
      body: deptsAsync.when(
        loading: () => const LoadingView(message: 'Loading KTU departments...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(departmentsProvider),
        ),
        data: (depts) {
          if (depts.isEmpty) {
            return const EmptyView(
              title: 'No Departments Found',
              message: 'Check back later or contact academic administration.',
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: depts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final dept = depts[index];
              return GlassCard(
                onTap: () => context.push('/subjects?dept=${dept.slug}'),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.blue50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.blue100),
                      ),
                      child: Center(
                        child: Text(
                          dept.code,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dept.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy950,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Code: ${dept.code} • 8 Semesters',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.slate400,
                      size: 24,
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
