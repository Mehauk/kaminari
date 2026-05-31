import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';

part 'discover_cubit.freezed.dart';

@freezed
abstract class DiscoverState with _$DiscoverState {
  const factory DiscoverState({
    @Default(BookType.all) BookType filter,
    @Default('') String query,
    @Default([]) List<BookDetails> books,
  }) = _DiscoverState;
}

class DiscoverCubit extends Cubit<DiscoverState> {
  final DatabaseService dbService;
  late final StreamSubscription<void> _sub;

  DiscoverCubit({required this.dbService}) : super(const DiscoverState()) {
    // Initial load
    dbService.getBooks().then((books) => emit(state.copyWith(books: books)));

    // Reload whenever the database signals changes
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
}
