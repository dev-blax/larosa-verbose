import 'package:flutter/material.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../../../Services/maps_service.dart';

class DestinationInput extends StatelessWidget {
  final Function(String, {double? lat, double? lng}) onDestinationSelected;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback? onProceedToBooking;

  const DestinationInput({
    super.key,
    required this.onDestinationSelected,
    required this.controller,
    required this.focusNode,
    this.onProceedToBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: controller,
        // focusNode: focusNode,
        googleAPIKey: MapsService.apiKey,
        inputDecoration: InputDecoration(
          hintText: 'Where to?',
          prefixIcon: const Icon(Icons.location_on),
        ),
        debounceTime: 500,
        countries: const ['tz'],
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          controller.text = prediction.description ?? '';
          final lat = prediction.lat != null ? double.tryParse(prediction.lat!) : null;
          final lng = prediction.lng != null ? double.tryParse(prediction.lng!) : null;
          onDestinationSelected(
            prediction.description ?? '',
            lat: lat,
            lng: lng,
          );
          focusNode.unfocus();
          // Automatically proceed to booking if callback is provided
          onProceedToBooking?.call();
        },
        itemClick: (Prediction prediction) {
          controller.text = prediction.description ?? '';
          final lat = prediction.lat != null ? double.tryParse(prediction.lat!) : null;
          final lng = prediction.lng != null ? double.tryParse(prediction.lng!) : null;
          onDestinationSelected(
            prediction.description ?? '',
            lat: lat,
            lng: lng,
          );
          focusNode.unfocus();
          // Automatically proceed to booking if callback is provided
          onProceedToBooking?.call();
        },
        seperatedBuilder: const Divider(),
        itemBuilder: (context, index, prediction) { 
          return ListTile(
            leading: const Icon(Icons.place, color: Colors.grey),
            title: Text(prediction.description ?? ''),
            subtitle: Text(
              prediction.description ?? '',
              style: const TextStyle(fontSize: 12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            dense: true,
          );
        },
      ),
    );
  }
}
