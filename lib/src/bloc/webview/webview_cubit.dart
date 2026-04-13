import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'webview_cubit.freezed.dart';

@freezed
abstract class WebviewState with _$WebviewState {
  const factory WebviewState({
    @Default('') String url,
    @Default('Loading...') String title,
    @Default(0.0) double progress,
    @Default(true) bool isLoading,
    @Default(false) bool canGoBack,
    @Default(false) bool canGoForward,
    @Default(false) bool isImporting,
    @Default(false) bool hasAppliedPadding,
    @Default(false) bool extractionFailed,
  }) = _WebviewState;
}

class WebviewCubit extends Cubit<WebviewState> {
  WebviewCubit() : super(const WebviewState());

  void setExtractionFailed(bool failed) {
    emit(state.copyWith(extractionFailed: failed, isImporting: false));
  }

  void updateProgress(int progress) {
    emit(state.copyWith(progress: progress / 100, isLoading: progress < 100));
  }

  void setPaddingApplied(bool applied) {
    emit(state.copyWith(hasAppliedPadding: applied));
  }

  void resetForNewPage() {
    emit(
      state.copyWith(
        progress: 0,
        isLoading: true,
        hasAppliedPadding: false,
        extractionFailed: false,
      ),
    );
  }

  void updateNavigation({
    required bool back,
    required bool forward,
    String? url,
    String? title,
  }) {
    emit(
      state.copyWith(
        canGoBack: back,
        canGoForward: forward,
        url: url ?? state.url,
        title: title ?? state.title,
      ),
    );
  }

  void setImporting(bool importing) {
    emit(state.copyWith(isImporting: importing));
  }
}
