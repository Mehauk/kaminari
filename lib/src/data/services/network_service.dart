import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  Future<ConnectivityResult> checkConnectivity() =>
      _connectivity.checkConnectivity();

  bool isWifiOrEthernet(ConnectivityResult connectivityResult) {
    return connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet;
  }

  Future<bool> get hasAllowedDownloadConnection async {
    final result = await checkConnectivity();
    return isWifiOrEthernet(result);
  }
}
