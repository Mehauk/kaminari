import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/data/models/sounds.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:tiny_segmenter_dart/tiny_segmenter_dart.dart';

class KanjiService {
  static const String kanaJsonPath = "assets/data/kana.json";
  static const String kanjiJsonPath = "assets/data/kanji.json";
  static const String wordsDBPath = "assets/data/words.sqlite3";
  static const String soundsTable = "Sounds";
  static const String visitedTable = "Visited";

  static TinySegmenter? _mecab;

  static Future<void> _initMecab() async {
    if (_mecab != null) return;
    _mecab = TinySegmenter();
  }

  static Future<List<String>> tokenizeText(String text) async {
    if (text.startsWith("http")) return [text];
    await _initMecab();
    final res = _mecab!.segment(text);

    return res.expand((e) {
      return RegExp(
        r'[^\p{L}\p{N}\p{Z}]|[\p{L}\p{N}\p{Z}]+',
        unicode: true,
      ).allMatches(e).map((m) => m.group(0)!);
    }).toList();
  }

  static Future<(Map<String, Object?>, List<KanjiEntry>)> lookupToken(
    String token,
  ) async {
    print(token);

    Map<String, Object?>? wordMap = await KanjiService.getEntry(token);
    final transliteration = await JpTransliterate.transliterate(kanji: token);

    wordMap ??= await KanjiService.getEntry(transliteration.hiragana);
    wordMap ??= await KanjiService.getEntry(transliteration.katakana);

    if (wordMap == null || wordMap["word"] != token) {
      wordMap = {
        "letters": token,
        "sounds": wordMap?["sounds"] ?? token,
        "mean": wordMap?["mean"] ?? "",
        "freq": 0.0,
      };
    }

    // Register word as visited for "Words Learned" functionality
    final String? visitedWord =
        (wordMap["word"] ?? wordMap["letters"]) as String?;
    if (visitedWord != null && visitedWord.trim().isNotEmpty) {
      KanjiService.visitEntry(visitedWord); // Background registration
    }

    List<KanjiEntry> kanjis = (await KanjiService.getKanjiSounds(
      wordMap["letters"] as String,
    )).map((e) => KanjiEntry(e)).toList();

    return (wordMap, kanjis);
  }

  // _________________________KA NA_________________________
  static Future<List> getKana() async {
    return jsonDecode(await rootBundle.loadString(kanaJsonPath));
  }

  static Future<bool> buildKanaDB({bool rebuild = false}) async {
    String basePath = await getDatabasesPath();
    String dbPath = path.join(basePath, "$soundsTable.sqlite3");
    Database db = await openDatabase(dbPath);

    bool soundsTableExists =
        (await db.rawQuery(
          "SELECT Count(*) FROM sqlite_master WHERE type='table' AND name='$soundsTable'",
        ))[0]["Count(*)"] ==
        1;

    if (!soundsTableExists || rebuild) {
      await db.execute("DROP TABLE IF EXISTS $soundsTable");
      await db.execute(
        "CREATE TABLE $soundsTable (ord INT PRIMARY KEY, kata TEXT NOT NULL, hira TEXT NOT NULL, sound TEXT NOT NULL, hard INT NOT NULL, complexity int NOT NULL)",
      );

      List kana = await getKana();

      int order = 0;

      for (var l in kana) {
        for (var d in l) {
          await db.insert(soundsTable, {
            "ord": order,
            "kata": d["kana"],
            "hira": d["hira"],
            "sound": d["eng"],
            "hard": 1,
            "complexity": (d["hira"] as String).length,
          });

          order += 1;
        }
      }
    }
    return true;
  }

  static Future<Database> getSoundsDB() async {
    String basePath = await getDatabasesPath();
    String dbPath = path.join(basePath, "$soundsTable.sqlite3");

    return await openDatabase(dbPath);
  }

  static Future<int> getMaxSounds() async {
    final Database db = await getSoundsDB();
    return (await db.query(soundsTable, columns: ["COUNT(*)"]))[0]["COUNT(*)"]
        as int;
  }

  // _________________________WORDS_________________________
  static Future<Database> getWordsDB() async {
    Directory applicationDirectory = await getApplicationDocumentsDirectory();

    String dbPath = path.join(applicationDirectory.path, "WordsKanjis.db");

    bool dbExistsEnglish = await File(dbPath).exists();

    if (!dbExistsEnglish) {
      ByteData data = await rootBundle.load(wordsDBPath);
      List<int> bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      await File(dbPath).writeAsBytes(bytes, flush: true);
    }
    return await openDatabase(dbPath);
  }

  static Future<Map<String, Object?>?> getEntry(String word) async {
    final Database db = await getWordsDB();

    try {
      final List<Map<String, Object?>> lister = await db.query(
        "Words",
        where: "word = ? OR kana = ?",
        whereArgs: [word, word],
        orderBy: "freq DESC",
      );

      return lister.first;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, Object?>>> getKanjiSounds(String word) async {
    List<Map<String, Object?>> kjs = [];

    final Database db = await getWordsDB();

    for (var i = 0; i < word.length; i++) {
      List<Map<String, Object?>> res = await db.query(
        "kanji",
        where: "letter = ?",
        whereArgs: [word[i]],
      );

      if (res.isNotEmpty) kjs.add(res.first);
    }

    return kjs;
  }

  // _________________________VISIT_________________________
  static Future<List> getBaseKanji() async {
    return jsonDecode(await rootBundle.loadString(kanjiJsonPath));
  }

  static Future<bool> buildVisitedTable() async {
    Database db = await getWordsDB();

    final bool soundsTableExists =
        (await db.rawQuery(
          "SELECT Count(*) FROM sqlite_master WHERE type='table' AND name='$visitedTable'",
        ))[0]["Count(*)"] ==
        1;

    if (!soundsTableExists) {
      await db.execute("DROP TABLE IF EXISTS $visitedTable");
      await db.execute(
        "CREATE TABLE $visitedTable (visitedword TEXT PRIMARY KEY, visits INT)",
      );
    }
    return true;
  }

  static Future<void> visitEntry(String word, {int visitAdder = 2}) async {
    final Database db = await getWordsDB();

    int visits = visitAdder;
    final List l = (await db.query(
      visitedTable,
      where: "visitedword = ?",
      whereArgs: [word],
    ));
    if (l.isNotEmpty) visits = visits + l.first["visits"] as int;

    if (visits > 7) visits = 7;
    if (visits < 1) visits = 1;

    await db.insert(visitedTable, {
      "visitedword": word,
      "visits": visits,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> getNumberVisited() async {
    final Database db = await getWordsDB();
    return (await db.query(visitedTable, columns: ["COUNT(*)"]))[0]["COUNT(*)"]
        as int;
  }

  static Future<List<KanjiModel>> getVisitedWords({required int n}) async {
    final Database db = await getWordsDB();

    final List<Map<String, Object?>> lm = await db.query(
      "$visitedTable, Words",
      where: "visitedword = word",
      orderBy: "RANDOM() * (1 + freq) * visits DESC",
      limit: n,
    );

    final int n1 = lm.length;
    if (n1 < 2) return [];

    List<KanjiModel> lk = [];
    for (var i = 0; i < n1; i++) {
      int x = i;
      int ind = i;
      while ((ind - x).abs() < 1) {
        x = Random().nextInt(n1);
      }
      lk.add(KanjiModel(lm[i], fakeMean: lm[x]["mean"] as String));
    }

    return lk;
  }
}
