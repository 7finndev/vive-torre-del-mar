class SponsorModel {
  final int id;
  final String name;
  final String logoUrl;
  final String? websiteUrl;
  final int priority; // <--- ¡ESTO FALTABA!

  SponsorModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.websiteUrl,
    required this.priority, // <--- Y esto
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) {
    return SponsorModel(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
      websiteUrl: json['website_url'],
      // Si por lo que sea viene null, ponemos 0
      priority: json['priority'] ?? 0, 
    );
  }
}