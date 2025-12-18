import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart'; // Para limpiar el HTML del texto

// MODELO SENCILLO DE NOTICIA
class NewsItem {
  final String title;
  final String imageUrl;
  final String link;
  final String date;

  NewsItem({required this.title, required this.imageUrl, required this.link, required this.date});
}

// EL PROVIDER QUE USARÁ LA VISTA
final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  // URL de la API de WordPress de torredelmar.org
  // Pedimos los últimos 5 posts y que incluya la imagen destacada (_embed)
  final url = Uri.parse('https://www.torredelmar.org/wp-json/wp/v2/posts?per_page=5&_embed');

  final response = await http.get(url);

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    
    return data.map((json) {
      // 1. Título (A veces viene con caracteres raros, los limpiamos)
      String titleRaw = json['title']['rendered'] ?? 'Noticia';
      String title = parse(titleRaw).body?.text ?? titleRaw;

      // 2. Enlace
      String link = json['link'] ?? 'https://www.torredelmar.org';

      // 3. Fecha
      String dateRaw = json['date'] ?? ''; 
      // Podríamos formatearla mejor con intl, de momento la dejamos simple o vacía

      // 4. Imagen (Esto es lo más truculento en WordPress)
      String imageUrl = 'https://via.placeholder.com/300x200?text=Torre+del+Mar'; // Imagen por defecto
      try {
        if (json['_embedded'] != null && 
            json['_embedded']['wp:featuredmedia'] != null && 
            json['_embedded']['wp:featuredmedia'].isNotEmpty) {
          imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
        }
      } catch (e) {
        // Si falla, se queda la imagen por defecto
      }

      return NewsItem(
        title: title, 
        imageUrl: imageUrl, 
        link: link, 
        date: "ACTUALIDAD" // O formatear dateRaw
      );
    }).toList();
  } else {
    throw Exception('Error cargando noticias');
  }
});