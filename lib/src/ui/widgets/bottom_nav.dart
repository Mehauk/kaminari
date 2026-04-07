import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/home/home_nav_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/utils/string_extensions.dart';

extension on HomeNavTab {
  IconData get icon => switch (this) {
    HomeNavTab.home => Icons.home_filled,
    HomeNavTab.discover => Icons.explore_outlined,
    HomeNavTab.history => Icons.history,
  };
}

class LightningBottomNav extends StatelessWidget {
  const LightningBottomNav(this.items, {super.key, required this.activeIndex});

  final List<LightningBottomNavItem> items;
  final HomeNavTab activeIndex;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(KaminariTheme.borderRadius),
            topRight: Radius.circular(KaminariTheme.borderRadius),
          ),
          child: BgFilter(
            bgColor: KaminariTheme.surfaceVariant.withAlpha(200),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(KaminariTheme.borderRadius),
                  topRight: Radius.circular(KaminariTheme.borderRadius),
                ),
                border: BoxBorder.fromLTRB(
                  top: BorderSide(
                    color: KaminariTheme.surfaceTint.withAlpha(45),
                  ),
                ),
              ),
              child: Padding(
                padding: .symmetric(horizontal: 20),
                child: Row(children: items),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LightningBottomNavItem extends StatelessWidget {
  const LightningBottomNavItem(this.tab, {super.key});

  final HomeNavTab tab;

  @override
  Widget build(BuildContext context) {
    final bool active = context.read<HomeNavCubit>().state == tab;
    return Expanded(
      child: InkWell(
        onTap: () => context.read<HomeNavCubit>().selectTab(tab),
        child: Padding(
          padding: .fromLTRB(4, 18, 4, 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(KaminariTheme.borderRadius),
              color: active ? KaminariTheme.textTitle.withAlpha(50) : null,
            ),
            child: Padding(
              padding: .all(2),
              child: Stack(
                alignment: AlignmentGeometry.topCenter,
                children: [
                  Icon(
                    tab.icon,
                    color: active ? KaminariTheme.textTitle : null,
                  ),
                  Align(
                    alignment: AlignmentGeometry.xy(0, 1),
                    child: CustomText(
                      tab.name.capitalize,
                      .labelMedium,
                      fontSize: 14,
                      colorOverride: active ? KaminariTheme.textTitle : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
