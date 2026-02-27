import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import '../../core/constants/stickers.dart';

class ChatService {
  // Shared HTTP client for connection reuse
  static final http.Client _client = http.Client();

  // API tokens loaded from .env
  static String get _hfApiToken => dotenv.env['HF_API_TOKEN'] ?? '';
  static String get _groqApiToken => dotenv.env['GROQ_API_KEY'] ?? '';
  static String get _geminiApiToken => dotenv.env['GEMINI_API_KEY'] ?? '';

  // Provider configurations: each entry has a base URL, auth token, and models
  static List<Map<String, dynamic>> get _providers => [
    {
      'name': 'HuggingFace',
      'url': 'https://router.huggingface.co/v1/chat/completions',
      'token': _hfApiToken,
      'models': [
        'meta-llama/Llama-3.3-70B-Instruct',
        'meta-llama/Llama-3.1-8B-Instruct',
      ],
    },
    {
      'name': 'Groq',
      'url': 'https://api.groq.com/openai/v1/chat/completions',
      'token': _groqApiToken,
      'models': [
        'llama-3.3-70b-versatile',
        'llama-3.1-8b-instant',
        'gemma2-9b-it',
      ],
    },
  ];

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return "Error: No internet connection.";
    }

    final StringBuffer errorLog = StringBuffer();

    // Try Gemini First (Very generous free tier, 15 RPM)
    if (_geminiApiToken.isNotEmpty) {
      debugPrint("[Gemini] Attempting model: gemini-2.5-flash");
      try {
        final model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: _geminiApiToken,
        );

        // Convert format
        final baseSystemPrompt =
            messages.firstWhere(
              (m) => m['role'] == 'system',
              orElse: () => {'content': ''},
            )['content'] ??
            '';

        // Append sticker mapping instructions to the system prompt
        final systemPrompt =
            "$baseSystemPrompt\n\n${Stickers.getSystemPromptMapping()}";

        List<Content> geminiHistory = [];
        for (var msg in messages) {
          if (msg['role'] == 'system') continue;

          final role = msg['role'] == 'assistant' ? 'model' : 'user';
          geminiHistory.add(Content(role, [TextPart(msg['content'] ?? '')]));
        }

        // Add system instructions explicitly if supported, or just inject at start
        // To be safe and compatible with older gemini implementations, we'll prepend system prompt to the user's first message
        // if geminiHistory is not empty and system prompt exists
        if (systemPrompt.isNotEmpty && geminiHistory.isNotEmpty) {
          final firstUserMsg = geminiHistory.firstWhere(
            (c) => c.role == 'user',
            orElse: () => geminiHistory.first,
          );
          if (firstUserMsg.parts.isNotEmpty) {
            final oldText = (firstUserMsg.parts.first as TextPart).text;
            firstUserMsg.parts[0] = TextPart(
              "System Instruction: $systemPrompt\n\nUser: $oldText",
            );
          } else {
            geminiHistory.insert(
              0,
              Content('user', [TextPart("System Instruction: $systemPrompt")]),
            );
          }
        }

        // Separate the last message as the actual prompt, and rest as history for startChat
        if (geminiHistory.isNotEmpty) {
          final currentMsg = geminiHistory.removeLast();
          final chat = model.startChat(history: geminiHistory);

          final response = await chat
              .sendMessage(currentMsg)
              .timeout(const Duration(seconds: 30));
          if (response.text != null && response.text!.isNotEmpty) {
            return response.text!.trim();
          }
        }
      } catch (e) {
        debugPrint("[Gemini] Chat Service Error: $e");
        errorLog.writeln("Gemini: Exception($e)");
      }
    } else {
      debugPrint("Skipping Gemini: No API token configured.");
      errorLog.writeln("Gemini: Skipped (no API token)");
    }

    // Try other providers and models in order if Gemini fails or is not configured
    for (final provider in _providers) {
      final String providerName = provider['name'];
      final String url = provider['url'];
      final String token = provider['token'];
      final List<String> models = List<String>.from(provider['models']);

      // Skip provider if no token is configured
      if (token.isEmpty) {
        debugPrint("Skipping $providerName: No API token configured.");
        errorLog.writeln("$providerName: Skipped (no API token)");
        continue;
      }

      for (final modelId in models) {
        try {
          debugPrint("[$providerName] Attempting model: $modelId");

          final response = await _client
              .post(
                Uri.parse(url),
                headers: {
                  'Authorization': 'Bearer $token',
                  'Content-Type': 'application/json',
                },
                body: jsonEncode({
                  'model': modelId,
                  'messages': messages,
                  'max_tokens': 500,
                  'temperature': 0.7,
                  'stream': false,
                }),
              )
              .timeout(const Duration(seconds: 30));

          debugPrint(
            "[$providerName] Response Status ($modelId): ${response.statusCode}",
          );

          if (response.statusCode == 200) {
            final Map<String, dynamic> result = jsonDecode(response.body);
            if (result['choices'] != null &&
                result['choices'].isNotEmpty &&
                result['choices'][0]['message'] != null) {
              return result['choices'][0]['message']['content']
                  .toString()
                  .trim();
            }
          }

          // Error handling
          String errorMsg;
          if (response.statusCode == 503) {
            errorMsg = "503 Loading";
          } else if (response.statusCode == 401) {
            errorMsg = "401 Unauthorized (Check API Token)";
            errorLog.writeln("$providerName/$modelId: $errorMsg");
            break; // Skip remaining models for this provider
          } else {
            try {
              final errorJson = jsonDecode(response.body);
              errorMsg =
                  "${response.statusCode} - ${errorJson['error']?['message'] ?? errorJson['error'] ?? response.body}";
            } catch (_) {
              errorMsg = "${response.statusCode} - ${response.body}";
            }
          }

          errorLog.writeln("$providerName/$modelId: $errorMsg");
          debugPrint(
            "[$providerName] Model $modelId failed: $errorMsg. Trying next...",
          );
        } catch (e) {
          debugPrint('[$providerName] Chat Service Error ($modelId): $e');
          errorLog.writeln("$providerName/$modelId: Exception($e)");
        }
      }
    }

    // If we exhausted all providers and models
    return "AI Service Unavailable. Errors:\n$errorLog";
  }
}
