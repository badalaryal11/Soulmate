import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatService {
  //https://huggingface.co/settings/tokens
  static String get _apiToken => dotenv.env['HF_API_TOKEN'] ?? '';

  // Using Llama 3 (8B Instruct) via Hugging Face Router (OpenAI Compatible)
  static const String _modelUrl =
      'https://router.huggingface.co/v1/chat/completions';
  static const String _modelId = 'meta-llama/Meta-Llama-3-8B-Instruct';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    // Check removed as valid token is present

    try {
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _modelId,
          'messages': messages,
          'max_tokens': 250,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['choices'] != null &&
            result['choices'].isNotEmpty &&
            result['choices'][0]['message'] != null) {
          return result['choices'][0]['message']['content'].toString().trim();
        }
        return "I'm not sure what to say.";
      } else if (response.statusCode == 503) {
        return "The model is currently loading... please try again in a few seconds.";
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return "Error: Unable to connect to AI (${response.statusCode})";
      }
    } catch (e) {
      debugPrint('Chat Service Error: $e');
      return "Error: $e";
    }
  }
}
