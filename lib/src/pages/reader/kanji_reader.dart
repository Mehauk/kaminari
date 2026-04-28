import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';

Future<DictionaryEntry> _getDictionaryEntry(String node) async {
  // start
  // lookup
  Map<String, Object?>? wordMap = await KanjiService.getEntry(node);

  final t = (await JpTransliterate.transliterate(kanji: node));

  // lookup failed 1
  wordMap = wordMap ?? await KanjiService.getEntry(t.hiragana);
  wordMap = wordMap ?? await KanjiService.getEntry(t.katakana);

  // either lookup worked
  if (wordMap != null) KanjiService.visitEntry(wordMap["word"] as String);

  // lookup failed 2
  wordMap =
      wordMap ??
      {"letters": node, "sounds": t.katakana, "mean": "", "freq": 0.0};

  // kanji lookups
  List<KanjiEntry> kanjis = (await KanjiService.getKanjiSounds(
    wordMap["letters"] as String,
  )).map((e) => KanjiEntry(e)).toList();

  // update Dictionary Entry
  return DictionaryEntry(wordMap, kanjis: kanjis);
}

class ReadingPage extends StatefulWidget {
  final ChapterInfo chapter;
  const ReadingPage(this.chapter, {super.key});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  // Logic to process text into spans
  Future<List<TextSpan>> _buildContentSpans() async {
    List<TextSpan> spans = [];
    for (var paragraph in widget.chapter.content ?? []) {
      print("asdasd");
      final tokens = await KanjiService.tokenizeText(paragraph);
      print("asdasd2");

      for (var token in tokens) {
        spans.add(
          TextSpan(
            text: token,
            style: TextStyle(color: Colors.white, fontSize: 18),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _showDictionaryPopup(token);
              },
          ),
        );
      }
      spans.add(const TextSpan(text: "\n\n"));
    }
    return spans;
  }

  void _showDictionaryPopup(String token) async {
    final entry = await _getDictionaryEntry(token);
    showModalBottomSheet(
      context: context,
      builder: (_) => DictionaryView(entry), // Use your existing DictionaryView
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<TextSpan>>(
        future: _buildContentSpans(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();
          return SingleChildScrollView(
            child: RichText(text: TextSpan(children: snapshot.data!)),
          );
        },
      ),
    );
  }
}
