import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/chapter_analysis_service.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/pages/home/prep/chapter_prep_page.dart';
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
