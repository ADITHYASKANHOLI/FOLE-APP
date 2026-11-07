class SpaceSession {
  final String id;
  final String startedAt;
  final String expiresAt;
  final String status;
  final int? durationMinutes;

  const SpaceSession({
    required this.id,
    required this.startedAt,
    required this.expiresAt,
    required this.status,
    this.durationMinutes,
  });

  factory SpaceSession.fromJson(Map<String, dynamic> json) {
    return SpaceSession(
      id: json['id']?.toString() ?? '',
      startedAt: json['started_at']?.toString() ?? '',
      expiresAt: json['expires_at']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      durationMinutes: (json['duration_minutes'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'started_at': startedAt,
        'expires_at': expiresAt,
        'status': status,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
      };

  bool get isActive => status.toLowerCase() == 'active';
}

class SpaceStatus {
  final bool isOpen;
  final int capacity;
  final int currentOccupancy;
  final int availableSeats;
  final Map<String, dynamic>? openingHours;
  final String serverNow;
  final SpaceSession? userActiveSession;
  final Map<String, dynamic>? nextBlockingEvent;

  const SpaceStatus({
    required this.isOpen,
    required this.capacity,
    required this.currentOccupancy,
    required this.availableSeats,
    this.openingHours,
    required this.serverNow,
    this.userActiveSession,
    this.nextBlockingEvent,
  });

  factory SpaceStatus.fromJson(Map<String, dynamic> json) {
    final activeSessionJson =
        json['user_active_session'] as Map<String, dynamic>?;
    return SpaceStatus(
      isOpen: json['is_open'] == true,
      capacity: (json['capacity'] as num?)?.toInt() ?? 30,
      currentOccupancy: (json['current_occupancy'] as num?)?.toInt() ?? 0,
      availableSeats: (json['available_seats'] as num?)?.toInt() ?? 30,
      openingHours: json['opening_hours'] as Map<String, dynamic>?,
      serverNow: json['server_now']?.toString() ??
          DateTime.now().toUtc().toIso8601String(),
      userActiveSession: activeSessionJson != null
          ? SpaceSession.fromJson(activeSessionJson)
          : null,
      nextBlockingEvent: json['next_blocking_event'] as Map<String, dynamic>?,
    );
  }
}

class EventRegistration {
  final String id;
  final String eventId;
  final String ticketCode;
  final String status;
  final String? registeredAt;

  const EventRegistration({
    required this.id,
    required this.eventId,
    required this.ticketCode,
    required this.status,
    this.registeredAt,
  });

  factory EventRegistration.fromJson(Map<String, dynamic> json) {
    return EventRegistration(
      id: json['id']?.toString() ?? json['registration_id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      ticketCode: json['ticket_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'registered',
      registeredAt: json['registered_at']?.toString(),
    );
  }
}

class SpaceEvent {
  final String id;
  final String title;
  final String slug;
  final String? description;
  final String startsAt;
  final String endsAt;
  final int capacity;
  final int registeredCount;
  final String status;
  final bool allowVirtualCheckin;
  final String venue;
  final String? flyerUrl;
  final EventRegistration? userRegistration;

  const SpaceEvent({
    required this.id,
    required this.title,
    required this.slug,
    this.description,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.registeredCount,
    required this.status,
    this.allowVirtualCheckin = false,
    this.venue = 'FOLE SPACE',
    this.flyerUrl,
    this.userRegistration,
  });

  factory SpaceEvent.fromJson(Map<String, dynamic> json) {
    final regJson = json['user_registration'] as Map<String, dynamic>?;
    return SpaceEvent(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      startsAt: json['starts_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 30,
      registeredCount: (json['registered_count'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? 'published',
      allowVirtualCheckin: json['allow_virtual_checkin'] == true,
      venue: json['venue']?.toString() ?? 'FOLE SPACE Labs',
      flyerUrl: json['flyer_url']?.toString(),
      userRegistration:
          regJson != null ? EventRegistration.fromJson(regJson) : null,
    );
  }

  bool get isRegistered => userRegistration != null;
  bool get isLive => status.toLowerCase() == 'live';
  int get availableSpots => (capacity - registeredCount).clamp(0, capacity);
}

class MyRegistrationItem {
  final String registrationId;
  final String eventId;
  final String eventTitle;
  final String startsAt;
  final String endsAt;
  final String ticketCode;
  final String status;
  final String eventStatus;

  const MyRegistrationItem({
    required this.registrationId,
    required this.eventId,
    required this.eventTitle,
    required this.startsAt,
    required this.endsAt,
    required this.ticketCode,
    required this.status,
    required this.eventStatus,
  });

  factory MyRegistrationItem.fromJson(Map<String, dynamic> json) {
    return MyRegistrationItem(
      registrationId: json['registration_id']?.toString() ?? '',
      eventId: json['event_id']?.toString() ?? '',
      eventTitle: json['event_title']?.toString() ?? 'FOLE SPACE Event',
      startsAt: json['starts_at']?.toString() ?? '',
      endsAt: json['ends_at']?.toString() ?? '',
      ticketCode: json['ticket_code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'registered',
      eventStatus: json['event_status']?.toString() ?? 'published',
    );
  }
}

class MySpaceData {
  final SpaceSession? activeSession;
  final List<MyRegistrationItem> upcomingRegistrations;
  final List<dynamic> history;

  const MySpaceData({
    this.activeSession,
    this.upcomingRegistrations = const [],
    this.history = const [],
  });

  factory MySpaceData.fromJson(Map<String, dynamic> json) {
    final sessionJson = json['active_session'] as Map<String, dynamic>?;
    final regsJson = json['upcoming_registrations'] as List<dynamic>? ?? [];
    final histJson = json['history'] as List<dynamic>? ?? [];

    return MySpaceData(
      activeSession:
          sessionJson != null ? SpaceSession.fromJson(sessionJson) : null,
      upcomingRegistrations: regsJson
          .map((r) => MyRegistrationItem.fromJson(r as Map<String, dynamic>))
          .toList(),
      history: histJson,
    );
  }
}
