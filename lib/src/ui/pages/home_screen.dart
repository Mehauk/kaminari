import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/app_bar.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          LightningAppBar(),
          Padding(
            padding: const .symmetric(horizontal: 20),
            child: Column(
              children: [
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _InfoTile("DAILY STREAK", ("12", "days"))),
                    SizedBox(width: 16),
                    Expanded(child: _InfoTile("WORDS LEARNED", ("842", ""))),
                  ],
                ),
                SizedBox(height: 32),
                _BookCard(),
                SizedBox(height: 32),
                Row(
                  children: [
                    LightningIcon(
                      Icons.insert_chart_outlined_rounded,
                      type: .golden,
                    ),
                    SizedBox(width: 8),
                    CustomText("Mastery", .headlineMedium),
                  ],
                ),
                SizedBox(height: 16),
                _MasteryCard(
                  title: "Kana",
                  subTitle: "Hiragana & Katakana",
                  percent: 0.9,
                  type: .glowing,
                ),
                SizedBox(height: 16),
                _MasteryCard(
                  title: "Kanji",
                  subTitle: "JLPT N2 Level Focus",
                  percent: 0.4,
                  type: .thin,
                ),
                SizedBox(height: 32),
                LightningCard(
                  type: .striking,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: AlignmentGeometry.centerLeft,
                        end: AlignmentGeometry.centerRight,
                        colors: [
                          KaminariTheme.surfaceTint.withAlpha(25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: .all(24),
                      child: Column(
                        crossAxisAlignment: .start,
                        children: [
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              CustomText(
                                "KANJI OF THE DAY",
                                .labelSmall,
                                colorOverride: KaminariTheme.textTitle,
                              ),
                              CustomText("ONYOMI", .labelSmall),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: .spaceBetween,
                            crossAxisAlignment: .start,
                            children: [
                              CustomText("電", .bodyLarge, fontSizeOverride: 42),
                              CustomText(
                                "デン (Den)",
                                .bodyLarge,
                                colorOverride: KaminariTheme.textTitle,
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Divider(thickness: 0.5),
                          SizedBox(height: 12),
                          CustomText("Electricity, Lightning", .bodyMedium),
                          SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({
    required this.title,
    required this.subTitle,
    required this.percent,
    required this.type,
  }) : assert(0.0 <= percent && 1.0 >= percent);

  final String title;
  final String subTitle;

  /// 0.0-1.0
  final double percent;
  final LightningBorderEffectType type;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: type,
      child: Padding(
        padding: .all(24),
        child: Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Column(
              crossAxisAlignment: .start,
              children: [
                CustomText(title, .headlineMedium),
                SizedBox(height: 4),
                CustomText(subTitle, .bodyMedium),
              ],
            ),
            Stack(
              alignment: AlignmentGeometry.center,
              children: [
                SizedBox.square(
                  dimension: 80,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 6,
                  ),
                ),
                CustomText(
                  "${(percent * 100).toStringAsFixed(0)}%",
                  .labelSmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  const _BookCard();

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
                                colorOverride: KaminariTheme.textTitle,
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

class _InfoTile extends StatelessWidget {
  const _InfoTile(this.title, this.headline);

  final String title;
  final (String, String) headline;

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .thin,
      child: Padding(
        padding: const .all(KaminariTheme.borderRadius),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            CustomText(title, .labelSmall),
            SizedBox(height: 6),
            Row(
              children: [
                RichText(
                  text: TextSpan(
                    text: "${headline.$1} ",
                    style: TextTheme.of(
                      context,
                    ).headlineLarge?.copyWith(color: KaminariTheme.textTitle),
                    children: [
                      TextSpan(
                        text: "${headline.$2} ",
                        style: TextTheme.of(
                          context,
                        ).labelMedium?.copyWith(color: KaminariTheme.textTitle),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
