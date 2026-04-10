import 'package:flutter_bloc/flutter_bloc.dart';

enum BookType {
  all("All"),
  webNovel("Web Novels"),
  lightNovel("Light Novels"),
  shortStory("Short Stories");

  final String text;
  const BookType(this.text);

  String get short => switch (this) {
    BookType.all => text,
    BookType.webNovel => "WEB",
    BookType.lightNovel => "LN",
    BookType.shortStory => "SS",
  };
}

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
