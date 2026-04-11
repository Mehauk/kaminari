import 'package:flutter_bloc/flutter_bloc.dart';

class WebviewState {
  final String url;
  final String title;
  final double progress;
  final bool isLoading;
  final bool canGoBack;
  final bool canGoForward;
  final bool isImporting;
  final bool hasAppliedPadding; // 1. Added this

  const WebviewState({
    this.url = '',
    this.title = 'Loading...',
    this.progress = 0.0,
    this.isLoading = true,
    this.canGoBack = false,
    this.canGoForward = false,
    this.isImporting = false,
    this.hasAppliedPadding = false, // 2. Default to false
  });

  WebviewState copyWith({
    String? url,
    String? title,
    double? progress,
    bool? isLoading,
    bool? canGoBack,
    bool? canGoForward,
    bool? isImporting,
    bool? hasAppliedPadding, // 3. Added to copyWith
  }) {
    return WebviewState(
      url: url ?? this.url,
      title: title ?? this.title,
      progress: progress ?? this.progress,
      isLoading: isLoading ?? this.isLoading,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isImporting: isImporting ?? this.isImporting,
      hasAppliedPadding: hasAppliedPadding ?? this.hasAppliedPadding,
    );
  }
}

class WebviewCubit extends Cubit<WebviewState> {
  WebviewCubit() : super(const WebviewState());

  void updateProgress(int progress) {
    emit(state.copyWith(progress: progress / 100, isLoading: progress < 100));
  }

  // 4. Added to track when the JS has run
  void setPaddingApplied(bool applied) {
    emit(state.copyWith(hasAppliedPadding: applied));
  }

  // 5. Helper to reset everything when a new page starts
  void resetForNewPage() {
    emit(
      state.copyWith(progress: 0, isLoading: true, hasAppliedPadding: false),
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
        url: url,
        title: title,
      ),
    );
  }

  void setImporting(bool importing) {
    emit(state.copyWith(isImporting: importing));
  }
}
