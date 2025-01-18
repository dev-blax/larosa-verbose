class Product {
  final String id;
  final String imageUrl;
  final String name;
  final String shortDescription;
  final double price;
  int quantity;

  Product({
    required this.id,
    required this.imageUrl,
    required this.name,
    required this.shortDescription,
    required this.price,
    this.quantity = 1,
  });
}