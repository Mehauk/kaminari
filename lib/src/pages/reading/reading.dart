import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
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
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 130, 24, 60),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final paragraph = chapter.content?[index] ?? "";
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(
                        paragraph,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 18,
                          height: 1.8,
                          color: KaminariTheme.textPrimary,
                        ),
                      ),
                    );
                  }, childCount: chapter.content?.length ?? 0),
                ),
              ),
            ],
          ),
          ClipRRect(
            child: BgFilter(
              bgColor: KaminariTheme.background.withAlpha(200),
              child: SafeArea(
                bottom: false,
                child: Column(
                  mainAxisSize: .min,
                  children: [
                    Row(
                      spacing: 4,
                      children: [
                        LightningIconButton(
                          icon: Icons.arrow_back_ios_new,
                          onPressed: () => Navigator.of(context).pop(),
                        ),

                        CustomText(
                          chapter.title,
                          .labelMedium,
                          fontSize: 18,
                          color: KaminariTheme.textSecondary,
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
