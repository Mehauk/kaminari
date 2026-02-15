import 'package:flutter/material.dart';
import 'package:kaminari/src/ui/pages/book_details/book_details_page.dart';
import 'package:kaminari/src/ui/pages/home/home_page.dart';

import 'src/config/theme.dart';

class KaminariApp extends StatelessWidget {
  const KaminariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kaminari Browser',
      theme: KaminariTheme.theme,
      initialRoute: '/',
      routes: {
        '/': (_) => const HomePage(),
        '/book-details': (_) => const BookDetailsPage(),
      },
    );
  }
}
