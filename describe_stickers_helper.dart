// ignore_for_file: avoid_print
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

void main() async {
  final envFile = File('.env');
  String? apiKey;
  if (await envFile.exists()) {
    final lines = await envFile.readAsLines();
    for (final line in lines) {
      if (line.startsWith('GEMINI_API_KEY=')) {
        apiKey = line.substring('GEMINI_API_KEY='.length).trim();
        if (apiKey.startsWith('"') && apiKey.endsWith('"')) {
          apiKey = apiKey.substring(1, apiKey.length - 1);
        }
        break;
      }
    }
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('No GEMINI_API_KEY found in .env');
    exit(1);
  }

  final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: apiKey);

  final stickerUrls = [
    'https://i.waifu.pics/J2EF9YT.gif',
    'https://i.waifu.pics/EYcAlMR.gif',
    'https://i.waifu.pics/8ixFGjY.gif',
    'https://i.waifu.pics/M4kkraV.gif',
    'https://i.waifu.pics/V4ztx1j.gif',
    'https://i.waifu.pics/wSJHUmH.gif',
  ];

  print('Describing ${stickerUrls.length} stickers...');

  for (int i = 0; i < stickerUrls.length; i++) {
    final url = stickerUrls[i];
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final imageBytes = response.bodyBytes;
        final prompt = TextPart(
          "Describe exactly what this sticker shows in one short, descriptive phrase. This will be used so an AI chatbot knows what sticker the user sent. Focus on the character (e.g. cat, dog, character), emotion, and action.",
        );
        final imageParts = [DataPart('image/gif', imageBytes)];

        final aiResponse = await model.generateContent([
          Content.multi([prompt, ...imageParts]),
        ]);

        print('--- Sticker $i ---');
        print('URL: $url');
        print('Desc: ${aiResponse.text?.trim()}');
        print('');
      } else {
        print('Failed to download sticker $i: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting description for sticker $i: $e');
    }
    await Future.delayed(const Duration(seconds: 5));
  }
}
