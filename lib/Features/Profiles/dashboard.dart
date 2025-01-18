import 'package:flutter/material.dart';
import '../../Services/auth_service.dart';
import '../../Services/log_service.dart';
import 'reservation.dart';
import 'supplier.dart';

class Dashboard extends StatefulWidget {
  final String supplierId;

  const Dashboard({Key? key, required this.supplierId}) : super(key: key);

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadDashboard(widget.supplierId);
    });
  }

  // Future<void> loadDashboard(String supplierId) async {
  //   try {
  //     String? category = AuthService.isReservation();

  //     if (category == null) {
  //       throw Exception('Category is missing. Please log in again.');
  //     }

  //     if (category == 'Restaurant') {
  //       navigateToSupplierDashboard(supplierId);
  //     } else {
  //       navigateToReservationDashboard(supplierId);
  //     }
  //   } catch (error) {
  //     LogService.logError('Error in loadDashboard: $error');
  //   }
  // }

  Future<void> loadDashboard(String supplierId) async {
  try {
    bool? isReservation = AuthService.isReservation();

    if (isReservation == null) {
      throw Exception('Reservation status is missing. Please log in again.');
    }

    if (isReservation) {
      navigateToReservationDashboard(supplierId);
    } else {
      navigateToSupplierDashboard(supplierId);
    }
  } catch (error) {
    LogService.logError('Error in loadDashboard: $error');
  }
}


  void navigateToSupplierDashboard(String supplierId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SupplierDashboard(supplierId: supplierId),
      ),
    );
  }

  void navigateToReservationDashboard(String supplierId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReservationDashboard(supplierId: supplierId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Navigator.pop(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}