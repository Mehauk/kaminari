import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';

class LastReadBookCard extends StatelessWidget {
  const LastReadBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .glowing,
      innerShadow: [
        BoxShadow(
          color: KaminariTheme.surfaceTint.withAlpha(30),
          blurRadius: 10,
          offset: const Offset(1, 1),
        ),
      ],
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
                                color: KaminariTheme.textTitle,
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          LinearProgressIndicator(value: 0.68),
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

class DiscoverableBookCard extends StatelessWidget {
  const DiscoverableBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .thin,
      child: SizedBox(
        width: 168,
        height: 312,
        child: Column(
          children: [
            Flexible(
              flex: 2,
              child: Image.network(
                "https://lh3.googleusercontent.com/aida-public/AB6AXuBAM6pilxIHDQ86aOPcfulMu3N0-G1_l52Tgpg_BrlXJnoetaNnvL-mVe_ZU7hDQwYQKEZTlTcNVzylERI2NudXlw2xHYcODehuVjneis4WJBnZJKHFdYgk8HaSoI1p5lhWJcJZsSJsoEmqKBlNAQ_Dqsuuo61OkKmvGdtLsJRotAMor-JJ3pHoJKYyYHFwQ6MCMQVfBKVP-znV0DyALYccVmAzd7MPkgwtLqeCUnUooY0OPuw3HTNCh18GhQuHqc0a2aj3nowh4QEm",
                alignment: Alignment(0, -0.2),
                fit: BoxFit.cover,
                width: double.maxFinite,
                height: 192,
              ),
            ),
            Flexible(
              child: Padding(
                padding: const .fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomText(
                      "The Electric Blade of Edo",
                      .headlineMedium,
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: .w300,
                    ),
                    SizedBox(height: 4),
                    CustomText(
                      "Kento Sato",
                      .titleMedium,
                      fontSize: 12,
                      fontWeight: .w300,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
