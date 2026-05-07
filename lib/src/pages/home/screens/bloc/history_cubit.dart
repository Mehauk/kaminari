import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/database_service.dart';

part 'history_cubit.freezed.dart';

enum HistoryFilter { all, favorites }

@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default(HistoryFilter.all) HistoryFilter filter,
    @Default([]) List<BookDetails> history,
    @Default(true) bool isLoading,
  }) = _HistoryState;
}

class HistoryCubit extends Cubit<HistoryState> {
  final DatabaseService dbService;

  HistoryCubit({required this.dbService}) : super(const HistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    emit(state.copyWith(isLoading: true));
    final books = await dbService.getHistoryBooks();
    emit(state.copyWith(history: books, isLoading: false));
  }

  void setFilter(HistoryFilter filter) {
    emit(state.copyWith(filter: filter));
  }
}
