import 'package:flutter_test/flutter_test.dart';
import 'package:engivault_mobile/features/organizer/domain/organizer_models.dart';

void main() {
  group('OrganizerEvent Model', () {
    test('parses event metadata and live flag correctly', () {
      final json = {
        'id': 'ev-01',
        'title': 'Competitive Programming Desk',
        'slug': 'competitive-programming-desk',
        'starts_at': '2026-11-12T10:00:00Z',
        'ends_at': '2026-11-12T13:00:00Z',
        'status': 'live',
        'capacity': 30,
        'allow_virtual_checkin': true,
      };

      final event = OrganizerEvent.fromJson(json);
      expect(event.id, 'ev-01');
      expect(event.title, 'Competitive Programming Desk');
      expect(event.isLive, isTrue);
      expect(event.allowVirtualCheckin, isTrue);
      expect(event.capacity, 30);
    });
  });

  group('OrganizerDeskStats Model', () {
    test('calculates checkin rate and remaining count correctly', () {
      final json = {
        'registered': 20,
        'checked_in': 15,
        'virtual_checked_in': 5,
      };

      final stats = OrganizerDeskStats.fromJson(json);
      expect(stats.registered, 20);
      expect(stats.checkedIn, 15);
      expect(stats.virtualCheckedIn, 5);
      expect(stats.remaining, 5);
      expect(stats.checkinRate, 0.75); // 15 / 20 = 75%
    });

    test('handles zero registrations safely without division by zero', () {
      final json = {
        'registered': 0,
        'checked_in': 0,
        'virtual_checked_in': 0,
      };

      final stats = OrganizerDeskStats.fromJson(json);
      expect(stats.remaining, 0);
      expect(stats.checkinRate, 0.0);
    });
  });

  group('OrganizerDeskData and Attendees', () {
    test('parses complete roster and individual attendee details', () {
      final json = {
        'event': {
          'id': 'ev-01',
          'title': 'AI & Robotics Lab',
          'status': 'live',
          'starts_at': '2026-11-12T10:00:00Z',
          'ends_at': '2026-11-12T12:00:00Z',
          'capacity': 25,
        },
        'stats': {
          'registered': 2,
          'checked_in': 1,
          'virtual_checked_in': 0,
        },
        'attendees': [
          {
            'registration_id': 'reg-01',
            'student_id': 'u-01',
            'username': 'rahul_v',
            'display_name': 'Rahul V',
            'ticket_code': 'FS1.CODE-001',
            'is_checked_in': true,
            'checked_in_at': '2026-11-12T10:05:00Z',
            'checkin_method': 'qr',
            'checkin_id': 'chk-01',
          },
          {
            'registration_id': 'reg-02',
            'student_id': 'u-02',
            'username': 'ananya_cs',
            'display_name': 'Ananya CS',
            'ticket_code': 'FS1.CODE-002',
            'is_checked_in': false,
          },
        ],
      };

      final desk = OrganizerDeskData.fromJson(json);
      expect(desk.event.title, 'AI & Robotics Lab');
      expect(desk.stats.registered, 2);
      expect(desk.stats.checkedIn, 1);
      expect(desk.attendees.length, 2);

      final first = desk.attendees.first;
      expect(first.username, 'rahul_v');
      expect(first.isCheckedIn, isTrue);
      expect(first.checkinMethod, 'qr');
      expect(first.checkinId, 'chk-01');

      final second = desk.attendees[1];
      expect(second.username, 'ananya_cs');
      expect(second.isCheckedIn, isFalse);
    });
  });

  group('CheckinResult Model', () {
    test('parses successful check-in response', () {
      final json = {
        'success': true,
        'message': 'Check-in confirmed!',
        'checkin': {
          'id': 'chk-01',
          'student_username': 'rahul_v',
          'checkin_time': '2026-11-12T10:05:00Z',
          'method': 'qr',
        },
      };

      final result = CheckinResult.fromJson(json);
      expect(result.success, isTrue);
      expect(result.message, 'Check-in confirmed!');
      expect(result.studentUsername, 'rahul_v');
      expect(result.checkinId, 'chk-01');
      expect(result.method, 'qr');
    });
  });
}
