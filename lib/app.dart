import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/data/repositories/extractor_cache.dart';
import 'package:kaminari/src/data/services/database_service.dart';
import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/pages/home/home_page.dart';
import 'package:kaminari/src/pages/webview/import_webview_page.dart';

import 'src/config/theme.dart';

final RouteObserver<ModalRoute> routeObserver = RouteObserver<ModalRoute>();

class KaminariApp extends StatelessWidget {
  const KaminariApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: DatabaseService()),
        RepositoryProvider.value(value: ExtractorCache(LocalStorageService())),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kaminari Browser',
        theme: KaminariTheme.theme,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomePage(),
          '/import-view': (context) => ImportWebviewPage(
            initialUrl: ModalRoute.of(context)?.settings.arguments as String?,
          ),
        },
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
