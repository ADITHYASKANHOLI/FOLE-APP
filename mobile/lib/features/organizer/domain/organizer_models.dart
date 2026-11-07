class OrganizerEvent {
  final String id;
  final String title;
  final String? slug;
  final String startsAt;
  final String endsAt;
  final String status;
  final int capacity;
  final bool allowVirtualCheckin;

  const OrganizerEvent({
    required this.id,
    required this.title,
    this.slug,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.capacity,
    this.allowVirtualCheckin = false,
  });

  factory OrganizerEvent.fromJson(Map<String, dynamic> json) {
    return OrganizerEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString(),
      startsAt: json['starts_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      status: json['status']?.toString() ?? 'published',
      capacity: (json['capacity'] as num?)?.toInt() ?? 30,
      allowVirtualCheckin: json['allow_virtual_checkin'] == true,
    );
  }

  bool get isLive => status.toLowerCase() == 'live';
}

class OrganizerAttendee {
  final String registrationId;
  final String studentId;
  final String username;
  final String displayName;
  final String ticketCode;
  final bool isCheckedIn;
  final String? checkedInAt;
  final String? checkinMethod;
  final String? checkinId;

  const OrganizerAttendee({
    required this.registrationId,
    required this.studentId,
    required this.username,
    required this.displayName,
    required this.ticketCode,
    required this.isCheckedIn,
    this.checkedInAt,
    this.checkinMethod,
    this.checkinId,
  });

  factory OrganizerAttendee.fromJson(Map<String, dynamic> json) {
    return OrganizerAttendee(
      registrationId: json['registration_id']?.toString() ?? '',
      studentId: json['student_id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      displayName: json['display_name']?.toString() ??
          json['username']?.toString() ??
          'Student',
      ticketCode: json['ticket_code']?.toString() ?? '',
      isCheckedIn: json['is_checked_in'] == true,
      checkedInAt: json['checked_in_at']?.toString(),
      checkinMethod: json['checkin_method']?.toString(),
      checkinId: json['checkin_id']?.toString(),
    );
  }
}

class OrganizerDeskStats {
  final int registered;
  final int checkedIn;
  final int virtualCheckedIn;

  const OrganizerDeskStats({
    required this.registered,
    required this.checkedIn,
    required this.virtualCheckedIn,
  });

  factory OrganizerDeskStats.fromJson(Map<String, dynamic> json) {
    return OrganizerDeskStats(
      registered: (json['registered'] as num?)?.toInt() ?? 0,
      checkedIn: (json['checked_in'] as num?)?.toInt() ?? 0,
      virtualCheckedIn: (json['virtual_checked_in'] as num?)?.toInt() ?? 0,
    );
  }

  int get remaining => (registered - checkedIn).clamp(0, registered);
  double get checkinRate =>
      registered > 0 ? (checkedIn / registered).clamp(0.0, 1.0) : 0.0;
}

class OrganizerDeskData {
  final OrganizerEvent event;
  final OrganizerDeskStats stats;
  final List<OrganizerAttendee> attendees;

  const OrganizerDeskData({
    required this.event,
    required this.stats,
    required this.attendees,
  });

  factory OrganizerDeskData.fromJson(Map<String, dynamic> json) {
    final eventJson = json['event'] as Map<String, dynamic>? ?? {};
    final statsJson = json['stats'] as Map<String, dynamic>? ?? {};
    final listJson = json['attendees'] as List<dynamic>? ?? [];

    return OrganizerDeskData(
      event: OrganizerEvent.fromJson(eventJson),
      stats: OrganizerDeskStats.fromJson(statsJson),
      attendees: listJson
          .map((a) => OrganizerAttendee.fromJson(a as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CheckinResult {
  final bool success;
  final String message;
  final String? checkinId;
  final String? studentUsername;
  final String? checkinTime;
  final String? method;

  const CheckinResult({
    required this.success,
    required this.message,
    this.checkinId,
    this.studentUsername,
    this.checkinTime,
    this.method,
  });

  factory CheckinResult.fromJson(Map<String, dynamic> json) {
    final checkinJson = json['checkin'] as Map<String, dynamic>?;
    return CheckinResult(
      success: json['success'] == true,
      message: json['message']?.toString() ?? 'Check-in processed',
      checkinId: checkinJson?['id']?.toString(),
      studentUsername: checkinJson?['student_username']?.toString(),
      checkinTime: checkinJson?['checkin_time']?.toString(),
      method: checkinJson?['method']?.toString(),
    );
  }
}
