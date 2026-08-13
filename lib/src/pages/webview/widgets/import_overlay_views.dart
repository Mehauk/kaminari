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

  const ImportPreviewView({
    super.key,
    required this.book,
    required this.onTypeChanged,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
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
}

class ImportSuccessView extends StatelessWidget {
  final String? bookTitle;
  final VoidCallback onDone;

  const ImportSuccessView({
    super.key,
    required this.bookTitle,
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
