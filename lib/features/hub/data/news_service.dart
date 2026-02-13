import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart'; // Para limpiar el HTML de WordPress
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Importamos los modelos nuevos (Asegúrate de que la ruta sea correcta)
import 'models/app_config_model.dart';
import 'models/app_news_model.dart';

// =============================================================================
// 1. MODELO DE UI (MANTENEMOS EL TUYO PARA NO ROMPER LA PANTALLA)
// =============================================================================
class NewsItem {
  final String title;
  final String imageUrl;
  final String link;
  final String date;
  final bool isInternal; // Para saber si viene de Supabase o WP (opcional)

  NewsItem({
    required this.title,
    required this.imageUrl,
    required this.link,
    required this.date,
    this.isInternal = false,
  });
}

// =============================================================================
// 2. PROVIDER DE CONFIGURACIÓN (VELOCIDAD CARRUSEL, ETC)
// =============================================================================
// La UI podrá leer esto para saber a qué velocidad mover el carrusel
final appConfigProvider = FutureProvider<AppConfigModel>((ref) async {
  final supabase = Supabase.instance.client;
  
  try {
    // Leemos la fila con ID 1
    final data = await supabase.from('app_config').select().eq('id', 1).single();
    return AppConfigModel.fromJson(data);
  } catch (e) {
    // Fallback por si falla la BD o está vacía
    print("⚠️ Error cargando config, usando valores por defecto: $e");
    return AppConfigModel(
      id: 1, 
      carouselIntervalMs: 5000, 
      maxNewsCount: 5, 
      enableExternalSource: true, 
      loadingBgImage: '', 
      loadingMessage: ''
    );
  }
});

// =============================================================================
// 3. PROVIDER PRINCIPAL DE NOTICIAS (HÍBRIDO)
// =============================================================================
final newsProvider = FutureProvider<List<NewsItem>>((ref) async {
  
  final supabase = Supabase.instance.client;
  
  // 1. OBTENER CONFIGURACIÓN Y NOTICIAS INTERNAS (PARALELO)
  // Usamos Future.wait para que sea instantáneo
  final results = await Future.wait<dynamic>([
    ref.watch(appConfigProvider.future), // Reusamos la config
    supabase
      .from('app_news')
      .select()
      .eq('is_active', true)
      .order('priority', ascending: false) // Las más importantes primero
      .order('published_at', ascending: false) // Luego las más nuevas
  ]);

  final AppConfigModel config = results[0] as AppConfigModel;
  final List<dynamic> internalRaw = results[1] as List<dynamic>;

  // 2. PROCESAR NOTICIAS INTERNAS
  List<NewsItem> finalList = internalRaw.map((json) {
    final news = AppNewsModel.fromJson(json);
    
    // Formatear fecha
    String dateFormatted = DateFormat('d MMM yyyy', 'es_ES').format(news.publishedAt);

    return NewsItem(
      title: news.title,
      imageUrl: news.imageUrl ?? 'https://via.placeholder.com/600x400/003366/ffffff?text=Vive+Torre+del+Mar',
      link: news.linkUrl ?? '',
      date: dateFormatted,
      isInternal: true,
    );
  }).toList();

  // 3. ¿NECESITAMOS BUSCAR FUERA? (WORDPRESS)
  // Solo si la config lo permite Y no hemos llenado el cupo máximo
  if (config.enableExternalSource && finalList.length < config.maxNewsCount) {
    try {
      // Calculamos cuántas nos faltan para no pedir de más (aunque WP a veces ignora esto)
      final itemsNeeded = config.maxNewsCount - finalList.length;
      
      // Llamamos a la lógica de WordPress (Tu código original encapsulado)
      final externalNews = await _fetchWordPressNews(itemsNeeded);
      
      finalList.addAll(externalNews);
      
    } catch (e) {
      // SI FALLA WORDPRESS, NO PASA NADA.
      // Simplemente imprimimos el error y devolvemos las noticias que ya tenemos (internas).
      print("⚠️ Error cargando noticias externas (WordPress): $e");
    }
  }

  // 4. LIMITAR Y DEVOLVER
  // Nos aseguramos de no superar el máximo configurado
  return finalList.take(config.maxNewsCount).toList();
});


