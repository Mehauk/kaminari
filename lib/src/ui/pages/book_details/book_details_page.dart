import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/book_details/book_details_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage({super.key, this.bookId});

  final String? bookId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookDetailsCubit(bookId: bookId),
      child: const _BookDetailsView(),
    );
  }
}

class _BookDetailsView extends StatelessWidget {
  const _BookDetailsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookDetailsCubit, BookDetailsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: KaminariTheme.background,
          body: CustomScrollView(
            slivers: [
              _CoverAppBar(state: state),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    _BookHeader(state: state),
                    const SizedBox(height: 24),
                    _ProgressSection(state: state),
                    const SizedBox(height: 24),
                    _StatsRow(state: state),
                    const SizedBox(height: 24),
                    _SynopsisSection(state: state),
                    const SizedBox(height: 24),
                    _ChapterList(state: state),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────
// Cover image sliver app bar
// ──────────────────────────────────────────────────────

class _CoverAppBar extends StatelessWidget {
  const _CoverAppBar({required this.state});

  final BookDetailsState state;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: KaminariTheme.background.withAlpha(225),
      leading: _DetailsAppbarIconButton(
        icon: Icons.arrow_back_ios_new,
        onpressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        _DetailsAppbarIconButton(
          icon: Icons.bookmark_border_rounded,
          onpressed: () => print(1),
        ),
        _DetailsAppbarIconButton(
          icon: Icons.more_vert_rounded,
          onpressed: () => print(2),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: .parallax,
        background: Stack(
          fit: .expand,
          children: [
            Image.network(
              state.coverUrl,
              fit: .cover,
              alignment: const Alignment(0, -0.2),
            ),

            // Bottom gradient fade
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .bottomCenter,
                  end: .topCenter,
                  stops: [0.0, 0.2, 0.9],
                  colors: [
                    KaminariTheme.background,
                    Color(0xCC15130B),
                    Color.fromARGB(0, 105, 21, 21),
                  ],
                ),
              ),
            ),
            // Top gradient fade (for status bar readability)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: .topCenter,
                  end: .bottomCenter,
                  stops: [0.0, 0.3],
                  colors: [Color(0x9915130B), Colors.transparent],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsAppbarIconButton extends StatelessWidget {
  const _DetailsAppbarIconButton({required this.icon, required this.onpressed});

  final IconData icon;
  final void Function() onpressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: .circular(KaminariTheme.borderRadius),
        child: BgFilter(
          bgColor: KaminariTheme.colorScheme.primaryContainer.withAlpha(30),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: .circular(KaminariTheme.borderRadius),
              border: LightningBorderEffectType.thin.border(),
            ),
            child: InkWell(
              onTap: onpressed,
              child: Padding(
                padding: EdgeInsets.all(10.0),
                child: Icon(icon, size: 20),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Title, author, genre chips
// ──────────────────────────────────────────────────────

class _BookHeader extends StatelessWidget {
  const _BookHeader({required this.state});

  final BookDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        // Japanese title
        CustomText(state.title, .titleMedium, fontSize: 22),
        const SizedBox(height: 4),
        // Romanized title
        CustomText(
          state.titleRomaji,
          .headlineMedium,
          color: KaminariTheme.textTitle,
        ),
        const SizedBox(height: 8),
        // Author
        Row(
          children: [
            Icon(
              CupertinoIcons.person_fill,
              size: 14,
              color: KaminariTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: CustomText(state.author, .bodyMedium, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Genre + JLPT chips
        Row(
          spacing: 8,
          children: [
            Chip(
              label: Text(state.bookType),
              labelStyle: TextStyle().copyWith(
                color: KaminariTheme.textSecondary,
              ),
              color: WidgetStatePropertyAll(KaminariTheme.surfaceVariant),
            ),
            _JlptBadge(level: state.jlptLevel),
          ],
        ),
      ],
    );
  }
}

class _JlptBadge extends StatelessWidget {
  const _JlptBadge({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: KaminariTheme.cyan.withAlpha(25),
        shape: const StadiumBorder(
          side: BorderSide(color: KaminariTheme.cyan, width: 1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        child: CustomText(
          'JLPT $level',
          .labelSmall,
          color: KaminariTheme.cyan,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Reading progress + CTA
// ──────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.state});

  final BookDetailsState state;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .glowing,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                CustomText('READING PROGRESS', .labelSmall),
                CustomText(
                  '${(state.progress * 100).toStringAsFixed(0)}%',
                  .labelSmall,
                  color: KaminariTheme.textTitle,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: state.progress),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  CupertinoIcons.book_fill,
                  size: 13,
                  color: KaminariTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: CustomText(
                    state.currentChapter,
                    .bodyMedium,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CustomText(
              'Page ${state.currentPage} of ${state.totalPages}',
              .labelSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: const Text('CONTINUE READING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Stats row: words, time, level
// ──────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final BookDetailsState state;

  @override
  Widget build(BuildContext context) {
    final hours = state.estimatedMinutes ~/ 60;
    final mins = state.estimatedMinutes % 60;
    final timeLabel = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Row(
      children: [
        _StatTile(
          icon: Icons.text_fields_rounded,
          value: '${(state.totalWordCount / 1000).toStringAsFixed(1)}k',
          label: 'Words',
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.timer_outlined,
          value: timeLabel,
          label: 'Est. Read',
        ),
        const SizedBox(width: 12),
        _StatTile(
          icon: Icons.translate_rounded,
          value: state.jlptLevel,
          label: 'JLPT',
          valueColor: KaminariTheme.cyan,
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: LightningCard(
        type: .thin,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Column(
            children: [
              Icon(icon, size: 18, color: KaminariTheme.textSecondary),
              const SizedBox(height: 6),
              CustomText(
                value,
                .headlineMedium,
                fontSize: 18,
                color: valueColor ?? KaminariTheme.textTitle,
              ),
              const SizedBox(height: 2),
              CustomText(label, .labelSmall, fontSize: 11),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Synopsis with expand/collapse
// ──────────────────────────────────────────────────────

class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.state});

  final BookDetailsState state;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .striking,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 16,
                  color: KaminariTheme.textTitle,
                ),
                const SizedBox(width: 8),
                CustomText('Synopsis', .headlineMedium, fontSize: 16),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: state.synopsisExpanded ? .showSecond : .showFirst,
              firstChild: Text(
                state.synopsis,
                maxLines: 4,
                overflow: .ellipsis,
                style: TextTheme.of(context).bodyMedium?.copyWith(fontSize: 14),
              ),
              secondChild: Text(
                state.synopsis,
                style: TextTheme.of(context).bodyMedium?.copyWith(fontSize: 14),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => context.read<BookDetailsCubit>().toggleSynopsis(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    state.synopsisExpanded ? 'Show less' : 'Show more',
                    .labelSmall,
                    color: KaminariTheme.textTitle,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    state.synopsisExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: KaminariTheme.textTitle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Chapter list
// ──────────────────────────────────────────────────────

class _ChapterList extends StatelessWidget {
  const _ChapterList({required this.state});

  final BookDetailsState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          children: [
            Icon(
              Icons.list_alt_rounded,
              size: 16,
              color: KaminariTheme.textTitle,
            ),
            const SizedBox(width: 8),
            CustomText('Chapters', .headlineMedium, fontSize: 16),
            const Spacer(),
            CustomText('${state.chapters.length} total', .labelSmall),
          ],
        ),
        const SizedBox(height: 12),
        LightningCard(
          type: .thin,
          child: Column(
            children: [
              for (int i = 0; i < state.chapters.length; i++) ...[
                _ChapterTile(
                  chapter: state.chapters[i],
                  isCurrent: state.chapters[i].title == state.currentChapter,
                ),
                if (i < state.chapters.length - 1)
                  Divider(
                    height: 1,
                    color: KaminariTheme.surfaceTint.withAlpha(20),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.chapter, required this.isCurrent});

  final ChapterInfo chapter;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Chapter number badge
            SizedBox(
              width: 36,
              child: CustomText(
                '${chapter.number}'.padLeft(2, '0'),
                .labelSmall,
                color: isCurrent
                    ? KaminariTheme.textTitle
                    : KaminariTheme.textSecondary.withAlpha(120),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText(
                    chapter.title,
                    .bodyMedium,
                    fontSize: 14,
                    color: isCurrent ? KaminariTheme.textPrimary : null,
                  ),
                  if (chapter.wordCount > 0) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      '~${(chapter.wordCount / 1000).toStringAsFixed(1)}k words',
                      .labelSmall,
                      fontSize: 11,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (isCurrent)
              Container(
                padding: const .symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: KaminariTheme.textTitle.withAlpha(30),
                  borderRadius: .circular(6),
                  border: Border.all(
                    color: KaminariTheme.textTitle.withAlpha(80),
                  ),
                ),
                child: CustomText(
                  'CURRENT',
                  .labelSmall,
                  fontSize: 9,
                  color: KaminariTheme.textTitle,
                ),
              )
            else if (chapter.isRead)
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: KaminariTheme.surfaceTint.withAlpha(180),
              )
            else
              Icon(
                Icons.circle_outlined,
                size: 16,
                color: KaminariTheme.textSecondary.withAlpha(80),
              ),
          ],
        ),
      ),
    );
  }
}
