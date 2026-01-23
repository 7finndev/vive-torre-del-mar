/* ESTE CODIGO ES PARA OBTENER DE LA PAGINA OFICIAL, LAS NOTICIAS, PERO LA WEB NO ESTA ACTUALIZADA.
    MANTENEMOS ESTE CODIGO PARA CUANDO EXISTAN NOTICIAS ACTUALIZADAS.
    */
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart'; // Para limpiar el HTML del texto
import 'package:intl/intl.dart'; 

// MODELO DE NOTICIA
class NewsItem {
  final String title;
  final String imageUrl;
  final String link;
  final String date;

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.link,
    required this.date,
  });
}

// EL PROVIDER
final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  // TRUCO ANTI-CACHÉ
  final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
  
  // URL API WordPress
  final url = Uri.parse(
    'https://www.torredelmar.org/wp-json/wp/v2/posts?per_page=5&_embed&t=$cacheBuster'
  );

  try {
    final response = await http.get(url).timeout(const Duration(seconds: 10)); // Añadido timeout por seguridad

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      return data.map((json) {
        // 1. TÍTULO LIMPIO
        String titleRaw = json['title']['rendered'] ?? 'Noticia';
        String title = parse(titleRaw).body?.text ?? titleRaw;

        // 2. ENLACE
        String link = json['link'] ?? 'https://www.torredelmar.org';

        // 3. FECHA REAL
        String dateFormatted = "Reciente";
        if (json['date'] != null) {
          try {
            DateTime parsedDate = DateTime.parse(json['date']);
            dateFormatted = DateFormat('d MMM yyyy', 'es_ES').format(parsedDate);
          } catch (e) {
            // Ignorar
          }
        }

        // 4. IMAGEN DESTACADA
        String imageUrl = 'https://via.placeholder.com/600x400/003366/ffffff?text=Vive+Torre+del+Mar'; 
        
        try {
          if (json['_embedded'] != null && 
              json['_embedded']['wp:featuredmedia'] != null && 
              json['_embedded']['wp:featuredmedia'].isNotEmpty) {
            var mediaDetails = json['_embedded']['wp:featuredmedia'][0]['media_details'];
            if (mediaDetails != null && mediaDetails['sizes'] != null && mediaDetails['sizes']['medium_large'] != null) {
               imageUrl = mediaDetails['sizes']['medium_large']['source_url'];
            } else {
               imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
            }
          }
        } catch (e) {
          // Ignorar error de imagen
        }

        return NewsItem(
          title: title, 
          imageUrl: imageUrl, 
          link: link, 
          date: dateFormatted 
        );
      }).toList();
    } else {
      // Si el servidor da error 500 o 404, lanzamos excepción
      throw Exception("Error del servidor: ${response.statusCode}");
    }
  } catch (e) {
    // 🛑 CAMBIO CRÍTICO: NO DEVOLVER LISTA VACÍA [].
    // HAY QUE LANZAR EL ERROR PARA QUE EL HUB SEPA QUE NO HAY INTERNET.
    throw e; 
  }
});