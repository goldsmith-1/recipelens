import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const RecipeLensApp());

class RecipeLensApp extends StatelessWidget {
  const RecipeLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RecipeLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F4D3A), tertiary: const Color(0xFFE4572E)),
        scaffoldBackgroundColor: const Color(0xFFF7F8F4),
        cardTheme: CardTheme(elevation: 0, color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0x1F000000)))),
      ),
      home: const HomeScreen(),
    );
  }
}
