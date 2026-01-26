import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class OsrmService {
  Future<List<LatLng>> getWalkingRoute(LatLng start, LatLng end) async {
    // Perfil 'foot' para ir andando (o 'walking')
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?geometries=geojson&overview=full'
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 5)); // Timeout de 5s

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['routes'] == null || (data['routes'] as List).isEmpty) {
          return [];
        }

        final List<dynamic> coordinates = data['routes'][0]['geometry']['coordinates'];

        // Convertimos [long, lat] a LatLng(lat, long)
        return coordinates.map((coord) {
          return LatLng(coord[1].toDouble(), coord[0].toDouble());
        }).toList();
      } else {
        return [];
      }
    } catch (e) {
      // Si hay error de red, devolvemos lista vacía y el provider lo marcará como offline
      return [];
    }
  }
}