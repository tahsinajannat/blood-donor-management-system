import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common_widgets.dart';
import 'chat_thread_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: Consumer<ChatProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.error != null && provider.conversations.isEmpty) {
            return ErrorRetry(
              message: provider.error!,
              onRetry: () => provider.loadConversations(),
            );
          }
          if (provider.conversations.isEmpty) {
            return const EmptyState(
              icon: Icons.forum_outlined,
              title: 'No conversations yet',
              subtitle: 'Message a donor or a requester to start chatting.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadConversations(),
            color: AppColors.primary,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 78, color: AppColors.border),
              itemBuilder: (context, i) =>
                  _ConversationTile(conversation: provider.conversations[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationItem conversation;
  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final initials = conversation.otherUserName.isNotEmpty
        ? conversation.otherUserName
            .trim()
            .split(RegExp(r'\s+'))
            .map((e) => e.isNotEmpty ? e[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';

    String timeStr = '';
    if (conversation.updatedAt != null) {
      try {
        timeStr = DateFormat('MMM d').format(DateTime.parse(conversation.updatedAt!));
      } catch (_) {}
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      leading: CircleAvatar(
        radius: 26,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        child: Text(initials,
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
      ),
      title: Text(conversation.otherUserName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(
        conversation.lastMessage?.isNotEmpty == true
            ? conversation.lastMessage!
            : 'Say hello 👋',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: Text(timeStr,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatThreadScreen(
            conversationId: conversation.id,
            otherUserName: conversation.otherUserName,
          ),
        ),
      ),
    );
  }
}
