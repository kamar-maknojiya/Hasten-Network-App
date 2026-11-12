import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class NetworkService extends ChangeNotifier with WidgetsBindingObserver {
  static final NetworkService _instance = NetworkService._internal();

  factory NetworkService() => _instance;

  NetworkService._internal();

  bool _isConnected = true;

  bool get isConnected => _isConnected;

  StreamSubscription? _internetSubscription;
  Timer? _disconnectDebounce;

  // The radio/DNS stack briefly drops out for a second or two right after
  // the screen wakes up. Waiting this long before trusting a "disconnected"
  // reading avoids flashing the No Internet screen for that blip.
  static const _disconnectGrace = Duration(seconds: 3);
  static const _resumeGrace = Duration(seconds: 2);

  Future<void> initialize() async {
    _isConnected = await InternetConnection().hasInternetAccess;

    WidgetsBinding.instance.addObserver(this);

    _internetSubscription?.cancel();
    _internetSubscription = InternetConnection().onStatusChange.listen(_handleStatusChange);
  }

  void _handleStatusChange(InternetStatus status) {
    final connected = status == InternetStatus.connected;

    if (connected) {
      _disconnectDebounce?.cancel();
      _setConnected(true);
      return;
    }

    _disconnectDebounce?.cancel();
    _disconnectDebounce = Timer(_disconnectGrace, () async {
      final stillDown = !(await InternetConnection().hasInternetAccess);
      if (stillDown) {
        _setConnected(false);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Don't let a stale/transient reading flip the flag right as the
      // screen turns back on — cancel any pending disconnect and give the
      // network stack a moment to reconnect before rechecking.
      _disconnectDebounce?.cancel();
      Future.delayed(_resumeGrace, checkConnection);
    }
  }

  Future<void> checkConnection() async {
    final connected = await InternetConnection().hasInternetAccess;
    _disconnectDebounce?.cancel();
    _setConnected(connected);
  }

  void _setConnected(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      debugPrint("Network Status => $_isConnected");
      notifyListeners();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disconnectDebounce?.cancel();
    _internetSubscription?.cancel();
    super.dispose();
  }
}
