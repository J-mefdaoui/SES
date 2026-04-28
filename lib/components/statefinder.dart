import 'dart:convert';
import 'package:http/http.dart' as http;

class GetState {
  static Future<String?> getGovernorat(double lat, double lng) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?'
      'lat=$lat&lon=$lng&format=json&addressdetails=1',
    );

    try {
      final response = await http.get(
        url,
        headers: {'User-Agent': 'NeglectMap/1.0', 'Accept-Language': 'en'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        return address['state'] ?? address['region'] ?? 'Unknown';
      }
    } catch (e) {
      print('Online geocoding failed: $e');
    }
    return null;
  }
}
