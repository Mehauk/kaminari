import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/globals/background_webview_cubit.dart';
import 'package:kaminari/src/pages/home/prep/prep_cards.dart';
import 'package:kaminari/src/pages/reader/dict_orientation_dialog.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/pages/reader/kanji_alignment_dialog.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/bottom_sheet.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';
import 'package:kaminari/src/utils/string_extensions.dart';

class ReaderPage extends StatelessWidget {
  const ReaderPage(this.chapter, {super.key, required this.bookId});

  final ChapterInfo chapter;
  final int bookId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReaderCubit(
        chapter,
        bookId: bookId,
        dbService: context.read(),
        settings: context.read(),
      ),
      child: const _ReaderView(),
    );
  }
}

class _ReaderView extends StatefulWidget {
  const _ReaderView();

  @override
  State<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<_ReaderView> {
  late ScrollController _scrollController;
  bool _showScrollThumb = false;
  Timer? _hideThumbTimer;
  final Map<int, GlobalKey> _chapterKeys = {};
  final Map<int, double> _chapterStartOffsets = {};

  GlobalKey _getKeyForChapter(int chapterId) {
    return _chapterKeys.putIfAbsent(chapterId, () => GlobalKey());
  }

  @override
  void initState() {
    super.initState();
    final readerCubit = context.read<ReaderCubit>();
    final initialOffset = readerCubit.chapter.scrollPosition ?? 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    // The initial chapter is always at the top (start offset 0.0)
    if (readerCubit.chapter.id != null) {
      _chapterStartOffsets[readerCubit.chapter.id!] = 0.0;
    }

    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      _onScroll();

      if (!_showScrollThumb) {
        setState(() {
          _showScrollThumb = true;
        });
      }

      _hideThumbTimer?.cancel();
      _hideThumbTimer = Timer(const Duration(milliseconds: 1200), () {
        if (mounted) setState(() => _showScrollThumb = false);
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final backgroundCubit = context.read<BackgroundWebviewCubit>();

      final isChapterEmpty =
          readerCubit.chapter.content == null ||
          readerCubit.chapter.content!.isEmpty;

      if (isChapterEmpty) {
        backgroundCubit.enqueueChapters(
          bookId: readerCubit.bookId,
          chapters: [readerCubit.chapter],
          isPriority: true,
        );
      }

      context
          .read<DatabaseService>()
          .getNextChaptersWithoutContent(
            readerCubit.bookId,
            readerCubit.chapter.number,
            3,
          )
          .then((nextChapters) {
            if (mounted && nextChapters.isNotEmpty) {
              backgroundCubit.enqueueChapters(
                bookId: readerCubit.bookId,
                chapters: nextChapters,
                isPriority: false,
              );
            }
          });
    });
  }

  @override
  void dispose() {
    _hideThumbTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showMoreBottomSheet(BuildContext context) {
    final backgroundCubit = context.read<BackgroundWebviewCubit>();
    final readerCubit = context.read<ReaderCubit>();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LightningBottomSheet(
        children: [
          (
            Icons.refresh,
            "Re-download current chapter.",
            () {
              print([readerCubit.chapter]);
              Navigator.of(ctx).pop();
              backgroundCubit.enqueueChapters(
                bookId: readerCubit.bookId,
                chapters: [readerCubit.chapter],
                isPriority: true,
                forceReloadSelectors: true,
              );
            },
          ),
          (
            Icons.swap_vert_circle_outlined,
            "Dictionary position",
            () {
              Navigator.of(ctx).pop();
              showDialog<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: readerCubit,
                  child: const DictOrientationDialog(),
                ),
              );
            },
          ),
          (
            Icons.align_horizontal_left_rounded,
            "Kanji card position",
            () {
              Navigator.of(ctx).pop();
              showDialog<void>(
                context: context,
                builder: (_) => BlocProvider.value(
                  value: readerCubit,
                  child: const KanjiAlignmentDialog(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _onTokenTap(
    BuildContext context,
    String token,
    int paragraphIndex,
    int tokenIndex,
    TapUpDetails details,
  ) async {
    final cubit = context.read<ReaderCubit>();
    await cubit.lookupToken(
      token,
      paragraphIndex,
      tokenIndex,
      tapY: details.globalPosition.dy,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final cubit = context.read<ReaderCubit>();

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll - currentScroll < 400) {
      cubit.loadNextChapter();
    }

    for (var loaded in cubit.loadedChapters) {
      if (_chapterStartOffsets.containsKey(loaded.id)) continue;
      final key = _chapterKeys[loaded.id];
      final context = key?.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          final startOffset = _scrollController.offset + position.dy - 140.0;
          _chapterStartOffsets[loaded.id!] = startOffset;
        }
      }
    }

    ChapterInfo? activeChapter;
    final currentOffset = _scrollController.offset;
    for (var loaded in cubit.loadedChapters) {
      final startOffset = _chapterStartOffsets[loaded.id];
      if (startOffset == null) continue;
      if (startOffset <= currentOffset) {
        activeChapter = loaded;
      }
    }

    if (activeChapter != null) {
      cubit.updateActiveChapter(activeChapter);
    }
  }

  void _saveActiveChapterScrollPosition() {
    if (!_scrollController.hasClients) return;

    final cubit = context.read<ReaderCubit>();
    final activeTitle = cubit.state.activeChapterTitle;
    if (activeTitle == null) return;

    final activeChapter = cubit.loadedChapters.firstWhere(
      (c) => c.title == activeTitle,
      orElse: () => cubit.chapter,
    );

    double? startOffset = _chapterStartOffsets[activeChapter.id];

    if (startOffset == null) {
      final key = _chapterKeys[activeChapter.id];
      final context = key?.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final position = box.localToGlobal(Offset.zero);
          startOffset = _scrollController.offset + position.dy - 140.0;
          _chapterStartOffsets[activeChapter.id!] = startOffset;
        }
      }
    }

    if (startOffset != null) {
      final relativeScroll = _scrollController.offset - startOffset;
      cubit.saveScrollPosition(
        activeChapter.id!,
        relativeScroll.clamp(0.0, double.infinity),
      );
    } else {
      cubit.saveScrollPosition(activeChapter.id!, 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();

    return MultiBlocListener(
      listeners: [
        BlocListener<ReaderCubit, ReaderState>(
          listenWhen: (prev, curr) =>
              curr.activeWaitingChapter != null &&
              prev.activeWaitingChapter?.id != curr.activeWaitingChapter?.id,
          listener: (context, state) {
            context.read<BackgroundWebviewCubit>().enqueueChapters(
              bookId: cubit.bookId,
              chapters: [state.activeWaitingChapter!],
              isPriority: true,
            );
          },
        ),
        BlocListener<BackgroundWebviewCubit, BackgroundWebviewState>(
          listenWhen: (prev, curr) =>
              curr.completedChapterIds.length > prev.completedChapterIds.length,
          listener: (context, bgState) {
            final readerCubit = context.read<ReaderCubit>();
            final readerState = readerCubit.state;

            // Check if the current chapter has been completed
            if (bgState.completedChapterIds.contains(readerCubit.chapter.id)) {
              readerCubit.onChapterDownloaded(readerCubit.chapter.id!);
            }

            // Check if a next waiting chapter has been completed
            if (readerState.activeWaitingChapter != null &&
                bgState.completedChapterIds.contains(
                  readerState.activeWaitingChapter!.id,
                )) {
              readerCubit.onChapterDownloaded(
                readerState.activeWaitingChapter!.id!,
              );
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: KaminariTheme.background,
        body: BlocBuilder<ReaderCubit, ReaderState>(
          builder: (context, state) {
            return Stack(
              children: [
                Builder(
                  builder: (context) {
                    if (state.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state.errorMessage != null) {
                      return Center(
                        child: CustomText(
                          state.errorMessage!,
                          TextType.bodyLarge,
                        ),
                      );
                    }

                    if (state.items.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          _saveActiveChapterScrollPosition();
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(
                              24,
                              140,
                              24,
                              state.computedDictOrientation ==
                                      DictOrientation.bottom
                                  ? 180
                                  : 100,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final item = state.items[index];
                                switch (item.type) {
                                  case ReaderItemType.title:
                                    return Column(
                                      key: _getKeyForChapter(item.chapterId),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        MiniPrepCard(
                                          chapterId: item.chapterId,
                                          chapterTitle: item.chapterTitle,
                                          chapterNumber: item.chapterNumber,
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 16,
                                            bottom: 24,
                                          ),
                                          child: _TokenizedParagraph(
                                            tokens: item.tokens,
                                            paragraphIndex: index,
                                            onTokenTap: _onTokenTap,
                                            isTitle: true,
                                          ),
                                        ),
                                      ],
                                    );
                                  case ReaderItemType.paragraph:
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 24,
                                      ),
                                      child: _TokenizedParagraph(
                                        tokens: item.tokens,
                                        paragraphIndex: index,
                                        onTokenTap: _onTokenTap,
                                      ),
                                    );
                                  case ReaderItemType.pageBreak:
                                    return _PageBreak(
                                      nextChapterTitle: item.chapterTitle,
                                      nextChapterNumber: item.chapterNumber,
                                    );
                                }
                              }, childCount: state.items.length),
                            ),
                          ),
                          if (state.isLoadingNext)
                            const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.only(bottom: 64),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                Positioned(
                  top: 140,
                  bottom: 50,
                  right: 8,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _showScrollThumb ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: AnimatedBuilder(
                        animation: _scrollController,
                        builder: (context, child) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final pos = _scrollController.hasClients
                                  ? _scrollController.position
                                  : null;
                              final viewportHeight =
                                  pos?.viewportDimension ??
                                  constraints.maxHeight;
                              final totalHeight =
                                  (pos?.maxScrollExtent ?? 0) + viewportHeight;
                              final thumbHeight = totalHeight > 0
                                  ? (viewportHeight / totalHeight) *
                                        constraints.maxHeight
                                  : constraints.maxHeight * 0.12;
                              final normalizedThumbHeight = thumbHeight.clamp(
                                24.0,
                                constraints.maxHeight * 0.18,
                              );
                              final maxTop =
                                  constraints.maxHeight -
                                  normalizedThumbHeight -
                                  4.0;
                              final thumbTop = (maxTop > 0 && pos != null)
                                  ? (pos.pixels /
                                            (pos.maxScrollExtent > 0
                                                ? pos.maxScrollExtent
                                                : 1)) *
                                        maxTop
                                  : 0.0;

                              return Container(
                                width: 4,
                                decoration: BoxDecoration(
                                  color: KaminariTheme.surfaceTint.withAlpha(
                                    30,
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      top: thumbTop + 2,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: normalizedThumbHeight,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: KaminariTheme.gold.withAlpha(
                                            220,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ),

                BlocBuilder<BackgroundWebviewCubit, BackgroundWebviewState>(
                  builder: (context, bgState) {
                    final isDownloadingThis =
                        bgState.activeChapterId == cubit.chapter.id;
                    final needsContent =
                        state.items.isEmpty && !state.isLoading;

                    if (needsContent) {
                      final isLocal =
                          cubit.chapter.url.startsWith('epub://') ||
                          cubit.chapter.url.startsWith('file://');

                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isLocal) ...[
                              const Icon(
                                Icons.book_outlined,
                                size: 48,
                                color: KaminariTheme.textSecondary,
                              ),
                              const SizedBox(height: 24),
                              const CustomText(
                                "No content found in this local chapter.",
                                TextType.bodyLarge,
                                color: KaminariTheme.textSecondary,
                              ),
                            ] else ...[
                              if (isDownloadingThis)
                                const CircularProgressIndicator()
                              else
                                const Icon(
                                  Icons.cloud_download_outlined,
                                  size: 48,
                                  color: KaminariTheme.textSecondary,
                                ),
                              const SizedBox(height: 24),
                              CustomText(
                                isDownloadingThis
                                    ? "Downloading chapter..."
                                    : "Waiting in download queue...",
                                TextType.bodyLarge,
                                color: KaminariTheme.textSecondary,
                              ),
                            ],
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                LightningIconButton(
                                  icon: Icons.arrow_back_ios_new,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                Expanded(
                                  child: CustomText(
                                    state.activeChapterTitle ??
                                        cubit.chapter.title,
                                    TextType.labelMedium,
                                    fontSize: 16,
                                    color: KaminariTheme.textSecondary,
                                  ),
                                ),
                                LightningIconButton(
                                  icon: Icons.more_vert,
                                  onPressed: () =>
                                      _showMoreBottomSheet(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (state.computedDictOrientation ==
                                DictOrientation.top)
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) =>
                                    SizeTransition(
                                      sizeFactor: animation,
                                      child: child,
                                    ),
                                child: DictionaryView(
                                  entry: state.selectedEntry,
                                  englishEntry: state.selectedEnglishEntry,
                                  showDownloadPrompt:
                                      state.showEnglishDictDownloadPrompt,
                                  isDownloading: state.isEnglishDictDownloading,
                                  downloadProgress:
                                      state.englishDictDownloadProgress,
                                  onDownload: cubit.downloadEnglishDictionary,
                                  clearSelection: cubit.clearSelection,
                                  orientation: state.computedDictOrientation,
                                  alignment: state.kanjiAlignment,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                if (state.computedDictOrientation == DictOrientation.bottom)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      child: BgFilter(
                        bgColor: KaminariTheme.background.withAlpha(200),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: KaminariTheme.surfaceTint.withAlpha(40),
                              ),
                            ),
                          ),
                          child: SafeArea(
                            top: false,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  SizeTransition(
                                    sizeFactor: animation,
                                    child: child,
                                  ),
                              child: DictionaryView(
                                entry: state.selectedEntry,
                                englishEntry: state.selectedEnglishEntry,
                                showDownloadPrompt:
                                    state.showEnglishDictDownloadPrompt,
                                isDownloading: state.isEnglishDictDownloading,
                                downloadProgress:
                                    state.englishDictDownloadProgress,
                                onDownload: cubit.downloadEnglishDictionary,
                                clearSelection: cubit.clearSelection,
                                orientation: state.computedDictOrientation,
                                alignment: state.kanjiAlignment,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (kDebugMode)
                  BlocBuilder<BackgroundWebviewCubit, BackgroundWebviewState>(
                    builder: (context, backgroundState) {
                      final isDownloadingOthers =
                          backgroundState.isProcessing &&
                          backgroundState.activeChapterId != cubit.chapter.id;

                      if (!isDownloadingOthers) return const SizedBox.shrink();

                      return Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          child: Container(
                            color: KaminariTheme.gold.withAlpha(200),
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: const Center(
                              child: Text(
                                'Downloading next chapters in background...',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PageBreak extends StatelessWidget {
  const _PageBreak({
    required this.nextChapterTitle,
    required this.nextChapterNumber,
  });

  final String nextChapterTitle;
  final int nextChapterNumber;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: KaminariTheme.bronze,
                  thickness: 1,
                  endIndent: 16,
                ),
              ),
              Icon(
                Icons.menu_book_rounded,
                color: KaminariTheme.goldSoft.withAlpha(180),
                size: 20,
              ),
              const SizedBox(width: 8),
              CustomText(
                "CHAPTER ${nextChapterNumber + 1}",
                TextType.labelSmall,
                color: KaminariTheme.goldSoft,
                fontWeight: FontWeight.bold,
              ),
              const Expanded(
                child: Divider(
                  color: KaminariTheme.bronze,
                  thickness: 1,
                  indent: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomText(
            "Coming up: $nextChapterTitle",
            TextType.bodyMedium,
            color: KaminariTheme.textSecondary.withAlpha(120),
            fontSize: 13,
            fontWeight: FontWeight.w300,
          ),
        ],
      ),
    );
  }
}

class _TokenizedParagraph extends StatelessWidget {
  const _TokenizedParagraph({
    required this.tokens,
    required this.paragraphIndex,
    required this.onTokenTap,
    this.isTitle = false,
  });

  final List<String> tokens;
  final int paragraphIndex;
  final Function(BuildContext, String, int, int, TapUpDetails) onTokenTap;
  final bool isTitle;

  @override
  Widget build(BuildContext context) {
    if (tokens.length == 1 && tokens.first.startsWith("http")) {
      return SizedBox(
        height: 400,
        child: Center(
          child: LightningCard(
            type: .glowing,
            child: Image.network(tokens.first),
          ),
        ),
      );
    }

    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (previous, current) {
        final bool wasSelectedParagraph =
            previous.selectedParagraphIndex == paragraphIndex;
        final bool isSelectedParagraph =
            current.selectedParagraphIndex == paragraphIndex;
        if (wasSelectedParagraph != isSelectedParagraph) return true;
        if (isSelectedParagraph &&
            previous.selectedTokenIndex != current.selectedTokenIndex) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        final selectedParagraphIndex = state.selectedParagraphIndex;
        final selectedTokenIndex = state.selectedTokenIndex;

        return Text.rich(
          TextSpan(
            children: List.generate(tokens.length, (tokenIndex) {
              final token = tokens[tokenIndex];
              final bool isPunctuation = token.containsPunctuation;
              final isSelected =
                  selectedParagraphIndex == paragraphIndex &&
                  selectedTokenIndex == tokenIndex;

              return TextSpan(
                text: token,
                style: TextStyle(
                  fontSize: isTitle ? 26 : 19,
                  height: isTitle ? 1.5 : 1.8,
                  fontWeight: isTitle ? FontWeight.bold : FontWeight.w500,
                  color: isPunctuation
                      ? KaminariTheme.textSecondary.withAlpha(150)
                      : (isSelected
                            ? KaminariTheme.textTitle
                            : (isTitle
                                  ? KaminariTheme.textTitle
                                  : KaminariTheme.textPrimary)),
                  backgroundColor: isSelected
                      ? KaminariTheme.bronze.withAlpha(125)
                      : Colors.transparent,
                ),
                recognizer: isPunctuation
                    ? null
                    : (TapGestureRecognizer()
                        ..onTapUp = (details) => onTokenTap(
                          context,
                          token,
                          paragraphIndex,
                          tokenIndex,
                          details,
                        )),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
