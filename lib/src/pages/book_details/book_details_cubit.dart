import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';

part 'book_details_cubit.freezed.dart';

// ──────────────────────────────────────────────────────
// State — wraps the data model and adds pure-UI flags
// ──────────────────────────────────────────────────────

@freezed
abstract class BookDetailsState with _$BookDetailsState {
  const factory BookDetailsState({
    required BookDetails book,
    @Default(false) bool synopsisExpanded,
  }) = _BookDetailsState;
}

// ──────────────────────────────────────────────────────
// Mock data — swap out with real data source later
// ──────────────────────────────────────────────────────

final mockBookDetails = BookDetails(
  url: '',
  title: 'オーバーロード XIV',
  author: '丸山くがね (Kugane Maruyama)',
  bookType: .lightNovel,
  jlptLevel: 'N2',
  synopsis:
      'The Sorcerer Kingdom continues to expand its influence over the Re-Estize Kingdom. '
      'Ainz Ooal Gown dispatches Albedo and the Pleiades to negotiate, while the kingdom\'s '
      'nobles scramble to form a coalition against the undead overlord. '
      'Meanwhile, Princess Renner harbors a secret that threatens to unravel everything...\n\n'
      'This volume focuses on the political machinations between the two nations and features '
      'rich vocabulary around medieval governance, military tactics, and court intrigue — '
      'ideal for N2 learners building reading stamina in formal registers.',
  currentChapter: 2,
  chapters: [
    ChapterInfo(number: 1, title: 'The Ruler of Death', url: ''),
    ChapterInfo(number: 2, title: 'Preparations', url: ''),
    ChapterInfo(number: 3, title: 'Preparations', url: ''),
  ],
);

// ──────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────

class BookDetailsCubit extends Cubit<BookDetailsState> {
  BookDetailsCubit({String? bookId})
    : super(BookDetailsState(book: mockBookDetails));

  void toggleSynopsis() {
    emit(state.copyWith(synopsisExpanded: !state.synopsisExpanded));
  }
}
