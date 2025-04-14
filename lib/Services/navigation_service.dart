import 'package:flutter/material.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  static BuildContext? _context;
  static ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _currentSnackBar;

  factory NavigationService() {
    return _instance;
  }

  NavigationService._internal();

  static void setContext(BuildContext context) {
    _context = context;
  }

  static BuildContext? get context => _context;

  static void hideErrorSnackBar() {
    if (_context != null && _currentSnackBar != null) {
      ScaffoldMessenger.of(_context!).hideCurrentSnackBar();
      _currentSnackBar = null;
    }
  }

  static void showErrorSnackBar(String message) {
    if (_context != null) {
      // Hide any existing snackbar first
      hideErrorSnackBar();
      
      // Show new snackbar and store reference
      _currentSnackBar = ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }


  static void showSnackBar(String message) {
    if (_context != null) {
      // Hide any existing snackbar first
      hideErrorSnackBar();
      
      // Show new snackbar and store reference
      _currentSnackBar = ScaffoldMessenger.of(_context!).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12.0),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade800,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
