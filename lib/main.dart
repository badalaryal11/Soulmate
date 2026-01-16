import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SoulmateApp());
}

class SoulmateApp extends StatelessWidget {
  const SoulmateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soulmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFE3C72)), // Tinder-ish pink
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Soulmate Initialization...'),
        ),
      ),
    );
  }
}
