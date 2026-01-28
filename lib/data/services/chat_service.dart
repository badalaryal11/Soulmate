import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:connectivity_plus/connectivity_plus.dart';

class ChatService {
  //https://huggingface.co/settings/tokens
  static String get _apiToken => dotenv.env['HF_API_TOKEN'] ?? '';

  // Using Zephyr 7B Beta via standard Inference API (Text Generation)
  static const String _modelId = 'HuggingFaceH4/zephyr-7b-beta';
  static const String _modelUrl =
      'https://api-inference.huggingface.co/models/$_modelId';

  Future<String> sendMessage(List<Map<String, String>> messages) async {
    // Check connectivity
    final connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) {
      return "Error: No internet connection.";
    }

    try {
      // 1. Manually format prompt for Zephyr
      final StringBuffer promptBuffer = StringBuffer();
      for (final msg in messages) {
        final role = msg['role'];
        final content = msg['content'];
        if (role == 'system') {
          promptBuffer.write('<|system|>\n$content</s>\n');
        } else if (role == 'user') {
          promptBuffer.write('<|user|>\n$content</s>\n');
        } else if (role == 'assistant') {
          promptBuffer.write('<|assistant|>\n$content</s>\n');
        }
      }
      promptBuffer.write('<|assistant|>\n'); // Prompt for completion

      final prompt = promptBuffer.toString();

      // 2. Send to raw generation endpoint
      final response = await http.post(
        Uri.parse(_modelUrl),
        headers: {
          'Authorization': 'Bearer $_apiToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': prompt,
          'parameters': {
            'max_new_tokens': 250,
            'temperature': 0.7,
            'top_p': 0.95,
            'return_full_text': false, // Only return the new part
          },
        }),
      );

      if (response.statusCode == 200) {
        // Response is a List: [{"generated_text": "..."}]
        final List<dynamic> result = jsonDecode(response.body);
        if (result.isNotEmpty && result[0]['generated_text'] != null) {
          return result[0]['generated_text'].toString().trim();
        }
        return "I'm not sure what to say.";
      } else if (response.statusCode == 503) {
        return "The model is warming up... please try again in 10s.";
      } else {
        debugPrint('API Error: ${response.statusCode} - ${response.body}');
        return "Error: AI Service Error (${response.statusCode})";
      }
    } catch (e) {
      debugPrint('Chat Service Error: $e');
      return "Error: $e";
    }
  }
}
