import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/globals/background_webview_cubit.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
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
      create: (context) =>
          ReaderCubit(chapter, dbService: context.read(), bookId: bookId),
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

  @override
  void initState() {
    super.initState();
    final readerCubit = context.read<ReaderCubit>();
    final initialOffset = readerCubit.chapter.scrollPosition ?? 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final backgroundCubit = context.read<BackgroundWebviewCubit>();

      final isChapterEmpty =
          readerCubit.chapter.content == null ||
          readerCubit.chapter.content!.isEmpty;

      // 1. If this chapter is empty, put it at the top of the download stack (Priority)
      if (isChapterEmpty) {
        backgroundCubit.enqueueChapters(
          bookId: readerCubit.bookId,
          chapters: [readerCubit.chapter],
          isPriority: true,
        );
      }

      // 2. Fetch the next 3 unloaded chapters and add them to the background queue (Standard priority)
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
    _scrollController.dispose();
    super.dispose();
  }

  void _onTokenTap(
    BuildContext context,
    String token,
    int paragraphInex,
    int tokenIndex,
  ) async {
    final cubit = context.read<ReaderCubit>();
    await cubit.lookupToken(token, paragraphInex, tokenIndex);
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();

    return MultiBlocListener(
      listeners: [
        // Listen to background cubit: if our current chapter ID moves into 'completed', reload content
        BlocListener<BackgroundWebviewCubit, BackgroundWebviewState>(
          listenWhen: (prev, curr) =>
              curr.completedChapterIds.contains(cubit.chapter.id) &&
              !prev.completedChapterIds.contains(cubit.chapter.id),
          listener: (context, state) {
            context.read<ReaderCubit>().reloadContent();
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: KaminariTheme.background,
        body: BlocBuilder<ReaderCubit, ReaderState>(
          builder: (context, state) {
            return Stack(
              children: [
                // MAIN CONTENT LAYER
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

                    if (state.tokenizedParagraphs.isEmpty) {
                      return const SizedBox.shrink(); // Handled by the Downloading overlay
                    }

                    return NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          cubit.saveScrollPosition(
                            _scrollController.position.pixels,
                          );
                        }
                        return false;
                      },
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(
                              24,
                              140,
                              24,
                              100,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final tokens = state.tokenizedParagraphs[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _TokenizedParagraph(
                                    tokens: tokens,
                                    paragraphIndex: index,
                                    onTokenTap: _onTokenTap,
                                  ),
                                );
                              }, childCount: state.tokenizedParagraphs.length),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                // DOWNLOAD STATUS OVERLAY (Full Center)
                BlocBuilder<BackgroundWebviewCubit, BackgroundWebviewState>(
                  builder: (context, bgState) {
                    final isDownloadingThis =
                        bgState.activeChapterId == cubit.chapter.id;
                    final needsContent =
                        state.tokenizedParagraphs.isEmpty && !state.isLoading;

                    if (needsContent) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),

                // HEADER / DICTIONARY BAR
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
                                    cubit.chapter.title,
                                    TextType.labelMedium,
                                    fontSize: 16,
                                    color: KaminariTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 48),
                              ],
                            ),
                            const SizedBox(height: 8),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) =>
                                  SizeTransition(
                                    sizeFactor: animation,
                                    child: child,
                                  ),
                              child: DictionaryView(
                                state.selectedEntry,
                                cubit.clearSelection,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // BACKGROUND PROGRESS BAR (Small Top Bar)
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

class _TokenizedParagraph extends StatelessWidget {
  const _TokenizedParagraph({
    required this.tokens,
    required this.paragraphIndex,
    required this.onTokenTap,
  });

  final List<String> tokens;
  final int paragraphIndex;
  final Function(BuildContext, String, int, int) onTokenTap;

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
                  fontSize: 19,
                  height: 1.8,
                  color: isPunctuation
                      ? KaminariTheme.textSecondary.withAlpha(150)
                      : (isSelected
                            ? KaminariTheme.textTitle
                            : KaminariTheme.textPrimary),
                  backgroundColor: isSelected
                      ? KaminariTheme.bronze.withAlpha(125)
                      : Colors.transparent,
                ),
                recognizer: isPunctuation
                    ? null
                    : (TapGestureRecognizer()
                        ..onTap = () => onTokenTap(
                          context,
                          token,
                          paragraphIndex,
                          tokenIndex,
                        )),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
