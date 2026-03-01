import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';

part 'book_details_cubit.freezed.dart';

@freezed
abstract class BookDetailsState with _$BookDetailsState {
  const factory BookDetailsState({@Default(false) bool synopsisExpanded}) =
      _BookDetailsState;
}

class BookDetailsCubit extends Cubit<BookDetailsState> {
  final BookDetails book;
  BookDetailsCubit(this.book) : super(BookDetailsState());

  void toggleSynopsis() {
    emit(state.copyWith(synopsisExpanded: !state.synopsisExpanded));
  }
}
