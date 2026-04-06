import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';

class LightningBottomNav extends StatelessWidget {
  const LightningBottomNav(this.items, {super.key});

  final List<LightningBottomNavItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(KaminariTheme.borderRadius),
          topRight: Radius.circular(KaminariTheme.borderRadius),
        ),
        child: BgFilter(
          bgColor: KaminariTheme.surfaceVariant.withAlpha(180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(KaminariTheme.borderRadius),
                topRight: Radius.circular(KaminariTheme.borderRadius),
              ),
              border: BoxBorder.fromLTRB(
                top: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(30)),
              ),
            ),
            child: Padding(
              padding: .symmetric(horizontal: 20),
              child: Row(children: items),
            ),
          ),
        ),
      ),
    );
  }
}

class LightningBottomNavItem extends StatelessWidget {
  const LightningBottomNavItem(
    this.icon,
    this.label, {
    super.key,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
                Icon(icon, color: active ? KaminariTheme.textTitle : null),
                Align(
                  alignment: AlignmentGeometry.xy(0, 1),
                  child: CustomText(
                    label,
                    .labelMedium,
                    fontSizeOverride: 14,
                    colorOverride: active ? KaminariTheme.textTitle : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
