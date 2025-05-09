class ReservationCategory {
  final int id;
  final String name;

  ReservationCategory({required this.id, required this.name});

  factory ReservationCategory.fromJson(Map<dynamic, dynamic> json) {
    return ReservationCategory(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}

class ReservationFacility {
  final int id;
  final String name;
  final ReservationCategory? category;

  ReservationFacility({
    required this.id,
    required this.name,
    this.category,
  });

  factory ReservationFacility.fromJson(Map<dynamic, dynamic> json) {
    final categoryJson = json['category'] as Map<dynamic, dynamic>?;
    return ReservationFacility(
      id: json['id'] as int,
      name: json['name'] as String,
      category: categoryJson != null ? ReservationCategory.fromJson(categoryJson) : null,
    );
  }
}
