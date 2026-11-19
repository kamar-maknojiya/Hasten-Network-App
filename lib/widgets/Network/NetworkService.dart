import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:vision_broadband/networking/api_url.dart';

/// Tracks internet status for the "No Internet" screen.
///
/// Fixes the false "No Internet" after the phone screen was off:
///  - stops checking while the app is in the background (radio is asleep then)
///  - on resume, retries for up to ~12 seconds before saying "offline"
///  - checks our own server + Google instead of the package's default sites
///  - needs 2 failed checks in a row before showing the No Internet screen
class NetworkService extends ChangeNotifier with WidgetsBindingObserver {
  static final NetworkService _instance = NetworkService._internal();

  factory NetworkService() => _instance;

  NetworkService._internal();

  bool _isConnected = true;

  bool get isConnected => _isConnected;

  StreamSubscription<InternetStatus>? _sub;
  Timer? _disconnectDebounce;
  bool _resuming = false;
  bool _observing = false;

  /// Any HTTP reply (even 404) means the internet works.
  static bool _reachable(http.Response r) => r.statusCode > 0 && r.statusCode < 500;

  final InternetConnection _checker = InternetConnection.createInstance(
    checkInterval: const Duration(seconds: 6),
    useDefaultOptions: false,
    customCheckOptions: [
      InternetCheckOption(
        uri: Uri.parse(mainUrl),
        timeout: const Duration(seconds: 5),
        responseStatusFn: _reachable,
      ),
      InternetCheckOption(
        uri: Uri.parse('https://www.google.com/generate_204'),
        timeout: const Duration(seconds: 5),
        responseStatusFn: _reachable,
      ),
      InternetCheckOption(
        uri: Uri.parse('https://one.one.one.one'),
        timeout: const Duration(seconds: 5),
        responseStatusFn: _reachable,
      ),
    ],
  );

  /// Waiting this long (plus a 2nd check) before trusting a "disconnected" reading.
  static const _disconnectGrace = Duration(seconds: 3);

  Future<void> initialize() async {
    _isConnected = await _checker.hasInternetAccess;

    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    _listen();
  }

  void _listen() {
    _sub?.cancel();
    _sub = _checker.onStatusChange.listen(_handleStatusChange);
  }

  void _handleStatusChange(InternetStatus status) {
    if (status == InternetStatus.connected) {
      _disconnectDebounce?.cancel();
      _setConnected(true);
      return;
    }
    if (_resuming) return; // the resume check decides

    // second opinion before showing "No Internet"
    _disconnectDebounce?.cancel();
    _disconnectDebounce = Timer(_disconnectGrace, () async {
      if (!(await _checker.hasInternetAccess)) _setConnected(false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      // screen off / app in background: stop checking, the radio is asleep
      _disconnectDebounce?.cancel();
      _sub?.cancel();
      _sub = null;
    } else if (state == AppLifecycleState.resumed) {
      _onResume();
    }
  }

  /// After unlock: give the network up to ~12 s to wake up before saying offline.
  Future<void> _onResume() async {
    if (_resuming) return;
    _resuming = true;
    _disconnectDebounce?.cancel();

    var connected = false;
    for (final wait in const [1, 2, 3, 3, 3]) {
      await Future.delayed(Duration(seconds: wait));
      if (await _checker.hasInternetAccess) {
        connected = true;
        break;
      }
    }

    _setConnected(connected);
    _resuming = false;
    _listen(); // start watching again
  }

  /// Used by the "Retry" button.
  Future<void> checkConnection() async {
    final connected = await _checker.hasInternetAccess;
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
    if (_observing) WidgetsBinding.instance.removeObserver(this);
    _disconnectDebounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}
