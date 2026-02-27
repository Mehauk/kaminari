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
  }) = _DiscoverState;
}

class DiscoverCubit extends Cubit<DiscoverState> {
  final DatabaseService dbService;
  DiscoverCubit({required this.dbService}) : super(const DiscoverState());

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
