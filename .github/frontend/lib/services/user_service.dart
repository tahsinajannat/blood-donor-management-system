import '../config/api_config.dart';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _client = ApiClient();

  Future<AppUser> getProfile() async {
    final res = await _client.get(ApiConfig.profile);
    return AppUser.fromJson(Map<String, dynamic>.from(res));
  }

  Future<AppUser> updateProfile(Map<String, dynamic> updates) async {
    final res = await _client.put(ApiConfig.profile, body: updates);
    return AppUser.fromJson(Map<String, dynamic>.from(res['user']));
  }

  Future<Map<String, dynamic>> searchDonors({
    String? bloodGroup,
    String? area,
    String? city,
    int page = 1,
    int itemsPerPage = 10,
  }) async {
    final res = await _client.get(ApiConfig.donors, query: {
      if (bloodGroup != null && bloodGroup.isNotEmpty) 'blood_group': bloodGroup,
      if (area != null && area.isNotEmpty) 'area': area,
      if (city != null && city.isNotEmpty) 'city': city,
      'page': page,
      'items_per_page': itemsPerPage,
    });
    final map = Map<String, dynamic>.from(res);
    final donors = (map['data'] as List)
        .map((e) => AppUser.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return {
      'donors': donors,
      'pagination': map['pagination'],
    };
  }
}
