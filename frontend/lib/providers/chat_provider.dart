import 'package:flutter/material.dart';

import '../models/chat.dart';
import '../services/chat_service.dart';

class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();

  List<ConversationItem> conversations = [];
  bool isLoading = false;
  String? error;

  Future<void> loadConversations() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      conversations = await _service.getConversations();
    } catch (e) {
      error = 'Failed to load conversations.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<int> openConversationWith(int otherUserId) async {
    final conv = await _service.createOrGetConversation(otherUserId);
    return conv['id'] is int ? conv['id'] : int.parse(conv['id'].toString());
  }
}

class MessageThreadProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  final int conversationId;

  MessageThreadProvider(this.conversationId);

  List<ChatMessage> messages = [];
  bool isLoading = false;
  bool isSending = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      messages = await _service.getMessages(conversationId, itemsPerPage: 100);
    } catch (e) {
      error = 'Failed to load messages.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;
    isSending = true;
    notifyListeners();
    try {
      final msg = await _service.sendMessage(conversationId, text.trim());
      messages.add(msg);
    } catch (e) {
      error = 'Failed to send message.';
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
