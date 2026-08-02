import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/repositories/app_settings.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/lightning_border_effect.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/card.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late bool _downloadOverMobile;

  @override
  void initState() {
    super.initState();
    _downloadOverMobile = context.read<AppSettings>().getDownloadOverMobile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KaminariTheme.background,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: BgFilter(
              child: Container(
                decoration: BoxDecoration(
                  border: const Border(
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
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  children: [
                    LightningIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    CustomText(
                      "Settings",
                      TextType.headlineMedium,
                      color: KaminariTheme.textTitle,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                LightningCard(
                  type: LightningBorderEffectType.thin,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 16.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomText(
                                "Download over mobile network",
                                TextType.bodyLarge,
                                color: KaminariTheme.textPrimary,
                              ),
                              const SizedBox(height: 4),
                              CustomText(
                                "Allow background chapter downloads when not connected to Wi-Fi",
                                TextType.labelSmall,
                                color: KaminariTheme.textSecondary,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _downloadOverMobile,
                          onChanged: (value) async {
                            setState(() {
                              _downloadOverMobile = value;
                            });
                            await context
                                .read<AppSettings>()
                                .setDownloadOverMobile(value);
                          },
                        ),
                      ],
                    ),
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
