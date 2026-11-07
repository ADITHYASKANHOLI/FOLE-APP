import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../domain/space_models.dart';

final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  return SpaceRepository(ApiClient());
});

final spaceStatusProvider =
    FutureProvider.autoDispose<SpaceStatus>((ref) async {
  final repo = ref.watch(spaceRepositoryProvider);
  return repo.getStatus();
});

final spaceEventsProvider =
    FutureProvider.autoDispose<List<SpaceEvent>>((ref) async {
  final repo = ref.watch(spaceRepositoryProvider);
  return repo.getEvents();
});

final mySpaceProvider = FutureProvider.autoDispose<MySpaceData>((ref) async {
  final repo = ref.watch(spaceRepositoryProvider);
  return repo.getMySpace();
});

class SpaceRepository {
  final ApiClient _client;

  SpaceRepository(this._client);

  Future<SpaceStatus> getStatus() async {
    final res = await _client.get(ApiEndpoints.spaceStatus);
    final data = res.data as Map<String, dynamic>;
    return SpaceStatus.fromJson(data);
  }

  Future<SpaceSession> checkin() async {
    final res = await _client.post(ApiEndpoints.spaceCheckin);
    final data = res.data as Map<String, dynamic>;
    final sessionData = data['session'] as Map<String, dynamic>? ?? {};
    return SpaceSession.fromJson(sessionData);
  }

  Future<bool> checkout() async {
    final res = await _client.post(ApiEndpoints.spaceCheckout);
    final data = res.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  Future<SpaceSession> extend() async {
    final res = await _client.post(ApiEndpoints.spaceExtend);
    final data = res.data as Map<String, dynamic>;
    final sessionData = data['session'] as Map<String, dynamic>? ?? {};
    return SpaceSession.fromJson(sessionData);
  }

  Future<MySpaceData> getMySpace() async {
    final res = await _client.get(ApiEndpoints.spaceMy);
    final data = res.data as Map<String, dynamic>;
    return MySpaceData.fromJson(data);
  }

  Future<List<SpaceEvent>> getEvents({String? category, String? month}) async {
    final query = <String, dynamic>{};
    if (category != null && category.isNotEmpty) query['category'] = category;
    if (month != null && month.isNotEmpty) query['month'] = month;

    final res =
        await _client.get(ApiEndpoints.spaceEvents, queryParameters: query);
    final data = res.data as Map<String, dynamic>;
    final list = data['events'] as List<dynamic>? ?? [];
    return list
        .map((e) => SpaceEvent.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<EventRegistration> registerEvent(String eventId) async {
    final res = await _client.post(ApiEndpoints.spaceEventRegister(eventId));
    final data = res.data as Map<String, dynamic>;
    final regData = data['registration'] as Map<String, dynamic>? ?? {};
    return EventRegistration.fromJson(regData);
  }

  Future<bool> cancelEvent(String eventId) async {
    final res = await _client.post(ApiEndpoints.spaceEventCancel(eventId));
    final data = res.data as Map<String, dynamic>;
    return data['success'] == true;
  }

  Future<bool> virtualCheckin(String eventId) async {
    final res =
        await _client.post(ApiEndpoints.spaceEventVirtualCheckin(eventId));
    final data = res.data as Map<String, dynamic>;
    return data['success'] == true;
  }
}
