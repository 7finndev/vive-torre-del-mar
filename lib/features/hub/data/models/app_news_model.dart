class AppNewsModel {
  final int id;
  final String title;
  final String? imageUrl;
  final String? linkUrl;
  final int priority;
  final bool isActive;
  final DateTime publishedAt;

  AppNewsModel({
    required this.id,
    required this.title,
    this.imageUrl,
    this.linkUrl,
    this.priority = 0,
    this.isActive = true,
    required this.publishedAt,
  });

  factory AppNewsModel.fromJson(Map<String, dynamic> json) {
    return AppNewsModel(
      id: json['id'],
      title: json['title'] ?? 'Sin título',
      imageUrl: json['image_url'],
      // Mapeamos 'link_url' (nombre nuevo) o 'link' (nombre viejo) por seguridad
      linkUrl: json['link_url'] ?? json['link'], 
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
      publishedAt: json['published_at'] != null 
          ? DateTime.parse(json['published_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'image_url': imageUrl,
      'link_url': linkUrl,
      'priority': priority,
      'is_active': isActive,
      'published_at': publishedAt.toIso8601String(),
    };
  }
}