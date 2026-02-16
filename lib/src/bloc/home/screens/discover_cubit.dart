import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/data/models/book.dart';

class DiscoverState {
  const DiscoverState({this.filter = BookType.all, this.query = ''});

  final BookType filter;
  final String query;

  DiscoverState copyWith({BookType? filter, String? query}) {
    return DiscoverState(
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit() : super(const DiscoverState());

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
