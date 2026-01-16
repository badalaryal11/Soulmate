import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';

class AiService {
  // TODO: Replace with your actual Gemini API Key from Google AI Studio
  // Get one here: https://aistudio.google.com/app/apikey
  static const String _apiKey = 'YOUR_API_KEY_HERE';

  late final GenerativeModel _model;
  late final ChatSession _chat;

  AiService({String? userName, String? matchName}) {
    _model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: _apiKey,
      generationConfig: GenerationConfig(maxOutputTokens: 100),
    );

    // Initial persona setup
    _chat = _model.startChat(
      history: [
        Content.text(
          'You are ${matchName ?? "a friend"}, a potential soulmate on a dating app called Soulmate. '
          'You are talking to ${userName ?? "someone"}. '
          'Be flirty, fun, engaging, and brief in your responses. '
          'Do not use hashtags. Keep messages under 2-3 sentences.',
        ),
        Content.model([
          TextPart(
            'Hey there! 😉 I\'m so glad we matched. What are you up to?',
          ),
        ]),
      ],
    );
  }

  Future<String> sendMessage(String message) async {
    if (_apiKey == 'YOUR_API_KEY_HERE') {
      // Fallback for demo if no key is provided
      await Future.delayed(const Duration(seconds: 1));
      return "I'm a real AI waiting to happen! Add a Gemini API Key to see me shine. ✨\n(But yes, I think '$message' is interesting!)";
    }

    try {
      final response = await _chat.sendMessage(Content.text(message));
      return response.text ?? "I'm lost for words... 😍";
    } catch (e) {
      debugPrint('AI Error: $e');
      return "Oops, my connection is playing hard to get. Try again? 🥺";
    }
  }
}
