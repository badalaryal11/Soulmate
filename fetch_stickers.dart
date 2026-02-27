// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final endpoints = ['pat', 'hug', 'kiss', 'happy', 'dance', 'smile'];

  for (final endpoint in endpoints) {
    final url = 'https://api.waifu.pics/sfw/$endpoint';
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final gifUrl = data['url'];
        print("    {");
        print("      'url': '$gifUrl',");
        print("      'desc': 'anime character doing $endpoint',");
        print("    },");
      }
    } catch (e) {
      print('Error on $endpoint: $e');
    }
  }
}
