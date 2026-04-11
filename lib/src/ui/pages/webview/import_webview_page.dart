import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/webview/webview_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
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
      create: (_) => WebviewCubit(),
      child: _ImportWebviewPage(initialUrl: initialUrl),
    );
  }
}

class _ImportWebviewPage extends StatefulWidget {
  const _ImportWebviewPage({this.initialUrl});
  final String? initialUrl;

  @override
  State<_ImportWebviewPage> createState() => __ImportWebviewPageState();
}

class __ImportWebviewPageState extends State<_ImportWebviewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            final cubit = context.read<WebviewCubit>();
            cubit.updateProgress(progress);

            if (progress >= 30 && !cubit.state.hasAppliedPadding) {
              cubit.setPaddingApplied(true); // Update Cubit immediately
              _controller.runJavaScript(
                "document.body.style.paddingTop = '120px'",
              );
            }
          },
          onPageStarted: (url) => {
            context.read<WebviewCubit>().resetForNewPage(),
          },
          onPageFinished: (url) async {
            // Re-apply on finish just in case the site cleared it
            _controller.runJavaScript(
              "document.body.style.paddingTop = '120px'",
            );

            final title = await _controller.getTitle();
            final canBack = await _controller.canGoBack();
            final canForward = await _controller.canGoForward();

            if (mounted) {
              context.read<WebviewCubit>().updateNavigation(
                back: canBack,
                forward: canForward,
                url: url,
                title: title,
              );
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl ?? 'https://syosetu.com/'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebviewCubit, WebviewState>(
      builder: (context, state) {
        return Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(child: WebViewWidget(controller: _controller)),
                ],
              ),
              Column(
                children: [
                  _WebAddressBar(controller: _controller, state: state),
                  if (state.isLoading)
                    LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 4,
                    ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: state.isImporting
                ? null
                : () {
                    context.read<WebviewCubit>().setImporting(true);
                  },
            icon: state.isImporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.download_outlined),
            label: Text(state.isImporting ? "IMPORTING..." : "IMPORT"),
          ),
        );
      },
    );
  }
}

class _WebAddressBar extends StatelessWidget {
  const _WebAddressBar({required this.controller, required this.state});
  final WebViewController controller;
  final WebviewState state;

  @override
  Widget build(BuildContext context) {
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
                            state.url,
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
