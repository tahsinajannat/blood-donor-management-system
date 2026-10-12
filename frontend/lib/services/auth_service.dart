import '../config/api_config.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _client = ApiClient();

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String bloodGroup,
    required String password,
    String? area,
    String? road,
    String? city,
    String? dateOfBirth,
  }) async {
    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'blood_group': bloodGroup,
      'password': password,
      if (area != null && area.isNotEmpty) 'area': area,
      if (road != null && road.isNotEmpty) 'road': road,
      if (city != null && city.isNotEmpty) 'city': city,
      if (dateOfBirth != null && dateOfBirth.isNotEmpty)
        'date_of_birth': dateOfBirth,
    };
    final res =
        await _client.post(ApiConfig.register, body: body, auth: false);
    return Map<String, dynamic>.from(res);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      ApiConfig.login,
      body: {'email': email, 'password': password},
      auth: false,
    );
    return Map<String, dynamic>.from(res);
  }
}
