import 'package:flutter/material.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/widgets/backdrop_filter.dart';
import 'package:kaminari/src/widgets/lightning_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          BgFilter(
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.white10, width: 1),
                  ),
                  color: KaminariTheme.background.withAlpha(200),
                  boxShadow: [
                    BoxShadow(
                      color: KaminariTheme.surfaceTint.withAlpha(15),
                      blurRadius: 15,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                padding: .symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: .spaceBetween,
                  children: [
                    Text(
                      "⚡ Kaminari Browser",
                      style: TextTheme.of(context).headlineMedium?.copyWith(
                        color: KaminariTheme.textTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => print(1),
                      icon: Icon(Icons.settings_outlined),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
                LightningCard(
                  type: .glow,
                  innerShadow: [
                    BoxShadow(
                      color: Colors.black54,
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
                            child: SizedBox(
                              height: 192,
                              width: double.maxFinite,
                            ),
                          ),
                          Positioned(
                            left: 20,
                            top: 12,
                            child: Chip(label: Text("NOVEL")),
                          ),
                          Padding(
                            padding: const .symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            child: Text(
                              "Overlord: Volume 14",
                              style: TextTheme.of(context).headlineMedium,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const .fromLTRB(24, 4, 24, 24),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: [
                            Text(
                              "Chapter 3: The Witch of the Falling Kingdom",
                              style: TextTheme.of(context).bodyLarge,
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
                                            child: Text(
                                              "READING PROGRESS",
                                              style: TextTheme.of(
                                                context,
                                              ).labelSmall,
                                            ),
                                          ),
                                          SizedBox(width: 8),

                                          Text(
                                            "68%",
                                            style: TextTheme.of(context)
                                                .labelSmall
                                                ?.copyWith(
                                                  color:
                                                      KaminariTheme.textTitle,
                                                ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      LinearProgressIndicator(
                                        value: 0.68,
                                        color: KaminariTheme.textTitle,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 16),
                                FilledButton(
                                  onPressed: () => print(2),
                                  child: Text("Continue "),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
            Text(title, style: TextTheme.of(context).labelSmall),
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


// AppBar(
//         titleSpacing: 0,
//         title: Text(
          // "Kaminari Browser",

//         ),
//         leading: Icon(
//           Icons.electric_bolt_sharp,
//           color: KaminariTheme.textTitle,
//         ),
//         actions: [

//         ],
//       )