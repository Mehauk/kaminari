import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/epub_import_service.dart';

part 'discover_cubit.freezed.dart';

@freezed
abstract class DiscoverState with _$DiscoverState {
  const factory DiscoverState({
    @Default(BookType.all) BookType filter,
    @Default('') String query,
    @Default([]) List<BookDetails> books,
    BookDetails? epubPreviewBook, // Tracks local picked eBook metadata
    @Default(false) bool isImporting, // Processing states
    String? importErrorMessage,
  }) = _DiscoverState;
}

class DiscoverCubit extends Cubit<DiscoverState> {
  final DatabaseService dbService;
  late final StreamSubscription<void> _sub;

  DiscoverCubit({required this.dbService}) : super(const DiscoverState()) {
    dbService.getBooks().then((books) => emit(state.copyWith(books: books)));

    _sub = dbService.onBooksChanged.listen((_) async {
      final books = await dbService.getBooks();
      emit(state.copyWith(books: books));
    });
  }

  @override
  Future<void> close() {
    _sub.cancel();
    return super.close();
  }

  void setFilter(BookType filter) {
    emit(state.copyWith(filter: filter));
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void clearQuery() {
    emit(state.copyWith(query: ''));
  }

  // --- Local EPUB Import Operations ---

  Future<void> importEpubFile(String filePath) async {
    emit(
      state.copyWith(
        isImporting: true,
        importErrorMessage: null,
        epubPreviewBook: null,
      ),
    );
    try {
      final bookDetails = await EpubImportService.parseEpub(filePath);
      emit(state.copyWith(isImporting: false, epubPreviewBook: bookDetails));
    } catch (e) {
      emit(
        state.copyWith(isImporting: false, importErrorMessage: e.toString()),
      );
    }
  }

  void updatePreviewBookType(BookType type) {
    if (state.epubPreviewBook != null) {
      emit(
        state.copyWith(
          epubPreviewBook: state.epubPreviewBook!.copyWith(bookType: type),
        ),
      );
    }
  }

  void invertPreviewChapters() {
    if (state.epubPreviewBook != null) {
      final reversedChapters = state.epubPreviewBook!.chapters.reversed
          .toList();
      final renumberedChapters = List<ChapterInfo>.generate(
        reversedChapters.length,
        (i) => reversedChapters[i].copyWith(number: i),
      );
      emit(
        state.copyWith(
          epubPreviewBook: state.epubPreviewBook!.copyWith(
            chapters: renumberedChapters,
          ),
        ),
      );
    }
  }

  Future<void> confirmEpubImport() async {
    if (state.epubPreviewBook == null) return;
    emit(state.copyWith(isImporting: true));
    try {
      await dbService.saveBook(state.epubPreviewBook!);
      emit(state.copyWith(isImporting: false, epubPreviewBook: null));
    } catch (e) {
      emit(
        state.copyWith(
          isImporting: false,
          importErrorMessage: "Failed to save: $e",
        ),
      );
    }
  }

  void cancelEpubImport() {
    emit(
      state.copyWith(
        epubPreviewBook: null,
        importErrorMessage: null,
        isImporting: false,
      ),
    );
  }
}
