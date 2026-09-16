import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/data/services/stats_service.dart';
import 'package:kaminari/src/pages/home/prep/prep_cards.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/book_cards.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = context.read<DatabaseService>();
    return SingleChildScrollView(
      child: Column(
        children: [
          LightningAppBar(),
          Padding(
            padding: const .symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(height: 16),
                FutureBuilder(
                  future: Future.wait([
                    Future.value(StatsService.getDailyStreak()),
                    KanjiService.getNumberVisited(),
                  ]),
                  builder: (context, AsyncSnapshot<List<int>> snapshot) {
                    final streak = snapshot.data?[0] ?? 0;
                    final words = snapshot.data?[1] ?? 0;

                    return Row(
                      children: [
                        Expanded(
                          child: _InfoTile("DAILY STREAK", ("$streak", "days")),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _InfoTile("WORDS LEARNED", ("$words", "")),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 32),
                StreamBuilder<void>(
                  stream: dbService.onBooksChanged,
                  builder: (context, _) {
                    return FutureBuilder<BookDetails?>(
                      future: dbService.getLastAccessedBook(),
                      builder: (context, snapshot) {
                        final book = snapshot.data;
                        if (book != null) {
                          final nextChapter =
                              book.chapters[book.currentChapter];
                          return Column(
                            children: [
                              LastReadBookCard(book),
                              ReviewPrepCard(
                                nextChapter: nextChapter,
                                book: book,
                              ),
                            ],
                          );
                        } else {
                          return _PlaceholderBookCard(
                            isLoading: snapshot.connectionState == .waiting,
                          );
                        }
                      },
                    );
                  },
                ),
                SizedBox(height: 32),
                StreamBuilder<void>(
                  stream: dbService.onBooksChanged,
                  builder: (context, _) {
                    return FutureBuilder<List<BookDetails>>(
                      future: dbService.getHistoryBooks(),
                      builder: (context, snapshot) {
                        final history = snapshot.data ?? [];
                        final extraHistory = history.skip(1).take(2).toList();

                        if (extraHistory.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText(
                                "RECENT READING HISTORY",
                                TextType.labelSmall,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...extraHistory.map((book) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: HistoryBookCard(
                                  book,
                                  onFavoriteToggle: () async {
                                    if (book.id != null) {
                                      await dbService.updateBookFavorite(
                                        book.id!,
                                        !book.isFavorite,
                                      );
                                      dbService.notifyBooksChanged();
                                    }
                                  },
                                ),
                              );
                            }),
                          ],
                        );
                      },
                    );
                  },
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderBookCard extends StatelessWidget {
  const _PlaceholderBookCard({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: LightningBorderEffectType.thin,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Stack(
          children: [
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 48,
                    color: KaminariTheme.textSecondary,
                  ),
                  SizedBox(height: 16),
                  CustomText("No recent activity", TextType.bodyMedium),
                ],
              ),
            ),
            if (isLoading)
              BgFilter(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.title, this.headline);

  final String title;
  final (String, String) headline;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .thin,
      child: Padding(
        padding: const .all(KaminariTheme.borderRadius),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            CustomText(title, .labelSmall),
            SizedBox(height: 6),
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    text: "${headline.$1} ",
                    style: TextTheme.of(
                      context,
                    ).headlineLarge?.copyWith(color: KaminariTheme.textTitle),
                    children: [
                      TextSpan(
                        text: "${headline.$2} ",
                        style: TextTheme.of(
                          context,
                        ).labelMedium?.copyWith(color: KaminariTheme.textTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
