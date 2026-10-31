import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const AutoCaptionApp());
}

class AutoCaptionApp extends StatelessWidget {
  const AutoCaptionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Caption',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
