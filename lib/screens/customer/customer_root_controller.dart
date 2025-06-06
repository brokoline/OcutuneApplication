// lib/screens/customer/dashboard/customer_root_controller.dart

import 'package:flutter/material.dart';

/// Controller for CustomerRootScreen (Customer Dashboard)
class CustomerRootController extends ChangeNotifier {
  // Index for the bottom navigation bar
  int _currentIndex = 0;

  /// Getter for the current tab index
  int get currentIndex => _currentIndex;

  /// Sætter den aktuelle tab‐indeks og notifikér lyttere, hvis indeks ændrer sig
  void setIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}
