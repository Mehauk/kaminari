import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/pages/home/prep/chapter_prep_cubit.dart';
import 'package:kaminari/src/pages/home/prep/flashcard.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class ChapterPrepPage extends StatelessWidget {
  final BookDetails book;
  final ChapterInfo chapter;

  const ChapterPrepPage({super.key, required this.book, required this.chapter});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChapterPrepCubit(chapter),
      child: Scaffold(
        backgroundColor: KaminariTheme.background,
        body: BlocBuilder<ChapterPrepCubit, ChapterPrepState>(
          builder: (context, state) {
            return Stack(
              children: [
                // 1. CONTENT LAYER
                if (state.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (state.items.isEmpty)
                  const Center(
                    child: CustomText(
                      "No complex words found.",
                      TextType.bodyLarge,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 140, 32, 32),
                    child: Column(
                      children: [
                        Expanded(
                          child: FlashcardWidget(
                            item: state.items[state.currentIndex],
                            isFlipped: state.isFlipped,
                            onTap: () =>
                                context.read<ChapterPrepCubit>().toggleFlip(),
                          ),
                        ),
                        const SizedBox(height: 32),
                        CustomText(
                          "${state.currentIndex + 1} / ${state.items.length}",
                          TextType.labelMedium,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed:
                                state.currentIndex == state.items.length - 1
                                ? () => Navigator.pop(context)
                                : () => context
                                      .read<ChapterPrepCubit>()
                                      .nextCard(),
                            child: Text(
                              state.currentIndex == state.items.length - 1
                                  ? "FINISH"
                                  : "NEXT WORD",
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 2. HEADER LAYER (Lightning Style)
                ClipRRect(
                  child: BgFilter(
                    bgColor: KaminariTheme.background.withAlpha(200),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: KaminariTheme.surfaceTint.withAlpha(40),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            LightningIconButton(
                              icon: Icons.arrow_back_ios_new,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                            Expanded(
                              child: CustomText(
                                "Prep: ${chapter.title}",
                                TextType.labelMedium,
                                fontSize: 16,
                                color: KaminariTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
