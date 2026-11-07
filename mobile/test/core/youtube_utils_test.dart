import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/core/utils/youtube_utils.dart';

void main() {
  group('YouTubeUtils - Video ID Extraction', () {
    test('extracts direct 11-character video ID', () {
      expect(YouTubeUtils.extractVideoId('dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
      expect(YouTubeUtils.extractVideoId('abc123_-XYZ'), 'abc123_-XYZ');
    });

    test('extracts from standard watch URL', () {
      expect(
        YouTubeUtils.extractVideoId(
            'https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeUtils.extractVideoId(
            'https://youtube.com/watch?v=dQw4w9WgXcQ&t=120s'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts from short youtu.be URL', () {
      expect(
        YouTubeUtils.extractVideoId('https://youtu.be/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
      expect(
        YouTubeUtils.extractVideoId(
            'https://youtu.be/dQw4w9WgXcQ?si=abcdef123'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts from embed URL', () {
      expect(
        YouTubeUtils.extractVideoId(
            'https://www.youtube.com/embed/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts from shorts URL', () {
      expect(
        YouTubeUtils.extractVideoId(
            'https://www.youtube.com/shorts/dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('extracts from mobile m.youtube.com URL', () {
      expect(
        YouTubeUtils.extractVideoId(
            'https://m.youtube.com/watch?v=dQw4w9WgXcQ'),
        'dQw4w9WgXcQ',
      );
    });

    test('rejects non-whitelisted domains', () {
      expect(
          YouTubeUtils.extractVideoId('https://vimeo.com/12345678901'), isNull);
      expect(
          YouTubeUtils.extractVideoId(
              'https://evil-youtube.com/watch?v=dQw4w9WgXcQ'),
          isNull);
      expect(YouTubeUtils.extractVideoId('https://notyoutube.com/dQw4w9WgXcQ'),
          isNull);
    });

    test('rejects invalid or malformed strings', () {
      expect(YouTubeUtils.extractVideoId(null), isNull);
      expect(YouTubeUtils.extractVideoId(''), isNull);
      expect(YouTubeUtils.extractVideoId('   '), isNull);
      expect(YouTubeUtils.extractVideoId('too_short'), isNull);
      expect(YouTubeUtils.extractVideoId('this_id_is_way_too_long_to_be_valid'),
          isNull);
      expect(
          YouTubeUtils.extractVideoId('https://www.youtube.com/watch'), isNull);
    });
  });

  group('YouTubeUtils - Canonical URL Generation', () {
    const videoId = 'dQw4w9WgXcQ';

    test('builds canonical watch URL', () {
      expect(
        YouTubeUtils.getWatchUrl(videoId),
        'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      );
    });

    test('builds nocookie embed URL', () {
      expect(
        YouTubeUtils.getEmbedUrl(videoId),
        'https://www.youtube-nocookie.com/embed/dQw4w9WgXcQ',
      );
    });

    test('builds thumbnail URL with default or custom quality', () {
      expect(
        YouTubeUtils.getThumbnailUrl(videoId),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
      );
      expect(
        YouTubeUtils.getThumbnailUrl(videoId, quality: 'maxresdefault'),
        'https://img.youtube.com/vi/dQw4w9WgXcQ/maxresdefault.jpg',
      );
    });

    test('returns null for invalid inputs when building URLs', () {
      expect(YouTubeUtils.getWatchUrl('invalid'), isNull);
      expect(YouTubeUtils.getEmbedUrl(null), isNull);
      expect(YouTubeUtils.getThumbnailUrl(''), isNull);
    });
  });
}
