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
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../../academics/data/academics_repository.dart';
import '../data/lectures_repository.dart';

class LecturesBrowserScreen extends ConsumerStatefulWidget {
  final String? initialDept;
  final String? initialSem;
  final String? initialSubject;

  const LecturesBrowserScreen({
    super.key,
    this.initialDept,
    this.initialSem,
    this.initialSubject,
  });

  @override
  ConsumerState<LecturesBrowserScreen> createState() =>
      _LecturesBrowserScreenState();
}

class _LecturesBrowserScreenState extends ConsumerState<LecturesBrowserScreen> {
  late String? _selectedDept;
  late String? _selectedSem;
  late String? _selectedSubject;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDept = widget.initialDept;
    _selectedSem = widget.initialSem;
    _selectedSubject = widget.initialSubject;
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
      'subject': _selectedSubject,
      'q': _searchQuery,
    };
    final lecturesAsync = ref.watch(lecturesBrowserProvider(filters));

    return Scaffold(
      appBar: const EngivaultAppBar(title: 'Recorded Lectures'),
      body: Column(
        children: [
          // Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search lectures or topics...',
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
                  onSubmitted: (val) =>
                      setState(() => _searchQuery = val.trim()),
                ),
                const SizedBox(height: 10),
                deptsAsync.when(
                  data: (depts) => SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                            'All Disciplines', _selectedDept == null, () {
                          setState(() => _selectedDept = null);
                        }),
                        ...depts.map((d) => _buildFilterChip(
                                d.code,
                                _selectedDept == d.slug ||
                                    _selectedDept == d.code, () {
                              setState(() => _selectedDept = d.slug);
                            })),
                      ],
                    ),
                  ),
                  loading: () => const SizedBox(height: 32),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All Sems', _selectedSem == null, () {
                        setState(() => _selectedSem = null);
                      }),
                      ...List.generate(8, (i) => i + 1).map((s) =>
                          _buildFilterChip('S$s', _selectedSem == '$s', () {
                            setState(() => _selectedSem = '$s');
                          })),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Lecture List
          Expanded(
            child: lecturesAsync.when(
              data: (lectures) {
                if (lectures.isEmpty) {
                  return const EmptyView(
                    title: 'No Lectures Found',
                    message:
                        'Try clearing some filters or searching with different terms.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: lectures.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final lec = lectures[index];
                    return GlassCard(
                      onTap: () => context.push('/lessons/${lec.slug}'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade100),
                            ),
                            child: const Icon(Icons.play_circle_fill,
                                color: Colors.red, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    StatusBadge.info(lec.subjectTitle),
                                    const Spacer(),
                                    if (lec.durationSeconds != null)
                                      Text(
                                        DateFormatter.formatDuration(
                                            lec.durationSeconds),
                                        style: AppTypography.monoCode.copyWith(
                                            fontSize: 11,
                                            color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  lec.title,
                                  style: AppTypography.titleMedium
                                      .copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lec.moduleTitle,
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted),
                                ),
                                if (lec.instructor != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Faculty: ${lec.instructor}',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.royalBlue),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(message: 'Loading lectures...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(lecturesBrowserProvider(filters)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
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
