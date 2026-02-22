import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/models/book.dart';
import 'package:kaminari/src/pages/home/screens/bloc/discover_cubit.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/grid.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  void importFromContext(BuildContext context) {
    final query = context.read<DiscoverCubit>().state.query;
    // If it's a URL, go there, otherwise search
    final url = query.startsWith('http')
        ? query
        : 'https://www.google.com/search?q=$query';
    Navigator.of(context).pushNamed('/import-view', arguments: url);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoverCubit(),
      child: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                LightningAppBar(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: .end,
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              onChanged: context.read<DiscoverCubit>().setQuery,
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
                          return Grid.fromColumns(
                            columns: 2,
                            totalWidth: constraints.maxWidth,
                            spacing: 12,
                            runSpacing: 12,
                            children: [],
                          );
                        },
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
