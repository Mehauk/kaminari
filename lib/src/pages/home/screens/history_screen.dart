import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/pages/home/screens/bloc/history_cubit.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/book_cards.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HistoryCubit(dbService: context.read()),
      child: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
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
                      else if (state.history.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 64),
                          child: Text("No reading history yet."),
                        )
                      else
                        Column(
                          spacing: 16,
                          children: state.history
                              .map((book) => HistoryBookCard(book))
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
