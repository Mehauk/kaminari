import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';

part 'reader_cubit.freezed.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(true) bool isLoading,
    @Default([]) List<List<String>> tokenizedParagraphs,
    String? errorMessage,
    DictionaryEntry? selectedEntry,
    int? selectedParagraphIndex,
    int? selectedTokenIndex,
  }) = _ReaderState;
}

class ReaderCubit extends Cubit<ReaderState> {
  final int bookId;
  final ChapterInfo chapter;
  final DatabaseService dbService;

  ReaderCubit(this.chapter, {required this.dbService, required this.bookId})
    : super(const ReaderState()) {
    dbService.updateBookAccess(bookId, chapter.number);
    _tokenizeContent();
  }

  void saveScrollPosition(double pixels) {
    dbService.updateChapterScrollPosition(chapter.id!, pixels);
  }

  Future<void> _tokenizeContent() async {
    try {
      if (chapter.content == null || chapter.content!.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      List<List<String>> processed = [];
      for (var paragraph in chapter.content!) {
        print(paragraph);
        final tokens = await KanjiService.tokenizeText(paragraph);
        processed.add(tokens);
      }

      emit(state.copyWith(isLoading: false, tokenizedParagraphs: processed));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "Failed to process text: $e",
        ),
      );
    }
  }

  Future<void> lookupToken(
    String token,
    int paragraphIndex,
    int tokenIndex,
  ) async {
    print(token);
    // Logic extracted from kanji_reader.dart
    Map<String, Object?>? wordMap = await KanjiService.getEntry(token);
    final transliteration = await JpTransliterate.transliterate(kanji: token);

    // Fallback lookups
    // 異世 -> イヨ for some reason
    wordMap ??= await KanjiService.getEntry(transliteration.hiragana);
    wordMap ??= await KanjiService.getEntry(transliteration.katakana);

    print("wordMap: $wordMap");
    print("token: $token");
    print("word: ${wordMap?['word']}");
    print(wordMap?["word"] != token);

    if (state.selectedParagraphIndex == paragraphIndex &&
        state.selectedTokenIndex == tokenIndex) {
      clearSelection();
      return;
    }

    if (wordMap == null || wordMap["word"] != token) {
      wordMap = {
        "letters": token,
        "sounds": wordMap?["sounds"] ?? token,
        "mean": wordMap?["mean"] ?? "",
        "freq": 0.0,
      };
    }

    // if (wordMap != null) {
    //   KanjiService.visitEntry(wordMap["word"] as String);
    // }

    // Default structure if not found in dictionary

    List<KanjiEntry> kanjis = (await KanjiService.getKanjiSounds(
      wordMap["letters"] as String,
    )).map((e) => KanjiEntry(e)).toList();

    emit(
      state.copyWith(
        selectedEntry: DictionaryEntry(wordMap, kanjis: kanjis),
        selectedParagraphIndex: paragraphIndex,
        selectedTokenIndex: tokenIndex,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selectedEntry: null,
        selectedParagraphIndex: null,
        selectedTokenIndex: null,
      ),
    );
  }
}
