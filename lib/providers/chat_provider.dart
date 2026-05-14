import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/mock_api_service.dart';

// chatProvider — holds the conversation. We use a `StateNotifier<ChatState>`
// instead of a `FutureProvider` because messages are *appended* over time
// rather than fetched once; the loading state coexists with prior messages
// so the UI can show a typing indicator beneath them.
//
// TODO(llm-agent): replace MockApiService.sendChatMessage with a streaming
//   call to a real LLM. The provider already exposes `isLoading`, so a
//   streaming token-by-token implementation just needs to append-as-it-goes.

class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  const ChatState({required this.messages, this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) =>
      ChatState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
      );
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(ChatState(messages: _welcome()));

  static List<ChatMessage> _welcome() => [
    ChatMessage(
      id: 'welcome',
      content:
          'Hi! I\'m your Fintech AI Assistant. Ask me anything about your loan, balance, or payments.',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
    ),
  ];

  Future<void> send(String content) async {
    if (content.trim().isEmpty || state.isLoading) return;

    final userMsg = ChatMessage(
      id: 'u_${DateTime.now().millisecondsSinceEpoch}',
      content: content.trim(),
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      final reply = await MockApiService().sendChatMessage(content);
      state = state.copyWith(
        messages: [...state.messages, reply],
        isLoading: false,
      );
    } catch (_) {
      final errorMsg = ChatMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Sorry, something went wrong. Please try again.',
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
      );
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(),
);

// Derived providers so widgets only rebuild on the slice they care about.
final chatMessagesProvider = Provider<List<ChatMessage>>(
  (ref) => ref.watch(chatProvider).messages,
);

final chatLoadingProvider = Provider<bool>(
  (ref) => ref.watch(chatProvider).isLoading,
);
