import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage(this.chapter, {super.key});

  final ChapterInfo chapter;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaminariTheme.background,
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: .all(16),
              child: Column(spacing: 12, children: [SizedBox(height: 60)]),
            ),
          ),

          AppBar(
            backgroundColor: KaminariTheme.background.withAlpha(225),
            leading: LightningIconButton(
              icon: Icons.arrow_back_ios_new,
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              LightningIconButton(
                icon: Icons.bookmark_border_rounded,
                onPressed: () => print(1),
              ),
              LightningIconButton(
                icon: Icons.more_vert_rounded,
                onPressed: () => print(2),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
