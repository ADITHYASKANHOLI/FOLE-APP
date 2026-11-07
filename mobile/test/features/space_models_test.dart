import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/features/fole_space/domain/space_models.dart';

void main() {
  group('SpaceSession Model', () {
    test('parses active session JSON correctly', () {
      final json = {
        'id': 'sess-01',
        'started_at': '2026-11-07T14:15:30Z',
        'expires_at': '2026-11-07T15:00:30Z',
        'status': 'active',
        'duration_minutes': 45,
      };

      final session = SpaceSession.fromJson(json);
      expect(session.id, 'sess-01');
      expect(session.startedAt, '2026-11-07T14:15:30Z');
      expect(session.expiresAt, '2026-11-07T15:00:30Z');
      expect(session.status, 'active');
      expect(session.isActive, isTrue);
      expect(session.durationMinutes, 45);
    });

    test('serializes to JSON correctly', () {
      const session = SpaceSession(
        id: 'sess-02',
        startedAt: '2026-11-07T10:00:00Z',
        expiresAt: '2026-11-07T10:45:00Z',
        status: 'active',
        durationMinutes: 45,
      );

      final map = session.toJson();
      expect(map['id'], 'sess-02');
      expect(map['status'], 'active');
    });
  });

  group('SpaceStatus Model', () {
    test('parses open status with active session and capacity', () {
      final json = {
        'is_open': true,
        'capacity': 30,
        'current_occupancy': 12,
        'available_seats': 18,
        'opening_hours': {
          'monday': {'open': '09:00', 'close': '18:00', 'closed': false}
        },
        'server_now': '2026-11-07T14:15:30Z',
        'user_active_session': {
          'id': 'sess-01',
          'started_at': '2026-11-07T14:15:30Z',
          'expires_at': '2026-11-07T15:00:30Z',
          'status': 'active',
        },
      };

      final status = SpaceStatus.fromJson(json);
      expect(status.isOpen, isTrue);
      expect(status.capacity, 30);
      expect(status.currentOccupancy, 12);
      expect(status.availableSeats, 18);
      expect(status.userActiveSession, isNotNull);
      expect(status.userActiveSession!.id, 'sess-01');
    });

    test('handles closed status with zero seats', () {
      final json = {
        'is_open': false,
        'capacity': 30,
        'current_occupancy': 0,
        'available_seats': 0,
      };

      final status = SpaceStatus.fromJson(json);
      expect(status.isOpen, isFalse);
      expect(status.userActiveSession, isNull);
    });
  });

  group('SpaceEvent and Registration Models', () {
    test('parses event with user registration', () {
      final json = {
        'id': 'ev-01',
        'title': 'Competitive Programming & Graph Algorithms',
        'slug': 'competitive-programming-graphs',
        'starts_at': '2026-11-12T10:00:00Z',
        'ends_at': '2026-11-12T13:00:00Z',
        'capacity': 25,
        'registered_count': 14,
        'status': 'published',
        'allow_virtual_checkin': false,
        'venue': 'FOLE SPACE Labs',
        'user_registration': {
          'id': 'reg-01',
          'event_id': 'ev-01',
          'ticket_code': 'FS1.aB3_x9Z0-123456',
          'status': 'registered',
          'registered_at': '2026-11-07T14:20:00Z',
        },
      };

      final event = SpaceEvent.fromJson(json);
      expect(event.id, 'ev-01');
      expect(event.title, 'Competitive Programming & Graph Algorithms');
      expect(event.capacity, 25);
      expect(event.registeredCount, 14);
      expect(event.availableSpots, 11);
      expect(event.isRegistered, isTrue);
      expect(event.userRegistration!.ticketCode, 'FS1.aB3_x9Z0-123456');
    });

    test('parses live event status and spots clamp', () {
      final json = {
        'id': 'ev-02',
        'title': 'Hackathon Live Session',
        'slug': 'hackathon-live',
        'starts_at': '2026-11-07T14:00:00Z',
        'ends_at': '2026-11-07T18:00:00Z',
        'capacity': 20,
        'registered_count': 20,
        'status': 'live',
      };

      final event = SpaceEvent.fromJson(json);
      expect(event.isLive, isTrue);
      expect(event.availableSpots, 0);
      expect(event.isRegistered, isFalse);
    });
  });

  group('MySpaceData Model', () {
    test('parses upcoming passes and active session', () {
      final json = {
        'active_session': {
          'id': 'sess-09',
          'started_at': '2026-11-07T14:00:00Z',
          'expires_at': '2026-11-07T14:45:00Z',
          'status': 'active',
        },
        'upcoming_registrations': [
          {
            'registration_id': 'reg-99',
            'event_id': 'ev-01',
            'event_title': 'Algorithms Cohort',
            'starts_at': '2026-11-12T10:00:00Z',
            'ends_at': '2026-11-12T12:00:00Z',
            'ticket_code': 'FS1.SAMPLE-999',
            'status': 'registered',
            'event_status': 'published',
          }
        ],
        'history': [],
      };

      final mySpace = MySpaceData.fromJson(json);
      expect(mySpace.activeSession, isNotNull);
      expect(mySpace.upcomingRegistrations.length, 1);
      expect(mySpace.upcomingRegistrations.first.ticketCode, 'FS1.SAMPLE-999');
    });
  });
}
