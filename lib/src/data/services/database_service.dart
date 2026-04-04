import 'package:kaminari/src/data/models/book.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'kaminari.db');

    return await openDatabase(
      path,
      version: 8,
      onCreate: _createTables,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  /// Handles migrations between versions
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
  }

  static Future<void> _createTables(Database db, int version) async {
    // 1. BookDetails Table
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
        updatedDate TEXT,
        accessedDate INTEGER,
        bookType TEXT NOT NULL,
        currentChapterIndex INTEGER DEFAULT 0,
        firstChapterCharCount INTEGER DEFAULT 0,
        isFavorite INTEGER DEFAULT 0,
        UNIQUE(title, source, author, bookType)
      )
    ''');

    // 2. ChapterInfo Table
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
        UNIQUE(book_id, chapterNumber),
        FOREIGN KEY (book_id) REFERENCES BookDetails (id) ON DELETE CASCADE
      )
    ''');

    // 3. ChapterSection Table
    await db.execute('''
      CREATE TABLE ChapterSection (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        content TEXT NOT NULL,
        FOREIGN KEY (chapter_id) REFERENCES ChapterInfo (id) ON DELETE CASCADE
      )
    ''');
  }

  /// Fetch all books with their chapters in one go
  Future<List<BookDetails>> getBooks() async {
    final db = await database;

    // We fetch books and all their chapters in one query
    final rows = await db.rawQuery('''
      SELECT b.*, b.currentChapterIndex AS currentChapter, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title, 
             c.chapterNumber AS ch_number, c.scrollPosition
      FROM BookDetails b
      LEFT JOIN ChapterInfo c ON b.id = c.book_id
      ORDER BY b.id, c.chapterNumber ASC
    ''');

    final Map<int, Map<String, dynamic>> booksMap = {};

    for (final row in rows) {
      final bookId = row['id'] as int;

      // Initialize book if not in map
      if (!booksMap.containsKey(bookId)) {
        booksMap[bookId] = {
          ...row,
          'isFavorite': (row['isFavorite'] as int?) == 1,
          'chapters': [],
        };
      }

      // Add chapter if it exists
      if (row['ch_id'] != null) {
        final chapter = {
          "id": row['ch_id'] as int,
          "url": row['ch_url'] as String,
          "number": row['ch_number'] as int,
          "title": row['ch_title'] as String,
          "scrollPosition": row['scrollPosition'] as double?,
        };
        booksMap[bookId]!["chapters"].add(chapter);
      }
    }
    return booksMap.values.map((m) => BookDetails.fromJson(m)).toList();
  }

  Future<List<BookDetails>> getHistoryBooks() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT b.*, b.currentChapterIndex AS currentChapter, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title, 
             c.chapterNumber AS ch_number, c.scrollPosition
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
        });
      }
    }
    return booksMap.values.map((m) => BookDetails.fromJson(m)).toList();
  }

  /// Fetch a specific chapter with all its content sections
  Future<ChapterInfo?> getChapterWithContent(int chapterId) async {
    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT c.id, c.book_id, c.title, c.url, c.chapterNumber AS number, s.content, c.scrollPosition
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

    // 1. Get the last accessed book row
    final rows = await db.rawQuery('''
    SELECT *, currentChapterIndex AS currentChapter FROM BookDetails
    ORDER BY accessedDate DESC LIMIT 1
  ''');

    if (rows.isEmpty) return null;

    final bookRow = rows.first;
    final bookId = bookRow['id'] as int;

    // 2. Fetch its chapters
    final chapterRows = await db.rawQuery(
      '''
    SELECT c.id, c.book_id, c.title, c.url, c.chapterNumber AS number FROM ChapterInfo c
    WHERE book_id = ? 
    ORDER BY chapterNumber ASC
  ''',
      [bookId],
    );

    // 3. Construct a map that matches the structure expected by .fromJson
    final bookMap = Map<String, dynamic>.from(bookRow);
    bookMap['isFavorite'] = (bookMap['isFavorite'] as int?) == 1;
    bookMap['chapters'] = chapterRows;

    return BookDetails.fromJson(bookMap);
  }

  Future<void> updateBookAccess(int bookId, int currrentChapter) async {
    final db = await database;
    await db.update(
      'BookDetails',
      {
        'accessedDate': DateTime.now().millisecondsSinceEpoch,
        'currentChapterIndex': currrentChapter,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> updateBookFavorite(int bookId, bool isFavorite) async {
    final db = await database;
    await db.update(
      'BookDetails',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<BookDetails?> getBook(int bookId) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT b.*, b.currentChapterIndex AS currentChapter, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title,
             c.chapterNumber AS ch_number, c.scrollPosition
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
        .map((row) => {
              'id': row['ch_id'] as int,
              'url': row['ch_url'] as String,
              'number': row['ch_number'] as int,
              'title': row['ch_title'] as String,
              'scrollPosition': row['scrollPosition'] as double?,
            })
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

  Future<void> saveBook(BookDetails book) async {
    final db = await database;
    await db.transaction((txn) async {
      // 1. Check if the book exists
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
          'bookType': book.bookType.name,
          'firstChapterCharCount': book.firstChapterCharCount,
          'isFavorite': book.isFavorite ? 1 : 0,
        });
      }

      // 2. Handle Chapters
      for (var chapter in book.chapters) {
        // Check if this chapter exists by URL OR by Chapter Number
        final List<Map<String, dynamic>> existingChapters = await txn.query(
          'ChapterInfo',
          where: 'book_id = ? AND (url = ? OR chapterNumber = ?)',
          whereArgs: [bookId, chapter.url, chapter.number],
        );

        if (existingChapters.isEmpty) {
          // DOES NOT EXIST: Fresh insert
          final chapterId = await txn.insert('ChapterInfo', {
            'book_id': bookId,
            'title': chapter.title,
            'url': chapter.url,
            'chapterNumber': chapter.number,
            'scrollPosition': 0,
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
          // EXISTS: Update metadata but keep the ID (and thus the progress/content)
          int existingId = existingChapters.first['id'] as int;
          await txn.update(
            'ChapterInfo',
            {
              'title': chapter.title,
              'url': chapter.url, // Update URL in case it changed
              'chapterNumber': chapter.number,
            },
            where: 'id = ?',
            whereArgs: [existingId],
          );
        }
      }
    });
  }

  Future<int> saveChapterContent(int chapterId, List<String> content) async {
    final db = await database;
    return await db.transaction((txn) async {
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
      return content.length;
    });
  }

  Future<List<ChapterInfo>> getNextChaptersWithoutContent(
    int bookId,
    int currentChapterIndex,
    int limit,
  ) async {
    final db = await database;
    final rows = await db.rawQuery(
      '''
      SELECT id, book_id, title, url, chapterNumber AS number, scrollPosition
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
    return await db.delete('BookDetails', where: 'id = ?', whereArgs: [bookId]);
  }
}
