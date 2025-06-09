// lib/services/services/foreground_service_handler.dart

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

  DateTime _lastBatteryTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSyncTime    = DateTime.fromMillisecondsSinceEpoch(0);

  /// Kører én gang, når servicen starter
  @override
  Future<void> onStart(DateTime timestamp) async {
    _ble = FlutterReactiveBle();

    final deviceId  = (await AuthStorage.getLastConnectedDeviceId())!;
    final patientId = (await AuthStorage.getUserId())!;
    final jwt       = (await AuthStorage.getToken())!;

    // Definér dine karakteristika
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

    // Hold GATT-link åbent
    _ble.connectToDevice(id: deviceId).listen((upd) {
      debugPrint('🔗 BG-service BLE state=${upd.connectionState}');
    }, onError: (e) {
      debugPrint('⚠️ BG-service BLE-error: $e');
    });

    // Opret polling-services
    _batteryService = BatteryPollingService(ble: _ble, deviceId: deviceId);
    _lightService   = LightPollingService(
      ble:            _ble,
      characteristic: _lightChar,
      patientId:      patientId,
      sensorId:       (await ApiService.registerSensorUse(
        patientId:    patientId,
        deviceSerial: deviceId,
        jwt:          jwt,
      ))
          .toString(),
    );

    // Initialiser tidsstempler
    _lastBatteryTime = timestamp;
    _lastSyncTime    = timestamp;
    debugPrint('🔔 BG-service startet ved $timestamp');
  }

  /// Kører hver gang interval (10 s) udløses
  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    // --- Lys hver 10 s ---
    try {
      final data = await _ble.readCharacteristic(_lightChar);
      await _lightService.handleData(data);
    } catch (e) {
      debugPrint('⚠️ BG-lys polling error: $e');
    }

    // --- Batteri hver 5 min ---
    if (timestamp.difference(_lastBatteryTime) >= const Duration(minutes: 5)) {
      try {
        final bytes = await _ble.readCharacteristic(_batteryChar);
        final level = bytes.isNotEmpty ? bytes[0] : 0;
        await _batteryService.handleBattery(level, timestamp);
      } catch (e) {
        debugPrint('⚠️ BG-batteri polling error: $e');
      }
      _lastBatteryTime = timestamp;
    }

    // --- Synk offline-data hver 10 min ---
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

  /// Kører når servicen stoppes
  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('🛑 BG-service stoppet ved $timestamp');
  }

  @override
  void onButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}
}
