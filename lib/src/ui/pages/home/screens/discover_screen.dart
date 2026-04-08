import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/home/screens/discover_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/book_cards.dart';
import 'package:kaminari/src/ui/widgets/grid.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DiscoverCubit(),
      child: BlocBuilder<DiscoverCubit, DiscoverState>(
        builder: (context, state) {
          final selected = context.read<DiscoverCubit>().state.filter;

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
                            onPressed: () {},
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 8,
                          children: FilterType.values
                              .map((v) => _FilterChip(v, selected))
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Grid(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                          LastReadBookCard(),
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                          DiscoverableBookCard(),
                        ],
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
  const _FilterChip(this.filter, this.selectedFilter);

  final FilterType filter;
  final FilterType selectedFilter;

  @override
  Widget build(BuildContext context) {
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
