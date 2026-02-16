import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';

class ChatService {
  //https://huggingface.co/settings/tokens
  static String get _apiToken => dotenv.env['HF_API_TOKEN'] ?? '';

  static const List<String> _models = [
    'mistralai/Mistral-7B-Instruct-v0.2', // Backup 1: Older v0.2 (often more compatible than v0.3)
    'microsoft/Phi-3-mini-4k-instruct', // Backup 2: Non-3.5 version
    'HuggingFaceH4/zephyr-7b-beta', // Primary: The standard free tier chat model
    'meta-llama/Llama-3.2-1B-Instruct', // Backup 3: Ultimate fallback (Tiny, almost always avail)
  ];

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return "Error: No internet connection.";
    }

    final StringBuffer errorLog = StringBuffer();

    // Try each model in order
    for (final modelId in _models) {
      try {
        final url = Uri.parse(
          'https://router.huggingface.co/models/$modelId/v1/chat/completions',
        );

        debugPrint("Attempting to send request to $url using model: $modelId");

        final response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'messages': messages,
            'max_tokens': 500,
            'temperature': 0.7,
            'stream': false,
          }),
        );

        debugPrint("Response Status ($modelId): ${response.statusCode}");

        if (response.statusCode == 200) {
          final Map<String, dynamic> result = jsonDecode(response.body);
          if (result['choices'] != null &&
              result['choices'].isNotEmpty &&
              result['choices'][0]['message'] != null) {
            return result['choices'][0]['message']['content'].toString().trim();
          }
        }

        // Error handling
        String errorMsg;
        if (response.statusCode == 503) {
          errorMsg = "503 Loading";
        } else if (response.statusCode == 401) {
          errorMsg = "401 Unauthorized (Check API Token)";
          // If token is bad, no point trying other models (likely)
          // But sometimes specific models typically fail with auth issues while others don't if they are public?
          // The router usually enforces token for all.
          errorLog.writeln("$modelId: $errorMsg");
          break;
        } else {
          try {
            final errorJson = jsonDecode(response.body);
            errorMsg =
                "${response.statusCode} - ${errorJson['error']?['message'] ?? response.body}";
          } catch (_) {
            errorMsg = "${response.statusCode} - ${response.body}";
          }
        }

        errorLog.writeln("$modelId: $errorMsg");
        debugPrint("Model $modelId failed: $errorMsg. Trying next...");
      } catch (e) {
        debugPrint('Chat Service Error ($modelId): $e');
        errorLog.writeln("$modelId: Exception($e)");
      }
    }

    // If we exhausted all models
    return "AI Service Unavailable. Errors:\n$errorLog";
  }
}
