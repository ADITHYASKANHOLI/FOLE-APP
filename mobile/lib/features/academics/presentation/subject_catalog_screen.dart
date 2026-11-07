import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/academics_repository.dart';

class SubjectCatalogScreen extends ConsumerStatefulWidget {
  final String? initialDept;
  final int? initialSem;

  const SubjectCatalogScreen({
    super.key,
    this.initialDept,
    this.initialSem,
  });

  @override
  ConsumerState<SubjectCatalogScreen> createState() =>
      _SubjectCatalogScreenState();
}

class _SubjectCatalogScreenState extends ConsumerState<SubjectCatalogScreen> {
  late String? _selectedDept;
  late int? _selectedSem;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDept = widget.initialDept;
    _selectedSem = widget.initialSem;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deptsAsync = ref.watch(departmentsProvider);
    final filters = {
      'dept': _selectedDept,
      'sem': _selectedSem,
      'q': _searchQuery,
    };
    final subjectsAsync = ref.watch(subjectsFilterProvider(filters));

    return Scaffold(
      appBar: const EngivaultAppBar(title: 'KTU Subjects'),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search subjects (e.g. Calculus, Graphics)...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    isDense: true,
                  ),
                  onSubmitted: (val) {
                    setState(() => _searchQuery = val.trim());
                  },
                ),
                const SizedBox(height: 10),
                // Department Filter Pills
                deptsAsync.when(
                  data: (depts) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          label: 'All Branches',
                          isSelected: _selectedDept == null,
                          onTap: () => setState(() => _selectedDept = null),
                        ),
                        ...depts.map((d) => _buildFilterChip(
                              label: d.code,
                              isSelected: _selectedDept == d.slug ||
                                  _selectedDept == d.code,
                              onTap: () =>
                                  setState(() => _selectedDept = d.slug),
                            )),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 32),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                // Semester Filter Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All Semesters',
                        isSelected: _selectedSem == null,
                        onTap: () => setState(() => _selectedSem = null),
                      ),
                      ...List.generate(8, (i) => i + 1)
                          .map((semNum) => _buildFilterChip(
                                label: 'S$semNum',
                                isSelected: _selectedSem == semNum,
                                onTap: () =>
                                    setState(() => _selectedSem = semNum),
                              )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Subjects List
          Expanded(
            child: subjectsAsync.when(
              data: (subjects) {
                if (subjects.isEmpty) {
                  return const EmptyView(
                    title: 'No Subjects Found',
                    message:
                        'Try adjusting your department, semester, or search criteria.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
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
                                StatusBadge.info(
                                    'Semester ${s.semesterNumber}'),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(s.title,
                              style: AppTypography.titleLarge
                                  .copyWith(fontSize: 16)),
                          if (s.shortDescription != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              s.shortDescription!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.layers_outlined,
                                  size: 14, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text('${s.modulesCount} Modules',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              const SizedBox(width: 14),
                              const Icon(Icons.play_circle_outline,
                                  size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('${s.lessonsCount} Video Lectures',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                              const SizedBox(width: 14),
                              const Icon(Icons.description_outlined,
                                  size: 14, color: AppColors.statusSuccess),
                              const SizedBox(width: 4),
                              Text('${s.materialsCount} Notes',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const LoadingView(message: 'Loading subjects catalog...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(subjectsFilterProvider(filters)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.royalBlue : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.royalBlue : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
