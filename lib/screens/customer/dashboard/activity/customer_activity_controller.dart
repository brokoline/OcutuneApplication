import 'package:flutter/material.dart';
import 'package:ocutune_light_logger/services/auth_storage.dart';
import '../../../../services/services/api_services.dart';

class CustomerActivityController extends ChangeNotifier {
  List<Map<String, dynamic>> recent = [];
  List<String> activities = [];
  String? selected;
  bool isLoading = false;

  Future<void> loadActivities() async {
    isLoading = true;
    notifyListeners();

    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;

      final activitiesFromDb = await ApiService.fetchCustomerActivities(rawId.toString());

      recent = activitiesFromDb.map((a) {
        final start = DateTime.parse(a['start_time']).toLocal();
        final end = DateTime.parse(a['end_time']).toLocal();
        return {
          'id': a['id'],
          'label': a['event_type'],
          'start': start,
          'end': end,
          'deletable': (a['note'] as String?)?.toLowerCase().contains('manuelt') ?? false,
        };
      }).toList();

      recent.sort((a, b) => b['start'].compareTo(a['start']));
    } catch (e) {
      debugPrint('Error loading activities: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLabels() async {
    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;

      activities = await ApiService.fetchCustomerActivityLabels(rawId.toString());
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading labels: $e');
    }
  }

  Future<void> registerActivity(
      String label,
      DateTime start,
      DateTime end,
      BuildContext context,
      ) async {
    if (label.isEmpty) {
      _showSnackBar(context, 'Vælg en aktivitetstype');
      return;
    }

    final duration = end.difference(start);
    if (duration <= Duration.zero) {
      _showSnackBar(context, 'Sluttid skal være efter starttid');
      return;
    }

    try {
      final rawId = await AuthStorage.getCustomerId();
      if (rawId == null) return;

      await ApiService.addCustomerActivityEvent(
        customerId: rawId.toString(),
        eventType: label,
        note: 'Manuelt registreret',
        startTime: start.toIso8601String(),
        endTime: end.toIso8601String(),
        durationMinutes: duration.inMinutes,
      );

      selected = null;
      await Future.wait([loadActivities(), loadLabels()]);
      _showSnackBar(context, 'Aktivitet registreret');
    } catch (e) {
      _showSnackBar(context, 'Fejl under registrering');
      debugPrint('Register error: $e');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    });
  }
}