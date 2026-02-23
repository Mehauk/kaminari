import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';

class ImportingDialog extends StatelessWidget {
  const ImportingDialog({super.key});

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
                    CustomText("Importing Data", TextType.headlineMedium),
                    const SizedBox(height: 16),
                    Text(
                      "The data is now being imported...",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 24),
                    CircularProgressIndicator(),
                    const SizedBox(height: 16),
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
