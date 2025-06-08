// lib/services/services/foreground_service_handler.dart

import 'dart:async';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../auth_storage.dart';
import '../services/api_services.dart';
import 'battery_polling_service.dart';
import 'light_polling_service.dart';

@pragma('vm:entry-point')
class OcutuneForegroundHandler extends TaskHandler {
  late FlutterReactiveBle _ble;
  late StreamSubscription<ConnectionStateUpdate> _connectionSub;
  late BatteryPollingService _batteryService;
  late LightPollingService   _lightService;
  Timer? _tickTimer;

  @override
  Future<void> onStart(DateTime timestamp) async {
    // 1) Initialisér BLE i baggrunds-isolate
    _ble = FlutterReactiveBle();

    // 2) Hent sidst forbundne deviceId + patientId + JWT
    final deviceId  = await AuthStorage.getLastConnectedDeviceId();
    final patientId = await AuthStorage.getUserId() ?? '';
    final jwt       = await AuthStorage.getToken()  ?? '';

    if (deviceId == null) {
      print('❌ BG-service: intet deviceId gemt → afbryder');
      return;
    }

    // 3) Opret forbindelse og hold den åben (gem subscription)
    _connectionSub = _ble
        .connectToDevice(id: deviceId)
        .listen((upd) {
      if (upd.connectionState == DeviceConnectionState.connected) {
        print('🔗 BG-service: connected');
      } else if (upd.connectionState == DeviceConnectionState.disconnected) {
        print('🔌 BG-service: disconnected');
      }
    }, onError: (e) {
      print('⚠️ BG-service connection error: $e');
    });

    // 4) Start batteri-polling
    _batteryService = BatteryPollingService(ble: _ble, deviceId: deviceId);
    await _batteryService.start();

    // 5) Registrér sensorbrug og start lys-polling
    final sensorId = await ApiService.registerSensorUse(
      patientId:    patientId,
      deviceSerial: deviceId,
      jwt:          jwt,
    );
    if (sensorId != null) {
      final char = QualifiedCharacteristic(
        deviceId:         deviceId,
        serviceId:        Uuid.parse('0000181b-0000-1000-8000-00805f9b34fb'),
        characteristicId: Uuid.parse('834419a6-b6a4-4fed-9afb-acbb63465bf7'),
      );
      _lightService = LightPollingService(
        ble:            _ble,
        characteristic: char,
        patientId:      patientId,
        sensorId:       sensorId,
      );
      await _lightService.start();
    } else {
      print('❌ BG-service: kunne ikke registrere sensor til lys');
    }

    // 6) Ekstra tick hver 10s (valgfrit)
    _tickTimer = Timer.periodic(
      const Duration(seconds: 10),
          (_) => print('🕒 BG tick: ${DateTime.now()}'),
    );
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // Denne kører hver interval‐ms (plugin’et står for interval)
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _tickTimer?.cancel();
    _batteryService.stop();
    _lightService.stop();
    await _connectionSub.cancel();
    print('🛑 BG-service stoppet');
  }

  @override
  void onButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
