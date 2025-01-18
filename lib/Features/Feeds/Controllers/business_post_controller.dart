import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:larosa_block/Services/auth_service.dart';
import 'package:larosa_block/Utils/links.dart';
import 'package:larosa_block/Utils/helpers.dart';

class BusinessCategoryProvider with ChangeNotifier {
  List<Map<String, dynamic>> _businessCategories = [];
  List<Map<String, dynamic>> _units = [];
  bool _isLoadingUnits = true;
  String? _errorUnits;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> get businessCategories => _businessCategories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<Map<String, dynamic>> get units => _units;
  bool get isLoadingUnits => _isLoadingUnits;
  String? get errorUnits => _errorUnits;

  Map<String, dynamic>? selectedCategory;
  String? selectedUnit;
  List<Map<String, dynamic>> get selectedUnits =>
      selectedCategory?['units'] ?? [];

  BusinessCategoryProvider() {
    fetchUnits();
    fetchCategories();
  }

  Future<void> fetchUnits() async {
    final token = AuthService.getToken();
    final headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      'Authorization': 'Bearer $token',
    };

    try {
      var url = Uri.https(LarosaLinks.nakedBaseUrl, '/api/v1/unit-types');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _units = data.map((category) {
          return {
            "id": category['id'],
            'name': category['name'],
            'description': category['description'],
          };
        }).toList();
      } else {
        _errorUnits = 'Failed to load units';
        // HelperFunctions.showToast('Cannot load units', false);
      }
    } catch (e) {
      _errorUnits = 'An error occurred while loading units';
      //HelperFunctions.showToast('An error occurred while loading units', false);
    } finally {
      _isLoadingUnits = false;
      notifyListeners();
    }
  }

  Future<void> fetchCategories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final headers = {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      };

      var url = Uri.https(
          LarosaLinks.nakedBaseUrl, '/api/v1/business-categories/all');
      final response = await http.post(url, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _businessCategories = data.map((category) {
          // Convert each category to include units if they don't exist
          return {
            'id': category['id'],
            'name': category['name'],
          };
        }).toList();
      } else {
        _error = 'Failed to load categories';
        HelperFunctions.showToast('Cannot load categories', false);
      }
    } catch (e) {
      _error = 'An error occurred while loading categories';
      HelperFunctions.showToast(
          'An error occurred while loading categories', false);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(int categoryId) {
    selectedCategory = _businessCategories.firstWhere(
      (cat) => cat['id'] == categoryId,
      orElse: () => {} as Map<String, dynamic>,
    );
    selectedUnit = null;
    notifyListeners();
  }

  void selectUnit(String unit) {
    selectedUnit = unit;
    notifyListeners();
  }

  void clearSelection() {
    selectedCategory = null;
    selectedUnit = null;
    notifyListeners();
  }

  void retryFetch() {
    fetchCategories();
  }
}
