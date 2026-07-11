import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/book_cover.dart';

class ImportLoadingView extends StatelessWidget {
  final double progress;
  final String message;
  final bool isSaving;
  final VoidCallback? onCancel;

  const ImportLoadingView({
    super.key,
    required this.progress,
    required this.message,
    required this.isSaving,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          isSaving ? "Saving Entry..." : "AI Web Parsing",
          TextType.headlineMedium,
          alignment: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 110,
              child: CircularProgressIndicator(value: progress, strokeWidth: 5),
            ),
            CustomText(
              "${(progress * 100).toStringAsFixed(0)}%",
              TextType.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 32),
        CustomText(message, TextType.bodyMedium, alignment: TextAlign.center),
        if (!isSaving && onCancel != null) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text("CANCEL EXTRACTION"),
          ),
        ],
      ],
    );
  }
}

class ImportPreviewView extends StatelessWidget {
  final BookDetails book;
  final ValueChanged<BookType> onTypeChanged;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback? onHide;
  final VoidCallback? onMissingChapters;
  final bool showMissingChaptersBtn;

  const ImportPreviewView({
    super.key,
    required this.book,
    required this.onTypeChanged,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
    this.onHide,
    this.onMissingChapters,
    this.showMissingChaptersBtn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText("Verify Extracted Data", TextType.headlineMedium),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: KaminariTheme.surfaceTint.withAlpha(30),
                ),
                borderRadius: BorderRadius.circular(
                  KaminariTheme.altBorderRadius,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  KaminariTheme.altBorderRadius,
                ),
                child: BookCover(
                  coverUrl: book.coverUrl,
                  width: 80,
                  height: 110,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(book.title, TextType.titleMedium, maxLines: 2),
                  const SizedBox(height: 4),
                  CustomText(
                    "Author: ${book.author}",
                    TextType.bodyMedium,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    "Chapters: ${book.chapters.length}",
                    TextType.labelSmall,
                    color: KaminariTheme.textSecondary,
                  ),
                  if (book.jlptLevel != null) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      "Difficulty: JLPT ${book.jlptLevel}",
                      TextType.labelSmall,
                      color: KaminariTheme.cyan,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const CustomText(
          "Synopsis",
          TextType.labelSmall,
          color: KaminariTheme.textTitle,
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            child: Text(
              book.synopsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: KaminariTheme.textSecondary,
              ),
            ),
          ),
        ),

        // Structured chapter sequence preview (first, gap, last) with resume options
        _buildChapterSequenceSection(),

        const SizedBox(height: 20),
        const CustomText(
          "Select Book Type",
          TextType.labelSmall,
          color: KaminariTheme.textTitle,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<BookType>(
            segments: BookType.values
                .where((t) => t != BookType.all)
                .map(
                  (t) =>
                      ButtonSegment<BookType>(value: t, label: Text(t.short)),
                )
                .toList(),
            selected: {book.bookType},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                onTypeChanged(selected.first);
              }
            },
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text("RETRY AI"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                child: const Text("CONFIRM"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (onHide != null)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onHide,
                  child: const Text("HIDE"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: onCancel,
                  child: const Text("DISCARD & CLOSE"),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancel,
              child: const Text("DISCARD & CLOSE"),
            ),
          ),
      ],
    );
  }

  Widget _buildChapterSequenceSection() {
    if (book.chapters.isEmpty) return const SizedBox.shrink();

    final firstCh = book.chapters.first;
    final inBetweenCount = book.chapters.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const CustomText(
              "Chapters",
              TextType.labelSmall,
              color: KaminariTheme.textTitle,
            ),
            if (showMissingChaptersBtn && onMissingChapters != null)
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onMissingChapters,
                child: const CustomText(
                  "Missing Chapters?",
                  TextType.labelSmall,
                  color: KaminariTheme.cyan,
                  fontSize: 11,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: KaminariTheme.surfaceVariant.withAlpha(30),
            borderRadius: BorderRadius.circular(KaminariTheme.altBorderRadius),
            border: Border.all(color: KaminariTheme.surfaceTint.withAlpha(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display First Chapter
              _buildChapterRow(firstCh),

              // Segment representing skipped entries
              if (inBetweenCount > 0) ...[
                CustomText(
                  "• • •  $inBetweenCount more  • • •",
                  TextType.labelSmall,
                  color: KaminariTheme.textSecondary.withAlpha(120),
                  fontSize: 11,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChapterRow(ChapterInfo ch) {
    return CustomText(ch.title, TextType.bodyMedium, fontSize: 13, maxLines: 1);
  }
}

class ImportSuccessView extends StatelessWidget {
  final String? bookTitle;
  final List<ChapterInfo>? chapters;
  final VoidCallback onDone;

  const ImportSuccessView({
    super.key,
    required this.bookTitle,
    this.chapters,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: KaminariTheme.success,
          size: 64,
        ),
        const SizedBox(height: 16),
        const CustomText("Import Complete", TextType.headlineMedium),
        const SizedBox(height: 12),
        CustomText(
          "\"${bookTitle ?? 'The book'}\" has been cataloged successfully. Background cache operations are preparing chapter structures.",
          TextType.bodyMedium,
          alignment: TextAlign.center,
        ),
        if (chapters != null && chapters!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: CustomText(
              "Imported Chapters",
              TextType.labelSmall,
              color: KaminariTheme.textTitle,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height:
                180, // Constrained height equivalent to ~4 chapters comfortably
            decoration: BoxDecoration(
              color: KaminariTheme.surfaceVariant.withAlpha(50),
              borderRadius: BorderRadius.circular(
                KaminariTheme.altBorderRadius,
              ),
              border: Border.all(
                color: KaminariTheme.surfaceTint.withAlpha(30),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                KaminariTheme.altBorderRadius,
              ),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 12,
                ),
                itemCount: chapters!.length,
                itemBuilder: (context, index) {
                  final ch = chapters![index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: CustomText(
                            '${ch.number + 1}'.padLeft(2, '0'),
                            TextType.labelSmall,
                            color: KaminariTheme.textTitle,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomText(
                            ch.title,
                            TextType.bodyMedium,
                            fontSize: 13,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onDone,
            child: const Text("CLOSE WEBVIEW"),
          ),
        ),
      ],
    );
  }
}

class ImportFailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  const ImportFailureView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: KaminariTheme.error,
          size: 64,
        ),
        const SizedBox(height: 16),
        const CustomText("Operation Failed", TextType.headlineMedium),
        const SizedBox(height: 12),
        CustomText(message, TextType.bodyMedium, alignment: TextAlign.center),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                child: const Text("ABANDON"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                child: const Text("RETRY"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
