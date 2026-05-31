import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/services/chapter_analysis_service.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/utils/string_extensions.dart';

class WordOfTheDayCard extends StatefulWidget {
  const WordOfTheDayCard({super.key});

  @override
  State<WordOfTheDayCard> createState() => _WordOfTheDayCardState();
}

class _WordOfTheDayCardState extends State<WordOfTheDayCard> {
  EntryAnalysisModel? _wodItem;
  String _jlptLevel = 'N2';
  bool _isLoading = true;
  StreamSubscription<void>? _booksSubscription;

  @override
  void initState() {
    super.initState();
    _loadWordOfTheDay();
    _booksSubscription = context.read<DatabaseService>().onBooksChanged.listen((
      _,
    ) {
      _loadWordOfTheDay();
    });
  }

  @override
  void dispose() {
    _booksSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadWordOfTheDay() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final dbService = context.read<DatabaseService>();
    final storage = LocalStorageService();

    final book = await dbService.getLastAccessedBook();
    if (book == null || book.chapters.isEmpty) {
      if (mounted) {
        setState(() {
          _wodItem = null;
          _jlptLevel = 'N2';
          _isLoading = false;
        });
      }
      return;
    }

    final nextChapter = book.chapters[book.currentChapter];
    final now = DateTime.now();
    final todayStr =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final savedBookId = storage.getData('wod_book_id') as int?;
    final savedChapterId = storage.getData('wod_chapter_id') as int?;
    final lastShownDate = storage.getData('wod_last_shown_date') as String?;

    List<String> shownWords = [];
    final rawShown = storage.getData('wod_shown_words');
    if (rawShown is List<String>) {
      shownWords = List<String>.from(rawShown);
    } else if (rawShown is List) {
      shownWords = rawShown.map((e) => e.toString()).toList();
    }

    bool needsNewWord = false;

    // Detect reset triggers (new chapter or new book)
    if (savedBookId != book.id || savedChapterId != nextChapter.id) {
      needsNewWord = true;
      shownWords = [];
      await storage.saveData('wod_book_id', book.id);
      await storage.saveData('wod_chapter_id', nextChapter.id);
      await storage.saveData('wod_shown_words', <String>[]);
    } else if (lastShownDate != todayStr) {
      needsNewWord = true;
    }

    EntryAnalysisModel? selectedWord;

    if (needsNewWord) {
      final items = await ChapterAnalysisService.analyzeChapter(
        book.id!,
        nextChapter,
        db: dbService,
      );

      if (items.isNotEmpty) {
        // Sort items descending by calculated Japanese difficulty
        final sortedItems = List<EntryAnalysisModel>.from(items);
        sortedItems.sort((a, b) {
          final diffA = a.word.calculateJapaneseDifficulty();
          final diffB = b.word.calculateJapaneseDifficulty();
          return diffB.compareTo(diffA);
        });

        // Pick the hardest word not yet shown
        for (final item in sortedItems) {
          if (!shownWords.contains(item.word)) {
            selectedWord = item;
            break;
          }
        }

        // If all words are already shown, reset history and restart with the hardest
        if (selectedWord == null) {
          shownWords = [];
          selectedWord = sortedItems.first;
        }

        shownWords.add(selectedWord.word);
        await storage.saveData('wod_shown_words', shownWords);
        await storage.saveData('wod_last_shown_date', todayStr);
        await storage.saveData(
          'wod_current_word_json',
          jsonEncode(selectedWord.toJson()),
        );
      }
    } else {
      // Re-use currently saved word for today
      final cachedJson = storage.getData('wod_current_word_json') as String?;
      if (cachedJson != null) {
        try {
          selectedWord = EntryAnalysisModel.fromJson(jsonDecode(cachedJson));
        } catch (e) {
          print("Failed to decode cached word of the day: $e");
        }
      }
      if (selectedWord == null) {
        final items = await ChapterAnalysisService.analyzeChapter(
          book.id!,
          nextChapter,
          db: dbService,
        );
        if (items.isNotEmpty) {
          final sortedItems = List<EntryAnalysisModel>.from(items);
          sortedItems.sort(
            (a, b) => b.word.calculateJapaneseDifficulty().compareTo(
              a.word.calculateJapaneseDifficulty(),
            ),
          );
          selectedWord = sortedItems.first;
        }
      }
    }

    String level = 'N2';
    if (selectedWord != null) {
      level = await selectedWord.word.jlptEstimate;
    }

    if (mounted) {
      setState(() {
        _wodItem = selectedWord;
        _jlptLevel = level;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 150,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final word = _wodItem?.word ?? "電";
    final reading = _wodItem?.entry.sounds.join("") ?? "デン (Den)";
    final meaning =
        _wodItem?.entry.meanings.join("; ") ?? "Electricity, Lightning";

    return LightningCard(
      type: LightningBorderEffectType.striking,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              KaminariTheme.surfaceTint.withAlpha(25),
              Colors.transparent,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CustomText(
                    "WORD OF THE DAY",
                    TextType.labelSmall,
                    color: KaminariTheme.textTitle,
                  ),
                  CustomText("LEVEL: $_jlptLevel", TextType.labelSmall),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomText(word, TextType.bodyLarge, fontSize: 36),
                  ),
                  const SizedBox(width: 16),
                  CustomText(
                    reading,
                    TextType.bodyLarge,
                    color: KaminariTheme.textTitle,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Divider(thickness: 0.5),
              const SizedBox(height: 12),
              CustomText(meaning, TextType.bodyMedium),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
