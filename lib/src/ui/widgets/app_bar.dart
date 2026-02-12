import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class LightningAppBar extends StatelessWidget {
  const LightningAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BgFilter(
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.white10, width: 1)),
            color: KaminariTheme.background.withAlpha(200),
            boxShadow: [
              BoxShadow(
                color: KaminariTheme.surfaceTint.withAlpha(15),
                blurRadius: 15,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          padding: .symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: [
              LightningIcon(Icons.bolt, type: .glowing),
              CustomText(
                "Kaminari Browser",
                .headlineMedium,
                colorOverride: KaminariTheme.textTitle,
              ),
              Expanded(child: SizedBox.shrink()),
              LightningIcon(CupertinoIcons.person_alt_circle),
            ],
          ),
        ),
      ),
    );
  }
}
