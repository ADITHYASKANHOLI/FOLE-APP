import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/engivault_app_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/loading_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/status_badge.dart';
import '../data/materials_repository.dart';
import '../domain/material_models.dart';

class MaterialsCatalogScreen extends ConsumerStatefulWidget {
  final String? initialSubjectId;

  const MaterialsCatalogScreen({super.key, this.initialSubjectId});

  @override
  ConsumerState<MaterialsCatalogScreen> createState() =>
      _MaterialsCatalogScreenState();
}

class _MaterialsCatalogScreenState
    extends ConsumerState<MaterialsCatalogScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _downloadingIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filter = MaterialFilter(
      subjectId: widget.initialSubjectId,
      search: _searchQuery.isNotEmpty ? _searchQuery : null,
    );
    final materialsAsync = ref.watch(materialsListProvider(filter));

    return Scaffold(
      appBar: const EngivaultAppBar(title: 'Study Materials'),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes, question banks, derivations...',
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
              onSubmitted: (val) => setState(() => _searchQuery = val.trim()),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: materialsAsync.when(
              data: (materials) {
                if (materials.isEmpty) {
                  return const EmptyView(
                    title: 'No Materials Found',
                    message:
                        'No study notes or question papers matched your query.',
                    icon: Icons.description_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: materials.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = materials[index];
                    final isDownloading = _downloadingIds.contains(item.id);

                    return GlassCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.statusSuccessBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.picture_as_pdf,
                                color: AppColors.statusSuccess, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (item.subjectTitle != null)
                                      StatusBadge.info(item.subjectTitle!),
                                    const Spacer(),
                                    StatusBadge.code(item.formattedSize),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.title,
                                  style: AppTypography.titleMedium
                                      .copyWith(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.originalFilename,
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          isDownloading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : IconButton(
                                  icon: const Icon(Icons.download_rounded,
                                      color: AppColors.royalBlue),
                                  tooltip: 'Download & Open',
                                  onPressed: () => _handleDownload(item),
                                ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const LoadingView(
                  message: 'Loading study materials catalogue...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.invalidate(materialsListProvider(filter)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDownload(MaterialItem item) async {
    setState(() => _downloadingIds.add(item.id));
    try {
      final repo = ref.read(materialsRepositoryProvider);
      final auth = await repo.getDownloadAuthorization(item.id);

      final uri = Uri.parse(auth.downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open document URL.')),
          );
        }
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $err')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _downloadingIds.remove(item.id));
      }
    }
  }
}
