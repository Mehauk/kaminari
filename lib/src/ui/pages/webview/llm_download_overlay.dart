import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/llm/llm_initialization_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';

class LlmOverlay extends StatelessWidget {
  const LlmOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LlmInitializationCubit, LlmState>(
      listener: (context, state) {
        if (<LlmStatus>[.error, .installed, .initial].contains(state.status)) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return BgFilter(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                clipBehavior: Clip.hardEdge,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: KaminariTheme.surfaceTint.withAlpha(100),
                  ),
                ),
                child: BgFilter(
                  bgColor: Colors.black.withAlpha(30),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText("Download Model", TextType.headlineMedium),
                        const SizedBox(height: 16),
                        Text(
                          "A local model ~2gb is required to handle dynamic imports",
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        if (state.status == .downloading) ...[
                          LinearProgressIndicator(value: state.progress / 100),
                          const SizedBox(height: 8),
                          Text('${state.progress}%'),
                        ],
                        if (!<LlmStatus>[
                          .downloading,
                          .installed,
                        ].contains(state.status))
                          FilledButton(
                            onPressed: () => context
                                .read<LlmInitializationCubit>()
                                .downloadAndInstall(),

                            child: const Text('Download Now'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
