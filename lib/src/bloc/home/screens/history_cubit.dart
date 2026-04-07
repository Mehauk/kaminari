import 'package:flutter_bloc/flutter_bloc.dart';

enum HistoryFilter { all, favorites }

class HistoryState {
  const HistoryState({this.filter = HistoryFilter.all});

  final HistoryFilter filter;

  HistoryState copyWith({HistoryFilter? filter}) {
    return HistoryState(filter: filter ?? this.filter);
  }
}

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit() : super(const HistoryState());

  void setFilter(HistoryFilter filter) {
    emit(state.copyWith(filter: filter));
  }
}
