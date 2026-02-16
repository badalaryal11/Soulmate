import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main() async {
  // Load .env manually since we are in a script
  final envFile = File('.env');
  String? token;
  if (await envFile.exists()) {
    final lines = await envFile.readAsLines();
    for (var line in lines) {
      if (line.startsWith('HF_API_TOKEN=')) {
        token = line.split('=')[1].trim();
      }
    }
  }

  if (token == null || token.isEmpty) {
    stderr.writeln('Error: HF_API_TOKEN not found in .env');
    return; // Cannot test without token
  }

  stdout.writeln('Using Token: ${token.substring(0, 4)}...');

  const modelId = 'microsoft/Phi-3.5-mini-instruct';
  const modelUrl = 'https://router.huggingface.co/v1/chat/completions';

  stdout.writeln('Testing Model: $modelId');
  stdout.writeln('URL: $modelUrl');

  final messages = [
    {'role': 'system', 'content': 'You are a helpful assistant.'},
    {'role': 'user', 'content': 'Hello!'},
  ];

  try {
    final client = http.Client();
    final response = await client
        .post(
          Uri.parse(modelUrl),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': modelId,
            'messages': messages,
            'max_tokens': 100,
            'temperature': 0.7,
            'stream': false,
          }),
        )
        .timeout(const Duration(seconds: 10));

    stdout.writeln('Response Status: ${response.statusCode}');
    stdout.writeln('Response Body: ${response.body}');
  } catch (e) {
    stderr.writeln('Error: $e');
  }
}
