class ApiEndpoints {
  // Public Academic
  static const String home = '/home';
  static const String departments = '/departments';
  static const String semesters = '/semesters';
  static const String subjects = '/subjects';
  static String subjectDetail(String slug) => '/subjects/$slug';
  static String lessonDetail(String idOrSlug) => '/lessons/$idOrSlug';
  static const String lectures = '/lectures';
  static const String materials = '/materials';
  static String materialDownload(String id) => '/materials/$id/download';
  static const String search = '/search';

  // FOLE WORKS
  static const String foleWorks = '/fole-works';
  static String foleWorksDetail(String slug) => '/fole-works/$slug';

  // Student Auth
  static const String login = '/auth/login';
  static const String signup = '/auth/signup';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';
  static const String changePassword = '/auth/change-password';

  // Admin Operations
  static const String adminLogin = '/admin/login';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminLessons = '/admin/lessons';

  // FOLE SPACE
  static const String spaceStatus = '/fole-space/status';
  static const String spaceCheckin = '/fole-space/checkin';
  static const String spaceCheckout = '/fole-space/checkout';
  static const String spaceExtend = '/fole-space/extend';
  static const String spaceMy = '/fole-space/my';
  static const String spaceEvents = '/fole-space/events';
  static String spaceEventRegister(String id) =>
      '/fole-space/events/$id/register';
  static String spaceEventCancel(String id) => '/fole-space/events/$id/cancel';
  static String spaceEventVirtualCheckin(String id) =>
      '/fole-space/events/$id/checkin/virtual';

  // Organizer Desk
  static const String organizerEvents = '/organizer/events';
  static String organizerDesk(String id) => '/organizer/events/$id/desk';
  static String organizerCheckinQr(String id) =>
      '/organizer/events/$id/checkin/qr';
  static String organizerCheckinManual(String id) =>
      '/organizer/events/$id/checkin/manual';
  static String organizerRevokeCheckin(String eventId, String checkinId) =>
      '/organizer/events/$eventId/checkin/$checkinId';
  static String organizerEventStatus(String id) =>
      '/organizer/events/$id/status';
}
