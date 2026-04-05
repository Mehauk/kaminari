import 'package:flutter/material.dart';

import 'src/config/theme.dart';
import 'src/screens/home_screen.dart';

class KaminariApp extends StatelessWidget {
  const KaminariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kaminari Browser',
      theme: KaminariTheme.theme,
      home: const HomeScreen(),
    );
  }
}
