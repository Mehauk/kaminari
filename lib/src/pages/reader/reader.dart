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
  const ReaderPage(this.chapter, {super.key});

  final ChapterInfo chapter;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReaderCubit(chapter),
      child: const _ReaderView(),
    );
  }
}

class _ReaderView extends StatelessWidget {
  const _ReaderView();

  void _onTokenTap(BuildContext context, String token) async {
    final cubit = context.read<ReaderCubit>();

    // Show a small loading indicator or just fetch
    final entry = await cubit.lookupToken(token);

    if (context.mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: KaminariTheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => DictionaryView(entry),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ReaderCubit>();

    return Scaffold(
      backgroundColor: KaminariTheme.background,
      body: Stack(
        children: [
          BlocBuilder<ReaderCubit, ReaderState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state.errorMessage != null) {
                return Center(
                  child: CustomText(state.errorMessage!, TextType.bodyLarge),
                );
              }

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 140, 24, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final tokens = state.tokenizedParagraphs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _TokenizedParagraph(
                            tokens: tokens,
                            onTokenTap: (t) => _onTokenTap(context, t),
                          ),
                        );
                      }, childCount: state.tokenizedParagraphs.length),
                    ),
                  ),
                ],
              );
            },
          ),

          // Header Bar
          ClipRRect(
            child: BgFilter(
              bgColor: KaminariTheme.background.withAlpha(200),
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
                        const SizedBox(width: 48), // Balance for back button
                      ],
                    ),
                    const SizedBox(height: 8),
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

class _TokenizedParagraph extends StatelessWidget {
  const _TokenizedParagraph({required this.tokens, required this.onTokenTap});

  final List<String> tokens;
  final Function(String) onTokenTap;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: tokens.map((token) {
          final bool isPunctuation = RegExp(
            r'[^\w\s\u4e00-\u9faf\u3040-\u309f\u30a0-\u30ff]',
          ).hasMatch(token);

          return TextSpan(
            text: token,
            style: TextStyle(
              fontSize: 19,
              height: 1.8,
              color: isPunctuation
                  ? KaminariTheme.textSecondary.withAlpha(150)
                  : KaminariTheme.textPrimary,
              // Optional: slight underline or background for interactive parts
            ),
            recognizer: isPunctuation
                ? null
                : (TapGestureRecognizer()..onTap = () => onTokenTap(token)),
          );
        }).toList(),
      ),
    );
  }
}
