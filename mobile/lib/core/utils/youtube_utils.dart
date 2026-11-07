class YouTubeUtils {
  static const List<String> allowedDomains = [
    'youtube.com',
    'www.youtube.com',
    'm.youtube.com',
    'music.youtube.com',
    'youtu.be',
  ];

  static final RegExp videoIdRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');

  /// Extracts a valid 11-character YouTube video ID from any supported format.
  /// Returns null if URL is malformed, phishing, or non-whitelisted.
  static String? extractVideoId(String? input) {
    if (input == null) return null;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Direct video ID input
    if (videoIdRegex.hasMatch(trimmed)) {
      return trimmed;
    }

    try {
      final uriString =
          trimmed.startsWith(RegExp(r'https?://', caseSensitive: false))
              ? trimmed
              : 'https://$trimmed';
      final uri = Uri.parse(uriString);
      final host = uri.host.toLowerCase();

      final isAllowed = allowedDomains.any(
        (domain) => host == domain || host.endsWith('.$domain'),
      );

      if (!isAllowed) {
        return null;
      }

      String? candidateId;

      if (host == 'youtu.be' || host.endsWith('.youtu.be')) {
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segments.isNotEmpty) {
          candidateId = segments.first;
        }
      } else {
        if (uri.path == '/watch') {
          candidateId = uri.queryParameters['v'];
        } else if (uri.path.startsWith('/embed/')) {
          final parts = uri.path.substring('/embed/'.length).split('/');
          if (parts.isNotEmpty) candidateId = parts.first;
        } else if (uri.path.startsWith('/shorts/')) {
          final parts = uri.path.substring('/shorts/'.length).split('/');
          if (parts.isNotEmpty) candidateId = parts.first;
        } else if (uri.path.startsWith('/live/')) {
          final parts = uri.path.substring('/live/'.length).split('/');
          if (parts.isNotEmpty) candidateId = parts.first;
        }
      }

      if (candidateId == null) return null;

      // Strip query or fragment if embedded in segment
      final cleanId = candidateId.split(RegExp(r'[?#&]')).first;
      if (videoIdRegex.hasMatch(cleanId)) {
        return cleanId;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Construct canonical watch URL
  static String? getWatchUrl(String? input) {
    final id = extractVideoId(input);
    if (id == null) return null;
    return 'https://www.youtube.com/watch?v=$id';
  }

  /// Construct secure nocookie embed URL
  static String? getEmbedUrl(String? input) {
    final id = extractVideoId(input);
    if (id == null) return null;
    return 'https://www.youtube-nocookie.com/embed/$id';
  }

  /// Construct thumbnail image URL
  static String? getThumbnailUrl(String? input,
      {String quality = 'hqdefault'}) {
    final id = extractVideoId(input);
    if (id == null) return null;
    return 'https://img.youtube.com/vi/$id/$quality.jpg';
  }
}
