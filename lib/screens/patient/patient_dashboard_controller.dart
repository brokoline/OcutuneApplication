import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import 'package:ocutune_light_logger/controller/ble_controller.dart';

class PatientDashboardController extends ChangeNotifier {
  final String patientId;

  PatientDashboardController({ required this.patientId }) {
    _init();
  }

  String _userName = 'Bruger';
  String get userName => _userName;

  bool get isConnected => BleController.connectedDeviceNotifier.value != null;
  int get batteryLevel => BleController.batteryNotifier.value;

  IconData get batteryIcon => _iconForLevel(batteryLevel);
  Color get batteryColor => _colorForLevel(batteryLevel);

  Future<void> _init() async {
    final name = (await AuthStorage.getName()).trim();
    if (name.isNotEmpty) {
      _userName = name.split(' ').first;
    }
    BleController.connectedDeviceNotifier.addListener(_onBleUpdate);
    BleController.batteryNotifier.addListener(_onBleUpdate);
    notifyListeners();
  }

  void _onBleUpdate() {
    notifyListeners();
  }

  IconData _iconForLevel(int level) {
    if (level > 90) return Icons.battery_full;
    if (level > 60) return Icons.battery_6_bar;
    if (level > 40) return Icons.battery_4_bar;
    if (level > 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _colorForLevel(int level) {
    if (level >= 25) return Colors.green;
    if (level >= 10) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    BleController.connectedDeviceNotifier.removeListener(_onBleUpdate);
    BleController.batteryNotifier.removeListener(_onBleUpdate);
    super.dispose();
  }
}
