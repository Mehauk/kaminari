import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/app.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/pages/book_details/book_details_cubit.dart';
import 'package:kaminari/src/pages/reader/reader.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class BookDetailsPage extends StatelessWidget {
  const BookDetailsPage(this.book, {super.key});

  final BookDetails book;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BookDetailsCubit(book, dbService: context.read()),
      child: _BookDetailsView(),
    );
  }
}

class _BookDetailsView extends StatefulWidget {
  const _BookDetailsView();

  @override
  State<_BookDetailsView> createState() => _BookDetailsViewState();
}

class _BookDetailsViewState extends State<_BookDetailsView> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 4. Subscribe this page to the route observer
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    // 5. Always unsubscribe on dispose
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 6. This is the "Lifecycle Hook" you are looking for!
  // It triggers when the top route (the Reader) is popped and this page becomes visible.
  @override
  void didPopNext() {
    context.read<BookDetailsCubit>().refreshProgress();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookDetailsCubit>();
    return Scaffold(
      backgroundColor: KaminariTheme.background,
      body: CustomScrollView(
        slivers: [
          const _CoverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                RepaintBoundary(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const _BookHeader(),
                      const SizedBox(height: 24),
                      const _ProgressSection(),
                      const SizedBox(height: 24),
                      const _StatsRow(),
                      const SizedBox(height: 24),
                      const _SynopsisSection(),
                      const SizedBox(height: 24),
                      const _ChapterListHeader(),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          SliverFixedExtentList.list(
            itemExtent: 50,
            children: cubit.book.chapters
                .map(
                  (c) => _ChapterTile(
                    chapter: c,
                    current: cubit.state.currentChapter,
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Cover image sliver app bar
// ──────────────────────────────────────────────────────

class _CoverAppBar extends StatelessWidget {
  const _CoverAppBar();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookDetailsCubit>();
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: KaminariTheme.background.withAlpha(225),
      leading: LightningIconButton(
        icon: Icons.arrow_back_ios_new,
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        LightningIconButton(
          icon: Icons.bookmark_border_rounded,
          onPressed: () => print(1),
        ),
        LightningIconButton(
          icon: Icons.more_vert_rounded,
          onPressed: () => print(2),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: .parallax,
        background: Stack(
          fit: .expand,
          children: [
            Image.network(
              cubit.book.coverUrl ?? '',
              fit: .cover,
              alignment: const Alignment(0, -0.2),
              errorBuilder: (context, error, stackTrace) => Image.asset(
                'assets/images/placeholder_book.png',
                alignment: Alignment(0, -0.2),
                fit: BoxFit.cover,
                width: double.maxFinite,
                height: 192,
              ),
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

// ──────────────────────────────────────────────────────
// Title, author, genre chips
// ──────────────────────────────────────────────────────

class _BookHeader extends StatelessWidget {
  const _BookHeader();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookDetailsCubit>();
    return Column(
      crossAxisAlignment: .start,
      children: [
        // title
        CustomText(cubit.book.title, .titleMedium, fontSize: 22),
        // const SizedBox(height: 4),
        // // alt title
        // CustomText(
        //   cubit.book.titleRomaji,
        //   .headlineMedium,
        //   color: KaminariTheme.textTitle,
        // ),
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
              child: CustomText(cubit.book.author, .bodyMedium, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Genre + JLPT chips
        Row(
          children: [
            Chip(
              label: Text(cubit.book.bookType.text),
              labelStyle: const TextStyle().copyWith(
                color: KaminariTheme.textSecondary,
              ),
              color: const WidgetStatePropertyAll(KaminariTheme.surfaceVariant),
            ),
            const SizedBox(width: 8),
            _JlptBadge(level: cubit.book.jlptLevel ?? 'N/A'),
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
  const _ProgressSection();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookDetailsCubit>();
    return LightningCard(
      type: .glowing,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText('READING PROGRESS', .labelSmall),
                CustomText(
                  '${(cubit.book.progress * 100).toStringAsFixed(0)}%',
                  .labelSmall,
                  color: KaminariTheme.textTitle,
                ),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: cubit.book.progress),
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
                    cubit.book.chapters[cubit.state.currentChapter].title,
                    .bodyMedium,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            CustomText(
              'Chapter ${cubit.state.currentChapter + 1} of ${cubit.book.chapters.length}',
              .labelSmall,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  final fullChapter = await context
                      .read<DatabaseService>()
                      .getChapterWithContent(
                        cubit.book.chapters[cubit.state.currentChapter].id!,
                      );
                  if (context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            ReaderPage(fullChapter!, bookId: cubit.book.id!),
                      ),
                    );
                  }
                },
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
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookDetailsCubit>();
    final hours = 0 ~/ 60;
    final mins = 0 % 60;
    final timeLabel = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Row(
      children: [
        _StatTile(
          icon: Icons.text_fields_rounded,
          value: '${(0 / 1000).toStringAsFixed(1)}k',
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
          value: cubit.book.jlptLevel ?? 'N/A',
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
  const _SynopsisSection();

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<BookDetailsCubit>();
    final state = cubit.state;
    return GestureDetector(
      onTap: () => context.read<BookDetailsCubit>().toggleSynopsis(),

      child: LightningCard(
        type: .striking,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              Text(
                cubit.book.synopsis,
                maxLines: state.synopsisExpanded ? null : 4,
                overflow: state.synopsisExpanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 10),
              Row(
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
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────
// Chapter list
// ──────────────────────────────────────────────────────

class _ChapterListHeader extends StatelessWidget {
  const _ChapterListHeader();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<BookDetailsCubit>();
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
            CustomText('${cubit.book.chapters.length} total', .labelSmall),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ChapterTile extends StatelessWidget {
  const _ChapterTile({required this.chapter, required this.current});

  final ChapterInfo chapter;
  final int current;

  @override
  Widget build(BuildContext context) {
    final bool isCurrent = current == chapter.number;
    return InkWell(
      onTap: () async {
        final bookId = context.read<BookDetailsCubit>().book.id!;
        final db = context.read<DatabaseService>();

        final fullChapter = await db.getChapterWithContent(chapter.id!);

        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              // 2. Use '_' to signify we aren't using the route's context
              builder: (_) => ReaderPage(fullChapter!, bookId: bookId),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Chapter number badge
            SizedBox(
              width: 36,
              child: CustomText(
                '${chapter.number + 1}'.padLeft(2, '0'),
                .labelSmall,
                color: isCurrent
                    ? KaminariTheme.textTitle
                    : KaminariTheme.textSecondary.withAlpha(120),
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomText(
                chapter.title,
                .bodyMedium,
                fontSize: 14,
                color: isCurrent ? KaminariTheme.textPrimary : null,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            if (isCurrent)
              Icon(Icons.circle, size: 16, color: KaminariTheme.textTitle)
            else if (chapter.number < current)
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
