import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class ConfirmationDialog extends StatelessWidget {
  const ConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: LightningCard(
        type: .glowing,
        child: Padding(
          padding: const .symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              CustomText("Delete Book", .headlineMedium),
              SizedBox(height: 4),
              CustomText(
                "Are you sure you want to delete this book?",
                .labelMedium,
                fontSize: 18,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: .end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const CustomText('Cancel', .bodyMedium),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const CustomText(
                      'Delete',
                      .bodyMedium,
                      color: KaminariTheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
