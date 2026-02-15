import 'package:flutter_bloc/flutter_bloc.dart';

class ChapterInfo {
  const ChapterInfo({
    required this.number,
    required this.title,
    required this.isRead,
    this.wordCount = 0,
  });

  final int number;
  final String title;
  final bool isRead;
  final int wordCount;
}

class BookDetailsState {
  const BookDetailsState({
    required this.id,
    required this.title,
    required this.titleRomaji,
    required this.author,
    required this.coverUrl,
    required this.bookType,
    required this.jlptLevel,
    required this.synopsis,
    required this.totalPages,
    required this.currentPage,
    required this.currentChapter,
    required this.chapters,
    required this.totalWordCount,
    required this.estimatedMinutes,
    this.synopsisExpanded = false,
  });

  final String id;
  final String title;
  final String titleRomaji;
  final String author;
  final String coverUrl;
  final String bookType;
  final String jlptLevel;
  final String synopsis;
  final int totalPages;
  final int currentPage;
  final String currentChapter;
  final List<ChapterInfo> chapters;
  final int totalWordCount;
  final int estimatedMinutes;
  final bool synopsisExpanded;

  double get progress => totalPages > 0 ? currentPage / totalPages : 0.0;

  BookDetailsState copyWith({bool? synopsisExpanded}) {
    return BookDetailsState(
      id: id,
      title: title,
      titleRomaji: titleRomaji,
      author: author,
      coverUrl: coverUrl,
      bookType: bookType,
      jlptLevel: jlptLevel,
      synopsis: synopsis,
      totalPages: totalPages,
      currentPage: currentPage,
      currentChapter: currentChapter,
      chapters: chapters,
      totalWordCount: totalWordCount,
      estimatedMinutes: estimatedMinutes,
      synopsisExpanded: synopsisExpanded ?? this.synopsisExpanded,
    );
  }
}

// Mock data — swap out with real data source later
final _mockBookDetails = BookDetailsState(
  id: 'overlord-14',
  title: 'オーバーロード XIV',
  titleRomaji: 'Overlord: Volume 14',
  author: '丸山くがね (Kugane Maruyama)',
  coverUrl:
      "https://lh3.googleusercontent.com/aida-public/AB6AXuA87VKJVB1SgRkQzTgDKHSssUaKKoTmKQYsyHDcyV22DophVDGIxAZ5WXYSVgv-5PvFhwFATrJvZ1LOF-Q2N1UXAQ1B2QHx45n-Zl_89Mb6IUCiZiziLlnzLAiPJFJE96AZuOVYVN9WEZFA77n438ux3REjvsk1Wl5rvbyVl1k0rFEWcbgH9TR6WpDqSSEQtC0BVUcl5egjG5mBmjejws15kHspmwLKzw1GGNVF_OMnQ5JwpWyPyhlL4i2HMBrsYbt1QcEposxoGmCV",
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

class BookDetailsCubit extends Cubit<BookDetailsState> {
  BookDetailsCubit({String? bookId}) : super(_mockBookDetails);

  void toggleSynopsis() {
    emit(state.copyWith(synopsisExpanded: !state.synopsisExpanded));
  }
}
