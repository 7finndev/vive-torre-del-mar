import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'event_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 1) // Mantenemos tu ID 1
class EventModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  @JsonKey(name: 'type', defaultValue: 'gastronomic')
  final String type;

  @HiveField(3)
  @JsonKey(name: 'status', defaultValue: 'archived')
  final String status;

  // GETTER INTELIGENTE
  String get computedStatus {
    final now = DateTime.now();

    // Si la fecha actual es ANTES del inicio -> 'upcoming'
    if (now.isBefore(startDate)) {
      return 'upcoming';
    }

    // Si la fecha actual es DESPUÉS del fin -> 'archived'
    if (now.isAfter(endDate)) {
      return 'archived';
    }

    // Si estamos en medio -> 'active'
    return 'active';
  }

  @HiveField(4)
  @JsonKey(name: 'theme_color_hex', defaultValue: '#FF9800')
  final String themeColorHex;

  @HiveField(5)
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  @HiveField(6)
  @JsonKey(name: 'bg_image_url')
  final String? bgImageUrl;

  @HiveField(7)
  @JsonKey(name: 'base_price')
  final double? basePrice;

  @HiveField(8)
  @JsonKey(name: 'start_date')
  final DateTime startDate;

  @HiveField(9)
  @JsonKey(name: 'end_date')
  final DateTime endDate;

  @HiveField(10)
  @JsonKey(defaultValue: '')
  final String slug;

  // --- NUEVOS CAMPOS DE DISEÑO (Índices 11-14) ---

  @HiveField(11)
  @JsonKey(name: 'bg_color')
  final String? bgColorHex; // Color de fondo de la app

  @HiveField(12)
  @JsonKey(name: 'nav_color')
  final String? navColorHex; // Color de la barra de navegación

  @HiveField(13)
  @JsonKey(name: 'text_color')
  final String? textColorHex; // Color principal del texto

  @HiveField(14)
  @JsonKey(name: 'font_family')
  final String? fontFamily; // Nombre de la fuente (ej: 'Roboto')

  // ------------------------------------------------

  // Helper Visual
  bool get isActive => computedStatus == 'active';

  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.themeColorHex,
    required this.startDate,
    required this.endDate,
    required this.slug,
    this.logoUrl,
    this.bgImageUrl,
    this.basePrice,
    // Añadimos los nuevos al constructor (opcionales)
    this.bgColorHex,
    this.navColorHex,
    this.textColorHex,
    this.fontFamily,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) =>
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);
}
