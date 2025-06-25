import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';

class ClinicianRootController extends ChangeNotifier {
  String _name = '';
  String _role = '';
  bool _loading = true;

  final List<String> _notifications = [];

  /// Offentlig getter til UI’et
  String get name => _name;
  String get role => _role;
  bool get loading => _loading;
  List<String> get notifications => List.unmodifiable(_notifications);

  /// Computed welcome‐tekst
  String get welcomeText {
    if (_role.isNotEmpty) {
      return 'Velkommen $_name, $_role';
    }
    return 'Velkommen $_name';
  }

  ClinicianRootController() {
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loading = true;
    notifyListeners();

    // Hent navn + rolle
    final results = await Future.wait<String?>([
      AuthStorage.getClinicianName(),
      AuthStorage.getUserRole(),
    ]);
    _name = results[0] ?? '';
    _role = results[1] ?? '';

    // Simuler API‐kald til notifikationer
    await Future.delayed(const Duration(milliseconds: 300));
    _notifications
      ..clear()
      ..addAll([
        'Patient X har sendt en ny besked',
        'Patient Y har registreret ny aktivitet',
        'Patient Zs lysniveau er under normalen',
      ]);

    _loading = false;
    notifyListeners();
  }

  Future<void> refreshNotifications() async {
    // Hvis du har et reelt endpoint, kald det her
    await Future.delayed(const Duration(milliseconds: 200));
    notifyListeners();
  }

  void handleNotificationTap(int index) {
    // Business‐logic for notifikationstap
    debugPrint('Notifikation trykket: ${_notifications[index]}');
  }
}
