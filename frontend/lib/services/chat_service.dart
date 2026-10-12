import '../config/api_config.dart';
import '../models/chat.dart';
import 'api_client.dart';

class ChatService {
  final ApiClient _client = ApiClient();

  Future<List<ConversationItem>> getConversations() async {
    final res = await _client.get(ApiConfig.conversations);
    final list = (res['conversations'] as List)
        .map((e) => ConversationItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  Future<Map<String, dynamic>> createOrGetConversation(int otherUserId) async {
    final res = await _client
        .post(ApiConfig.conversations, body: {'user_id': otherUserId});
    return Map<String, dynamic>.from(res['conversation']);
  }

  Future<List<ChatMessage>> getMessages(int conversationId,
      {int page = 1, int itemsPerPage = 30}) async {
    final res = await _client.get(
      ApiConfig.messages(conversationId),
      query: {'page': page, 'items_per_page': itemsPerPage},
    );
    final list = (res['messages'] as List)
        .map((e) => ChatMessage.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  Future<ChatMessage> sendMessage(int conversationId, String message) async {
    final res = await _client.post(ApiConfig.messages(conversationId),
        body: {'message': message});
    return ChatMessage.fromJson(Map<String, dynamic>.from(res));
  }
}
