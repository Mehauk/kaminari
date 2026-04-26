import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/app_settings.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';

part 'reader_cubit.freezed.dart';

enum ReaderItemType { title, paragraph, pageBreak }

enum DictOrientation { top, bottom }

class ReaderItem {
  final ReaderItemType type;
  final List<String> tokens;
  final int chapterId;
  final String chapterTitle;
  final int chapterNumber;

  const ReaderItem({
    required this.type,
    required this.tokens,
    required this.chapterId,
    required this.chapterTitle,
    required this.chapterNumber,
  });
}

@freezed
abstract class ReaderState with _$ReaderState {
  const factory ReaderState({
    @Default(true) bool isLoading,
    @Default([]) List<ReaderItem> items,
    @Default(false) bool isLoadingNext,
    ChapterInfo? activeWaitingChapter,
    String? errorMessage,
    DictionaryEntry? selectedEntry,
    int? selectedParagraphIndex,
    int? selectedTokenIndex,
    String? activeChapterTitle,
    @Default(DictOrientation.bottom) DictOrientation dictOrientation,
  }) = _ReaderState;
}

class ReaderCubit extends Cubit<ReaderState> {
  final int bookId;
  final ChapterInfo chapter;
  final DatabaseService dbService;
  final AppSettings settings;

  final List<int> _loadedChapterIds = [];
  final List<ChapterInfo> _loadedChapters = [];
  List<ChapterInfo> _allChapters = [];
  int _lastLoadedChapterNumber = 0;

  List<ChapterInfo> get loadedChapters => _loadedChapters;

  ReaderCubit(
    this.chapter, {
    required this.bookId,
    required this.dbService,
    required this.settings,
  }) : super(ReaderState(dictOrientation: settings.getDictOrientation())) {
    dbService.updateBookAccess(bookId, chapter.number);
    _tokenizeContent();
  }

  void saveScrollPosition(int chapterId, double pixels) {
    dbService.updateChapterScrollPosition(chapterId, pixels);
  }

  Future<void> _loadBookDetails() async {
    final book = await dbService.getBook(bookId);
    if (book != null) {
      _allChapters = book.chapters;
    }
  }

  ChapterInfo? _getNextChapter() {
    if (_allChapters.isEmpty) return null;
    final currentIdx = _allChapters.indexWhere(
      (c) => c.number == _lastLoadedChapterNumber,
    );
    if (currentIdx != -1 && currentIdx + 1 < _allChapters.length) {
      return _allChapters[currentIdx + 1];
    }
    return null;
  }

  Future<void> reloadContent() async {
    emit(state.copyWith(isLoading: true));
    final updatedChapter = await dbService.getChapterWithContent(chapter.id!);
    if (updatedChapter != null && updatedChapter.content != null) {
      List<ReaderItem> processed = [];

      // Tokenize title first
      final titleTokens = await KanjiService.tokenizeText(updatedChapter.title);
      processed.add(
        ReaderItem(
          type: ReaderItemType.title,
          tokens: titleTokens,
          chapterId: updatedChapter.id!,
          chapterTitle: updatedChapter.title,
          chapterNumber: updatedChapter.number,
        ),
      );

      for (var paragraph in updatedChapter.content!) {
        final tokens = await KanjiService.tokenizeText(paragraph);
        processed.add(
          ReaderItem(
            type: ReaderItemType.paragraph,
            tokens: tokens,
            chapterId: updatedChapter.id!,
            chapterTitle: updatedChapter.title,
            chapterNumber: updatedChapter.number,
          ),
        );
      }

      _lastLoadedChapterNumber = updatedChapter.number;
      _loadedChapterIds.clear();
      _loadedChapterIds.add(updatedChapter.id!);
      _loadedChapters.clear();
      _loadedChapters.add(updatedChapter);

      emit(state.copyWith(isLoading: false, items: processed));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _tokenizeContent() async {
    try {
      await _loadBookDetails();
      emit(state.copyWith(activeChapterTitle: chapter.title));

      if (chapter.content == null || chapter.content!.isEmpty) {
        emit(state.copyWith(isLoading: false));
        return;
      }

      List<ReaderItem> processed = [];

      // Tokenize title first
      final titleTokens = await KanjiService.tokenizeText(chapter.title);
      processed.add(
        ReaderItem(
          type: ReaderItemType.title,
          tokens: titleTokens,
          chapterId: chapter.id!,
          chapterTitle: chapter.title,
          chapterNumber: chapter.number,
        ),
      );

      for (var paragraph in chapter.content!) {
        final tokens = await KanjiService.tokenizeText(paragraph);
        processed.add(
          ReaderItem(
            type: ReaderItemType.paragraph,
            tokens: tokens,
            chapterId: chapter.id!,
            chapterTitle: chapter.title,
            chapterNumber: chapter.number,
          ),
        );
      }

      _lastLoadedChapterNumber = chapter.number;
      _loadedChapterIds.add(chapter.id!);
      _loadedChapters.add(chapter);

      emit(state.copyWith(isLoading: false, items: processed));
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: "Failed to process text: $e",
        ),
      );
    }
  }

