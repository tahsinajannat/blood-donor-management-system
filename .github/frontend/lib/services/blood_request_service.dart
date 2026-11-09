import '../config/api_config.dart';
import '../models/blood_request.dart';
import 'api_client.dart';

class BloodRequestService {
  final ApiClient _client = ApiClient();

  Future<List<BloodRequest>> getAll() async {
    final res = await _client.get(ApiConfig.bloodRequests);
    final list = (res['requests'] as List)
        .map((e) => BloodRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  Future<List<BloodRequest>> getMine() async {
    final res = await _client.get(ApiConfig.myBloodRequests);
    final list = (res['requests'] as List)
        .map((e) => BloodRequest.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  Future<BloodRequest> getById(int id) async {
    final res = await _client.get(ApiConfig.bloodRequestById(id));
    return BloodRequest.fromJson(Map<String, dynamic>.from(res));
  }

  Future<BloodRequest> create({
    required String patientName,
    String? contactNumber,
    required String bloodGroup,
    required int units,
    required String requestType,
    required String cause,
    required String locationDetail,
    required DateTime requiredTime,
    String? note,
  }) async {
    final res = await _client.post(ApiConfig.bloodRequests, body: {
      'patient_name': patientName,
      if (contactNumber != null && contactNumber.isNotEmpty)
        'contact_number': contactNumber,
      'blood_group': bloodGroup,
      'units': units,
      'request_type': requestType,
      'cause': cause,
      'location_detail': locationDetail,
      'required_time': requiredTime.toIso8601String(),
      if (note != null && note.isNotEmpty) 'note': note,
    });
    return BloodRequest.fromJson(Map<String, dynamic>.from(res['request']));
  }

  Future<BloodRequest> update(int id, Map<String, dynamic> updates) async {
    final res = await _client.put(ApiConfig.bloodRequestById(id), body: updates);
    return BloodRequest.fromJson(Map<String, dynamic>.from(res['request']));
  }

  Future<void> delete(int id) async {
    await _client.delete(ApiConfig.bloodRequestById(id));
  }
}
