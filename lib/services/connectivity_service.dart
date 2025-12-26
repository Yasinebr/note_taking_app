import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

class ConnectivityService {
  static ConnectivityService? _instance;

  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  StreamSubscription<BatteryState>? _batterySubscription;
  Timer? _batteryNotificationTimer;

  bool _isConnected = false;
  BatteryState _lastBatteryState = BatteryState.unknown;
  bool _isInitialized = false;
  bool _skipInitialBatteryNotification = true;


  final Set<ConnectivityResult> _onlineResults = {
    ConnectivityResult.mobile,
    ConnectivityResult.wifi,
  };

  ConnectivityService._();

  static ConnectivityService get instance => _instance ??= ConnectivityService._();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _checkInitialConnectivity();
      _startMonitoring();
      _isInitialized = true;
      if (kDebugMode) debugPrint('ConnectivityService initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('Initialization error: $e');
    }
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      _isConnected = await _checkConnectivity();
      if (kDebugMode) debugPrint('Initial connectivity: $_isConnected');
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to check initial connectivity: $e');
      _isConnected = false;
    }
  }

  void _startMonitoring() {
    _monitorConnectivity();
    _monitorBattery();
  }

  void _monitorConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
          (result) {
        final wasConnected = _isConnected;
        _isConnected = _isConnectedFromResult(result);

        if (_isConnected != wasConnected) {
          _showConnectivityNotification(_isConnected);
          if (kDebugMode) debugPrint('Connectivity changed: $_isConnected');
        }
      },
      onError: (error) {
        if (kDebugMode) debugPrint('Connectivity error: $error');
      },
    );
  }

  void _monitorBattery() {
    _batterySubscription = Battery().onBatteryStateChanged.listen(
          (state) {
        if (state == _lastBatteryState) return;

        if (_skipInitialBatteryNotification && state == BatteryState.unknown) {
          _lastBatteryState = state;
          _skipInitialBatteryNotification = false;
          return;
        }

        _batteryNotificationTimer?.cancel();
        _batteryNotificationTimer = Timer(const Duration(seconds: 3), () {
          _showBatteryNotification(state);
        });

        _lastBatteryState = state;
        _skipInitialBatteryNotification = false;

        if (kDebugMode) debugPrint('Battery state changed: $state');
      },
      onError: (error) {
        if (kDebugMode) debugPrint('Battery monitoring error: $error');
      },
    );
  }

  void _showConnectivityNotification(bool isConnected) {
    if (isConnected) {
      NotificationService.showInstantNotification(
        id: 998,
        title: 'Internet Restored',
        body: 'Back online',
      );
    } else {
      NotificationService.showInstantNotification(
        id: 999,
        title: 'No Internet',
        body: 'Device is offline',
      );
    }
  }

  void _showBatteryNotification(BatteryState state) {
    final message = _getBatteryMessage(state);
    if (message.isNotEmpty) {
      NotificationService.showInstantNotification(
        id: 997,
        title: 'Battery Status',
        body: message,
      );
    }
  }

  String _getBatteryMessage(BatteryState state) {
    switch (state) {
      case BatteryState.charging:
        return 'Now charging';
      case BatteryState.discharging:
        return 'Now discharging';
      case BatteryState.full:
        return 'Fully charged';
      case BatteryState.connectedNotCharging:
        return 'Connected but not charging';
      case BatteryState.unknown:
        return '';
    }
  }


  bool _isConnectedFromResult(ConnectivityResult result) {
    return _onlineResults.contains(result);
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return _isConnectedFromResult(result);
  }

  Future<bool> isConnected() async {
    return _isInitialized ? _isConnected : await _checkConnectivity();
  }

  Future<int> getBatteryLevel() async {
    try {
      return await Battery().batteryLevel;
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to get battery level: $e');
      return -1;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _batterySubscription?.cancel();
    _batteryNotificationTimer?.cancel();

    _connectivitySubscription = null;
    _batterySubscription = null;
    _batteryNotificationTimer = null;
    _isInitialized = false;

    if (kDebugMode) debugPrint('ConnectivityService disposed');
  }

  @visibleForTesting
  static void reset() {
    _instance?.dispose();
    _instance = null;
  }
}
