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

class ImportPreviewView extends StatefulWidget {
  final BookDetails book;
  final ValueChanged<BookType> onTypeChanged;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final VoidCallback? onRetryMetadata;
  final VoidCallback? onRetryChapters;
  final VoidCallback onCancel;
  final VoidCallback? onHide;
  final VoidCallback? onMissingChapters;
  final bool showMissingChaptersBtn;
  final Set<String>? unpinnedFields;
  final ValueChanged<String>? onTogglePin;

  const ImportPreviewView({
    super.key,
    required this.book,
    required this.onTypeChanged,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
    this.onRetryMetadata,
    this.onRetryChapters,
    this.onHide,
    this.onMissingChapters,
    this.showMissingChaptersBtn = false,
    this.unpinnedFields,
    this.onTogglePin,
  });

  @override
  State<ImportPreviewView> createState() => _ImportPreviewViewState();
}

class _ImportPreviewViewState extends State<ImportPreviewView> {
  String? _errorMessage;

  bool _isFieldPinned(String fieldKey) {
    if (widget.unpinnedFields == null) return true; // Pin by default
    return !widget.unpinnedFields!.contains(fieldKey);
  }

  void _validateAndRun(
    List<String> fieldKeys,
    VoidCallback action,
    String errorExplanation,
  ) {
    final anyUnpinned = fieldKeys.any((key) => !_isFieldPinned(key));

    if (!anyUnpinned) {
      setState(() {
        _errorMessage = errorExplanation;
      });
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    } else {
      setState(() {
        _errorMessage = null;
      });
      action();
    }
  }

