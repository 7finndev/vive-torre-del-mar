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
// 4. LÓGICA PRIVADA DE WORDPRESS (TU CÓDIGO ORIGINAL REFACTORIZADO)
// =============================================================================
Future<List<NewsItem>> _fetchWordPressNews(int limit) async {
  
  // URL BASE (WordPress API)
  // Usamos el límite dinámico, pero mínimo pedimos 3 para asegurar variedad
  final int fetchCount = limit < 3 ? 3 : limit; 
  final String baseUrl = 'https://www.torredelmar.org/wp-json/wp/v2/posts?per_page=$fetchCount&_embed';
  
  final String cacheBuster = DateTime.now().millisecondsSinceEpoch.toString();
  final String urlWithCache = '$baseUrl&t=$cacheBuster';

  Future<http.Response> fetchWithProxy(String proxyUrl) async {
    return await http.get(Uri.parse(proxyUrl)).timeout(const Duration(seconds: 20));
  }

  http.Response? response;
    
  // LÓGICA DE PROXY (WEB)
  if (kIsWeb) {
    try {
      final proxyA = 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(urlWithCache)}';
      response = await fetchWithProxy(proxyA);
    } catch (e) {
      print("⚠️ Fallo Proxy A, intentando B...");
      final proxyB = 'https://corsproxy.io/?${Uri.encodeComponent(urlWithCache)}';
      response = await fetchWithProxy(proxyB);
    }
  } else {
    // LÓGICA NATIVA (MÓVIL)
    response = await http.get(Uri.parse(urlWithCache)).timeout(const Duration(seconds: 20));
  }

  if (response.statusCode == 200) {
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

  } else {
    throw Exception("Error WordPress: ${response.statusCode}");
  }
}