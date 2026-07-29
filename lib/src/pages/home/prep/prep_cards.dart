import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/chapter_analysis_service.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/pages/home/prep/chapter_prep_page.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class ReviewPrepCard extends StatelessWidget {
  const ReviewPrepCard({
    super.key,
    required this.nextChapter,
    required this.book,
  });

  final ChapterInfo nextChapter;
  final BookDetails book;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: ChapterAnalysisService.getPrepCount(
        book.id!,
        nextChapter,
        context.read<DatabaseService>(),
      ),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 100;
        final reviewed = nextChapter.prepReviewedCount.clamp(0, total);

        if (total == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: LightningCard(
            type: .thin,
            child: InkWell(
              onTap: () async {
                final fullChapter = await context
                    .read<DatabaseService>()
                    .getChapterWithContent(nextChapter.id!);
                if (fullChapter != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ChapterPrepPage(book: book, chapter: fullChapter),
                    ),
                  );
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    LightningIcon(Icons.psychology_alt_outlined, type: .golden),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            "READING PREP",
                            TextType.labelSmall,
                            color: KaminariTheme.textTitle,
                          ),
                          CustomText(
                            "$reviewed/$total key words reviewed for Chapter ${nextChapter.number + 1}",
                            TextType.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class MiniPrepCard extends StatelessWidget {
  const MiniPrepCard({
    super.key,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterNumber,
  });

  final int chapterId;
  final String chapterTitle;
  final int chapterNumber;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();
    final activeChapter = cubit.loadedChapters.firstWhere(
      (c) => c.id == chapterId,
      orElse: () => cubit.chapter,
    );

    return FutureBuilder<int>(
      future: ChapterAnalysisService.getPrepCount(
        cubit.bookId,
        activeChapter,
        context.read<DatabaseService>(),
      ),
      builder: (context, snapshot) {
        final total = snapshot.data ?? 100;
        final reviewed = activeChapter.prepReviewedCount.clamp(0, total);

        if (total == 0) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: LightningCard(
            type: .thin,
            child: InkWell(
              onTap: () async {
                final db = context.read<DatabaseService>();
                final book = await db.getBook(cubit.bookId);
                final fullChapter = await db.getChapterWithContent(chapterId);
                if (book != null && fullChapter != null && context.mounted) {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ChapterPrepPage(book: book, chapter: fullChapter),
                        ),
                      )
                      .then((_) {
                        // Update state within current reader segment on progress modification
                        cubit.reloadPrepProgress(chapterId);
                      });
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology_alt_outlined,
                      size: 16,
                      color: KaminariTheme.textTitle,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(
                        "REVIEW KEY WORDS ($reviewed/$total)",
                        TextType.labelSmall,
                        fontSize: 12,
                        color: KaminariTheme.textTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: KaminariTheme.textSecondary.withAlpha(120),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
