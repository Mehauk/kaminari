import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kaminari/src/bloc/home/screens/discover_cubit.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
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
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/book-details'),
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
                Positioned(
                  left: 20,
                  top: 12,
                  child: Chip(label: Text("NOVEL")),
                ),
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
                        child: Row(children: [Text("Continue")]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryBookCard extends StatelessWidget {
  const HistoryBookCard({super.key});

  @override
  Widget build(BuildContext context) {
    return LightningCard(
      type: .thin,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/book-details'),
        child: Padding(
          padding: .all(16),
          child: Row(
            spacing: 16,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  border: LightningBorderEffectType.glowing.border(),
                  borderRadius: .circular(KaminariTheme.borderRadius),
                ),
                position: .foreground,
                child: ClipRRect(
                  borderRadius: .circular(KaminariTheme.borderRadius),
                  child: Image.network(
                    width: 64,
                    height: 80,
                    fit: .cover,
                    "https://lh3.googleusercontent.com/aida-public/AB6AXuBfYT489cK1M-YKRsuBsboDbV29o05OtNYm5Y7qLYFxl0-kDxkSJ5-OoUPSNDWQOXgwRiEWtqvR-OWbARrcvsZOmWFVgauGZPs-d-3eeNyTyTGGOddWTVUPXVglwi5b__NpqBSGbINqP0tqnPVTKszK3ifTfCSKdJ3oBVvuZs9h7nJVz8_kpCmCVu8lyibhuLG291Pnf1m_dH9UBysxfC-UZ3j24_nVDCD0WZW8ZQ778kof2lCFHhAs4q5CMBY0W9SZcGe4AB_tZX5U",
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    CustomText("ノルウェイの森(Norwegian Wood)", .titleMedium),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14),
                        SizedBox(width: 4),
                        CustomText("2 hours ago", .labelSmall),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.book, size: 14),
                        SizedBox(width: 4),
                        CustomText("page 156 / 200", .labelSmall),
                      ],
                    ),
                    SizedBox(height: 12),
                    LinearProgressIndicator(value: 156 / 200),
                  ],
                ),
              ),
              Column(
                spacing: 24,
                children: [
                  Icon(Icons.bookmark_border_rounded),
                  Icon(Icons.more_vert),
                  SizedBox(),
                ],
              ),
            ],
          ),
        ),
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
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed('/book-details'),
        child: Column(
          children: [
            Stack(
              children: [
                Image.network(
                  "https://lh3.googleusercontent.com/aida-public/AB6AXuBAM6pilxIHDQ86aOPcfulMu3N0-G1_l52Tgpg_BrlXJnoetaNnvL-mVe_ZU7hDQwYQKEZTlTcNVzylERI2NudXlw2xHYcODehuVjneis4WJBnZJKHFdYgk8HaSoI1p5lhWJcJZsSJsoEmqKBlNAQ_Dqsuuo61OkKmvGdtLsJRotAMor-JJ3pHoJKYyYHFwQ6MCMQVfBKVP-znV0DyALYccVmAzd7MPkgwtLqeCUnUooY0OPuw3HTNCh18GhQuHqc0a2aj3nowh4QEm",
                  alignment: Alignment(0, -0.2),
                  fit: BoxFit.cover,
                  width: double.maxFinite,
                  height: 192,
                ),
                Padding(
                  padding: .all(12),
                  child: ClipPath(
                    clipper: ShapeBorderClipper(shape: StadiumBorder()),
                    child: BgFilter(
                      bgColor: KaminariTheme.surfaceTint.withAlpha(65),
                      child: Padding(
                        padding: .symmetric(horizontal: 24, vertical: 4),
                        child: Text(
                          BookType.lightNovel.short,
                          style: TextStyle().copyWith(
                            fontSize: 14,
                            color: KaminariTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
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
          ],
        ),
      ),
    );
  }
}