  Widget _buildLockableField({
    required String fieldKey,
    required Widget child,
  }) {
    if (widget.onTogglePin == null) return child;
    final isPinned = _isFieldPinned(fieldKey);
    return Row(
      children: [
        Expanded(child: child),
        const SizedBox(width: 8),
        IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: Icon(
            isPinned ? Icons.lock : Icons.lock_open_outlined,
            size: 16,
            color: isPinned
                ? KaminariTheme.cyan
                : KaminariTheme.textSecondary.withAlpha(120),
          ),
          onPressed: () => widget.onTogglePin!(fieldKey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool showSeparatedRetries = widget.onRetryMetadata != null;

    final isCoverPinned = _isFieldPinned('coverUrl');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(KaminariTheme.borderRadius),
        border: Border.all(
          color: _errorMessage != null
              ? KaminariTheme.error
              : Colors.transparent,
          width: _errorMessage != null ? 2.0 : 0.0,
        ),
      ),
      padding: _errorMessage != null
          ? const EdgeInsets.all(8.0)
          : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CustomText("Verify Extracted Data", TextType.headlineMedium),

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: KaminariTheme.error.withAlpha(25),
                borderRadius: BorderRadius.circular(
                  KaminariTheme.altBorderRadius,
                ),
                border: Border.all(color: KaminariTheme.error.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: KaminariTheme.error,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomText(
                      _errorMessage!,
                      TextType.labelSmall,
                      color: KaminariTheme.error,
                      fontSize: 12,
                      maxLines: 3,
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                  child: Stack(
                    children: [
                      BookCover(
                        coverUrl: widget.book.coverUrl,
                        width: 80,
                        height: 110,
                        fit: BoxFit.cover,
                        cacheImage: false,
                      ),
                      if (widget.onTogglePin != null)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => widget.onTogglePin!('coverUrl'),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withAlpha(180),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isCoverPinned
                                    ? Icons.lock
                                    : Icons.lock_open_outlined,
                                size: 14,
                                color: isCoverPinned
                                    ? KaminariTheme.cyan
                                    : Colors.white70,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLockableField(
                      fieldKey: 'title',
                      child: CustomText(
                        widget.book.title,
                        TextType.titleMedium,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildLockableField(
                      fieldKey: 'author',
                      child: CustomText(
                        "Author: ${widget.book.author}",
                        TextType.bodyMedium,
                        maxLines: 1,
                      ),
                    ),

                    if (widget.book.jlptLevel != null) ...[
                      const SizedBox(height: 4),
                      _buildLockableField(
                        fieldKey: 'jlptLevel',
                        child: CustomText(
                          "Difficulty: JLPT ${widget.book.jlptLevel}",
                          TextType.labelSmall,
                          color: KaminariTheme.cyan,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLockableField(
            fieldKey: 'synopsis',
            child: const CustomText(
              "Synopsis",
              TextType.labelSmall,
              color: KaminariTheme.textTitle,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: SingleChildScrollView(
              child: Text(
                widget.book.synopsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: KaminariTheme.textSecondary,
                ),
              ),
            ),
          ),

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
              selected: {widget.book.bookType},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  widget.onTypeChanged(selected.first);
                }
              },
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 24),
          if (showSeparatedRetries) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onRetryMetadata != null
                        ? () => _validateAndRun(
                            [
                              'title',
                              'author',
                              'synopsis',
                              'coverUrl',
                              'jlptLevel',
                            ],
                            widget.onRetryMetadata!,
                            "Please unlock (unpin) at least one metadata field to retry.",
                          )
                        : null,
                    child: const Text("RETRY METADATA AI"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onConfirm,
                    child: const Text("CONFIRM"),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (widget.book.source == "Local EPUB") {
                        widget.onRetry();
                      } else {
                        _validateAndRun(
                          [
                            'title',
                            'author',
                            'synopsis',
                            'coverUrl',
                            'jlptLevel',
                          ],
                          widget.onRetry,
                          "Please unlock (unpin) at least one field to retry AI extraction.",
                        );
                      }
                    },
                    child: Text(
                      widget.book.source == "Local EPUB"
                          ? "RE-SELECT FILE"
                          : "RETRY AI",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onConfirm,
                    child: const Text("CONFIRM"),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          if (widget.onHide != null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onHide,
                    child: const Text("HIDE"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: widget.onCancel,
                    child: const Text("DISCARD & CLOSE"),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: widget.onCancel,
                child: const Text("DISCARD & CLOSE"),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChapterSequenceSection() {
    if (widget.book.chapters.isEmpty) return const SizedBox.shrink();

    final firstCh = widget.book.chapters.first;
    final inBetweenCount = widget.book.chapters.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        CustomText(
          "Chapters: ${widget.book.chapters.length}",
          TextType.labelSmall,
          color: KaminariTheme.textTitle,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (widget.onRetryChapters != null)
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onRetryChapters,
                child: CustomText(
                  (widget.showMissingChaptersBtn &&
                          widget.onMissingChapters != null)
                      ? "FIX INCORRECT ORDERING"
                      : "FIX INCORRECT ORDERING OR MISSING CHAPTERS",
                  TextType.labelSmall,
                  color: KaminariTheme.cyan,
                  fontSize: 11,
                ),
              ),
            if (widget.showMissingChaptersBtn &&
                widget.onMissingChapters != null)
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: widget.onMissingChapters,
                child: const CustomText(
                  "FIX MISSING CHAPTERS",
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
              CustomText(
                "FIRST CHAPTER (not last)",
                TextType.labelSmall,
                color: KaminariTheme.textSecondary.withAlpha(120),
              ),
              CustomText(
                firstCh.title.trim(),
                TextType.bodyMedium,
                fontSize: 13,
              ),
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
            height: 180,
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
  final VoidCallback? onRetry;
  final VoidCallback? onRetryMetadata;
  final VoidCallback? onRetryChapters;
  final VoidCallback onCancel;

  const ImportFailureView({
    super.key,
    required this.message,
    required this.onCancel,
    this.onRetry,
    this.onRetryMetadata,
    this.onRetryChapters,
  });

  @override
  Widget build(BuildContext context) {
    final bool showSeparated =
        onRetryMetadata != null && onRetryChapters != null;

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
        if (showSeparated) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onRetryChapters,
              child: const Text("RETRY CHAPTER EXTRACTION"),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onRetryMetadata,
              child: const Text("RE-RUN AI SELECTOR SEARCH"),
            ),
          ),
          const SizedBox(height: 12),
        ] else if (onRetry != null) ...[
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: onRetry, child: const Text("RETRY")),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancel,
            child: const Text("ABANDON & CLOSE"),
          ),
        ),
      ],
    );
  }
}
