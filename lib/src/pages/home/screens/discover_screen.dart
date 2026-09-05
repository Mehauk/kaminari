import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/pages/home/screens/bloc/discover_cubit.dart';
import 'package:kaminari/src/pages/webview/widgets/import_overlay_views.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/book_cards.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/empty_state.dart';
import 'package:kaminari/src/ui/widgets/grid.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  void importFromContext(BuildContext context) {
    final query = context.read<DiscoverCubit>().state.query;
    final url = query.startsWith('http')
        ? query
        : 'https://www.google.com/search?q=$query';
    Navigator.of(context).pushNamed('/import-view', arguments: url);
  }

  Future<void> _pickEpubFile(BuildContext context) async {
    final cubit = context.read<DiscoverCubit>();
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );

    if (result != null && result.files.single.path != null) {
      await cubit.importEpubFile(result.files.single.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoverCubit(dbService: context.read()),
      child: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          final cubit = context.read<DiscoverCubit>();

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const LightningAppBar(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: cubit.setQuery,
                                  onSubmitted: (_) =>
                                      importFromContext(context),
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.link),
                                    labelText: 'Add a book or source',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filled(
                                onPressed: () => importFromContext(context),
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // New Local Import Trigger
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _pickEpubFile(context),
                              icon: const Icon(
                                Icons.file_open_outlined,
                                size: 18,
                              ),
                              label: const Text("IMPORT LOCAL EPUB EBOOK"),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              spacing: 8,
                              children: BookType.values
                                  .map((v) => _FilterChip(v))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              if (state.books.isEmpty) {
                                return EmptyState(
                                  icon: const Icon(Icons.search_off, size: 48),
                                  title: state.query.isEmpty
                                      ? 'No books yet.'
                                      : 'No results for "${state.query}"',
                                  subtitle: state.query.isEmpty
                                      ? 'Add a web novel or import a local EPUB.'
                                      : 'Try a different search or pick an EPUB.',
                                  actionLabel: 'Add / Search',
                                  onAction: () => importFromContext(context),
                                );
                              }

                              return Grid.fromColumns(
                                columns: 2,
                                totalWidth: constraints.maxWidth,
                                spacing: 12,
                                runSpacing: 12,
                                children: state.books
                                    .map((b) => (1, DiscoverableBookCard(b)))
                                    .toList(),
                              );
                            },
                          ),
                          const SizedBox(height: 56),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Processing and preview layers
              if (state.isImporting)
                Positioned.fill(
                  child: BgFilter(
                    bgColor: Colors.black.withAlpha(200),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                ),

              if (state.epubPreviewBook != null)
                Positioned.fill(
                  child: BgFilter(
                    bgColor: Colors.black.withAlpha(200),
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: LightningCard(
                              type: LightningBorderEffectType.striking,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: SingleChildScrollView(
                                  child: ImportPreviewView(
                                    book: state.epubPreviewBook!,
                                    onTypeChanged: cubit.updatePreviewBookType,
                                    onConfirm: cubit.confirmEpubImport,
                                    onRetry: () => _pickEpubFile(context),
                                    onCancel: cubit.cancelEpubImport,
                                    onInvertChapters:
                                        cubit.invertPreviewChapters,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              if (state.importErrorMessage != null)
                Positioned.fill(
                  child: BgFilter(
                    bgColor: Colors.black.withAlpha(200),
                    child: SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: LightningCard(
                              type: LightningBorderEffectType.thin,
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: ImportFailureView(
                                  message: state.importErrorMessage!,
                                  onRetry: () => _pickEpubFile(context),
                                  onCancel: cubit.cancelEpubImport,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip(this.filter);

  final BookType filter;

  @override
  Widget build(BuildContext context) {
    final selectedFilter = context.select<DiscoverCubit, BookType>(
      (c) => c.state.filter,
    );
    final selected = filter == selectedFilter;
    return DecoratedBox(
      decoration: ShapeDecoration(
        shadows: [
          selected
              ? BoxShadow(
                  color: KaminariTheme.textTitle.withAlpha(25),
                  blurRadius: 10,
                )
              : BoxShadow(color: Colors.black26, blurRadius: 10),
        ],
        color: selected
            ? KaminariTheme.textTitle.withAlpha(50)
            : KaminariTheme.surfaceVariant,
        shape: StadiumBorder(
          side: selected
              ? BorderSide(color: KaminariTheme.textTitle.withAlpha(75))
              : BorderSide.none,
        ),
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: StadiumBorder()),
        child: InkWell(
          onTap: () => context.read<DiscoverCubit>().setFilter(filter),
          child: Padding(
            padding: const .symmetric(vertical: 9, horizontal: 20),
            child: CustomText(
              filter.text,
              .labelSmall,
              color: selected ? KaminariTheme.textTitle : null,
            ),
          ),
        ),
      ),
    );
  }
}
