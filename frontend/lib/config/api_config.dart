/// Central place to configure the backend base URL.
///
/// - Android emulator -> host machine: use http://10.0.2.2:8000
/// - iOS simulator -> host machine: use http://127.0.0.1:8000
/// - Physical device: use your computer's LAN IP, e.g. http://192.168.1.10:8000
/// - Deployed backend: use the public URL, e.g. https://api.yourdomain.com
class ApiConfig {
  ApiConfig._();

  /// Change this single value to point the whole app at your backend.
  static const String baseUrl = "http://127.0.0.1:8000";

  // ---- Users ----
  static const String register = "/api/users/register";
  static const String login = "/api/users/login";
  static const String profile = "/api/users/profile";
  static const String donors = "/api/users/donors";

  // ---- Blood requests ----
  static const String bloodRequests = "/blood-requests/";
  static const String myBloodRequests = "/blood-requests/my";
  static String bloodRequestById(int id) => "/blood-requests/$id";

  // ---- Conversations & messages ----
  static const String conversations = "/conversations/";
  static String conversationById(int id) => "/conversations/$id";
  static String messages(int conversationId) =>
      "/conversations/$conversationId/messages";

  static const int connectTimeoutSeconds = 20;
}
