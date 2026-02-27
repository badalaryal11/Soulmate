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

  final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);

  final stickerUrls = [
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMmVtdWd5YmlyZHdrcTBpeWVib2k2cDB6OTJqdDJnZndhY2hheDcyMSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/11S5TjEEDEq8t126uYn/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExbDVtc2Vqa3RocWtlaGczMWE0NmxlaXRnODJ4cjdwd2YxcTJlaDUzMyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/26FLdmIp6wJr91JAI/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcGxtZmxhNjZpdHJmMGExdXpnd3J5NXB2NzR6ZGNsbnAxdXR1dWF6bCZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/MDJ9IbxxvDUQM/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExenF2emtxMzFxdXV6MzhpdGVldXZvcGV0MWtiam9uYnJwNXgyYXB6eSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/l4pTfx2qLszoacZRS/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdXQyOHE0bHExdGpnZW94YnRvdGR0NGQ3am9nZG13amIzejdmaGQwZiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/3o7TKoWXm3okO1kgHC/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExcm5nZHB0ZXFtaDFhMmhtdnhrNXVxc2NueHpvamZ1eDJucDNsOTNnbyZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/7kn27lnYSAE9O/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmNxdmQ3dDhybjFmOHp3anl6aDdzZWYxaTN1Mm13ZGg5NnB4eXZpdSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/R6gvnAxj2ISzJdbA63/giphy.gif',
    'https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExYzlqMDhzMjdzeWR5dzc0ejhmcTVyNm5yeWFzbnF3enlxMWg0a24weiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9cw/KztT2c4u8mYYUiMKdJ/giphy.gif',
    'https://media.tenor.com/WyYsbi0fei8AAAAC/love-mochi.gif',
    'https://media.tenor.com/_reUPa03zXsAAAAC/love-shine-on.gif',
    'https://media.tenor.com/kqHNV9zBRM8AAAAC/dog-happy-dog.gif',
    'https://media.tenor.com/d9PoZm99CTgAAAAC/sadcat-crying-cat.gif',
    'https://media.tenor.com/Ydqpw1Nn2JkAAAAC/quby-sad.gif',
    'https://media.tenor.com/T7fRyJXgmB8AAAAC/cute-cat.gif',
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
  }
}
