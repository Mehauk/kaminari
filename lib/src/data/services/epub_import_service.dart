import 'dart:io';

import 'package:epub_pro/epub_pro.dart'; // Modernized package import
import 'package:html/parser.dart' as html_parser;
import 'package:image/image.dart' as img;
import 'package:kaminari/src/data/models/book.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EpubImportService {
  const EpubImportService._();

  /// Unpacks an EPUB file, copies it to app storage, extracts metadata,
  /// saves cover images locally, parses chapters to raw paragraphs,
  /// and returns a populated [BookDetails] model.
  static Future<BookDetails> parseEpub(String originalFilePath) async {
    final file = File(originalFilePath);
    if (!await file.exists()) {
      throw Exception("Selected file does not exist.");
    }

    final bytes = await file.readAsBytes();
    final epubBook = await EpubReader.readBook(bytes);

    // Using epub_pro camelCase properties
    final title = epubBook.title ?? "Untitled Book";
    final author = epubBook.author ?? epubBook.authors.join(", ");
    final synopsis =
        epubBook.schema?.package?.metadata?.description ??
        "Local EPUB eBook file.";
    final rawLanguage =
        epubBook.schema?.package?.metadata?.languages.firstOrNull ?? "en";
    final language = rawLanguage.split(',').first.trim().toLowerCase();

    // 1. Copy the EPUB file to App Storage for persistent offline availability
    final savedEpubPath = await _copyEpubToAppStorage(
      originalFilePath,
      title,
      author,
    );

    // 2. Save Cover Image as a local PNG file if available
    String? localCoverPath;
    if (epubBook.coverImage != null) {
      localCoverPath = await _saveCoverImage(
        epubBook.coverImage!,
        title,
        author,
      );
    }

    // 3. Extract and flatten chapters recursively from the spine/TOC
    final List<EpubChapter> flatEpubChapters = [];
    _flattenChapters(epubBook.chapters, flatEpubChapters);

    final List<ChapterInfo> chapters = [];
    int totalCharCount = 0;

    for (int i = 0; i < flatEpubChapters.length; i++) {
      final epubChapter = flatEpubChapters[i];
      final paragraphs = _extractParagraphs(epubChapter.htmlContent ?? "");

      // Use index 0 (Chapter 1) to calculate character count for progress calculations
      if (i == 0) {
        totalCharCount = paragraphs.join().length;
      }

      chapters.add(
        ChapterInfo(
          number: i,
          title: epubChapter.title ?? "Chapter ${i + 1}",
          url: "epub://chapter/$i", // Virtual identifier instead of a web URL
          content: paragraphs,
        ),
      );
    }

    if (chapters.isEmpty) {
      throw Exception(
        "The selected EPUB does not contain any readable chapters.",
      );
    }

    return BookDetails(
      url: savedEpubPath, // Set URL to the persistent local file path
      source: "Local EPUB",
      title: title,
      author: author,
      synopsis: synopsis,
      chapters: chapters,
      coverUrl: localCoverPath,
      firstChapterCharCount: totalCharCount,
      language: language,
      bookType: BookType.lightNovel, // Default type
      accessedDate: DateTime.now().millisecondsSinceEpoch,
    );
  }

  static void _flattenChapters(
    List<EpubChapter> source,
    List<EpubChapter> target,
  ) {
    for (final chapter in source) {
      // Avoid adding chapter containers that possess neither text content nor titles
      final hasTitle =
          chapter.title != null && chapter.title!.trim().isNotEmpty;
      final hasContent =
          chapter.htmlContent != null && chapter.htmlContent!.trim().isNotEmpty;

      if (hasTitle || hasContent) {
        target.add(chapter);
      }
      if (chapter.subChapters.isNotEmpty) {
        _flattenChapters(chapter.subChapters, target);
      }
    }
  }

  static List<String> _extractParagraphs(String htmlContent) {
    if (htmlContent.trim().isEmpty) return [];
    final document = html_parser.parse(htmlContent);
    final body = document.body;
    if (body == null) return [];

    // Strip structural elements and noise
    body
        .querySelectorAll("script, style, link, svg")
        .forEach((el) => el.remove());

    final List<String> paragraphs = [];

    // Read blocks semantic to EPUB layouts
    final blocks = body.querySelectorAll(
      "p, li, h1, h2, h3, h4, h5, h6, dt, dd",
    );
    if (blocks.isNotEmpty) {
      for (final block in blocks) {
        final text = block.text.trim();
        if (text.isNotEmpty) {
          paragraphs.add(text);
        }
      }
    } else {
      // Fallback for flat unformatted files (split block texts by line breaks)
      final rawLines = body.text.split("\n");
      for (final line in rawLines) {
        final cleanLine = line.trim();
        if (cleanLine.isNotEmpty) {
          paragraphs.add(cleanLine);
        }
      }
    }

    return paragraphs;
  }

  static Future<String> _copyEpubToAppStorage(
    String sourcePath,
    String title,
    String author,
  ) async {
    final appDir = await getApplicationDocumentsDirectory();
    final epubsDir = Directory(p.join(appDir.path, "epubs"));
    if (!await epubsDir.exists()) {
      await epubsDir.create(recursive: true);
    }

    final safeTitle = title.replaceAll(RegExp(r'[^\w\s-]'), "").trim();
    final safeAuthor = author.replaceAll(RegExp(r'[^\w\s-]'), "").trim();
    final fileName =
        "${safeTitle}_${safeAuthor}_${DateTime.now().millisecondsSinceEpoch}.epub";
    final targetPath = p.join(epubsDir.path, fileName);

    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  static Future<String?> _saveCoverImage(
    img.Image coverImage,
    String title,
    String author,
  ) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory(p.join(appDir.path, "covers"));
      if (!await coversDir.exists()) {
        await coversDir.create(recursive: true);
      }

      final safeTitle = title.replaceAll(RegExp(r'[^\w\s-]'), "").trim();
      final safeAuthor = author.replaceAll(RegExp(r'[^\w\s-]'), "").trim();
      final fileName = "${safeTitle}_$safeAuthor.png";
      final targetPath = p.join(coversDir.path, fileName);

      final pngBytes = img.encodePng(coverImage);
      await File(targetPath).writeAsBytes(pngBytes);
      return targetPath;
    } catch (e) {
      print("[EpubImportService] Failed to encode or save cover image: $e");
      return null;
    }
  }
}
