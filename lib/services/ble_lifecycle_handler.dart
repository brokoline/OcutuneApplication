// lib/services/ble_lifecycle_handler.dart

import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';

class BleLifecycleHandler extends WidgetsBindingObserver {
  final BleController bleController;

  DiscoveredDevice? _lastDevice;
  String?        _lastPatientId;
  bool           _shouldAutoReconnect = false;
  StreamSubscription<ConnectionStateUpdate>? _connSub;

  BleLifecycleHandler({ required this.bleController });

  /// Start observer + lyt på GATT-state
  void start() {
    WidgetsBinding.instance.addObserver(this);
    _shouldAutoReconnect = true;

    _connSub = bleController.connectionStateStream.listen((update) {
      if (!_shouldAutoReconnect) return;

      // Hvis vi mister forbindelsen uventet
      if (update.connectionState == DeviceConnectionState.disconnected) {
        _retryConnect();
      }
    });
    debugPrint('🔁 BLE LifecycleHandler STARTET');
  }

  /// Stop observer + lyttere
  void stop() {
    _shouldAutoReconnect = false;
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    debugPrint('🛑 BLE LifecycleHandler STOPPET');
  }

  /// Husk hvilken enhed vi sidst var forbundet til
  void updateDevice({
    required DiscoveredDevice device,
    required String patientId,
  }) {
    _lastDevice    = device;
    _lastPatientId = patientId;
    debugPrint('💾 Husker device: ${device.name} (${device.id})');
  }

  /// Kun genopkobling på resume – ikke aktiv disconnect på pause
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_shouldAutoReconnect) return;

    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed → forsøger genopkobling');
      _retryConnect();
    }
  }

  /// Prøv at forbinde igen med en lille delay, gentager indtil success
  void _retryConnect() {
    if (_lastDevice == null || _lastPatientId == null) return;

    const delay = Duration(seconds: 5);
    Future.delayed(delay, () async {
      if (!_shouldAutoReconnect) return;

      debugPrint('🌀 Auto-reconnect til ${_lastDevice!.name} …');
      try {
        await bleController.connectToDevice(
          device:    _lastDevice!,
          patientId: _lastPatientId!,
        );
        debugPrint('✅ Genopkobling lykkedes');
      } catch (e) {
        debugPrint('❌ Genopkobling fejlede ($e), prøver igen om ${delay.inSeconds}s');
        _retryConnect();
      }
    });
  }
}
