class WorksActivityItem {
  final String id;
  final String title;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? startDate;
  final String? endDate;
  final String venue;
  final String fee;
  final String category;
  final String status;
  final String flyerUrl;
  final String? registrationUrl;

  const WorksActivityItem({
    required this.id,
    required this.title,
    required this.slug,
    this.shortDescription,
    this.description,
    this.startDate,
    this.endDate,
    required this.venue,
    required this.fee,
    required this.category,
    required this.status,
    required this.flyerUrl,
    this.registrationUrl,
  });

  factory WorksActivityItem.fromJson(Map<String, dynamic> json) {
    return WorksActivityItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      shortDescription: json['short_description']?.toString(),
      description: json['description']?.toString(),
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      venue: json['venue']?.toString() ?? 'FOLE SPACE',
      fee: json['fee']?.toString() ?? 'Free',
      category: json['category']?.toString() ?? 'Workshop',
      status: json['status']?.toString() ?? 'upcoming',
      flyerUrl: json['flyer_url']?.toString() ?? '',
      registrationUrl: json['registration_url']?.toString(),
    );
  }
}
