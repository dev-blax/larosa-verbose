
enum RideType {
  economy,
  comfort,
  boda,
}

enum PaymentMethod {
  cash,
  mobileMoney,
  card,
}

class RideModel {
  final String pickupLocation;
  final String destination;
  final RideType rideType;
  final PaymentMethod paymentMethod;
  final DateTime requestTime;

  RideModel({
    required this.pickupLocation,
    required this.destination,
    required this.rideType,
    required this.paymentMethod,
    DateTime? requestTime,
  }) : requestTime = requestTime ?? DateTime.now();
}

class DriverModel {
  final String id;
  final String name;
  final String photoUrl;
  final String vehicleType;
  final String vehicleNumber;
  final double rating;
  final int estimatedArrivalTimeInMinutes;
  final double cost;  
  final double routeDuration;
  final double costAfterOffer;

  DriverModel({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.rating,
    required this.estimatedArrivalTimeInMinutes,
    required this.cost,
    required this.routeDuration,
    required this.costAfterOffer,
  });

  // Mock data for testing
  static DriverModel getMockDriver() {
    return DriverModel(
      id: 'driver-123',
      name: 'James Mbogo',
      photoUrl: 'https://images.pexels.com/photos/32046645/pexels-photo-32046645/free-photo-of-stylish-man-in-cap-and-glasses-in-istanbul.jpeg?auto=compress&cs=tinysrgb&w=600',
      vehicleType: 'Toyota Corolla',
      vehicleNumber: 'T 123 ABC',
      rating: 4.8,
      estimatedArrivalTimeInMinutes: 5,
      cost: 4000.0,
      routeDuration: 10.0,
      costAfterOffer: 3500.0,
    );
  }
}

class LocationSuggestion {
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;

  LocationSuggestion({
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
  });

  // Mock data for testing
  static List<LocationSuggestion> getMockSuggestions() {
    return [
      LocationSuggestion(
        name: 'Glorious Garden',
        address: 'Glorious Garden, Dodoma',
        latitude: -6.1630,
        longitude: 35.7516,
      ),
      LocationSuggestion(
        name: 'Dodoma Airport',
        address: 'Dodoma Airport, Dodoma',
        latitude: -6.1700,
        longitude: 35.7528,
      ),
      LocationSuggestion(
        name: 'Bambalaga Bar and Grill',
        address: 'Bambalaga Bar and Grill, Dodoma',
        latitude: -6.1690,
        longitude: 35.7490,
      ),
    ];
  }
}
