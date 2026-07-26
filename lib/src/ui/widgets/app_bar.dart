import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/config/theme.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/pages/home/home_nav_cubit.dart';
import 'package:kaminari/src/ui/units/backdrop_filter.dart';
import 'package:kaminari/src/ui/units/text.dart';
import 'package:kaminari/src/ui/widgets/icon.dart';

class LightningAppBar extends StatelessWidget {
  const LightningAppBar({super.key});

  static int _clickCount = 0;
  static DateTime? _lastClickTime;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: [
              GestureDetector(
                onTap: () async {
                  try {
                    final tab = context.read<HomeNavCubit>().state;
                    if (tab == HomeNavTab.home) {
                      final now = DateTime.now();
                      if (_lastClickTime == null ||
                          now.difference(_lastClickTime!) >
                              const Duration(seconds: 2)) {
                        _clickCount = 1;
                      } else {
                        _clickCount++;
                      }
                      _lastClickTime = now;

                      if (_clickCount >= 5) {
                        _clickCount = 0;
                        final storage = LocalStorageService();
                        final current =
                            storage.getData('show_archived') == true;
                        final newValue = !current;
                        await storage.saveData('show_archived', newValue);

                        if (context.mounted) {
                          context.read<DatabaseService>().notifyBooksChanged();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                newValue
                                    ? 'Show Archived Books: Enabled'
                                    : 'Show Archived Books: Disabled',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    }
                  } catch (_) {}
                },
                child: const LightningIcon(
                  Icons.bolt,
                  type: LightningIconType.glowing,
                ),
              ),
              const SizedBox(width: 8),
              CustomText(
                "Kaminari Browser",
                TextType.headlineMedium,
                color: KaminariTheme.textTitle,
              ),
              const Expanded(child: SizedBox.shrink()),
              const LightningIcon(CupertinoIcons.person_alt_circle),
            ],
          ),
        ),
      ),
    );
  }
}
