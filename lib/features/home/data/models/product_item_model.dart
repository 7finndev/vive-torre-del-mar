import 'package:hive/hive.dart';

part 'product_item_model.g.dart'; 

@HiveType(typeId: 3) // <--- ASIGNAMOS UN ID ÚNICO
class ProductItemModel {
  @HiveField(0)
  final int? id;

  @HiveField(1)
  final int? productId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final String? description;

  @HiveField(4)
  final String courseType; 

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final int displayOrder;

  ProductItemModel({
    this.id,
    this.productId,
    required this.name,
    this.description,
    required this.courseType,
    this.imageUrl,
    this.displayOrder = 0,
  });

  factory ProductItemModel.fromJson(Map<String, dynamic> json) {
    return ProductItemModel(
      id: json['id'],
      productId: json['product_id'],
      name: json['name'],
      description: json['description'],
      courseType: json['course_type'] ?? 'entrante',
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'name': name,
      'description': description,
      'course_type': courseType,
      'image_url': imageUrl,
      'display_order': displayOrder,
    };
  }
}