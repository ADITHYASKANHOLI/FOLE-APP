class MaterialItem {
  final String id;
  final String title;
  final String materialType;
  final String originalFilename;
  final int? fileSize;
  final String? subjectId;
  final String? subjectTitle;
  final String? moduleId;
  final String? moduleTitle;
  final String downloadEndpoint;

  const MaterialItem({
    required this.id,
    required this.title,
    required this.materialType,
    required this.originalFilename,
    this.fileSize,
    this.subjectId,
    this.subjectTitle,
    this.moduleId,
    this.moduleTitle,
    required this.downloadEndpoint,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    return MaterialItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      materialType: json['material_type']?.toString() ?? 'notes',
      originalFilename: json['original_filename']?.toString() ?? 'document.pdf',
      fileSize: (json['file_size'] as num?)?.toInt(),
      subjectId: json['subject_id']?.toString(),
      subjectTitle: json['subject_title']?.toString(),
      moduleId: json['module_id']?.toString(),
      moduleTitle: json['module_title']?.toString(),
      downloadEndpoint: json['download_endpoint']?.toString() ?? '',
    );
  }

  String get formattedSize {
    if (fileSize == null || fileSize! <= 0) return 'PDF';
    final mb = fileSize! / (1024 * 1024);
    if (mb >= 1) return '${mb.toStringAsFixed(1)} MB';
    final kb = fileSize! / 1024;
    return '${kb.toStringAsFixed(0)} KB';
  }
}

class DownloadAuthResponse {
  final String downloadUrl;
  final String expiresAt;
  final String filename;
  final int? fileSize;
  final String mimeType;

  const DownloadAuthResponse({
    required this.downloadUrl,
    required this.expiresAt,
    required this.filename,
    this.fileSize,
    required this.mimeType,
  });

  factory DownloadAuthResponse.fromJson(Map<String, dynamic> json) {
    return DownloadAuthResponse(
      downloadUrl: json['download_url']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
      filename: json['filename']?.toString() ?? 'download.pdf',
      fileSize: (json['file_size'] as num?)?.toInt(),
      mimeType: json['mime_type']?.toString() ?? 'application/pdf',
    );
  }
}

class MaterialFilter {
  final String? subjectId;
  final String? moduleId;
  final String? search;

  const MaterialFilter({
    this.subjectId,
    this.moduleId,
    this.search,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaterialFilter &&
          runtimeType == other.runtimeType &&
          subjectId == other.subjectId &&
          moduleId == other.moduleId &&
          search == other.search;

  @override
  int get hashCode => subjectId.hashCode ^ moduleId.hashCode ^ search.hashCode;
}
