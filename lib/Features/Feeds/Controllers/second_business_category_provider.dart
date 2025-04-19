import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Services/log_service.dart';
import 'package:larosa_block/Utils/links.dart';

class BusinessCategory {
  final int id;
  final String name;
  final List<Subcategory> subcategories;

  BusinessCategory({
    required this.id,
    required this.name,
    required this.subcategories,
  });

  factory BusinessCategory.fromJson(Map<String, dynamic> json) {
    return BusinessCategory(
      id: json['id'],
      name: json['name'],
      subcategories: (json['subcategories'] as List)
          .map((e) => Subcategory.fromJson(e))
          .toList(),
    );
  }
}

class Subcategory {
  final int id;
  final String name;
  final List<UnitType> unitTypes;

  Subcategory({
    required this.id,
    required this.name,
    required this.unitTypes,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json) {
    return Subcategory(
      id: json['id'],
      name: json['name'],
      unitTypes: (json['unitTypes'] as List)
          .map((e) => UnitType.fromJson(e))
          .toList(),
    );
  }
}

class UnitType {
  final int id;
  final String name;
  final String description;

  UnitType({
    required this.id,
    required this.name,
    required this.description,
  });

  factory UnitType.fromJson(Map<String, dynamic> json) {
    return UnitType(
      id: json['id'],
      name: json['name'],
      description: json['description'],
    );
  }
}

class SecondBusinessCategoryProvider extends ChangeNotifier {
  final _dioService = DioService();
  List<BusinessCategory> _categories = [];
  Subcategory? _selectedSubcategory;
  bool _isLoading = false;
  String? _error;

  List<BusinessCategory> get categories => _categories;
  Subcategory? get selectedSubcategory => _selectedSubcategory;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioService.dio.post(
        '${LarosaLinks.baseurl}/api/v1/business-categories/all',
      );

      _categories = (response.data as List)
          .map((json) => BusinessCategory.fromJson(json))
          .toList();

      LogService.logDebug('categories: $_categories');
      notifyListeners();
    } on DioException catch (e) {
      _error = e.message ?? 'An error occurred while loading business categories';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> fetchBrandCategories() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _dioService.dio.get(
        '${LarosaLinks.baseurl}/api/v1/business-categories/brand',
      );

      _categories = (response.data as List)
          .map((json) => BusinessCategory.fromJson(json))
          .toList();

      LogService.logDebug('categories: $_categories');
      notifyListeners();
    } on DioException catch (e) {
      _error = e.message ?? 'An error occurred while loading brand categories';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectSubcategory(Subcategory subcategory) {
    _selectedSubcategory = subcategory;
    notifyListeners();
  }

  void clearSelection() {
    _selectedSubcategory = null;
    notifyListeners();
  }
}
