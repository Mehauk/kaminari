import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/data/models/book.dart';

// ──────────────────────────────────────────────────────
// State — wraps the data model and adds pure-UI flags
// ──────────────────────────────────────────────────────

class BookDetailsState {
  const BookDetailsState({
    required this.book,
    this.synopsisExpanded = false,
  });

  final BookDetails book;
  final bool synopsisExpanded;

  BookDetailsState copyWith({bool? synopsisExpanded}) {
    return BookDetailsState(
      book: book,
      synopsisExpanded: synopsisExpanded ?? this.synopsisExpanded,
    );
  }
}

// ──────────────────────────────────────────────────────
// Mock data — swap out with real data source later
// ──────────────────────────────────────────────────────

final _mockBookDetails = BookDetails(
  id: 'overlord-14',
  title: 'オーバーロード XIV',
  titleRomaji: 'Overlord: Volume 14',
  author: '丸山くがね (Kugane Maruyama)',
  coverUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuA87VKJVB1SgRkQzTgDKHSssUaKKoTmKQYsyHDcyV22DophVDGIxAZ5WXYSVgv-5PvFhwFATrJvZ1LOF-Q2N1UXAQ1B2QHx45n-Zl_89Mb6IUCiZiziLlnzLAiPJFJE96AZuOVYVN9WEZFA77n438ux3REjvsk1Wl5rvbyVl1k0rFEWcbgH9TR6WpDqSSEQtC0BVUcl5egjG5mBmjejws15kHspmwLKzw1GGNVF_OMnQ5JwpWyPyhlL4i2HMBrsYbt1QcEposxoGmCV',
  bookType: 'Light Novel',
  jlptLevel: 'N2',
  synopsis:
      'The Sorcerer Kingdom continues to expand its influence over the Re-Estize Kingdom. '
      'Ainz Ooal Gown dispatches Albedo and the Pleiades to negotiate, while the kingdom\'s '
      'nobles scramble to form a coalition against the undead overlord. '
      'Meanwhile, Princess Renner harbors a secret that threatens to unravel everything...\n\n'
      'This volume focuses on the political machinations between the two nations and features '
      'rich vocabulary around medieval governance, military tactics, and court intrigue — '
      'ideal for N2 learners building reading stamina in formal registers.',
  totalPages: 312,
  currentPage: 212,
  currentChapter: 'Chapter 3: The Witch of the Falling Kingdom',
  totalWordCount: 68400,
  estimatedMinutes: 342,
  chapters: [
    ChapterInfo(
      number: 1,
      title: 'The Ruler of Death',
      isRead: true,
      wordCount: 8200,
    ),
    ChapterInfo(
      number: 2,
      title: 'Preparations for War',
      isRead: true,
      wordCount: 9100,
    ),
    ChapterInfo(
      number: 3,
      title: 'The Witch of the Falling Kingdom',
      isRead: false,
      wordCount: 11400,
    ),
    ChapterInfo(
      number: 4,
      title: 'Flames of War',
      isRead: false,
      wordCount: 10800,
    ),
    ChapterInfo(
      number: 5,
      title: 'The Ruler\'s Gambit',
      isRead: false,
      wordCount: 9900,
    ),
    ChapterInfo(number: 6, title: 'Epilogue', isRead: false, wordCount: 5200),
  ],
);

// ──────────────────────────────────────────────────────
// Cubit
// ──────────────────────────────────────────────────────

class BookDetailsCubit extends Cubit<BookDetailsState> {
  BookDetailsCubit({String? bookId})
      : super(BookDetailsState(book: _mockBookDetails));

  void toggleSynopsis() {
    emit(state.copyWith(synopsisExpanded: !state.synopsisExpanded));
  }
}
