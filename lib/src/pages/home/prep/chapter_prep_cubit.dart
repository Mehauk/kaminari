import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/chapter_analysis_service.dart';
import 'package:kaminari/src/data/services/database_service.dart';

part 'chapter_prep_cubit.freezed.dart';

@freezed
abstract class ChapterPrepState with _$ChapterPrepState {
  const factory ChapterPrepState({
    @Default(true) bool isLoading,
    @Default([]) List<EntryAnalysisModel> items,
    @Default(0) int currentIndex,
    @Default(false) bool isFlipped,
  }) = _ChapterPrepState;
}

class ChapterPrepCubit extends Cubit<ChapterPrepState> {
  final int bookId;
  final DatabaseService dbService;
  ChapterInfo chapter;

  ChapterPrepCubit(this.bookId, this.chapter, this.dbService)
    : super(const ChapterPrepState()) {
    _init(chapter);
  }

  Future<void> _init(ChapterInfo chapter) async {
    final items = await ChapterAnalysisService.analyzeChapter(
      bookId,
      chapter,
      db: dbService,
    );
    emit(state.copyWith(items: items, isLoading: false));

    // Save initial progress of 1 if the user opens the deck for the first time
    if (items.isNotEmpty && chapter.prepReviewedCount == 0) {
      await dbService.updateChapterPrepProgress(chapter.id!, 1);
      this.chapter = chapter.copyWith(prepReviewedCount: 1);
    }
  }

  void toggleFlip() => emit(state.copyWith(isFlipped: !state.isFlipped));

  Future<void> nextCard() async {
    final nextIndex = state.currentIndex + 1;
    if (nextIndex < state.items.length) {
      emit(state.copyWith(currentIndex: nextIndex, isFlipped: false));
      await _updatePrepProgress(nextIndex);
    }
  }

  void previousCard() {
    if (state.currentIndex > 0) {
      emit(
        state.copyWith(currentIndex: state.currentIndex - 1, isFlipped: false),
      );
    }
  }

  Future<void> _updatePrepProgress(int nextIndex) async {
    final progress = nextIndex + 1;
    if (progress > chapter.prepReviewedCount) {
      await dbService.updateChapterPrepProgress(chapter.id!, progress);
      chapter = chapter.copyWith(prepReviewedCount: progress);
    }
  }
}
