import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';

class ChatService {
  //https://huggingface.co/settings/tokens
  static String get _apiToken => dotenv.env['HF_API_TOKEN'] ?? '';

  // Using Qwen 2.5 72B Instruct (Ungated, widely supported on Router)
  static const String _modelId = 'Qwen/Qwen2.5-72B-Instruct';
  static const String _modelUrl =
      'https://router.huggingface.co/v1/chat/completions';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return "Error: No internet connection.";
    }

    try {
      debugPrint("Sending request to $_modelUrl");
      debugPrint("Token available: ${_apiToken.isNotEmpty}");

      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // OpenAI compatible payload
          'model': _modelId,
          'messages': messages,
          'max_tokens': 500,
          'temperature': 0.7,
          'stream': false,
        }),
      );

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        if (result['choices'] != null &&
            result['choices'].isNotEmpty &&
            result['choices'][0]['message'] != null) {
          return result['choices'][0]['message']['content'].toString().trim();
        }
        return "I'm not sure what to say.";
      } else if (response.statusCode == 503) {
        return "The model is warming up... please try again in 10s.";
      } else if (response.statusCode == 401) {
        return "Error: Unauthorized. Check API Token.";
      } else if (response.statusCode == 410) {
        return "Error: Model not available (410).";
      } else {
        return "Error: AI Service Error (${response.statusCode})";
      }
    } catch (e) {
      debugPrint('Chat Service Error: $e');
      return "Error: $e";
    }
  }
}
