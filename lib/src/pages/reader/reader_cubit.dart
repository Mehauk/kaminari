import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:jp_transliterate/jp_transliterate.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';

part 'reader_cubit.freezed.dart';

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(true) bool isLoading,
    @Default([]) List<List<String>> tokenizedParagraphs,
    String? errorMessage,
  }) = _ReaderState;
}

class ReaderCubit extends Cubit<ReaderState> {
  final ChapterInfo chapter;

  ReaderCubit(this.chapter) : super(const ReaderState()) {
    _tokenizeContent();
  }

  Future<void> _tokenizeContent() async {
    try {
      if (chapter.content == null || chapter.content!.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      List<List<String>> processed = [];
      for (var paragraph in chapter.content!) {
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

  Future<DictionaryEntry> lookupToken(String token) async {
    // Logic extracted from kanji_reader.dart
    Map<String, Object?>? wordMap = await KanjiService.getEntry(token);
    final transliteration = await JpTransliterate.transliterate(kanji: token);

    // Fallback lookups
    wordMap ??= await KanjiService.getEntry(transliteration.hiragana);
    wordMap ??= await KanjiService.getEntry(transliteration.katakana);

    if (wordMap != null) {
      KanjiService.visitEntry(wordMap["word"] as String);
    }

    // Default structure if not found in dictionary
    wordMap ??= {
      "letters": token,
      "sounds": transliteration.katakana,
      "mean": "No definition found",
      "freq": 0.0,
    };

    List<KanjiEntry> kanjis = (await KanjiService.getKanjiSounds(
      wordMap["letters"] as String,
    )).map((e) => KanjiEntry(e)).toList();

    return DictionaryEntry(wordMap, kanjis: kanjis);
  }
}
