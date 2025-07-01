
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';

class BleLifecycleHandler extends WidgetsBindingObserver {
  final BleController bleController;

  DiscoveredDevice? _lastDevice;
  String?        _lastPatientId;
  bool           _shouldAutoReconnect = true;
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  BleLifecycleHandler({ required this.bleController });

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _shouldAutoReconnect = true;

    _connSub = bleController.connectionStateStream.listen((update) {
      if (!_shouldAutoReconnect) return;
      if (update.connectionState == DeviceConnectionState.disconnected) {
        _retryConnect();
      }
    });
    debugPrint('BLE LifecycleHandler STARTET');
  }

  void stop() {
    _shouldAutoReconnect = false;
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    debugPrint('BLE LifecycleHandler STOPPET');
  }

  void updateDevice({
    required DiscoveredDevice device,
    required String patientId,
  }) {
    _lastDevice    = device;
    _lastPatientId = patientId;
    debugPrint('Husker device: ${device.name} (${device.id})');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldAutoReconnect) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint('App resumed → forsøger genopkobling');
      _retryConnect();
    }
  }

  void _retryConnect() {
    if (_lastDevice == null || _lastPatientId == null) return;

    const delay = Duration(seconds: 5);
    Future.delayed(delay, () async {
      if (!_shouldAutoReconnect) return;

      debugPrint('Auto-reconnect til ${_lastDevice!.name} …');
      try {
        await bleController.connectToDevice(
          device:    _lastDevice!,
          patientId: _lastPatientId!,
        );
        debugPrint('Genopkobling lykkedes');
      } catch (e) {
        debugPrint('Genopkobling fejlede ($e), prøver igen om ${delay.inSeconds}s');
        _retryConnect();
      }
    });
  }
}