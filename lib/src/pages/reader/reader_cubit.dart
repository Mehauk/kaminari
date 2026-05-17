import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
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
    final (wordMap, kanjis) = await KanjiService.lookupToken(token);

    if (state.selectedParagraphIndex == paragraphIndex &&
        state.selectedTokenIndex == tokenIndex) {
      clearSelection();
      return;
    }

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
