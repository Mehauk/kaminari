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
  }) = _BookDetailsState;
}

class BookDetailsCubit extends Cubit<BookDetailsState> {
  final BookDetails book;
  final DatabaseService dbService;
  BookDetailsCubit(this.book, {required this.dbService})
    : super(BookDetailsState(currentChapter: book.currentChapter));

  void toggleSynopsis() {
    emit(state.copyWith(synopsisExpanded: !state.synopsisExpanded));
  }

  Future<void> refreshProgress() async {
    if (book.id == null) return;
    final latestChapter = await dbService.getBookCurrentChapter(book.id!);
    emit(state.copyWith(currentChapter: latestChapter));
  }
}
