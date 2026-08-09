import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkService {
  final Connectivity _connectivity = Connectivity();

  // Map Stream<List<ConnectivityResult>> to Stream<ConnectivityResult>
  Stream<ConnectivityResult> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_getPrimaryResult);

  // Map Future<List<ConnectivityResult>> to Future<ConnectivityResult>
  Future<ConnectivityResult> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    return _getPrimaryResult(results);
  }

  // Prioritize stable network interfaces if multiple are active
  ConnectivityResult _getPrimaryResult(List<ConnectivityResult> results) {
    if (results.isEmpty) return .none;
    if (results.contains(ConnectivityResult.ethernet)) return .ethernet;
    if (results.contains(ConnectivityResult.wifi)) return .wifi;
    if (results.contains(ConnectivityResult.vpn)) return .vpn;
    if (results.contains(ConnectivityResult.mobile)) return .mobile;
    return results.first;
  }

  bool isWifiOrEthernet(ConnectivityResult connectivityResult) {
    return connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet;
  }

  Future<bool> get hasAllowedDownloadConnection async {
    final result = await checkConnectivity();
    return isWifiOrEthernet(result);
  }
}
