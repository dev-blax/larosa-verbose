import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';

class OnboardingProvider with ChangeNotifier {
  final pageController = PageController();
  int _currentPageIndex = 0;

  int get currentPageIndex => _currentPageIndex;

  void updatePageIndicator(int index) {
    _currentPageIndex = index;
    notifyListeners();
  }

  void dotNavigationClick(int index) {
    _currentPageIndex = index;
    pageController.jumpToPage(index);
    notifyListeners();
  }

  void nextPage(BuildContext context) {
    if (_currentPageIndex == 2) {
      var box = Hive.box('onboardingBox');
      box.put('seenOnboarding', true);
      context.go('/');
    } else {
      _currentPageIndex++;
      pageController.jumpToPage(_currentPageIndex);
      notifyListeners();
    }
  }

  void skipPage() {
    _currentPageIndex = 2;
    pageController.jumpToPage(2);
    notifyListeners();
  }
}
