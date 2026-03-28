import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/pages/home/screens/bloc/history_cubit.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/book_cards.dart';
import 'package:kaminari/src/ui/widgets/empty_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(dbService: context.read()),
      child: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          final books = state.filter == HistoryFilter.favorites
              ? state.history.where((book) => book.isFavorite).toList()
              : state.history;

          return SingleChildScrollView(
            child: Column(
              children: [
                const LightningAppBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 32),
                      SegmentedButton<bool>(
                        onSelectionChanged: (selected) {
                          final isFavorites = selected.contains(true);
                          context.read<HistoryCubit>().setFilter(
                            isFavorites
                                ? HistoryFilter.favorites
                                : HistoryFilter.all,
                          );
                        },
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(value: true, icon: Text('Favorites')),
                          ButtonSegment(value: false, icon: Text('All')),
                        ],
                        selected: {state.filter == HistoryFilter.favorites},
                      ),
                      const SizedBox(height: 32),
                      if (state.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (books.isEmpty)
                        EmptyState(
                          icon: const Icon(Icons.book_outlined, size: 48),
                          title: state.filter == HistoryFilter.favorites
                              ? 'No favorites yet.'
                              : 'No reading history yet.',
                          subtitle: state.filter == HistoryFilter.favorites
                              ? 'Mark books as favorites to see them here.'
                              : 'Open a book to start tracking your reading history.',
                        )
                      else
                        Column(
                          spacing: 16,
                          children: books
                              .map(
                                (book) => HistoryBookCard(
                                  book,
                                  onFavoriteToggle: () => context
                                      .read<HistoryCubit>()
                                      .toggleFavorite(book),
                                ),
                              )
                              .toList(),
                        ),
                      const SizedBox(height: 56),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
