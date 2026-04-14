import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kaminari/src/data/services/llm_service.dart';

part 'llm_cubit.freezed.dart';

enum LlmStatus { initial, notInstalled, downloading, installed, error }

@freezed
abstract class LlmState with _$LlmState {
  const factory LlmState({
    @Default(LlmStatus.initial) LlmStatus status,
    @Default(0) int progress,
    String? errorMessage,
  }) = _LlmState;
}

class LlmCubit extends Cubit<LlmState> {
  final LlmService llm;

  LlmCubit(this.llm) : super(const LlmState()) {
    checkStatus();
  }

  Future<void> checkStatus() async {
    try {
      final downloaded = await llm.isDownloaded();
      if (downloaded) {
        emit(state.copyWith(status: LlmStatus.installed, progress: 100));
      } else {
        emit(state.copyWith(status: LlmStatus.notInstalled));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: LlmStatus.error,
          errorMessage: "Failed to check model status: $e",
        ),
      );
    }
  }

  Future<void> downloadAndInstall() async {
    emit(state.copyWith(status: LlmStatus.downloading, progress: 0));

    try {
      await llm.download().withProgress((int progress) {
        emit(state.copyWith(progress: progress));
      }).install();

      emit(state.copyWith(status: LlmStatus.installed, progress: 100));
    } catch (e) {
      emit(
        state.copyWith(
          status: LlmStatus.error,
          errorMessage: "Download failed: $e",
        ),
      );
    }
  }
}
