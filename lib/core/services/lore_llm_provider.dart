import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'ai_service.dart';
import '../models/story.dart';

/// Custom LLM provider that bridges the Flutter AI Toolkit's [LlmProvider]
/// interface with the Lore app's [AIService] for story-driven AI interactions.
class LoreLlmProvider extends ChangeNotifier implements LlmProvider {
  final AIService _aiService;
  final Story _story;
  List<ChatMessage> _history = [];

  LoreLlmProvider(this._aiService, this._story);

  @override
  Iterable<ChatMessage> get history => List.unmodifiable(_history);

  @override
  set history(Iterable<ChatMessage> value) {
    _history = value.toList();
    notifyListeners();
  }

  @override
  Stream<String> generateStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    try {
      final response = await _aiService.processStorySegment(
        text: prompt,
        storyId: _story.id,
        narrationStyle: _story.narrationStyle,
        worldNotes: _story.worldNotes,
        userPersona: 'The Protagonist',
        characterIds: _story.characterIds,
      );
      yield response;
    } catch (e) {
      yield "Error: $e";
    }
  }

  @override
  Stream<String> sendMessageStream(
    String prompt, {
    Iterable<Attachment> attachments = const [],
  }) async* {
    // Add user message to history
    _history.add(ChatMessage.user(prompt, attachments));
    notifyListeners();

    // Create LLM message placeholder
    final llmMessage = ChatMessage.llm();
    _history.add(llmMessage);

    try {
      final responseStream = generateStream(prompt, attachments: attachments);

      await for (final chunk in responseStream) {
        llmMessage.append(chunk);
        notifyListeners();
        yield chunk;
      }
    } catch (e) {
      llmMessage.append("Error: $e");
      notifyListeners();
      yield "Error: $e";
    }
  }
}
