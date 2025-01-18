import 'package:flutter/material.dart';
import 'package:larosa_block/Features/Cart/Models/product_model.dart';
import 'package:larosa_block/Services/log_service.dart';

class CartController extends ChangeNotifier {
  final List<Product> _cartItems = [];

  List<Product> get cartItems => _cartItems;

  double get totalPrice =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));

  void addProduct(Product product) {
    var existingProduct = _cartItems.firstWhere(
      (item) => item.id == product.id,
      orElse: () => Product(
          id: '', imageUrl: '', name: '', shortDescription: '', price: 0),
    );
    if (existingProduct.id.isNotEmpty) {
      existingProduct.quantity++;
      LogService.logFatal('other one');
    } else {
      _cartItems.add(product);
      LogService.logInfo('added to cart items');
    }
    notifyListeners();
  }

  void removeProduct(Product product) {
    if (product.quantity > 1) {
      product.quantity--;
    } else {
      _cartItems.remove(product);
    }
    notifyListeners();
  }

  void deleteProduct(Product product) {
    _cartItems.remove(product);
    notifyListeners();
  }
}
