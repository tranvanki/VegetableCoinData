import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Trạng thái kết nối. Tách thành interface để test không cần plugin thật.
abstract interface class NetworkInfo {
  Future<bool> get isConnected;
  Stream<bool> get onStatusChange;
}

class ConnectivityNetworkInfo implements NetworkInfo {
  ConnectivityNetworkInfo([Connectivity? connectivity])
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  static bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  @override
  Future<bool> get isConnected async =>
      _hasConnection(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onStatusChange =>
      _connectivity.onConnectivityChanged.map(_hasConnection).distinct();
}
//
//Future<>
