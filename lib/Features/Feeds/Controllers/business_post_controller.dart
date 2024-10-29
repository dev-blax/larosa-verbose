import 'package:flutter/material.dart';

class BusinessCategoryProvider with ChangeNotifier {
  final List<Map<String, dynamic>> businessCategories = [
  {
    'id': 1,
    'name': 'Food & Beverages',
    'units': [
      {
        'type': 'Meal Portion',
        'items': [
          {'name': 'Kisinia', 'stock': 0},
          {'name': 'Ugali na Nyama', 'stock': 0},
          {'name': 'Pilau', 'stock': 0},
          {'name': 'Chips Kuku (Fries with Chicken)', 'stock': 0},
          {'name': 'Chips Mayai (Fries with Eggs)', 'stock': 0},
          {'name': 'Pizza', 'stock': 0},
          {'name': 'Biryani', 'stock': 0},
          {'name': 'Makange', 'stock': 0},
        ]
      },
      {
        'type': 'Beverage',
        'items': [
          {'name': 'Chai (Tea)', 'stock': 0},
          {'name': 'Kahawa (Coffee)', 'stock': 0},
          {'name': 'Juice (Mango, Passion, Orange)', 'stock': 0},
          {'name': 'Soda Bottle', 'stock': 0},
          {'name': 'Water Bottle', 'stock': 0},
          {'name': 'Soda Can', 'stock': 0},
          {'name': 'Tamarind Juice', 'stock': 0},
          {'name': 'Coconut Water', 'stock': 0},
        ]
      },
      {
        'type': 'Dish',
        'items': [
          {'name': 'Nyama Choma (Grilled Meat)', 'stock': 0},
          {'name': 'Samaki (Fish)', 'stock': 0},
          {'name': 'Mishkaki (Skewered Meat)', 'stock': 0},
          {'name': 'Kuku wa Kienyeji (Local Chicken)', 'stock': 0},
          {'name': 'Kebab', 'stock': 0},
          {'name': 'Egg Chops', 'stock': 0},
          {'name': 'Sausages', 'stock': 0},
          {'name': 'Mboga za Mchicha (Spinach)', 'stock': 0},
          {'name': 'Supu (Soup)', 'stock': 0},
        ]
      },
      {
        'type': 'Snack',
        'items': [
          {'name': 'Samosa', 'stock': 0},
          {'name': 'Vitumbua', 'stock': 0},
          {'name': 'Mikate ya Boflo (Bread Rolls)', 'stock': 0},
          {'name': 'Bagia (Fried Black Gram)', 'stock': 0},
          {'name': 'Maandazi (Fried Dough)', 'stock': 0},
          {'name': 'Kashata (Coconut Candy)', 'stock': 0},
          {'name': 'Chips (French Fries)', 'stock': 0},
          {'name': 'Popcorn', 'stock': 0},
          {'name': 'Peanuts (Karanga)', 'stock': 0},
        ]
      }
    ]
  },
  {
    'id': 2,
    'name': 'Men\'s Fashion',
    'units': [
      {
        'type': 'Piece',
        'items': [
          {'name': 'Kitenge Shirt', 'stock': 0},
          {'name': 'Dashiki Shirt', 'stock': 0},
          {'name': 'Jacket', 'stock': 0},
          {'name': 'Casual T-Shirt', 'stock': 0},
          {'name': 'Khaki Pants', 'stock': 0},
          {'name': 'Jeans', 'stock': 0},
        ]
      },
      {
        'type': 'Pair',
        'items': [
          {'name': 'Leather Sandals', 'stock': 0},
          {'name': 'Formal Shoes', 'stock': 0},
          {'name': 'Socks', 'stock': 0},
          {'name': 'Sneakers', 'stock': 0},
        ]
      },
      {
        'type': 'Set',
        'items': [
          {'name': 'Suit Set', 'stock': 0},
          {'name': 'Sportswear Set', 'stock': 0},
          {'name': 'Traditional Maasai Shuka Set', 'stock': 0},
        ]
      }
    ]
  },
  {
    'id': 3,
    'name': 'Women\'s Fashion',
    'units': [
      {
        'type': 'Piece',
        'items': [
          {'name': 'Kitenge Dress', 'stock': 0},
          {'name': 'Kanga Wrap', 'stock': 0},
          {'name': 'Maxi Dress', 'stock': 0},
          {'name': 'Blouse', 'stock': 0},
          {'name': 'Skirt', 'stock': 0},
          {'name': 'Casual Top', 'stock': 0},
        ]
      },
      {
        'type': 'Pair',
        'items': [
          {'name': 'Heels', 'stock': 0},
          {'name': 'Flats', 'stock': 0},
          {'name': 'Sneakers', 'stock': 0},
          {'name': 'Sandals', 'stock': 0},
        ]
      },
      {
        'type': 'Set',
        'items': [
          {'name': 'Ankara Suit Set', 'stock': 0},
          {'name': 'Maasai Beaded Jewelry Set', 'stock': 0},
          {'name': 'Kitenge Wrap Set', 'stock': 0},
        ]
      },
      {
        'type': 'Bundle',
        'items': [
          {'name': 'Scarf Bundle', 'stock': 0},
          {'name': 'Hair Accessories Bundle', 'stock': 0},
        ]
      }
    ]
  },
  {
    'id': 4,
    'name': 'Children\'s Fashion',
    'units': [
      {
        'type': 'Piece',
        'items': [
          {'name': 'Kids Kitenge Outfit', 'stock': 0},
          {'name': 'T-Shirt', 'stock': 0},
          {'name': 'Jeans', 'stock': 0},
          {'name': 'Jumpsuit', 'stock': 0},
          {'name': 'Hoodie', 'stock': 0},
        ]
      },
      {
        'type': 'Pair',
        'items': [
          {'name': 'Kids Sneakers', 'stock': 0},
          {'name': 'Sandals', 'stock': 0},
          {'name': 'School Shoes', 'stock': 0},
          {'name': 'Socks', 'stock': 0},
        ]
      },
      {
        'type': 'Set',
        'items': [
          {'name': 'Traditional Wear Set', 'stock': 0},
          {'name': 'Tracksuit Set', 'stock': 0},
        ]
      }
    ]
  }
];

  Map<String, dynamic>? selectedCategory;
  String? selectedUnit; // Add a selected unit variable
  List<Map<String, dynamic>> get selectedUnits => selectedCategory?['units'] ?? [];

 void selectCategory(int categoryId) {
    selectedCategory = businessCategories.firstWhere((cat) => cat['id'] == categoryId);
    selectedUnit = null; // Clear the selected unit when category changes
    notifyListeners();
  }

  void selectUnit(String unit) {
    selectedUnit = unit;
    notifyListeners();
  }

  void clearSelection() {
    selectedCategory = null;
    selectedUnit = null; // Clear selected unit when clearing selection
    notifyListeners();
  }
}
