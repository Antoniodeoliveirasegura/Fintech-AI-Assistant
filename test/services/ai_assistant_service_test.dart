// Tests for the AI assistant's keyword routing.
//
// We test the *behavior* (does asking about my balance return a balance
// answer?) not the implementation. When AiAssistantService is later swapped
// for a real LLM, you'll want these same tests against the new backend —
// either by mocking the LLM or by tagging them as integration tests.

import 'package:flutter_test/flutter_test.dart';
import 'package:fintech_ai_assistant/models/chat_message.dart';
import 'package:fintech_ai_assistant/services/mock_api_service.dart';

void main() {
  final api = MockApiService();

  Future<String> ask(String question) async {
    final response = await api.sendChatMessage(question);
    return response.content;
  }

  group('AiAssistantService', () {
    test('always replies with role = assistant', () async {
      final msg = await api.sendChatMessage('hello');
      expect(msg.role, MessageRole.assistant);
      expect(msg.content, isNotEmpty);
    });

    test('balance question returns a balance answer', () async {
      final reply = await ask('What is my balance?');
      expect(reply.toLowerCase(), contains('balance'));
      expect(reply, contains('\$'));
    });

    test('next-payment question mentions next payment', () async {
      final reply = await ask('When is my next payment?');
      expect(reply.toLowerCase(), contains('next payment'));
    });

    test('late-payments question addresses late payments', () async {
      final reply = await ask('Do I have any late payments?');
      expect(reply.toLowerCase(), contains('late'));
    });

    test('"how much have I paid" returns the paid amount', () async {
      final reply = await ask('How much have I paid so far?');
      expect(reply.toLowerCase(), contains('paid'));
      expect(reply, contains('\$'));
    });

    test('percentage question returns progress percent', () async {
      final reply = await ask('What percentage of my loan is paid?');
      expect(reply, contains('%'));
    });

    test('"what should I do next" returns actionable advice', () async {
      final reply = await ask('What should I do next?');
      expect(reply, isNotEmpty);
      expect(
        reply.length,
        greaterThan(40),
        reason: 'advice replies should be substantive',
      );
    });

    test('summary question lists key fields', () async {
      final reply = await ask('Summarize my loan');
      expect(reply.toLowerCase(), contains('balance'));
      expect(reply.toLowerCase(), contains('interest'));
    });

    test('unrecognized question gets the fallback message', () async {
      final reply = await ask('purple monkey dishwasher');
      expect(reply.toLowerCase(), contains('not sure'));
    });
  });
}
