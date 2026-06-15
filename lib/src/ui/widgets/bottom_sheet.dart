import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';

class LightningBottomSheet extends StatelessWidget {
  const LightningBottomSheet({super.key, required this.children});

  final List<(IconData icon, String, void Function())> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: .circular(KaminariTheme.altBorderRadius),
      child: BgFilter(
        child: Padding(
          padding: const .all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 8),
              ...children.map(
                (e) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: KaminariTheme.surfaceTint.withAlpha(120),
                    borderRadius: .circular(KaminariTheme.altBorderRadius),
                  ),
                  child: ListTile(
                    leading: Icon(e.$1),
                    title: CustomText(e.$2, .labelMedium),
                    onTap: e.$3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
