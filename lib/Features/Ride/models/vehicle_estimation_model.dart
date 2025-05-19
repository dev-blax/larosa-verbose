class VehicleEstimationModel {
  final String vehicleType;
  final int pickupDuration;
  final double cost;
  final double routeDuration;
  final double costAfterOffer;

  VehicleEstimationModel({
    required this.vehicleType,
    required this.pickupDuration,
    required this.cost,
    required this.routeDuration,
    required this.costAfterOffer,
  });
}