// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductItemModelAdapter extends TypeAdapter<ProductItemModel> {
  @override
  final int typeId = 3;

  @override
  ProductItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductItemModel(
      id: fields[0] as int?,
      productId: fields[1] as int?,
      name: fields[2] as String,
      description: fields[3] as String?,
      courseType: fields[4] as String,
      imageUrl: fields[5] as String?,
      displayOrder: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, ProductItemModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.courseType)
      ..writeByte(5)
      ..write(obj.imageUrl)
      ..writeByte(6)
      ..write(obj.displayOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
