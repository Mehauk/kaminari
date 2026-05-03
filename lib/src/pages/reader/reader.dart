import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/pages/reader/reader_cubit.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

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
    final initialOffset =
        context.read<ReaderCubit>().chapter.scrollPosition ?? 0.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
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

    return Scaffold(
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
                          padding: const EdgeInsets.fromLTRB(24, 140, 24, 100),
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

              // Header Bar
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
                              const SizedBox(
                                width: 48,
                              ), // Balance for back button
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
                            child: ReaderDictionaryExtension(),
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
    // Wrap with BlocBuilder to react to selection changes for *this* paragraph only
    return BlocBuilder<ReaderCubit, ReaderState>(
      // Only rebuild this paragraph if:
      // 1. Its tokens or content changes (unlikely after initial load)
      // 2. The global selectedParagraphIndex matches *this* paragraph's index (it's the current selection)
      // 3. The global selectedParagraphIndex *was* this paragraph's index (it was previously selected and needs to deselect)
      buildWhen: (previous, current) {
        final bool wasSelectedParagraph =
            previous.selectedParagraphIndex == paragraphIndex;
        final bool isSelectedParagraph =
            current.selectedParagraphIndex == paragraphIndex;

        // Rebuild if this paragraph's selection status changes
        if (wasSelectedParagraph != isSelectedParagraph) {
          return true;
        }

        // Rebuild if this paragraph was selected and its *specific token index* changed
        // (i.e., a different token within the *same* paragraph was selected)
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
              final bool isPunctuation = RegExp(
                r'[^\w\s\u4e00-\u9faf\u3040-\u309f\u30a0-\u30ff]',
              ).hasMatch(token);

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
                            : KaminariTheme.textPrimary), // Highlighted color
                  backgroundColor: isSelected
                      ? KaminariTheme.bronze.withAlpha(125)
                      : Colors.transparent, // Highlight background
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
