import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../data/search_repository.dart';
import '../domain/search_models.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const GlobalSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  late final TextEditingController _controller;
  late String _query;
  String _selectedFilter = 'all';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = widget.initialQuery ?? '';
    _controller = TextEditingController(text: _query);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) {
        setState(() => _query = text.trim());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchResultsProvider(_query));

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search subjects, lectures, topics...',
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
          onChanged: _onSearchChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          if (_query.isNotEmpty) ...[
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildChip('All Results', 'all'),
                    _buildChip('Subjects', 'subject'),
                    _buildChip('Lectures', 'lesson'),
                    _buildChip('Notes', 'material'),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
          ],

          Expanded(
            child: _query.isEmpty
                ? const EmptyView(
                    title: 'Search Academic Vault',
                    message:
                        'Find subjects, modules, recorded video lectures, and syllabus question notes.',
                    icon: Icons.search,
                  )
                : searchAsync.when(
                    data: (results) {
                      final filtered = _selectedFilter == 'all'
                          ? results
                          : results
                              .where((r) => r.type == _selectedFilter)
                              .toList();

                      if (filtered.isEmpty) {
                        return EmptyView(
                          title: 'No Results Found',
                          message: 'No academic content matched "$_query".',
                          icon: Icons.search_off,
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return GlassCard(
                            onTap: () => _handleResultTap(context, item),
                            child: Row(
                              children: [
                                _buildTypeIcon(item.type),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
                                      ),
                                      if (item.breadcrumbs.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          item.breadcrumbs.join(' • '),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios,
                                    size: 14, color: AppColors.textMuted),
                              ],
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const LoadingView(message: 'Searching...'),
                    error: (err, _) => ErrorView(message: err.toString()),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: () => setState(() => _selectedFilter = value),
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

  Widget _buildTypeIcon(String type) {
    switch (type) {
      case 'subject':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.school, color: AppColors.royalBlue, size: 20),
        );
      case 'lesson':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(8)),
          child:
              const Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
        );
      case 'material':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.statusSuccessBg,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.description,
              color: AppColors.statusSuccess, size: 20),
        );
      default:
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.article,
              color: AppColors.textSecondary, size: 20),
        );
    }
  }

  void _handleResultTap(BuildContext context, SearchResult item) {
    if (item.type == 'subject' && item.slug != null) {
      context.push('/subjects/${item.slug}');
    } else if (item.type == 'lesson' && item.slug != null) {
      context.push('/lessons/${item.slug}');
    } else if (item.type == 'material') {
      context.push('/materials?q=${item.title}');
    }
  }
}
