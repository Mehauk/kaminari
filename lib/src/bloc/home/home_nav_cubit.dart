import 'package:flutter_bloc/flutter_bloc.dart';

enum HomeNavTab { discover, home, history }

class HomeNavCubit extends Cubit<HomeNavTab> {
  HomeNavCubit() : super(HomeNavTab.discover);

  void selectTab(HomeNavTab tab) {
    emit(tab);
  }
}
