import 'package:flutter/material.dart';

/// Controller for CustomerRootScreen (Customer Dashboard)
class CustomerRootController extends ChangeNotifier {
  // Index for the bottom navigation bar
  int _currentIndex = 0;

  /// Getter for the current tab index
  int get currentIndex => _currentIndex;

  /// Sets the current tab index and notifies listeners
  void setIndex(int index) {
    if (index != _currentIndex) {
      _currentIndex = index;
      notifyListeners();
    }
  }

// You can expand this controller with additional customer-related state,
// such as fetching user data, handling notifications, etc.
}
