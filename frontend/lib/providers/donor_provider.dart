import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';

class DonorProvider extends ChangeNotifier {
  final UserService _service = UserService();

  List<AppUser> donors = [];
  bool isLoading = false;
  String? error;

  String? bloodGroup;
  String area = '';
  String city = '';

  Future<void> search({bool reset = true}) async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      final res = await _service.searchDonors(
        bloodGroup: bloodGroup,
        area: area,
        city: city,
        page: 1,
        itemsPerPage: 30,
      );
      donors = res['donors'];
    } catch (e) {
      error = 'Failed to load donors. Pull down to retry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setBloodGroup(String? value) {
    bloodGroup = value;
    notifyListeners();
  }
}
