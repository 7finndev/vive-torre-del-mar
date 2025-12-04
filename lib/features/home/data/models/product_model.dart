import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class ProductModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  @JsonKey(name: 'establishment_id')
  final int establishmentId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  @JsonKey(name: 'image_url')
  final String? imageUrl;

  @HiveField(5)
  final List<String>? allergens;

  @HiveField(6)
  final double? price;

  @HiveField(7, defaultValue: false)
  @JsonKey(name: 'is_winner')
  final bool isWinner;

  @HiveField(8, defaultValue: true) 
  @JsonKey(name: 'is_available') 
  final bool isAvailable;
  // ----------------------------

  ProductModel({
    required this.id,
    required this.establishmentId,
    required this.name,
    this.description,
    this.imageUrl,
    this.allergens,
    this.price,
    this.isWinner = false, // Por defecto no es ganador
    this.isAvailable = true,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => 
      _$ProductModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}