import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/organizer_models.dart';

final organizerRepositoryProvider = Provider<OrganizerRepository>((ref) {
  return OrganizerRepository(ApiClient());
});

final organizerEventsProvider =
    FutureProvider.autoDispose<List<OrganizerEvent>>((ref) async {
  final repo = ref.watch(organizerRepositoryProvider);
  return repo.getEvents();
});

final organizerDeskProvider = FutureProvider.autoDispose
    .family<OrganizerDeskData, String>((ref, eventId) async {
  final repo = ref.watch(organizerRepositoryProvider);
  return repo.getDesk(eventId);
});

class OrganizerRepository {
  final ApiClient _client;

  OrganizerRepository(this._client);

  Future<List<OrganizerEvent>> getEvents() async {
    final res = await _client.get(ApiEndpoints.organizerEvents);
    final data = res.data as Map<String, dynamic>;
    final list = data['events'] as List<dynamic>? ?? [];
    return list
        .map((e) => OrganizerEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrganizerDeskData> getDesk(String eventId) async {
    final res = await _client.get(ApiEndpoints.organizerDesk(eventId));
    final data = res.data as Map<String, dynamic>;
    return OrganizerDeskData.fromJson(data);
  }

  Future<CheckinResult> scanQrCheckin(String eventId, String qrPayload) async {
    final res = await _client.post(
      ApiEndpoints.organizerCheckinQr(eventId),
      data: {'qr_payload': qrPayload.trim()},
    );
    final data = res.data as Map<String, dynamic>;
    return CheckinResult.fromJson(data);
  }

  Future<CheckinResult> manualCheckin(
      String eventId, String registrationId) async {
    final res = await _client.post(
      ApiEndpoints.organizerCheckinManual(eventId),
      data: {'registration_id': registrationId.trim()},
    );
    final data = res.data as Map<String, dynamic>;
    return CheckinResult.fromJson(data);
  }

  Future<bool> revokeCheckin(String eventId, String checkinId) async {
    final res = await _client
        .delete(ApiEndpoints.organizerRevokeCheckin(eventId, checkinId));
    final data = res.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  Future<String> updateStatus(String eventId, String action) async {
    final res = await _client.post(
      ApiEndpoints.organizerEventStatus(eventId),
      data: {'action': action},
    );
    final data = res.data as Map<String, dynamic>;
    return data['status']?.toString() ?? action;
  }
}
