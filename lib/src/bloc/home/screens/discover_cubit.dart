import 'package:flutter_bloc/flutter_bloc.dart';

enum FilterType {
  all("All"),
  lightNovels("Light Novels"),
  shortStories("Short Stories");

  final String text;
  const FilterType(this.text);
}

class DiscoverState {
  const DiscoverState({this.filter = FilterType.all, this.query = ''});

  final FilterType filter;
  final String query;

  DiscoverState copyWith({FilterType? filter, String? query}) {
    return DiscoverState(
      filter: filter ?? this.filter,
      query: query ?? this.query,
    );
  }
}

class DiscoverCubit extends Cubit<DiscoverState> {
  DiscoverCubit() : super(const DiscoverState());

  void setFilter(FilterType filter) {
    emit(state.copyWith(filter: filter));
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }

  void clearQuery() {
    emit(state.copyWith(query: ''));
  }
}
