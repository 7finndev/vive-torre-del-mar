// ESTE CODIGO MOSTRARÁ DOS NOTICIAS DE EJEMPLO:
// Ahora el ACET puede usar ese carrusel para poner lo que quiera.
//    Ejemplo: Cuando empiece la ruta, pueden subir una foto que diga "¡YA HEMOS EMPEZADO!" y poner el enlace a las bases legales.
//    Cómo hacerlo: Simplemente entran en su panel de Supabase -> Table Editor -> news -> "Insert Row".
/*
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Constructor factory para convertir desde Supabase
  factory NewsItem.fromMap(Map<String, dynamic> map) {
    // Formatear fecha
    String dateFormatted = "";
    if (map['created_at'] != null) {
      try {
        final date = DateTime.parse(map['created_at']);
        dateFormatted = DateFormat('d MMM yyyy', 'es_ES').format(date);
      } catch (_) {}
    }

    return NewsItem(
      title: map['title'] ?? 'Noticia',
      // Si no hay imagen, ponemos una por defecto bonita
      imageUrl: map['image_url'] ?? 'https://via.placeholder.com/600x400?text=Torre+del+Mar',
      link: map['link'] ?? '',
      date: dateFormatted,
    );
  }
}

// EL PROVIDER
final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    // Pedimos las noticias activas, ordenadas por fecha (la más nueva primero)
    final response = await supabase
        .from('news')
        .select()
        .eq('is_active', true) 
        .order('created_at', ascending: false)
        .limit(5); // Solo las 5 últimas

    final data = List<Map<String, dynamic>>.from(response);
    return data.map((e) => NewsItem.fromMap(e)).toList();

  } catch (e) {
    print("⚠️ Error cargando noticias de Supabase: $e");
    // Devolvemos lista vacía para no romper la UI
    return [];
  }
});
*/

/*  ESTE CODIGO ES PARA OBTENER DE LA PAGINA OFICIAL, LAS NOTICIAS, PERO LA WEB NO ESTA ACTUALIZADA.
    MANTENEMOS ESTE CODIGO PARA CUANDO EXISTAN NOTICIAS ACTUALIZADAS.
    */
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart'; // Para limpiar el HTML del texto
import 'package:intl/intl.dart'; // <--- NUEVO: Para fechas bonitas

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
  // TRUCO ANTI-CACHÉ: Añadimos '?t=...' con la hora actual.
  // Esto obliga al servidor a responder siempre con datos frescos y no usar memoria vieja.
  final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
  
  // URL API WordPress
  // per_page=5: Trae las 5 últimas
  // _embed: Trae las imágenes
  final url = Uri.parse(
    'https://www.torredelmar.org/wp-json/wp/v2/posts?per_page=5&_embed&t=$cacheBuster'
  );

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      return data.map((json) {
        // 1. TÍTULO LIMPIO
        String titleRaw = json['title']['rendered'] ?? 'Noticia';
        String title = parse(titleRaw).body?.text ?? titleRaw;

        // 2. ENLACE
        String link = json['link'] ?? 'https://www.torredelmar.org';

        // 3. FECHA REAL (MEJORA CLAVE) 📅
        // La API devuelve algo como "2023-12-25T14:00:00"
        String dateFormatted = "Reciente";
        if (json['date'] != null) {
          try {
            DateTime parsedDate = DateTime.parse(json['date']);
            // Formateamos a "13 Ene 2026" (Necesitas importar intl)
            dateFormatted = DateFormat('d MMM yyyy', 'es_ES').format(parsedDate);
          } catch (e) {
            // Si falla el parseo, dejamos el texto por defecto
          }
        }

        // 4. IMAGEN DESTACADA
        // Usamos una imagen genérica mejor si falla la carga
        String imageUrl = 'https://via.placeholder.com/600x400/003366/ffffff?text=Vive+Torre+del+Mar'; 
        
        try {
          if (json['_embedded'] != null && 
              json['_embedded']['wp:featuredmedia'] != null && 
              json['_embedded']['wp:featuredmedia'].isNotEmpty) {
            // Intentamos coger la versión "medium_large" si existe, si no, la full
            var mediaDetails = json['_embedded']['wp:featuredmedia'][0]['media_details'];
            if (mediaDetails != null && mediaDetails['sizes'] != null && mediaDetails['sizes']['medium_large'] != null) {
               imageUrl = mediaDetails['sizes']['medium_large']['source_url'];
            } else {
               imageUrl = json['_embedded']['wp:featuredmedia'][0]['source_url'];
            }
          }
        } catch (e) {
          // print("Error extrayendo imagen: $e");
        }

        return NewsItem(
          title: title, 
          imageUrl: imageUrl, 
          link: link, 
          date: dateFormatted // <--- AHORA MOSTRAMOS LA FECHA REAL
        );
      }).toList();
    } else {
      // Si el servidor falla, devolvemos lista vacía en vez de explotar
      print("Error servidor noticias: ${response.statusCode}");
      return [];
    }
  } catch (e) {
    // Si no hay internet o la URL está mal
    print("Error cargando noticias: $e");
    return [];
  }
});
/**/