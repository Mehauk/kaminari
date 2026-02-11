import 'package:flutter/material.dart';
import 'package:kaminari/src/ui/pages/screens/home_screen.dart';
import 'package:kaminari/src/ui/widgets/bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeScreen(),
      bottomNavigationBar: LightningBottomNav([
        LightningBottomNavItem(Icons.home, "Home", active: true),
        LightningBottomNavItem(Icons.explore_outlined, "Discover"),
        LightningBottomNavItem(Icons.bookmark_border_rounded, "Favorites"),
        LightningBottomNavItem(Icons.history, "History"),
      ]),
    );
  }
}
