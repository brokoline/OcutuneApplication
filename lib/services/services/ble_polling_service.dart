import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:ocutune_light_logger/services/services/offline_storage_service.dart';
import 'package:intl/intl.dart';

class BlePollingService {
  final FlutterReactiveBle ble;
  final QualifiedCharacteristic readChar;
  Timer? _pollTimer;

  BlePollingService({required this.ble, required this.readChar});

  void startPolling({Duration interval = const Duration(seconds: 3)}) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(interval, (_) async {
      try {
        final rawData = await ble.readCharacteristic(readChar);
        final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());

        if (rawData.length != 48) return;

        final buffer = ByteData.sublistView(Uint8List.fromList(rawData));
        final values = List.generate(12, (i) => buffer.getUint32(i * 4, Endian.little));

        final parsed = {
          "timestamp": now,
          "lux_level": values[0],
          "melanopic_edi": values[1],
          "der": values[2],
          "illuminance": values[3],
          "spectrum": values[4],
          "light_type": values[5],
          "exposure_score": values[6],
          "action_required": values[7],
        };

        await OfflineStorageService.saveLocally(
          data: parsed,
          type: "light_sample",
        );
        print("📥 Polled and saved: $parsed");
      } catch (e) {
        print("⚠️ BLE polling error: $e");
      }
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }
}
