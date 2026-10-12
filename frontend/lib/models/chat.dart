class ConversationItem {
  final int id;
  final int otherUserId;
  final String otherUserFirstName;
  final String otherUserLastName;
  final String? lastMessage;
  final String? updatedAt;

  ConversationItem({
    required this.id,
    required this.otherUserId,
    required this.otherUserFirstName,
    required this.otherUserLastName,
    this.lastMessage,
    this.updatedAt,
  });

  String get otherUserName =>
      "$otherUserFirstName $otherUserLastName".trim();

  factory ConversationItem.fromJson(Map<String, dynamic> json) {
    return ConversationItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      otherUserId: json['other_user_id'] is int
          ? json['other_user_id']
          : int.parse(json['other_user_id'].toString()),
      otherUserFirstName: json['other_user_first_name'] ?? '',
      otherUserLastName: json['other_user_last_name'] ?? '',
      lastMessage: json['last_message'],
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String? senderFirstName;
  final String? senderLastName;
  final String message;
  final String? createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderFirstName,
    this.senderLastName,
    required this.message,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      conversationId: json['conversation_id'] is int
          ? json['conversation_id']
          : int.parse(json['conversation_id'].toString()),
      senderId: json['sender_id'] is int
          ? json['sender_id']
          : int.parse(json['sender_id'].toString()),
      senderFirstName: json['sender_first_name'],
      senderLastName: json['sender_last_name'],
      message: json['message'] ?? '',
      createdAt: json['created_at']?.toString(),
    );
  }
}