// =============================================================================
// 4. LÓGICA PRIVADA DE WORDPRESS 
// =============================================================================
Future<List<NewsItem>> _fetchWordPressNews(int limit) async {
  
  final int fetchCount = limit < 3 ? 3 : limit; 
  final String baseUrl = 'https://www.torredelmar.org/wp-json/wp/v2/posts?per_page=$fetchCount&_embed';
  
  final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
  final String urlWithCache = '$baseUrl&t=$cacheBuster';

  Future<http.Response> fetchWithProxy(String proxyUrl) async {
    return await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 15));
  }

  http.Response? response;
    
  // LÓGICA DE PROXY (WEB) - ACTUALIZADA PARA PRODUCCIÓN
  if (kIsWeb) {
    // Lista de proxies ordenados por fiabilidad actual en producción.
    // allorigins get (no raw) suele fallar menos en producción porque devuelve JSON
    // thingproxy y cors-anywhere de heroku son los backups más robustos.
    final proxies = [
      'https://api.allorigins.win/get?url=${Uri.encodeComponent(urlWithCache)}', // Proxy A (JSON envoltorio)
      'https://thingproxy.freeboard.io/fetch/$urlWithCache',                     // Proxy B (Raw)
      'https://cors-anywhere.herokuapp.com/$urlWithCache',                       // Proxy C (Raw)
    ];

    for (int i = 0; i < proxies.length; i++) {
      try {
        response = await fetchWithProxy(proxies[i]);
        
        // Verificamos si la respuesta fue exitosa
        if (response.statusCode == 200) {
          // Si usamos allorigins /get, los datos vienen envueltos en un campo 'contents'
          if (i == 0) {
            final jsonMap = json.decode(response.body);
            // Reemplazamos el body con el contenido real para que el resto del código funcione igual
            response = http.Response(jsonMap['contents'], 200); 
          }
          break; // ¡Éxito! Salimos del bucle
        } else {
           print("⚠️ Proxy ${i+1} devolvió código ${response.statusCode}. Intentando el siguiente...");
        }
      } catch (e) {
        print("⚠️ Fallo Proxy ${i+1}: $e");
        // Si es el último proxy y también falla, dejamos que el código siga
        // (abajo capturará que response == null o statusCode != 200 y lanzará la excepción general)
      }
    }
  } else {
    // LÓGICA NATIVA (MÓVIL) - No necesita Proxy
    try {
      response = await http.get(Uri.parse(urlWithCache)).timeout(const Duration(seconds: 20));
    } catch(e){
      throw Exception("Error de red en móvil: $e");
    }
  }

  // Si después de todos los intentos no hay respuesta o no es 200, abortamos WordPress
  if (response == null || response.statusCode != 200) {
    throw Exception("Imposible obtener noticias de WordPress. Todos los métodos fallaron.");
  }

  // PROCESAMIENTO DE DATOS (Mantenemos tu lógica exacta)
  try {
    final List<dynamic> data = json.decode(response.body);
    
    return data.map((jsonItem) {
      // A. TÍTULO
      String titleRaw = jsonItem['title']['rendered'] ?? 'Noticia';
      String title = parse(titleRaw).body?.text ?? titleRaw;

      // B. ENLACE
      String link = jsonItem['link'] ?? 'https://www.torredelmar.org';

      // C. FECHA
      String dateFormatted = "Externa";
      if (jsonItem['date'] != null) {
        try {
          DateTime parsedDate = DateTime.parse(jsonItem['date']);
          dateFormatted = DateFormat('d MMM yyyy', 'es_ES').format(parsedDate);
        } catch (e) {}
      }

      // D. IMAGEN
      String rawImageUrl = 'https://via.placeholder.com/600x400/cccccc/000000?text=Torre+del+Mar'; 
      try {
        if (jsonItem['_embedded'] != null && 
            jsonItem['_embedded']['wp:featuredmedia'] != null && 
            jsonItem['_embedded']['wp:featuredmedia'].isNotEmpty) {
          
          var mediaDetails = jsonItem['_embedded']['wp:featuredmedia'][0]['media_details'];
          if (mediaDetails != null && mediaDetails['sizes'] != null && mediaDetails['sizes']['medium_large'] != null) {
              rawImageUrl = mediaDetails['sizes']['medium_large']['source_url'];
          } else {
              rawImageUrl = jsonItem['_embedded']['wp:featuredmedia'][0]['source_url'];
          }
        }
      } catch (e) {}

      // E. OPTIMIZACIÓN WEB
      String finalImageUrl = rawImageUrl;
      if (kIsWeb && !rawImageUrl.contains('placeholder.com')) {
        finalImageUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(rawImageUrl)}&w=600&output=webp';
      }

      return NewsItem(
        title: title, 
        imageUrl: finalImageUrl, 
        link: link, 
        date: dateFormatted,
        isInternal: false
      );
    }).toList();
  } catch (e) {
    throw Exception("Error procesando el JSON de WordPress: $e");
  }
}