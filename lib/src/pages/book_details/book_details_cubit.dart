import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';

part 'book_details_cubit.freezed.dart';

@freezed
abstract class BookDetailsState with _$BookDetailsState {
  const factory BookDetailsState({
    @Default(false) bool synopsisExpanded,
    @Default(0) int currentChapter,
    @Default(false) bool isFavorite,
  }) = _BookDetailsState;
}

class BookDetailsCubit extends Cubit<BookDetailsState> {
  BookDetails book;
  final DatabaseService dbService;
  BookDetailsCubit(this.book, {required this.dbService})
    : super(
        BookDetailsState(
          currentChapter: book.currentChapter,
          isFavorite: book.isFavorite,
        ),
      );

  void toggleSynopsis() {
    emit(state.copyWith(synopsisExpanded: !state.synopsisExpanded));
  }

  Future<void> refreshProgress() async {
    if (book.id == null) return;
    final latestChapter = await dbService.getBookCurrentChapter(book.id!);
    emit(state.copyWith(currentChapter: latestChapter));
  }

  Future<void> toggleFavorite() async {
    if (book.id == null) return;
    final updatedFavorite = !state.isFavorite;
    await dbService.updateBookFavorite(book.id!, updatedFavorite);
    book = book.copyWith(isFavorite: updatedFavorite);
    emit(state.copyWith(isFavorite: updatedFavorite));
  }
}
