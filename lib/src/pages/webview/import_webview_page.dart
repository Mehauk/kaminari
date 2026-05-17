import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/data/repositories/extractor_builder.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:kaminari/src/pages/reader/dictionary_view.dart';
import 'package:kaminari/src/pages/webview/import_webview_cubit.dart';
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
                ),
            ],
          ),
          floatingActionButton: isNotImported
              ? FloatingActionButton.extended(
                  onPressed: () => webviewCubit.handleImport(),
                  backgroundColor: webviewState.importStatus.color,
                  icon: Icon(webviewState.importStatus.icon),
                  label: Text(webviewState.importStatus.label),
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

  const _ImportingProgressOverlay({
    required this.state,
    required this.onTypeChanged,
    required this.onConfirm,
    required this.onRetry,
    required this.onCancel,
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
                    child: SingleChildScrollView(child: _buildContent(context)),
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
    return switch (state.importStatus) {
      ImportStatus.extracting ||
      ImportStatus.saving => _buildLoadingState(context),
      ImportStatus.preview => _buildPreviewState(context),
      ImportStatus.success => _buildSuccessState(context),
      ImportStatus.failure => _buildFailureState(context),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildLoadingState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          state.importStatus == ImportStatus.saving
              ? "Saving Entry..."
              : "AI Web Parsing",
          TextType.headlineMedium,
          alignment: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 110,
              child: CircularProgressIndicator(
                value: state.importProgress,
                strokeWidth: 5,
              ),
            ),
            CustomText(
              "${(state.importProgress * 100).toStringAsFixed(0)}%",
              TextType.labelMedium,
            ),
          ],
        ),
        const SizedBox(height: 32),
        CustomText(
          state.progressMessage,
          TextType.bodyMedium,
          alignment: TextAlign.center,
        ),
        if (state.importStatus == ImportStatus.extracting) ...[
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onCancel,
            child: const Text("CANCEL EXTRACTION"),
          ),
        ],
      ],
    );
  }

  Widget _buildPreviewState(BuildContext context) {
    final book = state.previewBook;
    if (book == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CustomText("Verify Extracted Data", TextType.headlineMedium),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                border: LightningBorderEffectType.thin.border(),
                borderRadius: BorderRadius.circular(
                  KaminariTheme.altBorderRadius,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  KaminariTheme.altBorderRadius,
                ),
                child: Image.network(
                  book.coverUrl ?? '',
                  width: 80,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Image.asset(
                    'assets/images/placeholder_book.png',
                    width: 80,
                    height: 110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(book.title, TextType.titleMedium, maxLines: 2),
                  const SizedBox(height: 4),
                  CustomText(
                    "Author: ${book.author}",
                    TextType.bodyMedium,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  CustomText(
                    "Chapters: ${book.chapters.length}",
                    TextType.labelSmall,
                    color: KaminariTheme.textSecondary,
                  ),
                  if (book.jlptLevel != null) ...[
                    const SizedBox(height: 4),
                    CustomText(
                      "Difficulty: JLPT ${book.jlptLevel}",
                      TextType.labelSmall,
                      color: KaminariTheme.cyan,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const CustomText(
          "Synopsis",
          TextType.labelSmall,
          color: KaminariTheme.textTitle,
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 120),
          child: SingleChildScrollView(
            child: Text(
              book.synopsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: KaminariTheme.textSecondary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const CustomText(
          "Select Book Type",
          TextType.labelSmall,
          color: KaminariTheme.textTitle,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<BookType>(
            segments: BookType.values
                .where((t) => t != BookType.all)
                .map(
                  (t) => ButtonSegment<BookType>(value: t, label: Text(t.text)),
                )
                .toList(),
            selected: {book.bookType},
            onSelectionChanged: (selected) {
              if (selected.isNotEmpty) {
                onTypeChanged(selected.first);
              }
            },
            showSelectedIcon: false,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onRetry,
                child: const Text("RETRY AI"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onConfirm,
                child: const Text("CONFIRM"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: onCancel,
            child: const Text("DISCARD & CLOSE"),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle_outline_rounded,
          color: KaminariTheme.success,
          size: 64,
        ),
        const SizedBox(height: 16),
        const CustomText("Import Complete", TextType.headlineMedium),
        const SizedBox(height: 12),
        CustomText(
          "\"${state.previewBook?.title ?? 'The book'}\" has been cataloged successfully. Background cache operations are preparing chapter structures.",
          TextType.bodyMedium,
          alignment: TextAlign.center,
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("CLOSE WEBVIEW"),
          ),
        ),
      ],
    );
  }

  Widget _buildFailureState(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: KaminariTheme.error,
          size: 64,
        ),
        const SizedBox(height: 16),
        const CustomText("Operation Failed", TextType.headlineMedium),
        const SizedBox(height: 12),
        CustomText(
          state.progressMessage,
          TextType.bodyMedium,
          alignment: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancel,
                child: const Text("ABANDON"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: onRetry,
                child: const Text("RETRY"),
              ),
            ),
          ],
        ),
      ],
    );
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
                  cubit.state.selectedEntry,
                  cubit.clearSelection,
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
