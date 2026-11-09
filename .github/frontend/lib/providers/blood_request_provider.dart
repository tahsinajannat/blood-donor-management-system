import 'package:flutter/material.dart';

import '../models/blood_request.dart';
import '../services/api_exception.dart';
import '../services/blood_request_service.dart';

class BloodRequestProvider extends ChangeNotifier {
  final BloodRequestService _service = BloodRequestService();

  List<BloodRequest> allRequests = [];
  List<BloodRequest> myRequests = [];
  bool isLoadingAll = false;
  bool isLoadingMine = false;
  String? error;

  Future<void> loadAll() async {
    isLoadingAll = true;
    error = null;
    notifyListeners();
    try {
      allRequests = await _service.getAll();
    } on ApiException catch (e) {
      error = e.message;
    } catch (_) {
      error = 'Failed to load blood requests.';
    } finally {
      isLoadingAll = false;
      notifyListeners();
    }
  }

  Future<void> loadMine() async {
    isLoadingMine = true;
    notifyListeners();
    try {
      myRequests = await _service.getMine();
    } catch (_) {
      // silent - surfaced in UI via empty state
    } finally {
      isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<BloodRequest?> create({
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
    try {
      final created = await _service.create(
        patientName: patientName,
        contactNumber: contactNumber,
        bloodGroup: bloodGroup,
        units: units,
        requestType: requestType,
        cause: cause,
        locationDetail: locationDetail,
        requiredTime: requiredTime,
        note: note,
      );
      allRequests.insert(0, created);
      myRequests.insert(0, created);
      notifyListeners();
      return created;
    } on ApiException catch (e) {
      error = e.message;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateStatus(int id, String status) async {
    final updated = await _service.update(id, {'status': status});
    _replace(updated);
  }

  Future<void> delete(int id) async {
    await _service.delete(id);
    allRequests.removeWhere((r) => r.id == id);
    myRequests.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  void _replace(BloodRequest updated) {
    final i1 = allRequests.indexWhere((r) => r.id == updated.id);
    if (i1 != -1) allRequests[i1] = updated;
    final i2 = myRequests.indexWhere((r) => r.id == updated.id);
    if (i2 != -1) myRequests[i2] = updated;
    notifyListeners();
  }
}
