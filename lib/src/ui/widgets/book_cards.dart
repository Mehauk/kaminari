import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/pages/book_details/book_details_page.dart';
import 'package:kaminari/src/pages/reader/reader.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/utils/date_extensions.dart';

class LastReadBookCard extends StatelessWidget {
  const LastReadBookCard(this.book, {super.key});

  final BookDetails book;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .glowing,
      innerShadow: [
        BoxShadow(
          color: KaminariTheme.surfaceTint.withAlpha(30),
          blurRadius: 10,
          offset: const Offset(1, 1),
        ),
      ],
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => BookDetailsPage(book))),
        child: Column(
          children: [
            Stack(
              alignment: AlignmentGeometry.bottomStart,
              children: [
                Image.network(
                  book.coverUrl ?? '',
                  alignment: Alignment(0, -0.2),
                  fit: BoxFit.cover,
                  width: double.maxFinite,
                  height: 192,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/placeholder_book.png',
                    alignment: Alignment(0, -0.2),
                    fit: BoxFit.cover,
                    width: double.maxFinite,
                    height: 192,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentGeometry.bottomCenter,
                      end: AlignmentGeometry.topCenter,
                      colors: [
                        KaminariTheme.background,
                        KaminariTheme.background.withAlpha(128),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SizedBox(height: 192, width: double.maxFinite),
                ),
                Positioned(
                  left: 20,
                  top: 12,
                  child: Chip(label: Text(book.bookType.text)),
                ),
                Padding(
                  padding: const .symmetric(horizontal: 24, vertical: 4),
                  child: CustomText(book.title, .headlineMedium),
                ),
              ],
            ),
            Padding(
              padding: const .fromLTRB(24, 4, 24, 24),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText(
                    book.chapters[book.currentChapter].title,
                    .bodyLarge,
                  ),
                  SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: .min,
                          children: [
                            Row(
                              mainAxisAlignment: .spaceBetween,
                              crossAxisAlignment: .start,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    "READING PROGRESS",
                                    .labelSmall,
                                  ),
                                ),
                                SizedBox(width: 8),

                                CustomText(
                                  "${(book.progress(book.currentChapter) * 100).toInt()}%",
                                  .labelSmall,
                                  color: KaminariTheme.textTitle,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: book.progress(book.currentChapter),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      FilledButton(
                        onPressed: () async {
                          final db = context.read<DatabaseService>();
                          final currentChapter = await db.getBookCurrentChapter(
                            book.id!,
                          );
                          final fullChapter = await db.getChapterWithContent(
                            book.chapters[currentChapter].id!,
                          );
                          if (context.mounted) {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    ReaderPage(fullChapter!, bookId: book.id!),
                              ),
                            );
                          }
                        },
                        child: Row(children: [Text("Continue")]),
                      ),
                    ],
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

class HistoryBookCard extends StatelessWidget {
  const HistoryBookCard(this.book, {super.key});

  final BookDetails book;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .thin,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => BookDetailsPage(book))),
        child: Padding(
          padding: .all(16),
          child: Row(
            spacing: 16,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: LightningBorderEffectType.glowing.border(),
                  borderRadius: .circular(KaminariTheme.borderRadius),
                ),
                position: .foreground,
                child: ClipRRect(
                  borderRadius: .circular(KaminariTheme.borderRadius),
                  child: Image.network(
                    book.coverUrl ?? '',
                    width: 64,
                    height: 80,
                    fit: .cover,
                    errorBuilder: (context, error, stackTrace) => Image.asset(
                      'assets/images/placeholder_book.png',
                      width: 64,
                      height: 80,
                      fit: .cover,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(book.title, .titleMedium),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14),
                        SizedBox(width: 4),
                        CustomText(
                          book.accessedDate.toDateStringPrefRelative,
                          .labelSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.book, size: 14),
                        SizedBox(width: 4),
                        CustomText(
                          "chapter ${book.currentChapter + 1} / ${book.chapters.length}",
                          .labelSmall,
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: book.progress(book.currentChapter),
                    ),
                  ],
                ),
              ),
              Column(
                spacing: 24,
                children: [
                  Icon(Icons.bookmark_border_rounded),
                  Icon(Icons.more_vert),
                  SizedBox(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DiscoverableBookCard extends StatelessWidget {
  const DiscoverableBookCard(this.book, {super.key});

  final BookDetails book;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .thin,
      child: InkWell(
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (context) => BookDetailsPage(book))),
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  book.coverUrl ?? '',
                  alignment: Alignment(0, -0.2),
                  fit: BoxFit.cover,
                  width: double.maxFinite,
                  height: 192,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/placeholder_book.png',
                    alignment: Alignment(0, -0.2),
                    fit: BoxFit.cover,
                    width: double.maxFinite,
                    height: 192,
                  ),
                ),
                Padding(
                  padding: .all(12),
                  child: ClipPath(
                    clipper: ShapeBorderClipper(shape: StadiumBorder()),
                    child: BgFilter(
                      bgColor: KaminariTheme.surfaceTint.withAlpha(65),
                      child: Padding(
                        padding: .symmetric(horizontal: 24, vertical: 4),
                        child: Text(
                          book.bookType.short,
                          style: TextStyle().copyWith(
                            fontSize: 14,
                            color: KaminariTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const .fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: .start,
                children: [
                  CustomText(
                    book.title,
                    .headlineMedium,
                    fontSize: 14,
                    color: Colors.white,
                    fontWeight: .w300,
                  ),
                  SizedBox(height: 4),
                  CustomText(
                    book.author,
                    .titleMedium,
                    fontSize: 12,
                    fontWeight: .w300,
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
