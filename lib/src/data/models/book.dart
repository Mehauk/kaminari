// ignore_for_file: annotate_overrides

import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

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
abstract class ChapterInfoBase with _$ChapterInfoBase {
  const factory ChapterInfoBase({
    required String url,
    required int number,
    required String title,
    String? updatedDate,
  }) = _ChapterInfoBase;

  factory ChapterInfoBase.fromJson(Map<String, dynamic> json) =>
      _$ChapterInfoBaseFromJson(json);

  static const schema = _$_ChapterInfoBaseJsonSchema;
}

@freezed
abstract class ChapterInfo with _$ChapterInfo {
  const factory ChapterInfo({
    required String url,
    required int number,
    required String title,
    String? updatedDate,
  }) = _ChapterInfo;

  factory ChapterInfo.fromJson(Map<String, dynamic> json) =>
      _$ChapterInfoFromJson(json);
}

@freezed
abstract class BookDetailsBase with _$BookDetailsBase {
  const BookDetailsBase._();

  const factory BookDetailsBase({
    required String url,
    String? nextPageUrl,
    required String title,
    required String author,
    required String coverUrl,
    required String jlptLevel,
    required String synopsis,
    required List<ChapterInfoBase> chapters,
  }) = _BookDetailsBase;

  factory BookDetailsBase.fromJson(Map<String, dynamic> json) =>
      _$BookDetailsBaseFromJson(json);

  static const schema = _$_BookDetailsBaseJsonSchema;
}

@freezed
abstract class BookDetails with _$BookDetails {
  const BookDetails._();

  const factory BookDetails({
    required String url,
    required String title,
    required String author,
    required String synopsis,
    required List<ChapterInfo> chapters,
    String? coverUrl,
    String? jlptLevel,
    String? updatedDate,
    int? accessedDate,
    @Default(BookType.webNovel) BookType bookType,
    @Default(0) int currentChapter,
    @Default(false) bool synopsisExpanded,
  }) = _BookDetails;

  factory BookDetails.fromJson(Map<String, dynamic> json) =>
      _$BookDetailsFromJson(json);

  double get progress =>
      chapters.isEmpty ? 0 : currentChapter / chapters.length;
}
