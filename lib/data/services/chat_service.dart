import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';

class ChatService {
  //https://huggingface.co/settings/tokens
  static String get _apiToken => dotenv.env['HF_API_TOKEN'] ?? '';

  // List of models to try in order (Fallback mechanism)
  static const List<String> _models = [
    'meta-llama/Llama-3.2-3B-Instruct', // Primary: Fast, reliable
    'microsoft/Phi-3.5-mini-instruct', // Backup 1: Very fast
    'HuggingFaceH4/zephyr-7b-beta', // Backup 2: Good quality
    'google/gemma-2-9b-it', // Backup 3: High quality
  ];

  static const String _modelUrl =
      'https://router.huggingface.co/v1/chat/completions';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return "Error: No internet connection.";
    }

    String lastError = "Unknown Error";

    // Try each model in order
    for (final modelId in _models) {
      try {
        debugPrint(
          "Attempting to send request to $_modelUrl using model: $modelId",
        );

        final response = await http.post(
          Uri.parse(_modelUrl),
          headers: {
            'Authorization': 'Bearer $_apiToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': modelId,
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

        // If we get here, this model failed (non-200 or bad format).
        // Capture error and continue to next model.
        if (response.statusCode == 503) {
          lastError = "Model $modelId is loading (503)";
        } else if (response.statusCode == 401) {
          // If unauthorized, valid for all models likely, but let's try others just in case
          // usually token issue though.
          lastError = "Unauthorized (401)";
          break; // Don't retry if token is bad
        } else {
          lastError =
              "Error ($modelId): ${response.statusCode} - ${response.body}";
        }

        debugPrint("Model $modelId failed: $lastError. Trying next...");
      } catch (e) {
        debugPrint('Chat Service Error ($modelId): $e');
        lastError = "Exception: $e";
      }
    }

    // If we exhausted all models
    return "AI Service Unavailable. Last error: $lastError";
  }
}
