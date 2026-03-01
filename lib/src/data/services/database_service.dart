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
      version: 1, // Incremented version
      onCreate: _createTables,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON'); // Crucial
      },
    );
  }

  static Future<void> _createTables(Database db, int version) async {
    // 1. BookDetails Table
    await db.execute('''
      CREATE TABLE BookDetails (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        url TEXT NOT NULL UNIQUE,
        source TEXT NOT NULL,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        synopsis TEXT NOT NULL,
        coverUrl TEXT,
        jlptLevel TEXT,
        updatedDate TEXT,
        accessedDate INTEGER,
        bookType TEXT NOT NULL,
        currentChapterIndex INTEGER DEFAULT 0
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
      SELECT b.*, c.id AS ch_id, c.url AS ch_url, c.title AS ch_title, 
             c.chapterNumber AS ch_number
      FROM BookDetails b
      LEFT JOIN ChapterInfo c ON b.id = c.book_id
      ORDER BY b.id, c.chapterNumber ASC
    ''');

    final Map<int, Map<String, dynamic>> booksMap = {};

    for (final row in rows) {
      final bookId = row['id'] as int;

      // Initialize book if not in map
      if (!booksMap.containsKey(bookId)) {
        booksMap[bookId] = {...row, 'chapters': []};
      }

      // Add chapter if it exists
      if (row['ch_id'] != null) {
        final chapter = {
          "url": row['ch_url'] as String,
          "number": row['ch_number'] as int,
          "title": row['ch_title'] as String,
        };
        booksMap[bookId]!["chapters"].add(chapter);
      }
    }
    return booksMap.values.map((m) => BookDetails.fromJson(m)).toList();
  }

  /// Fetch a specific chapter with all its content sections
  Future<ChapterInfo?> getChapterWithContent(int chapterId) async {
    final db = await database;

    final rows = await db.rawQuery(
      '''
      SELECT c.*, s.content
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

  /// Helper to save a book (used in the WebviewCubit import flow)
  Future<void> saveBook(BookDetails book) async {
    final db = await database;
    await db.transaction((txn) async {
      final bookId = await txn.insert('BookDetails', {
        'url': book.url,
        'source': book.source,
        'title': book.title,
        'author': book.author,
        'synopsis': book.synopsis,
        'bookType': book.bookType.name,
      });

      for (var chapter in book.chapters) {
        final chapterId = await txn.insert('ChapterInfo', {
          'book_id': bookId,
          'title': chapter.title,
          'url': chapter.url,
          'chapterNumber': chapter.number,
        });

        if (chapter.content != null) {
          for (var section in chapter.content!) {
            await txn.insert('ChapterSection', {
              'chapter_id': chapterId,
              'content': section,
            });
          }
        }
      }
    });
  }
}
