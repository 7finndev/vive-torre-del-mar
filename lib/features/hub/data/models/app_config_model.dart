class AppConfigModel {
  final int id;
  // Configuración de Noticias
  final int carouselIntervalMs;
  final int maxNewsCount;
  final bool enableExternalSource;
  
  // Configuración Visual (Tus datos antiguos recuperados)
  final String loadingBgImage;
  final String loadingMessage;

  AppConfigModel({
    required this.id,
    required this.carouselIntervalMs,
    required this.maxNewsCount,
    required this.enableExternalSource,
    required this.loadingBgImage,
    required this.loadingMessage,
  });

  // Convertir de JSON (Supabase) a Objeto Dart
  factory AppConfigModel.fromJson(Map<String, dynamic> json) {
    return AppConfigModel(
      id: json['id'] is int ? json['id'] : 1,
      carouselIntervalMs: json['carousel_interval_ms'] ?? 5000,
      maxNewsCount: json['max_news_count'] ?? 5,
      enableExternalSource: json['enable_external_source'] ?? true,
      // Usamos valores por defecto seguros por si la BD viene vacía
      loadingBgImage: json['loading_bg_image'] ?? 'https://via.placeholder.com/1200', 
      loadingMessage: json['loading_message'] ?? 'Cargando experiencia...',
    );
  }

  // Convertir de Objeto Dart a JSON (Para guardar cambios)
  Map<String, dynamic> toJson() {
    return {
      'carousel_interval_ms': carouselIntervalMs,
      'max_news_count': maxNewsCount,
      'enable_external_source': enableExternalSource,
      'loading_bg_image': loadingBgImage,
      'loading_message': loadingMessage,
    };
  }

  // Utilidad para crear copias modificadas (útil para el editor)
  AppConfigModel copyWith({
    int? carouselIntervalMs,
    int? maxNewsCount,
    bool? enableExternalSource,
    String? loadingBgImage,
    String? loadingMessage,
  }) {
    return AppConfigModel(
      id: id,
      carouselIntervalMs: carouselIntervalMs ?? this.carouselIntervalMs,
      maxNewsCount: maxNewsCount ?? this.maxNewsCount,
      enableExternalSource: enableExternalSource ?? this.enableExternalSource,
      loadingBgImage: loadingBgImage ?? this.loadingBgImage,
      loadingMessage: loadingMessage ?? this.loadingMessage,
    );
  }
}