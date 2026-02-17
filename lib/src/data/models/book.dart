// ignore_for_file: annotate_overrides

import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';

enum BookType {
  all("All"),
  webNovel("Web Novels"),
  lightNovel("Light Novels"),
  shortStory("Short Stories");

  final String text;
  const BookType(this.text);

  String get short => switch (this) {
    BookType.all => text,
    BookType.webNovel => "WEB",
    BookType.lightNovel => "LN",
    BookType.shortStory => "SS",
  };
}

@freezed
class ChapterInfo with _$ChapterInfo {
  const ChapterInfo({
    required this.number,
    required this.title,
    required this.isRead,
    this.wordCount = 0,
  });

  final int number;
  final String title;
  final bool isRead;
  final int wordCount;
}

@freezed
class BookDetails with _$BookDetails {
  const BookDetails({
    required this.id,
    required this.title,
    required this.titleRomaji,
    required this.author,
    required this.coverUrl,
    required this.bookType,
    required this.jlptLevel,
    required this.synopsis,
    required this.totalPages,
    required this.currentPage,
    required this.currentChapter,
    required this.chapters,
    required this.totalWordCount,
    required this.estimatedMinutes,
    this.synopsisExpanded = false,
  });

  final String id;
  final String title;
  final String titleRomaji;
  final String author;
  final String coverUrl;
  final String bookType;
  final String jlptLevel;
  final String synopsis;
  final int totalPages;
  final int currentPage;
  final String currentChapter;
  final List<ChapterInfo> chapters;
  final int totalWordCount;
  final int estimatedMinutes;
  final bool synopsisExpanded;

  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;
}
