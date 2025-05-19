import 'package:larosa_block/Services/dio_service.dart';
import 'package:larosa_block/Utils/links.dart';

class ReservationService {
  static Future<List<dynamic>> getReservationsInCart() async {
    var response = await DioService().dio.post(LarosaLinks.reservationList);
    return response.data;
  }
}
