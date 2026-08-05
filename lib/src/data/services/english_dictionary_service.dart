import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class EnglishDictionaryEntry {
  final String word;
  final String pronunciation;
  final String etymology;
  final List<String> definitions;

  EnglishDictionaryEntry({
    required this.word,
    required this.pronunciation,
    required this.etymology,
    required this.definitions,
  });
}

class EnglishDictionaryService {
  static final EnglishDictionaryService _instance =
      EnglishDictionaryService._internal();
  factory EnglishDictionaryService() => _instance;
  EnglishDictionaryService._internal();

  Database? _db;
  bool _isDownloading = false;

  // Leveraging an Open-Source SQLite Dictionary
  // with schema matching `entries` -> `word`, `wordtype`, `definition`, etc.
  static const String _dbUrl =
      "https://github.com/CloudBytes-Academy/English-Dictionary-Open-Source/raw/refs/heads/main/sqlite3/dictionary.db";

  Future<String> get _dbPath async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, "english_dictionary.db");
  }

  Future<bool> isDictionaryAvailable() async {
    final file = File(await _dbPath);
    return file.exists();
  }

  Future<void> downloadDictionary(Function(double) onProgress) async {
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(_dbUrl));
      final response = await request.close();

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      final file = File(await _dbPath);
      final sink = file.openWrite();

      await for (var chunk in response) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        if (totalBytes > 0) {
          onProgress(receivedBytes / totalBytes);
        }
      }
      await sink.close();
    } catch (e) {
      final file = File(await _dbPath);
      if (await file.exists()) {
        await file.delete();
      }
      rethrow;
    } finally {
      _isDownloading = false;
    }
  }

  Future<void> initDb() async {
    if (_db != null) return;
    final dbPathStr = await _dbPath;
    if (await File(dbPathStr).exists()) {
      _db = await openDatabase(dbPathStr, readOnly: true);
    }
  }

  Future<EnglishDictionaryEntry?> lookup(String word) async {
    await initDb();
    if (_db == null) return null;

    final lowerWord = word.toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '');
    if (lowerWord.isEmpty) return null;

    // Check schema gracefully to support varied dictionary db versions
    final tables = await _db!.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['table', 'entries'],
    );
    if (tables.isEmpty) return null;

    final columns = await _db!.rawQuery('PRAGMA table_info(entries)');
    final colNames = columns.map((e) => e['name'] as String).toList();

    bool hasPronunciation = colNames.contains('pronunciation');
    bool hasEtymology = colNames.contains('etymology');
    bool hasWordType = colNames.contains('wordtype');

    List<String> selectCols = ['word', 'definition'];
    if (hasPronunciation) selectCols.add('pronunciation');
    if (hasEtymology) selectCols.add('etymology');
    if (hasWordType) selectCols.add('wordtype');

    final results = await _db!.query(
      'entries',
      columns: selectCols,
      where: 'word = ? COLLATE NOCASE',
      whereArgs: [lowerWord],
    );

    if (results.isEmpty) return null;

    List<String> definitions = [];
    String pronunciation = '';
    String etymology = '';

    for (var row in results) {
      final def = row['definition'] as String? ?? '';
      final wt = hasWordType ? (row['wordtype'] as String? ?? '') : '';
      if (def.isNotEmpty) {
        definitions.add(wt.isNotEmpty ? '[$wt] $def' : def);
      }
      if (pronunciation.isEmpty && hasPronunciation) {
        pronunciation = row['pronunciation'] as String? ?? '';
      }
      if (etymology.isEmpty && hasEtymology) {
        etymology = row['etymology'] as String? ?? '';
      }
    }

    return EnglishDictionaryEntry(
      word: lowerWord,
      pronunciation: pronunciation.isNotEmpty ? pronunciation : '',
      etymology: etymology.isNotEmpty ? etymology : '',
      definitions: definitions,
    );
  }
}
