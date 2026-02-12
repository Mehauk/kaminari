import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class LightningBookCard extends StatelessWidget {
  const LightningBookCard({super.key, this.reading = false});

  final bool reading;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .glowing,
      innerShadow: reading
          ? [
              BoxShadow(
                color: KaminariTheme.surfaceTint.withAlpha(30),
                blurRadius: 10,
                offset: const Offset(1, 1),
              ),
            ]
          : null,
      child: Column(
        children: [
          Stack(
            alignment: AlignmentGeometry.bottomStart,
            children: [
              Image.network(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuAsmvERQIxb69zOnC3qKBAhy-utzthLY4MKFP6Cna6vzDRyZBZRGPp2J6WEUCiRmVJL-f3q2U3jq1A94N7GbNG3lKuNOP9CoN5kzB2SMJh-62WJUjTsxlLAUiFfA4Oc-9CXr8VrJJ_7iBjGaP2xwIK-h5_sXYSqlGgJJz-vDvP_qe_Db6Kcw4Be4OxX-g07-ucZwCrxxAsUIzSZPGD5_LpXQjO7HHu3StMKAjIa_bubKQA88L9z9RYqn8yjJO7xGXByqLQbGV4DKjVI",
                alignment: Alignment(0, -0.2),
                fit: BoxFit.cover,
                width: double.maxFinite,
                height: 192,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentGeometry.bottomCenter,
                    end: AlignmentGeometry.topCenter,
                    colors: [
                      KaminariTheme.background,
                      KaminariTheme.background.withAlpha(128),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: SizedBox(height: 192, width: double.maxFinite),
              ),
              Positioned(left: 20, top: 12, child: Chip(label: Text("NOVEL"))),
              Padding(
                padding: const .symmetric(horizontal: 24, vertical: 4),
                child: CustomText("Overlord: Volume 14", .headlineMedium),
              ),
            ],
          ),
          Padding(
            padding: const .fromLTRB(24, 4, 24, 24),
            child: Column(
              crossAxisAlignment: .start,
              children: [
                CustomText(
                  "Chapter 3: The Witch of the Falling Kingdom",
                  .bodyLarge,
                ),
                SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: .min,
                        children: [
                          if (reading) ...[
                            Row(
                              mainAxisAlignment: .spaceBetween,
                              crossAxisAlignment: .start,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    "READING PROGRESS",
                                    .labelSmall,
                                  ),
                                ),
                                SizedBox(width: 8),

                                CustomText(
                                  "68%",
                                  .labelSmall,
                                  colorOverride: KaminariTheme.textTitle,
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            LinearProgressIndicator(value: 0.68),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    FilledButton(
                      onPressed: () => print(2),
                      child: Text("Continue"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
