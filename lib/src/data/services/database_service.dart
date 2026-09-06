import 'dart:async';
import 'dart:io';

import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/ui/widgets/book_cover.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;
  final StreamController<void> _booksChangeController =
      StreamController<void>.broadcast();

  Stream<void> get onBooksChanged => _booksChangeController.stream;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    _notifyChange();
    return _db!;
  }

  Future<Database> _initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'kaminari.db');

    return await openDatabase(
      path,
      version: 11, // Upgraded from 10
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  void _notifyChange() {
    try {
      if (!_booksChangeController.isClosed) _booksChangeController.add(null);
    } catch (_) {}
  }

  void notifyBooksChanged() {
    _notifyChange();
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 6) {
      await db.execute(
        'ALTER TABLE BookDetails ADD COLUMN isFavorite INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE BookDetails ADD COLUMN firstChapterCharCount INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 9) {
      await db.execute(
        'ALTER TABLE BookDetails ADD COLUMN language TEXT NOT NULL DEFAULT "ja"',
      );
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE BookAnalysisCache (
          book_id INTEGER PRIMARY KEY,
          chapter_id INTEGER NOT NULL,
          json_data TEXT NOT NULL,
          last_accessed INTEGER NOT NULL,
          FOREIGN KEY (book_id) REFERENCES BookDetails (id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 11) {
      // 1. Add prepReviewedCount column to ChapterInfo
      await db.execute(
        'ALTER TABLE ChapterInfo ADD COLUMN prepReviewedCount INTEGER DEFAULT 0',
      );
      // 2. Recreate BookAnalysisCache to fix its primary key constraint (chapter_id should be PK)
      await db.execute('DROP TABLE IF EXISTS BookAnalysisCache');
      await db.execute('''
        CREATE TABLE BookAnalysisCache (
          chapter_id INTEGER PRIMARY KEY,
          book_id INTEGER NOT NULL,
          json_data TEXT NOT NULL,
          last_accessed INTEGER NOT NULL,
          FOREIGN KEY (book_id) REFERENCES BookDetails (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  static Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE BookDetails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL,
        source TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        synopsis TEXT NOT NULL,
        coverUrl TEXT,
        jlptLevel TEXT,
        language TEXT NOT NULL DEFAULT 'en',
        updatedDate TEXT,
        accessedDate INTEGER,
        bookType TEXT NOT NULL,
        currentChapterIndex INTEGER DEFAULT 0,
        firstChapterCharCount INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        UNIQUE(title, source, author, bookType)
      )
    ''');

    await db.execute('''
      CREATE TABLE ChapterInfo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        book_id INTEGER NOT NULL,
        content_id INTEGER,
        title TEXT NOT NULL,
        url TEXT NOT NULL,
        wordCount INTEGER,
        chapterNumber INTEGER NOT NULL,
        scrollPosition REAL DEFAULT 0,
        prepReviewedCount INTEGER DEFAULT 0,
        UNIQUE(book_id, chapterNumber),
        FOREIGN KEY (book_id) REFERENCES BookDetails (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ChapterSection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES ChapterInfo (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE BookAnalysisCache (
        chapter_id INTEGER PRIMARY KEY,
        book_id INTEGER NOT NULL,
        json_data TEXT NOT NULL,
        last_accessed INTEGER NOT NULL,
        FOREIGN KEY (book_id) REFERENCES BookDetails (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<List<BookDetails>> getBooks() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, b.currentChapterIndex AS currentChapter, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title, 
             c.chapterNumber AS ch_number, c.scrollPosition, c.prepReviewedCount AS ch_prepReviewedCount
      FROM BookDetails b
      LEFT JOIN ChapterInfo c ON b.id = c.book_id
      ORDER BY b.id, c.chapterNumber ASC
    ''');

    final Map<int, Map<String, dynamic>> booksMap = {};

    for (final row in rows) {
      final bookId = row['id'] as int;

      if (!booksMap.containsKey(bookId)) {
        booksMap[bookId] = {
          ...row,
          'isFavorite': (row['isFavorite'] as int?) == 1,
          'chapters': [],
        };
      }

      if (row['ch_id'] != null) {
        final chapter = {
          "id": row['ch_id'] as int,
          "url": row['ch_url'] as String,
          "number": row['ch_number'] as int,
          "title": row['ch_title'] as String,
          "scrollPosition": row['scrollPosition'] as double?,
          "prepReviewedCount": row['ch_prepReviewedCount'] as int? ?? 0,
        };
        booksMap[bookId]!["chapters"].add(chapter);
      }
    }

    final showArchived = LocalStorageService().getData('show_archived') == true;
    final booksList = booksMap.values
        .map((m) => BookDetails.fromJson(m))
        .toList();
    if (showArchived) {
      return booksList;
    } else {
      return booksList
          .where(
            (b) => LocalStorageService().getData('archived_${b.id}') != true,
          )
          .toList();
    }
  }

  Future<List<BookDetails>> getHistoryBooks() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, b.currentChapterIndex AS currentChapter, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title, 
             c.chapterNumber AS ch_number, c.scrollPosition, c.prepReviewedCount AS ch_prepReviewedCount
      FROM BookDetails b
      LEFT JOIN ChapterInfo c ON b.id = c.book_id
      WHERE b.accessedDate IS NOT NULL
      ORDER BY b.accessedDate DESC
    ''');

    final Map<int, Map<String, dynamic>> booksMap = {};

    for (final row in rows) {
      final bookId = row['id'] as int;
      if (!booksMap.containsKey(bookId)) {
        booksMap[bookId] = {
          ...row,
          'isFavorite': (row['isFavorite'] as int?) == 1,
          'chapters': [],
        };
      }
      if (row['ch_id'] != null) {
        booksMap[bookId]!["chapters"].add({
          "id": row['ch_id'] as int,
          "url": row['ch_url'] as String,
          "number": row['ch_number'] as int,
          "title": row['ch_title'] as String,
          "scrollPosition": row['scrollPosition'] as double?,
          "prepReviewedCount": row['ch_prepReviewedCount'] as int? ?? 0,
        });
      }
    }

    final showArchived = LocalStorageService().getData('show_archived') == true;
    final booksList = booksMap.values
        .map((m) => BookDetails.fromJson(m))
        .toList();
    if (showArchived) {
      return booksList;
    } else {
      return booksList
          .where(
            (b) => LocalStorageService().getData('archived_${b.id}') != true,
          )
          .toList();
    }
  }

  Future<ChapterInfo?> getChapterWithContent(int chapterId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT c.id, c.book_id, c.title, c.url, c.chapterNumber AS number, s.content, c.scrollPosition, c.prepReviewedCount
      FROM ChapterInfo c
      LEFT JOIN ChapterSection s ON c.id = s.chapter_id
      WHERE c.id = ?
      ORDER BY s.id ASC
    ''',
      [chapterId],
    );

    if (rows.isEmpty) return null;

    final content = rows
        .where((r) => r['content'] != null)
        .map((r) => r['content'] as String)
        .toList();

    return ChapterInfo.fromJson({...rows.first, 'content': content});
  }

  Future<BookDetails?> getLastAccessedBook() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT *, currentChapterIndex AS currentChapter FROM BookDetails
      WHERE accessedDate IS NOT NULL
      ORDER BY accessedDate DESC
    ''');

    if (rows.isEmpty) return null;

    final showArchived = LocalStorageService().getData('show_archived') == true;

    Map<String, dynamic>? activeBookRow;
    for (final row in rows) {
      final bookId = row['id'] as int;
      final isArchived =
          LocalStorageService().getData('archived_$bookId') == true;
      if (showArchived || !isArchived) {
        activeBookRow = row;
        break;
      }
    }

    if (activeBookRow == null) return null;

    final bookId = activeBookRow['id'] as int;

    final chapterRows = await db.rawQuery(
      '''
      SELECT c.id, c.book_id, c.title, c.url, c.chapterNumber AS number, c.prepReviewedCount FROM ChapterInfo c
      WHERE book_id = ? 
      ORDER BY chapterNumber ASC
    ''',
      [bookId],
    );

    final bookMap = Map<String, dynamic>.from(activeBookRow);
    bookMap['isFavorite'] = (bookMap['isFavorite'] as int?) == 1;
    bookMap['chapters'] = chapterRows;

    return BookDetails.fromJson(bookMap);
  }

  Future<void> updateBookAccess(int bookId, int currentChapter) async {
    final db = await database;
    await db.update(
      'BookDetails',
      {
        'accessedDate': DateTime.now().millisecondsSinceEpoch,
        'currentChapterIndex': currentChapter,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
    _notifyChange();
  }

  Future<void> updateBookFavorite(int bookId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'BookDetails',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [bookId],
    );
    _notifyChange();
  }

  Future<BookDetails?> getBook(int bookId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT b.*, b.currentChapterIndex AS currentChapter, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title,
             c.chapterNumber AS ch_number, c.scrollPosition, c.prepReviewedCount AS ch_prepReviewedCount
      FROM BookDetails b
      LEFT JOIN ChapterInfo c ON b.id = c.book_id
      WHERE b.id = ?
      ORDER BY c.chapterNumber ASC
    ''',
      [bookId],
    );

    if (rows.isEmpty) return null;

    final bookMap = Map<String, dynamic>.from(rows.first);
    bookMap['isFavorite'] = (bookMap['isFavorite'] as int?) == 1;
    bookMap['chapters'] = rows
        .where((row) => row['ch_id'] != null)
        .map(
          (row) => {
            'id': row['ch_id'] as int,
            'url': row['ch_url'] as String,
            'number': row['ch_number'] as int,
            'title': row['ch_title'] as String,
            'scrollPosition': row['scrollPosition'] as double?,
            'prepReviewedCount': row['ch_prepReviewedCount'] as int? ?? 0,
          },
        )
        .toList();

    return BookDetails.fromJson(bookMap);
  }

  Future<void> updateChapterScrollPosition(
    int chapterId,
    double position,
  ) async {
    final db = await database;
    await db.update(
      'ChapterInfo',
      {'scrollPosition': position},
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  Future<void> updateChapterPrepProgress(int chapterId, int progress) async {
    final db = await database;
    await db.update(
      'ChapterInfo',
      {'prepReviewedCount': progress},
      where: 'id = ?',
      whereArgs: [chapterId],
    );
    _notifyChange();
  }

  Future<void> saveBook(BookDetails book) async {
    final db = await database;
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> existingBooks = await txn.query(
        'BookDetails',
        where: 'title = ? AND source = ? AND author = ? AND bookType = ?',
        whereArgs: [book.title, book.source, book.author, book.bookType.name],
      );

      int bookId;
      if (existingBooks.isNotEmpty) {
        bookId = existingBooks.first['id'] as int;
        await txn.update(
          'BookDetails',
          {
            'url': book.url,
            'synopsis': book.synopsis,
            'coverUrl': book.coverUrl,
            'jlptLevel': book.jlptLevel,
            'language': book.language,
            'updatedDate': book.updatedDate,
            'firstChapterCharCount': book.firstChapterCharCount,
          },
          where: 'id = ?',
          whereArgs: [bookId],
        );
      } else {
        bookId = await txn.insert('BookDetails', {
          'url': book.url,
          'source': book.source,
          'title': book.title,
          'author': book.author,
          'synopsis': book.synopsis,
          'coverUrl': book.coverUrl,
          'jlptLevel': book.jlptLevel,
          'language': book.language,
          'bookType': book.bookType.name,
          'firstChapterCharCount': book.firstChapterCharCount,
          'isFavorite': book.isFavorite ? 1 : 0,
        });
      }

      for (var chapter in book.chapters) {
        final List<Map<String, dynamic>> existingChapters = await txn.query(
          'ChapterInfo',
          where: 'book_id = ? AND (url = ? OR chapterNumber = ?)',
          whereArgs: [bookId, chapter.url, chapter.number],
        );

        if (existingChapters.isEmpty) {
          final chapterId = await txn.insert('ChapterInfo', {
            'book_id': bookId,
            'title': chapter.title,
            'url': chapter.url,
            'chapterNumber': chapter.number,
            'scrollPosition': 0,
            'prepReviewedCount': chapter.prepReviewedCount,
          });

          if (chapter.content != null) {
            for (var section in chapter.content!) {
              await txn.insert('ChapterSection', {
                'chapter_id': chapterId,
                'content': section,
              });
            }
          }
        } else {
          int existingId = existingChapters.first['id'] as int;
          await txn.update(
            'ChapterInfo',
            {
              'title': chapter.title,
              'url': chapter.url,
              'chapterNumber': chapter.number,
            },
            where: 'id = ?',
            whereArgs: [existingId],
          );

          // Force-save chapter sections if we have content payload
          if (chapter.content != null) {
            await txn.delete(
              'ChapterSection',
              where: 'chapter_id = ?',
              whereArgs: [existingId],
            );
            for (var section in chapter.content!) {
              await txn.insert('ChapterSection', {
                'chapter_id': existingId,
                'content': section,
              });
            }
          }
        }
      }
    });
    _notifyChange();
  }

  Future<int> saveChapterContent(int chapterId, List<String> content) async {
    final db = await database;
    final result = await db.transaction((txn) async {
      await txn.delete(
        'ChapterSection',
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
      );
      for (var section in content) {
        await txn.insert('ChapterSection', {
          'chapter_id': chapterId,
          'content': section,
        });
      }

      // Update firstChapterCharCount if this is Chapter 1 (index 0)
      final List<Map<String, dynamic>> chInfo = await txn.query(
        'ChapterInfo',
        columns: ['book_id', 'chapterNumber'],
        where: 'id = ?',
        whereArgs: [chapterId],
      );
      if (chInfo.isNotEmpty && chInfo.first['chapterNumber'] == 0) {
        final bookId = chInfo.first['book_id'] as int;
        final totalLength = content.join().length;
        await txn.update(
          'BookDetails',
          {'firstChapterCharCount': totalLength},
          where: 'id = ?',
          whereArgs: [bookId],
        );
      }

      return content.length;
    });
    _notifyChange();
    return result;
  }

  Future<List<ChapterInfo>> getNextChaptersWithoutContent(
    int bookId,
    int currentChapterIndex,
    int limit,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT id, book_id, title, url, chapterNumber AS number, scrollPosition, prepReviewedCount
      FROM ChapterInfo
      WHERE book_id = ? AND chapterNumber > ?
        AND id NOT IN (
          SELECT DISTINCT chapter_id FROM ChapterSection
        )
      ORDER BY chapterNumber ASC
      LIMIT ?
    ''',
      [bookId, currentChapterIndex, limit],
    );
    return rows.map((row) => ChapterInfo.fromJson(row)).toList();
  }

  Future<int> deleteBook(int bookId) async {
    final db = await database;

    try {
      final List<Map<String, dynamic>> results = await db.query(
        'BookDetails',
        columns: ['coverUrl'],
        where: 'id = ?',
        whereArgs: [bookId],
      );

      if (results.isNotEmpty) {
        final coverUrl = results.first['coverUrl'] as String?;
        if (coverUrl != null && coverUrl.isNotEmpty) {
          if (coverUrl.startsWith('http://') ||
              coverUrl.startsWith('https://')) {
            // Evict remote cached cover image from persistent cache
            await BookCoverCacheManager.instance.removeFile(coverUrl);
          } else if (!coverUrl.startsWith('assets/')) {
            // Clean up physically stored files (e.g. from local EPUB imports)
            final cleanPath = coverUrl.startsWith("file://")
                ? coverUrl.replaceFirst("file://", "")
                : coverUrl;
            final file = File(cleanPath);
            if (await file.exists()) {
              await file.delete();
            }
          }
        }
      }
    } catch (e) {
      print("[DatabaseService] Error cleaning up cover image files: $e");
    }

    final count = await db.delete(
      'BookDetails',
      where: 'id = ?',
      whereArgs: [bookId],
    );
    _notifyChange();
    return count;
  }

  Future<void> saveBookAnalysisCache({
    required int bookId,
    required int chapterId,
    required String jsonData,
  }) async {
    final db = await database;
    await db.insert('BookAnalysisCache', {
      'chapter_id': chapterId,
      'book_id': bookId,
      'json_data': jsonData,
      'last_accessed': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getBookAnalysisCache(int bookId, int chapterId) async {
    final db = await database;
    await _cleanupExpiredCaches(db);

    final results = await db.query(
      'BookAnalysisCache',
      where: 'book_id = ? AND chapter_id = ?',
      whereArgs: [bookId, chapterId],
    );

    if (results.isEmpty) return null;

    await db.update(
      'BookAnalysisCache',
      {'last_accessed': DateTime.now().millisecondsSinceEpoch},
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );

    return results.first['json_data'] as String;
  }

  /// Clears analysis caches and resets prep progress after 1 year of book inactivity.
  Future<void> _cleanupExpiredCaches(Database db) async {
    final oneYearAgo = DateTime.now()
        .subtract(const Duration(days: 365))
        .millisecondsSinceEpoch;

    // Find books inactive for over 1 year
    final List<Map<String, dynamic>> inactiveBooks = await db.query(
      'BookDetails',
      columns: ['id'],
      where: 'accessedDate IS NOT NULL AND accessedDate < ?',
      whereArgs: [oneYearAgo],
    );

    if (inactiveBooks.isNotEmpty) {
      final inactiveIds = inactiveBooks.map((b) => b['id'] as int).toList();
      final placeholders = List.filled(inactiveIds.length, '?').join(',');

      // 1. Clear Analysis Cache of inactive books
      await db.delete(
        'BookAnalysisCache',
        where: 'book_id IN ($placeholders)',
        whereArgs: inactiveIds,
      );

      // 2. Reset prep progress metrics for inactive books to 0
      await db.update(
        'ChapterInfo',
        {'prepReviewedCount': 0},
        where: 'book_id IN ($placeholders)',
        whereArgs: inactiveIds,
      );
    }

    // Maintain standard cleanup logic for standard 100 days cache
    final hundredDaysAgo = DateTime.now()
        .subtract(const Duration(days: 100))
        .millisecondsSinceEpoch;

    await db.delete(
      'BookAnalysisCache',
      where: 'last_accessed < ?',
      whereArgs: [hundredDaysAgo],
    );
  }
}
