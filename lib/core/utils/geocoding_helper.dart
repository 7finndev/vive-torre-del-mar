import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingHelper {
  /// Devuelve [lat, lng] o null si falla
  static Future<List<double>?> getCoordinatesFromAddress(String address) async {
    try {
      // Truco: Añadimos ", Torre del Mar, España" para mejorar la precisión
      // si el usuario solo escribe la calle.
      final query = "$address, Torre del Mar, Málaga, España";
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=1'
      );

      // Nominatim requiere un User-Agent (normas de uso)
      final response = await http.get(url, headers: {
        'User-Agent': 'TorreDelMarApp/1.0 (com.tuempresa.app)'
      });

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty) {
          final lat = double.parse(data[0]['lat']);
          final lon = double.parse(data[0]['lon']);
          return [lat, lon];
        }
      }
    } catch (e) {
      print("Error geocoding: $e");
    }
    return null;
  }
}