import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kaminari/src/bloc/bloc_observers.dart';

import 'app.dart';

void main() {
  Bloc.observer = DebugBlocObserver();
  runApp(const KaminariApp());
}
