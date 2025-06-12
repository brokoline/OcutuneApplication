import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../auth_storage.dart';
import '../services/api_services.dart';
import '../sync_use_case.dart';
import 'battery_polling_service.dart';
import 'light_polling_service.dart';

@pragma('vm:entry-point')
class OcutuneForegroundHandler extends TaskHandler {
  late final FlutterReactiveBle _ble;
  late final QualifiedCharacteristic _lightChar;
  late final QualifiedCharacteristic _batteryChar;

  late final BatteryPollingService _batteryService;
  late final LightPollingService _lightService;

  DateTime _lastSyncTime = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Future<void> onStart(DateTime timestamp) async {
    _ble = FlutterReactiveBle();

    // 1) Hent deviceId, patientId og jwt
    final deviceId  = (await AuthStorage.getLastConnectedDeviceId())!;
    final patientId = (await AuthStorage.getUserId())!;
    final jwt       = (await AuthStorage.getToken())!;

    // 2) Forsøg at hente gemt sensorId til dette device
    String? sensorId = await AuthStorage.getSensorIdForDevice(deviceId);
    if (sensorId == null) {
      // hvis ikke fundet → registrér ny og gem
      final newId = await ApiService.registerSensorUse(
        patientId:    patientId,
        deviceSerial: deviceId,
        jwt:          jwt,
      );
      if (newId == null) {
        debugPrint('❌ Kunne ikke registrere sensor');
        return;
      }
      sensorId = newId.toString();
      await AuthStorage.saveSensorIdForDevice(deviceId, sensorId);
    }

    // 3) Definér dine BLE-karakteristika
    _lightChar = QualifiedCharacteristic(
      deviceId:         deviceId,
      serviceId:        Uuid.parse('0000181b-0000-1000-8000-00805f9b34fb'),
      characteristicId: Uuid.parse('834419a6-b6a4-4fed-9afb-acbb63465bf7'),
    );
    _batteryChar = QualifiedCharacteristic(
      deviceId:         deviceId,
      serviceId:        Uuid.parse('180F'),
      characteristicId: Uuid.parse('2A19'),
    );

    // 4) Hold GATT-link åben i BG
    _ble.connectToDevice(id: deviceId).listen(
          (upd) => debugPrint('🔗 BG BLE state=${upd.connectionState}'),
      onError: (e) => debugPrint('⚠️ BG BLE-error: $e'),
    );

    // 5) Start polling-services
    _batteryService = BatteryPollingService(ble: _ble, deviceId: deviceId, sensorId: sensorId);
    await _batteryService.start();

    _lightPollingInit(patientId, sensorId);

    // 6) Initér sync-timer
    _lastSyncTime = timestamp;
    debugPrint('🔔 BG-service startet ved $timestamp, sensorId=$sensorId');
  }

  void _lightPollingInit(String patientId, String sensorId) async {
    _lightService = LightPollingService(
      ble:            _ble,
      characteristic: _lightChar,
      patientId:      patientId,
      sensorId:       sensorId,
    );
    await _lightService.start();
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // ── Lys hver 10 s ────────────────────────────────────────────────
    try {
      final data = await _ble.readCharacteristic(_lightChar);
      await _lightService.handleData(data);
    } catch (e) {
      debugPrint('⚠️ BG-lys polling error: $e');
    }

    // ── Sync offline-data hver 10 min ───────────────────────────────
    if (timestamp.difference(_lastSyncTime) >= const Duration(minutes: 10)) {
      try {
        debugPrint('⏳ Starter syncAll ved $timestamp');
        await SyncUseCase.syncAll();
        debugPrint('✅ syncAll færdig ved $timestamp');
      } catch (e) {
        debugPrint('⚠️ BG-sync error: $e');
      }
      _lastSyncTime = timestamp;
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Stop BG-services
    _batteryService.stop();
    _lightService.stop();
    debugPrint('🛑 BG-service stoppet ved $timestamp');
  }

  void onButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
