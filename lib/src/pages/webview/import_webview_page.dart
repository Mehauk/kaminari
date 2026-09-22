import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/app_settings.dart';
import 'package:kaminari/src/data/repositories/extractor_builder.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/pages/webview/import_webview_cubit.dart';
import 'package:kaminari/src/pages/webview/widgets/import_overlay_views.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ImportWebviewPage extends StatelessWidget {
  final String? initialUrl;
  const ImportWebviewPage({super.key, this.initialUrl});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => WebviewCubit(
        extractorBuilder: ExtractorBuilder(LlmService(), context.read()),
        backgroundWebviewCubit: context.read(),
        appSettings: context.read<AppSettings>(),
        initialUrl: initialUrl,
      ),
      child: const _ImportWebviewPage(),
    );
  }
}

class _ImportWebviewPage extends StatelessWidget {
  const _ImportWebviewPage();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebviewCubit, WebviewState>(
      builder: (context, webviewState) {
        final webviewCubit = context.read<WebviewCubit>();
        final bool isNotImported =
            webviewState.importStatus == ImportStatus.notImported;

        return Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  const SizedBox(height: 100),
                  Expanded(
                    child: WebViewWidget(controller: webviewCubit.controller),
                  ),
                ],
              ),
              Column(
                children: [
                  _WebAddressBar(controller: webviewCubit.controller),
                  if (webviewState.isLoading)
                    const LinearProgressIndicator(minHeight: 4),
                ],
              ),
              if (!isNotImported)
                _ImportingProgressOverlay(
                  state: webviewState,
                  onTypeChanged: webviewCubit.updatePreviewBookType,
                  onConfirm: webviewCubit.confirmImport,
                  onRetry: () => webviewCubit.handleImport(forceReload: true),
                  onCancel: webviewCubit.cancelImport,
                  onHide: webviewCubit.hideOverlay,
                ),
            ],
          ),
          floatingActionButton: isNotImported
              ? FloatingActionButton.extended(
                  onPressed: () => webviewCubit.handleImport(),
                  backgroundColor: webviewState.importStatus.color,
                  icon: Icon(webviewState.importStatus.icon),
                  label: Text(
                    webviewState.previewBook != null
                        ? "Show overlay"
                        : webviewState.importStatus.label,
                  ),
                )
              : null,
        );
      },
    );
  }
}

class _ImportingProgressOverlay extends StatelessWidget {
  final WebviewState state;
  final ValueChanged<BookType> onTypeChanged;
  final VoidCallback onConfirm;
  final VoidCallback onRetry;
  final VoidCallback onCancel;
  final VoidCallback onHide;

  const _ImportingProgressOverlay({
    required this.state,
    required this.onTypeChanged,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BgFilter(
        bgColor: Colors.black.withAlpha(200),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: LightningCard(
                  type: _getBorderType(),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: _buildContent(context),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  LightningBorderEffectType _getBorderType() {
    return switch (state.importStatus) {
      ImportStatus.preview => LightningBorderEffectType.striking,
      ImportStatus.success => LightningBorderEffectType.glowing,
      _ => LightningBorderEffectType.thin,
    };
  }

  Widget _buildContent(BuildContext context) {
    final webviewCubit = context.read<WebviewCubit>();
    return switch (state.importStatus) {
      ImportStatus.extracting || ImportStatus.saving => ImportLoadingView(
        progress: state.importProgress,
        message: state.progressMessage,
        isSaving: state.importStatus == ImportStatus.saving,
        onCancel: onCancel,
      ),
      ImportStatus.preview => ImportPreviewView(
        book: state.previewBook!,
        onTypeChanged: onTypeChanged,
        onConfirm: onConfirm,
        onRetry: onRetry,
        onRetryMetadata: webviewCubit.handleImportMetadata,
        onRetryChapters: webviewCubit.handleImportChapters,
        onCancel: onCancel,
        onHide: onHide,
        onMissingChapters: webviewCubit.resumeImport,
        showMissingChaptersBtn: webviewCubit.showMissingChapters,
        unpinnedFields: state.unpinnedFields,
        onTogglePin: webviewCubit.togglePinField,
      ),
      ImportStatus.success => ImportSuccessView(
        bookTitle: state.previewBook?.title,
        chapters: state.previewBook?.chapters,
        onDone: () => Navigator.of(context).pop(true),
      ),
      ImportStatus.failure => ImportFailureView(
        message: state.progressMessage,
        onCancel: onCancel,
        onRetry: onRetry,
        onRetryMetadata: webviewCubit.hasSelectors
            ? webviewCubit.handleImportMetadata
            : null,
        onRetryChapters: webviewCubit.hasSelectors
            ? webviewCubit.handleImportChapters
            : null,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _WebAddressBar extends StatelessWidget {
  const _WebAddressBar({required this.controller});
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WebviewCubit>();
    final url = cubit.state.url;
    return ClipRRect(
      child: BgFilter(
        bgColor: KaminariTheme.background.withAlpha(220),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    LightningIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: KaminariTheme.colorScheme.primaryContainer
                              .withAlpha(30),
                          borderRadius: BorderRadius.circular(
                            KaminariTheme.altBorderRadius,
                          ),
                          border: Border.all(
                            color: KaminariTheme.surfaceTint.withAlpha(50),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: KaminariTheme.cyan,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CustomText(
                                url,
                                TextType.labelSmall,
                                fontSize: 12,
                                color: KaminariTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    LightningIconButton(
                      icon: Icons.refresh,
                      onPressed: () => controller.reload(),
                    ),
                    if (kDebugMode)
                      LightningIconButton(
                        icon: Icons.bug_report_outlined,
                        onPressed: () => _showCachedExtractorsDialog(context),
                      ),
                  ],
                ),
                DictionaryView(
                  entry: cubit.state.selectedEntry,
                  clearSelection: cubit.clearSelection,
                  orientation: .top,
                  alignment: .right,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCachedExtractorsDialog(BuildContext context) {
    final cubit = context.read<WebviewCubit>();
    final cachedExtractors = cubit.getCachedExtractors();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cached Extractors'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cachedExtractors.isEmpty)
                const Text('No cached extractors found')
              else
                ...cachedExtractors.entries.map((entry) {
                  final origin = entry.key;
                  final extractors = entry.value;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        origin,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...extractors.entries.map((extEntry) {
                        final type = extEntry.key;
                        final extractor = extEntry.value;
                        return Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$type:',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[900],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  extractor.length > 200
                                      ? '${extractor.substring(0, 200)}...'
                                      : extractor,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontFamily: 'monospace',
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
