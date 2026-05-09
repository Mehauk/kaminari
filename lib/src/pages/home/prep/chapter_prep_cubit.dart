import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/services/chapter_analysis_service.dart';

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
  ChapterPrepCubit(ChapterInfo chapter) : super(const ChapterPrepState()) {
    _init(chapter);
  }

  Future<void> _init(ChapterInfo chapter) async {
    final items = await ChapterAnalysisService.analyzeChapter(chapter);
    emit(state.copyWith(items: items, isLoading: false));
  }

  void toggleFlip() => emit(state.copyWith(isFlipped: !state.isFlipped));

  void nextCard() {
    if (state.currentIndex < state.items.length - 1) {
      emit(
        state.copyWith(currentIndex: state.currentIndex + 1, isFlipped: false),
      );
    }
  }
}
