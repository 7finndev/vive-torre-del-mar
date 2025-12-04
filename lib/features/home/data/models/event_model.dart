import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

// Esta línea es vital para el Adapter:
part 'event_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 1) // ID 1 para Hive
class EventModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String type;

  @HiveField(3)
  final String status;

  @HiveField(4)
  @JsonKey(name: 'theme_color_hex')
  final String themeColorHex;

  @HiveField(5)
  @JsonKey(name: 'logo_url')
  final String? logoUrl;

  @HiveField(6)
  @JsonKey(name: 'bg_image_url')
  final String? bgImageUrl;

  @HiveField(7) @JsonKey(name: 'base_price') final double? basePrice;

  EventModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.themeColorHex,
    this.logoUrl,
    this.bgImageUrl,
    this.basePrice,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) => 
      _$EventModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventModelToJson(this);
}