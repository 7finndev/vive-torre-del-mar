class SponsorModel {
  final int id;
  final String name;
  final String logoUrl;
  final String? websiteUrl;
  final int priority;
  final bool isActive;

  SponsorModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    this.websiteUrl,
    required this.priority,
    required this.isActive,
  });

  factory SponsorModel.fromJson(Map<String, dynamic> json) {
    return SponsorModel(
      id: json['id'],
      name: json['name'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      websiteUrl: json['website_url'],
      priority: json['priority'] ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logo_url': logoUrl,
      'website_url': websiteUrl,
      'priority': priority,
      'is_active': isActive,
    };
  }
}