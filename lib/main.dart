import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kaminari/src/config/bloc_observers.dart';
import 'package:kaminari/src/data/services/kanji_service.dart';
import 'package:kaminari/src/data/services/local_storage_service.dart';
import 'package:kaminari/src/data/services/stats_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalStorageService().init();
  await dotenv.load(fileName: ".env");

  await StatsService.recordActivity();
  await KanjiService.buildVisitedTable();

  Bloc.observer = DebugBlocObserver();
  runApp(const KaminariApp());
}
