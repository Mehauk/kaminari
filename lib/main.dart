import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kaminari/src/config/bloc_observers.dart';
import 'package:kaminari/src/data/services/local_storage_service.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LocalStorageService().init();
  await dotenv.load(fileName: ".env");

  Bloc.observer = DebugBlocObserver();
  runApp(const KaminariApp());
}
