import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/services/llm_service.dart';
import 'package:kaminari/src/pages/webview/import_webview_cubit.dart';
import 'package:kaminari/src/pages/webview/importing_dialog.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ImportWebviewPage extends StatelessWidget {
  final String? initialUrl;
  const ImportWebviewPage({super.key, this.initialUrl});

  @override
  Widget build(context) {
    return BlocProvider(
      create: (context) => WebviewCubit(
        llmService: LlmService(),
        extractorCache: context.read(),
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
        final bool isDisabled = webviewState.importStatus != .notImported;

        return Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: WebViewWidget(controller: webviewCubit.controller),
                  ),
                ],
              ),
              Column(
                children: [
                  _WebAddressBar(controller: webviewCubit.controller),
                  if (webviewState.isLoading)
                    LinearProgressIndicator(minHeight: 4),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: isDisabled
                ? null
                : () async {
                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) => ImportingDialog(),
                    );
                    await webviewCubit.handleImport();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
            backgroundColor: webviewState.importStatus.color,
            icon: Icon(webviewState.importStatus.icon),
            label: Text(webviewState.importStatus.label),
          ),
        );
      },
    );
  }
}

class _WebAddressBar extends StatelessWidget {
  const _WebAddressBar({required this.controller});
  final WebViewController controller;

  @override
  Widget build(BuildContext context) {
    final url = context.select<WebviewCubit, String>((c) => c.state.url);
    return ClipRRect(
      child: BgFilter(
        bgColor: KaminariTheme.background.withAlpha(220),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
            child: Row(
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
