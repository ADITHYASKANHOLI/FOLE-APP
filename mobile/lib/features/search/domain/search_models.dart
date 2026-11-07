class SearchResult {
  final String id;
  final String type;
  final String title;
  final String? slug;
  final String? subjectSlug;
  final String? moduleSlug;
  final List<String> breadcrumbs;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.slug,
    this.subjectSlug,
    this.moduleSlug,
    required this.breadcrumbs,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final rawBreadcrumbs = json['breadcrumbs'] as List<dynamic>? ?? [];
    return SearchResult(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'subject',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      subjectSlug: json['subject_slug']?.toString(),
      moduleSlug: json['module_slug']?.toString(),
      breadcrumbs: rawBreadcrumbs.map((b) => b.toString()).toList(),
    );
  }
}