  Future<void> loadNextChapter() async {
    if (state.isLoadingNext || state.activeWaitingChapter != null) {
      return;
    }

    final nextCh = _getNextChapter();
    if (nextCh == null) {
      return;
    }

    emit(state.copyWith(isLoadingNext: true));

    try {
      final dbCh = await dbService.getChapterWithContent(nextCh.id!);
      if (dbCh != null && dbCh.content != null && dbCh.content!.isNotEmpty) {
        await _appendChapter(dbCh);
      } else {
        emit(state.copyWith(activeWaitingChapter: nextCh));
      }
    } catch (e) {
      print("Error loading next chapter: $e");
      emit(state.copyWith(isLoadingNext: false));
    }
  }

  Future<void> _appendChapter(ChapterInfo dbCh) async {
    try {
      List<ReaderItem> updatedItems = List.from(state.items);

      // Add page break
      updatedItems.add(
        ReaderItem(
          type: ReaderItemType.pageBreak,
          tokens: [],
          chapterId: dbCh.id!,
          chapterTitle: dbCh.title,
          chapterNumber: dbCh.number,
        ),
      );

      // Tokenize and add title
      final titleTokens = await KanjiService.tokenizeText(dbCh.title);
      updatedItems.add(
        ReaderItem(
          type: ReaderItemType.title,
          tokens: titleTokens,
          chapterId: dbCh.id!,
          chapterTitle: dbCh.title,
          chapterNumber: dbCh.number,
        ),
      );

      // Tokenize and add paragraphs
      for (var paragraph in dbCh.content!) {
        final tokens = await KanjiService.tokenizeText(paragraph);
        updatedItems.add(
          ReaderItem(
            type: ReaderItemType.paragraph,
            tokens: tokens,
            chapterId: dbCh.id!,
            chapterTitle: dbCh.title,
            chapterNumber: dbCh.number,
          ),
        );
      }

      _lastLoadedChapterNumber = dbCh.number;
      if (!_loadedChapterIds.contains(dbCh.id)) {
        _loadedChapterIds.add(dbCh.id!);
        _loadedChapters.add(dbCh);
      }

      emit(
        state.copyWith(
          items: updatedItems,
          isLoadingNext: false,
          activeWaitingChapter: null,
        ),
      );
    } catch (e) {
      print("Error appending chapter: $e");
      emit(state.copyWith(isLoadingNext: false));
    }
  }

  Future<void> onChapterDownloaded(int chapterId) async {
    if (chapterId == chapter.id && state.items.isEmpty) {
      await reloadContent();
    } else if (state.activeWaitingChapter?.id == chapterId) {
      final dbCh = await dbService.getChapterWithContent(chapterId);
      if (dbCh != null && dbCh.content != null && dbCh.content!.isNotEmpty) {
        await _appendChapter(dbCh);
      }
    }
  }

  void updateActiveChapter(ChapterInfo activeChapter) {
    if (state.activeChapterTitle != activeChapter.title) {
      emit(state.copyWith(activeChapterTitle: activeChapter.title));
      dbService.updateBookAccess(bookId, activeChapter.number);
    }
  }

  Future<void> lookupToken(
    String token,
    int paragraphIndex,
    int tokenIndex,
  ) async {
    if (token.trim().isEmpty) return;
    final (wordMap, kanjis) = await KanjiService.lookupToken(token);

    if (state.selectedParagraphIndex == paragraphIndex &&
        state.selectedTokenIndex == tokenIndex) {
      clearSelection();
      return;
    }

    emit(
      state.copyWith(
        selectedEntry: DictionaryEntry(wordMap, kanjis: kanjis),
        selectedParagraphIndex: paragraphIndex,
        selectedTokenIndex: tokenIndex,
      ),
    );
  }

  void clearSelection() {
    emit(
      state.copyWith(
        selectedEntry: null,
        selectedParagraphIndex: null,
        selectedTokenIndex: null,
      ),
    );
  }

  void setDictOrientation(DictOrientation orientation) {
    settings.setDictOrientation(orientation);
    emit(state.copyWith(dictOrientation: orientation));
  }
}
