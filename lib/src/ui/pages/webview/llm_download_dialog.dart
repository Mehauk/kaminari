import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/llm/llm_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';

class LlmOverlay extends StatelessWidget {
  const LlmOverlay({
    super.key,
    required this.context,
    required this.title,
    required this.message,
    this.progress,
    this.showConfirmButton = false,
    this.isIndeterminate = false,
  });

  final BuildContext context;
  final String title;
  final String message;
  final int? progress;
  final bool showConfirmButton;
  final bool isIndeterminate;

  @override
  Widget build(BuildContext context) {
    return BgFilter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            clipBehavior: Clip.hardEdge,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: KaminariTheme.surfaceTint.withAlpha(100)),
            ),
            child: BgFilter(
              bgColor: Colors.black.withAlpha(30),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomText(title, TextType.headlineMedium),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    if (progress != null) ...[
                      LinearProgressIndicator(value: progress! / 100),
                      const SizedBox(height: 8),
                      Text('$progress%'),
                    ],
                    if (isIndeterminate) const CircularProgressIndicator(),
                    if (showConfirmButton)
                      FilledButton(
                        onPressed: () =>
                            context.read<LlmCubit>().downloadAndInstall(),

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
  }
}
