import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/home/home_nav_cubit.dart';
import 'package:kaminari/src/ui/pages/home/screens/discover_screen.dart';
import 'package:kaminari/src/ui/pages/home/screens/history_screen.dart';
import 'package:kaminari/src/ui/pages/home/screens/home_screen.dart';
import 'package:kaminari/src/ui/widgets/bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeNavCubit(),
      child: BlocBuilder<HomeNavCubit, HomeNavTab>(
        builder: (context, state) {
          Widget body;
          switch (state) {
            case HomeNavTab.home:
              body = const HomeScreen();
              break;
            case HomeNavTab.discover:
              body = const DiscoverScreen();
              break;

            case HomeNavTab.history:
              body = const HistoryScreen();
              break;
          }

          return Scaffold(
            body: body,
            bottomNavigationBar: LightningBottomNav(
              HomeNavTab.values.map((v) => LightningBottomNavItem(v)).toList(),
            ),
          );
        },
      ),
    );
  }
}
