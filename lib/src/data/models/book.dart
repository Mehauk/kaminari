// ignore_for_file: annotate_overrides

import 'package:freezed_annotation/freezed_annotation.dart';

part 'book.freezed.dart';
part 'book.g.dart';

enum BookType {
  all("All"),
  webNovel("Web Novel"),
  lightNovel("Light Novel"),
  shortStory("Short Story");

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
abstract class BookDetailsExtractor with _$BookDetailsExtractor {
  const factory BookDetailsExtractor({
    String? firstPageUrl,
    String? nextPageUrl,
    required String title,
    required String author,
    String? coverUrl,
    String? jlptLevel,
    required String synopsis,
    required ChapterInfoExtractor individualChapterDetails,
  }) = _BookDetailsExtractor;

  factory BookDetailsExtractor.fromJson(Map<String, dynamic> json) =>
      _$BookDetailsExtractorFromJson(json);

  static const schema = _$_BookDetailsExtractorJsonSchema;
}

@freezed
abstract class ChapterInfoExtractor with _$ChapterInfoExtractor {
  const factory ChapterInfoExtractor({
    required String base,
    required String url,
    required String title,
    String? updatedDate,
  }) = _ChapterInfoExtractor;

  factory ChapterInfoExtractor.fromJson(Map<String, dynamic> json) =>
      _$ChapterInfoExtractorFromJson(json);

  static const schema = _$_ChapterInfoExtractorJsonSchema;
}

@freezed
abstract class ChapterExtractor with _$ChapterExtractor {
  const factory ChapterExtractor({required String contentSections}) =
      _ChapterExtractor;

  factory ChapterExtractor.fromJson(Map<String, dynamic> json) =>
      _$ChapterExtractorFromJson(json);

  static const schema = _$_ChapterExtractorJsonSchema;
}

@freezed
abstract class BookDetails with _$BookDetails {
  const BookDetails._();

  const factory BookDetails({
    int? id,
    required String url,
    required String source,
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
    @Default(0) int firstChapterCharCount,
    @Default(false) bool isFavorite,
    @Default(false) bool synopsisExpanded,
  }) = _BookDetails;

  factory BookDetails.fromJson(Map<String, dynamic> json) =>
      _$BookDetailsFromJson(json);

  double progress(int currentChapter) =>
      chapters.isEmpty ? 0 : currentChapter / chapters.length;
}

@freezed
abstract class ChapterInfo with _$ChapterInfo {
  const factory ChapterInfo({
    int? id,
    required String url,
    required int number,
    required String title,
    String? updatedDate,
    List<String>? content,
    double? scrollPosition,
  }) = _ChapterInfo;

  factory ChapterInfo.fromJson(Map<String, dynamic> json) =>
      _$ChapterInfoFromJson(json);
}
