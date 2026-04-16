import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'history_cubit.freezed.dart';

enum HistoryFilter { all, favorites }

@freezed
abstract class HistoryState with _$HistoryState {
  const factory HistoryState({
    @Default(HistoryFilter.all) HistoryFilter filter,
  }) = _HistoryState;
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(const HistoryState());

  void setFilter(HistoryFilter filter) {
    emit(state.copyWith(filter: filter));
  }
}
