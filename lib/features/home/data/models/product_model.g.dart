// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductModelAdapter extends TypeAdapter<ProductModel> {
  @override
  final int typeId = 3;

  @override
  ProductModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductModel(
      id: fields[0] as int,
      establishmentId: fields[1] as int,
      eventId: fields[9] as int,
      name: fields[2] as String,
      description: fields[3] as String?,
      ingredients: fields[10] as String?,
      imageUrl: fields[4] as String?,
      allergens: (fields[5] as List?)?.cast<String>(),
      price: fields[6] as double?,
      isWinner: fields[7] == null ? false : fields[7] as bool,
      isAvailable: fields[8] == null ? true : fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ProductModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.establishmentId)
      ..writeByte(9)
      ..write(obj.eventId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.ingredients)
      ..writeByte(4)
      ..write(obj.imageUrl)
      ..writeByte(5)
      ..write(obj.allergens)
      ..writeByte(6)
      ..write(obj.price)
      ..writeByte(7)
      ..write(obj.isWinner)
      ..writeByte(8)
      ..write(obj.isAvailable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: (json['id'] as num).toInt(),
      establishmentId: (json['establishment_id'] as num).toInt(),
      eventId: (json['event_id'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      ingredients: json['ingredients'] as String?,
      imageUrl: json['image_url'] as String?,
      allergens: (json['allergens'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      price: (json['price'] as num?)?.toDouble(),
      isWinner: json['is_winner'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? true,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'establishment_id': instance.establishmentId,
      'event_id': instance.eventId,
      'name': instance.name,
      'description': instance.description,
      'ingredients': instance.ingredients,
      'image_url': instance.imageUrl,
      'allergens': instance.allergens,
      'price': instance.price,
      'is_winner': instance.isWinner,
      'is_available': instance.isAvailable,
    };
