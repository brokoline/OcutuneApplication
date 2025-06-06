// lib/services/sync_scheduler.dart

import 'dart:async';
import 'sync_use_case.dart';

/// SyncScheduler sørger for, at SyncUseCase.syncAll() kaldes med et fast interval.
/// Selv hvis der opstår en fejl i syncAll(), vil den vente til næste interval og prøve igen.
class SyncScheduler {
  static Timer? _timer;

  /// Starter en periodisk timer, der kører [SyncUseCase.syncAll()] hvert [interval].
  /// Hvis der allerede er en kørende timer, stoppes den først.
  static void start({required Duration interval}) {
    // Stop en evt. eksisterende timer, så vi undgår flere samtidige Timers
    _timer?.cancel();

    // Kør første synkronisering med det samme
    _runSync();

    // Opret en Timer.periodic, der kører hvert [interval]
    _timer = Timer.periodic(interval, (_) {
      _runSync();
    });
  }

  /// Stopper den periodiske timer.
  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Intern helper-metode, som kalder [SyncUseCase.syncAll()] og fanger fejl.
  /// På den måde sikrer vi, at en exception ikke slukker for næste runde.
  static Future<void> _runSync() async {
    try {
      final now = DateTime.now();
      print("[SyncScheduler] Starter syncAll‐runde ved $now");
      await SyncUseCase.syncAll();
      print("[SyncScheduler] syncAll‐runde færdig uden fejl ved $now");
    } catch (e, stack) {
      // Hvis noget går galt i selve syncAll(), fanger vi det her og logger det.
      print("[SyncScheduler] FEJL i syncAll: $e\n$stack");
      // Timeren fortsætter uanset, så næste kald sker efter interval.
    }
  }
}
