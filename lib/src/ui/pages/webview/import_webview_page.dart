import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/webview/webview_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
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

  Future<void> _handleImport(BuildContext context) async {
    final cubit = context.read<WebviewCubit>();
    cubit.setImporting(true);

    try {
      // 1. Extract compressed text AND the cover image natively via JS
      final String rawPayload =
          await _controller.runJavaScriptReturningResult("""
      (function() {
        // Grab cover URL from OpenGraph tags if available
        const ogImage = document.querySelector('meta[property="og:image"]')?.content || '';
        
        const doc = document.cloneNode(true);
        doc.querySelectorAll('script, style, svg, img, footer, nav, noscript').forEach(el => el.remove());
        const text = doc.body.innerText.replace(/\\s+/g, ' ').trim().substring(0, 4500); 
        
        return JSON.stringify({ "text": text, "coverUrl": ogImage });
      })()
    """)
              as String;

      final Map<String, dynamic> siteData = jsonDecode(rawPayload);
      final String cleanText = siteData['text'] ?? '';
      final String coverUrl = siteData['coverUrl'] ?? '';

      // 2. Prompt Gemma 2B with a strict JSON schema constraint
      final String prompt =
          """
You are a precise data extraction bot. Extract the book metadata from the text below. 
Respond strictly in valid JSON matching this schema exactly, with no markdown formatting or extra text:
{
  "title": "Original Title",
  "titleRomaji": "English or Romaji Title",
  "author": "Author Name",
  "synopsis": "Full synopsis summary",
  "chapters": ["Chapter 1 title", "Chapter 2 title"]
}

Text to extract:
$cleanText
""";

      // Call your local LLM inference (Placeholder)
      final String llmJsonOutput = await _runGemmaInference(prompt);

      // 3. Parse LLM output safely into your BookDetails Freezed model
      final BookDetails extractedBook = _parseToBookDetails(
        llmOutput: llmJsonOutput,
        scrapedCoverUrl: coverUrl,
      );

      cubit.setImporting(false);

      // Success! You now have a complete BookDetails object.
      // E.g., pass it to your storage repository or navigate:
      print("Successfully scraped: ${extractedBook.title}");
      // Navigator.pushNamed(context, '/book-details', arguments: extractedBook.id);
    } catch (e) {
      // Trigger the red "FAILED TO IMPORT" button state
      print(e);
      cubit.setExtractionFailed(true);
    }
  }

  /// Safely maps the raw JSON string from Gemma 2B into your Freezed [BookDetails]
  BookDetails _parseToBookDetails({
    required String llmOutput,
    required String scrapedCoverUrl,
  }) {
    // Clean potential markdown blocks if Gemma ignored instructions (e.g. ```json ... ```)
    final String sanitizedOutput = llmOutput
        .replaceAll(RegExp(r'```json'), '')
        .replaceAll(RegExp(r'```'), '')
        .trim();

    final Map<String, dynamic> data = jsonDecode(sanitizedOutput);

    // Map the raw chapter strings into your Freezed ChapterInfo objects
    final List<dynamic> rawChapters = data['chapters'] as List<dynamic>? ?? [];
    final List<ChapterInfo> chapters = rawChapters.asMap().entries.map((entry) {
      return ChapterInfo(
        number: entry.key + 1,
        title: entry.value.toString().trim(),
        isRead: false,
        wordCount: 0, // Default since we don't know yet
      );
    }).toList();

    // Generate safe fallback estimates for UI stats
    final int totalChaps = chapters.isNotEmpty ? chapters.length : 1;
    final String fallbackCover = scrapedCoverUrl.isNotEmpty
        ? scrapedCoverUrl
        // Generic fallback dark placeholder if no image was found
        : 'https://placehold.co/400x600/15130B/E8E2D4/png?text=No+Cover';

    return BookDetails(
      id: 'imported-${DateTime.now().millisecondsSinceEpoch}',
      title: data['title']?.toString() ?? 'Unknown Title',
      titleRomaji:
          data['titleRomaji']?.toString() ?? data['title']?.toString() ?? '',
      author: data['author']?.toString() ?? 'Unknown Author',
      coverUrl: fallbackCover,
      bookType: 'Web Novel', // Sensible default for a web scraper
      jlptLevel: 'N/A', // Provide an unassigned default
      synopsis: data['synopsis']?.toString() ?? 'No synopsis available.',
      totalPages: totalChaps,
      currentPage: 1,
      currentChapter: chapters.isNotEmpty ? chapters.first.title : 'Chapter 1',
      chapters: chapters,
      totalWordCount:
          totalChaps * 3000, // Rough estimation: 3k words per chapter
      estimatedMinutes: (totalChaps * 3000) ~/ 200, // Estimate based on 200 wpm
      synopsisExpanded: false,
    );
  }

  Future<String> _runGemmaInference(String prompt) async {
    throw ("ERORS");
  }

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
                  _WebAddressBar(controller: _controller),
                  if (state.isLoading)
                    LinearProgressIndicator(
                      value: state.progress,
                      minHeight: 4,
                    ),
                ],
              ),
            ],
          ),
          floatingActionButton: BlocBuilder<WebviewCubit, WebviewState>(
            builder: (context, state) {
              // Determine button state
              final bool isFailed = state.extractionFailed;
              final bool isImporting = state.isImporting;
              final bool isDisabled = isFailed || isImporting;

              return FloatingActionButton.extended(
                // Disable if importing OR if it failed once on this page
                onPressed: isDisabled ? null : () => _handleImport(context),

                // Error color if failed, otherwise standard
                backgroundColor: isFailed ? KaminariTheme.error : null,

                icon: isImporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      )
                    : Icon(isFailed ? Icons.close : Icons.download_outlined),

                label: Text(
                  isFailed
                      ? "FAILED TO IMPORT"
                      : (isImporting ? "IMPORTING..." : "IMPORT"),
                ),
              );
            },
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
